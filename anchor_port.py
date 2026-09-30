"""Ports KCD:MP's per-build anchor table (builds.json, schema 2) from the Steam
WHGame.dll it was made for to another build of the same game version, here
the Xbox Game Pass one.

The table only holds results (RVAs), not the patterns that found them, so
each anchor is carried over by what its method implies:
  export        the export of the same name in the other binary
  rtti          the vtable of the same mangled class name (RTTI type
                descriptor -> complete object locator -> vftable), the one
                with the same 'offset' and slot count
  slot, pattern_slot, string_slot
                the pointer in that vtable at the same slot
  runtime       a value: copied
  ctor_data     gEnv: what ISystem::GetGlobalEnvironment returns
  pattern       code: the bytes at the Steam address with every address-
                bearing field masked, searched for in the other .text; with
                a 'site', the site is ported that way and the address read
                off the instruction there (rip-relative or call target)

Usage: anchor_port.py <steam WHGame.dll> <other WHGame.dll> <builds.json> <out.json>
"""
import json, re, struct, sys, hashlib
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_64
from capstone.x86 import X86_OP_MEM, X86_OP_IMM, X86_REG_RIP

cs = Cs(CS_ARCH_X86, CS_MODE_64)
cs.detail = True


class Bin:
    def __init__(self, path):
        self.path = path
        self.pe = pefile.PE(path, fast_load=True)
        self.pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXPORT']])
        self.img = bytes(self.pe.get_memory_mapped_image())
        self.base = self.pe.OPTIONAL_HEADER.ImageBase
        self.secs = {s.Name.decode().strip('\0'): (s.VirtualAddress, s.VirtualAddress + s.Misc_VirtualSize) for s in self.pe.sections}
        self.text = self.secs['.text']
        self.exports = {}
        for e in self.pe.DIRECTORY_ENTRY_EXPORT.symbols:
            if e.name:
                self.exports[e.name.decode()] = e.address
        self.sha256 = hashlib.sha256(open(path, 'rb').read()).hexdigest()
        self.size = len(open(path, 'rb').read())

    def u32(self, rva): return struct.unpack_from('<I', self.img, rva)[0]
    def u64(self, rva): return struct.unpack_from('<Q', self.img, rva)[0]
    def read(self, rva, n): return self.img[rva:rva + n]
    def in_text(self, rva): return self.text[0] <= rva < self.text[1]
    def in_image(self, rva): return 0 <= rva < len(self.img)

    def cstring(self, rva):
        end = self.img.index(b'\0', rva)
        return self.img[rva:end].decode('latin-1')

    def section_of(self, rva):
        for n, (a, b) in self.secs.items():
            if a <= rva < b: return n
        return None

    # ---- RTTI (MSVC x64) --------------------------------------------------
    def col_of_vtable(self, vt):
        col = self.u64(vt - 8) - self.base
        if not self.in_image(col) or self.u32(col) != 1 or self.u32(col + 20) != col: return None
        return col

    def td_of_col(self, col): return self.u32(col + 12)
    def td_name(self, td): return self.cstring(td + 16)
    def col_offset(self, col): return self.u32(col + 4)

    def find_td(self, name):
        needle = name.encode('latin-1') + b'\0'
        hits = [m.start() - 16 for m in re.finditer(re.escape(needle), self.img)]
        # a type descriptor: vftable pointer, spare (0), name
        return [h for h in hits if h >= 16 and self.u64(h + 8) == 0]

    def cols_for_td(self, td):
        needle = struct.pack('<I', td)
        out = []
        for m in re.finditer(re.escape(needle), self.img):
            c = m.start() - 12
            if c >= 0 and self.u32(c) == 1 and self.u32(c + 20) == c: out.append(c)
        return out

    def vtables_for_col(self, col):
        needle = struct.pack('<Q', self.base + col)
        return [m.start() + 8 for m in re.finditer(re.escape(needle), self.img) if m.start() % 8 == 0]

    def slot_count(self, vt):
        n = 0
        while True:
            va = self.u64(vt + 8 * n)
            if not self.in_text(va - self.base): return n
            n += 1
            if n > 4096: return n

    def vtable_by_name(self, name, offset, slots):
        tds = self.find_td(name)
        if not tds:
            short = name.split('@')[0]          # ".?AVCStatistics"
            alts = sorted(set(m.group().decode('latin-1') for m in re.finditer(re.escape(short.encode('latin-1')) + rb'@[A-Za-z0-9_@]*@@', self.img)))
            if len(alts) == 1: tds = self.find_td(alts[0]); name = alts[0] + ' (stand-in)'
            elif alts: return None, 'no %s; other builds of the class: %s' % (name, alts)
        cands = []
        for td in tds:
            for col in self.cols_for_td(td):
                if self.col_offset(col) != offset: continue
                for vt in self.vtables_for_col(col):
                    cands.append((vt, self.slot_count(vt)))
        if not cands: return None, 'no vtable for %s (offset %d)' % (name, offset)
        exact = [c for c in cands if c[1] == slots]
        if len(exact) == 1: return exact[0][0], 'slots %d' % slots
        if len(cands) == 1: return cands[0][0], 'slots %d (steam had %d)' % (cands[0][1], slots)
        return None, 'ambiguous: %s' % [(hex(v), n) for v, n in cands]

    # ---- code signatures ------------------------------------------------
    def signature(self, rva, length):
        """Bytes of the code at rva with every address-bearing field masked."""
        code = self.read(rva, length + 16)
        sig = bytearray(); mask = bytearray()
        pos = 0
        for insn in cs.disasm(code, self.base + rva):
            if pos >= length: break
            b = bytearray(insn.bytes); m = bytearray(b'\xff' * len(b))
            rel = insn.mnemonic.startswith(('call', 'jmp', 'j', 'loop'))
            for op in insn.operands:
                if op.type == X86_OP_MEM and op.mem.base == X86_REG_RIP and insn.disp_size:
                    for i in range(insn.disp_offset, insn.disp_offset + insn.disp_size): m[i] = 0
                if op.type == X86_OP_IMM and insn.imm_size and (rel or insn.imm_size == 8):
                    for i in range(insn.imm_offset, insn.imm_offset + insn.imm_size): m[i] = 0
            sig += b; mask += m; pos += len(b)
        return bytes(sig), bytes(mask)

    def find(self, sig, mask, limit=3):
        pat = b''.join(b'.' if mask[i] == 0 else re.escape(sig[i:i + 1]) for i in range(len(sig)))
        rx = re.compile(pat, re.DOTALL)
        a, b = self.text
        out = []
        for m in rx.finditer(self.img, a, b):
            out.append(m.start())
            if len(out) >= limit: break
        return out

    def rip_targets(self):
        """Every rip-relative data reference in .text, as a histogram of targets (once per binary; slow)."""
        if hasattr(self, '_rips'): return self._rips
        import collections
        hist = collections.Counter()
        a, b = self.text
        code = self.img[a:b]
        pos = 0
        while pos < len(code):
            last = pos
            for addr, size, mnem, ops in cs.disasm_lite(code[pos:pos + 1 << 20], self.base + a + pos):
                last = addr - self.base - a + size
                i = ops.find('[rip ')
                if i < 0: continue
                j = ops.find(']', i)
                expr = ops[i + 5:j].replace(' ', '')
                try:
                    disp = -int(expr[1:], 16) if expr[0] == '-' else int(expr[1:], 16)
                except (ValueError, IndexError):
                    continue
                hist[addr + size + disp - self.base] += 1
            pos = last + 1 if last <= pos else last   # past the byte capstone could not decode, or on to the next chunk
        self._rips = hist
        return hist

    def rip_sites(self, lo, hi, limit=400):
        """Addresses of instructions in .text whose rip-relative operand lands in [lo, hi)."""
        sites = []
        a, b = self.text
        code = self.img[a:b]
        pos = 0
        while pos < len(code) and len(sites) < limit:
            last = pos
            for addr, size, mnem, ops in cs.disasm_lite(code[pos:pos + 1 << 20], self.base + a + pos):
                last = addr - self.base - a + size
                i = ops.find('[rip ')
                if i < 0: continue
                j = ops.find(']', i)
                expr = ops[i + 5:j].replace(' ', '')
                try:
                    disp = -int(expr[1:], 16) if expr[0] == '-' else int(expr[1:], 16)
                except (ValueError, IndexError):
                    continue
                t = addr + size + disp - self.base
                if lo <= t < hi:
                    sites.append((addr - self.base, t - lo))
                    if len(sites) >= limit: break
            pos = last + 1 if last <= pos else last
        return sites

    def hottest_data(self, window=0x200):
        """The data address with the most rip-relative references into the window after it."""
        hist = self.rip_targets()
        d0, d1 = self.secs['.data']
        pts = sorted(t for t in hist if d0 <= t < d1)
        best, best_n, j = None, 0, 0
        for i, t in enumerate(pts):
            while pts[j] < t: j += 1
            n = 0; k = i
            while k < len(pts) and pts[k] < t + window: n += hist[pts[k]]; k += 1
            if n > best_n: best, best_n = t, n
        return best, best_n

    def insn_target(self, insn):
        for op in insn.operands:
            if op.type == X86_OP_MEM and op.mem.base == X86_REG_RIP:
                return insn.address + insn.size + op.mem.disp - self.base
            if op.type == X86_OP_IMM and insn.mnemonic.startswith(('call', 'jmp', 'j')):
                return op.imm - self.base
        return None

    def target_of(self, rva):
        """What the instruction at rva points at: a rip-relative operand or a branch target."""
        insn = next(cs.disasm(self.read(rva, 16), self.base + rva))
        return self.insn_target(insn), insn

    def insns_from(self, rva, count=120):
        return list(cs.disasm(self.read(rva, 768), self.base + rva))[:count]

    def referring_index(self, site, target):
        """Index of the first instruction at or after site that refers to target, and its mnemonic."""
        for i, insn in enumerate(self.insns_from(site)):
            if self.insn_target(insn) == target: return i, insn.mnemonic
        return None, None


def port_code(steam, other, rva):
    """The address in `other` of the code that is at `rva` in `steam`."""
    for length in (24, 32, 48, 64, 96, 128, 192, 256, 384):
        sig, mask = steam.signature(rva, length)
        if len(sig) < 8: return None, 'too little code'
        hits = other.find(sig, mask)
        if len(hits) == 1: return hits[0], 'unique at %d bytes' % len(sig)
        if not hits: return None, 'no match at %d bytes' % len(sig)
    return None, 'still %d matches at %d bytes' % (len(hits), len(sig))


def main(steam_path, other_path, builds_path, out_path):
    steam, other = Bin(steam_path), Bin(other_path)
    table = json.load(open(builds_path, encoding='utf-8'))
    entry = next(b for b in table['builds'] if b['whgame']['sha256'] == steam.sha256)
    res = entry['resolved']
    out = {}; notes = {}; fails = []

    def rva(s): return int(s, 16)

    # vtables first: the slot anchors need them
    for name, v in res.items():
        if v['method'] != 'rtti': continue
        vt = rva(v['vtable'])
        col = steam.col_of_vtable(vt)
        if col is None: fails.append((name, 'steam vtable has no locator')); continue
        cls = steam.td_name(steam.td_of_col(col)); off = steam.col_offset(col)
        got, why = other.vtable_by_name(cls, off, v['slots'])
        if got is None: fails.append((name, '%s: %s' % (cls, why))); continue
        out[name] = {'method': 'rtti', 'vtable': '0x%x' % got, 'slots': other.slot_count(got)}
        notes[name] = '%s offset %d, %s' % (cls, off, why)
    vt_map = {rva(res[n]['vtable']): rva(out[n]['vtable']) for n in out}

    for name, v in res.items():
        m = v['method']
        if m == 'rtti': continue
        if m == 'runtime':
            out[name] = dict(v); notes[name] = 'copied'
        elif m == 'export':
            ename = next((k for k, a in steam.exports.items() if a == rva(v['rva'])), None)
            if ename and ename in other.exports:
                out[name] = {'method': 'export', 'rva': '0x%x' % other.exports[ename]}; notes[name] = ename
            else:
                fails.append((name, 'export %r not in other' % ename))
        elif m in ('slot', 'pattern_slot', 'string_slot'):
            svt = rva(v['vtable']); slot = v['slot']
            if steam.u64(svt + 8 * slot) - steam.base != rva(v['rva']):
                fails.append((name, 'steam slot %d of %s does not hold %s' % (slot, v['vtable'], v['rva']))); continue
            if svt not in vt_map:
                col = steam.col_of_vtable(svt)
                if col is None: fails.append((name, 'its vtable %s has no RTTI' % v['vtable'])); continue
                cls = steam.td_name(steam.td_of_col(col))
                got, why = other.vtable_by_name(cls, steam.col_offset(col), steam.slot_count(svt))
                if got is None: fails.append((name, 'its vtable %s (%s): %s' % (v['vtable'], cls, why))); continue
                vt_map[svt] = got; notes['vtable ' + v['vtable']] = '%s -> 0x%x (%s)' % (cls, got, why)
            ovt = vt_map[svt]
            if slot >= other.slot_count(ovt): fails.append((name, 'slot %d beyond the other vtable' % slot)); continue
            fn = other.u64(ovt + 8 * slot) - other.base
            out[name] = {'method': m, 'slot': slot, 'rva': '0x%x' % fn, 'vtable': '0x%x' % ovt}; notes[name] = 'from vtable'
        elif m == 'ctor_data':
            # gEnv, a global struct: thousands of instructions refer to its fields. Port a sample of
            # those instructions by their code, read where each points in the other binary, subtract
            # the field offset, and take the answer most of them agree on.
            import collections
            g = rva(v['rva'])
            sites = steam.rip_sites(g, g + 0x200, limit=300)
            votes = collections.Counter(); tried = 0
            for site, field in sites[::10]:
                tried += 1
                osite, why = port_code(steam, other, site)
                if osite is None: continue
                ot, oi = other.target_of(osite)
                if ot is None: continue
                votes[ot - field] += 1
            if not votes: fails.append((name, 'none of %d reference sites ported' % tried)); continue
            best, n = votes.most_common(1)[0]
            if n < 5 or n < 0.6 * sum(votes.values()):
                fails.append((name, 'reference sites disagree: %s' % votes.most_common(4))); continue
            out[name] = {'method': m, 'rva': '0x%x' % best, 'refs_in_0x200': None}
            notes[name] = '%d of %d ported reference sites agree' % (n, sum(votes.values()))
        elif m == 'pattern':
            if 'site' in v:
                site = rva(v['site'])
                idx, mnem = steam.referring_index(site, rva(v['rva']))
                if idx is None:
                    fails.append((name, 'no instruction after steam site %s refers to %s' % (v['site'], v['rva']))); continue
                osite, why = port_code(steam, other, site)
                if osite is None: fails.append((name, 'site: ' + why)); continue
                oins = other.insns_from(osite)
                if idx >= len(oins) or oins[idx].mnemonic != mnem:
                    fails.append((name, 'other site: instruction %d is not a %s' % (idx, mnem))); continue
                ot = other.insn_target(oins[idx])
                if ot is None: fails.append((name, 'other site: instruction %d refers to nothing' % idx)); continue
                out[name] = {'method': m, 'rva': '0x%x' % ot, 'site': '0x%x' % osite}; notes[name] = 'site ' + why + '; insn %d %s' % (idx, mnem)
            else:
                r = rva(v['rva'])
                if not steam.in_text(r): fails.append((name, 'pattern anchor outside .text with no site')); continue
                got, why = port_code(steam, other, r)
                if got is None: fails.append((name, why)); continue
                out[name] = {'method': m, 'rva': '0x%x' % got}; notes[name] = why
        else:
            fails.append((name, 'unknown method ' + m))

    # sanity: every ported code address must be in .text, data in a data section
    for name, v in out.items():
        r = v.get('rva')
        if r and other.section_of(int(r, 16)) is None: fails.append((name, 'ported address outside the image'))

    new_entry = {
        'id': 'gamepass-1.5.6-' + other.sha256[:8],
        'store': 'gamepass',
        'game_version': entry.get('game_version'),
        'ported_from': entry['id'],
        'whgame': {'sha256': other.sha256, 'size': other.size,
                   'timestamp': other.pe.FILE_HEADER.TimeDateStamp, 'size_of_image': other.pe.OPTIONAL_HEADER.SizeOfImage},
        'supported': True,
        'resolved': out,
        'unresolved': {n: why for n, why in fails},
    }
    json.dump({'schema': 2, 'generated_by': 'anchor_port.py', 'builds': [new_entry]}, open(out_path, 'w'), indent=2)

    print('ported %d of %d anchors' % (len(out), len(res)))
    for n, why in notes.items():
        if 'stand-in' in why or 'agree' in why or 'steam had' in why: print('  NOTE %-55s %s' % (n, why))
    for n, why in fails: print('  FAIL %-55s %s' % (n, why))
    return notes


if __name__ == '__main__':
    main(*sys.argv[1:5])
