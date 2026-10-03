# KCD:MP on Xbox Game Pass

**English.** [KCD:MP](https://kcd-mp.com) is a third party's multiplayer mod for Kingdom Come: Deliverance II — a dedicated server, its own game modes, a server browser — closed source and **Steam only**. This package makes its 0.37.0 client run on the **Xbox Game Pass** build of the game without touching any file of theirs: a build-table entry for the Game Pass `WHGame.dll` (355 addresses ported from their Steam entry by `anchor_port.py`), a Steam-shaped junction inside the game folder, and a launcher that injects their client into the re-launched game process in time — from KCD:MP's own window, from a console menu, or with `-Connect host:port`. Steam friends keep using KCD:MP as they do; Game Pass friends run this installer and join the same servers.

Not the same thing as **[Kingdom Come: Co-op](https://github.com/ILliTAH/KingdomCome-Together)** (a fork of Kingdom Come: Together): that one is co-op *inside your own story save* with friends who run Together/KCDMP 0.18.2; this one is KCD:MP's *dedicated-server multiplayer on an empty map*. The two networks cannot see each other — pick the one your friends are on (table below, in Thai). Tested: one Game Pass player on a private freeroam server (trosecko), both from KCD:MP's window and from `-Connect` (0.35.0); one Game Pass player on a public RP server (kutnohorsko) with 0.36.0 — 352 anchors, third person, combat tables 9/9, progression. 0.37.0 (web interfaces with a mouse pointer, drawn by a Chromium engine in `kcdmp\cef\`): the table ported 355/355 — the 352 of 0.36.0 land where they did, plus the 3 of the mouse pointer — and tested in game: one Game Pass player on a public RP server (kutnohorsko), 355 anchors, the mouse pointer's anchors verified, the Chromium engine up inside the Game Pass game, the server's web pages drawn and used with the mouse and the keyboard. A newer `KcdMp-*-win-x64.zip` in Downloads replaces the old KCD:MP by itself (never an older one, never while the game runs; unpacked beside it and swapped in only whole, so a broken zip keeps the old one); KCD:MP's own Update button works too. Off on Game Pass because the KCD:MP client enables them for its verified Steam build only: discovery tracking, and item origin (items the game makes itself reach the server as `unmapped`, which matters under `[audit] mode = "enforce"`). Untested: more than one player at once, mixed Steam + Game Pass on one server, actual fights, voice, the klaster level.

Player download: the installer on the [Releases](https://github.com/ILliTAH/kcdmp-gamepass/releases) page. Build it yourself: `powershell -ExecutionPolicy Bypass -File Build-Installer.ps1` (Inno Setup 6). See `NOTICE.md` for what is whose; GPLv3.

---

# KCD:MP บน Xbox Game Pass (ภาษาไทย)

**KCD:MP** (https://kcd-mp.com) เป็นม็อดมัลติเพลเยอร์ของอีกทีมหนึ่ง: มี **dedicated server**, โหมดเกมของตัวเอง (freeroam ฯลฯ), หน้ารายการเซิร์ฟเวอร์, รองรับหลายสิบคนต่อเซิร์ฟเวอร์ — แต่ทีมนั้นรองรับเฉพาะเกมเวอร์ชัน **Steam**
ชุดนี้ทำให้ KCD:MP รันบนเกมเวอร์ชัน **Xbox Game Pass** ได้ โดยไม่แตะไฟล์ของ KCD:MP เลย — เพิ่มแค่ตารางที่อยู่สำหรับไบนารีของ Game Pass, โฟลเดอร์รูปแบบ Steam ในโฟลเดอร์เกม และตัวเปิดเกมที่ฉีด client ให้ทันเวลา
เพื่อนที่เล่นบน Steam ใช้ KCD:MP ตามปกติ เพื่อนที่เล่นบน Game Pass ใช้ตัวติดตั้งชุดนี้ แล้วเข้าเซิร์ฟเวอร์เดียวกัน

> ไม่เกี่ยวข้องกับ Warhorse Studios และไม่เกี่ยวข้องกับทีม KCD:MP — เป็นงานแฟนเมดที่ไม่แสวงกำไร รุ่นทดลอง

## เล่นแบบไหน ใช้อันไหน

มีสองชุดที่ทำให้ผู้เล่น Game Pass เล่นกับเพื่อนได้ **คนละเครือข่ายกัน ต่อหากันไม่ได้** เลือกตามที่เพื่อนคุณเล่น:

| | **KCD:MP บน Game Pass** (ชุดนี้) | **Kingdom Come: Co-op** ([repo](https://github.com/ILliTAH/KingdomCome-Together)) |
|---|---|---|
| เพื่อนของคุณเล่นอะไร | **KCD:MP** จาก kcd-mp.com (มีเซิร์ฟเวอร์ในรายการของ KCD:MP หรือเพื่อนเปิด KCD:MP server เอง) | **Kingdom Come: Together / KCDMP 0.18.2** หรือ Co-op fork |
| เล่นแบบไหน | มัลติเพลเยอร์บน **แมพเปล่า** (ไม่มีเนื้อเรื่อง ไม่ใช้เซฟ) — เดิน ขี่ม้า ต่อสู้ แชท ตามโหมดที่เซิร์ฟเวอร์ตั้ง | **co-op ในเซฟเนื้อเรื่องของตัวเอง** — เห็นเพื่อนเป็นตัวละครในโลกของเรา เล่นเควสต์ของตัวเองไป |
| ใครดูแลโลก | KCD:MP dedicated server (โปรแกรมแยก เปิดที่เครื่องใครก็ได้ ไม่ต้องมีเกม) | relay ของ Together + เกมของแต่ละคน (หรือ **Host World** เครื่องกลาง) |
| จำนวนคน | ตามเซิร์ฟเวอร์ (ค่าเริ่มต้น 32) | กลุ่มเล็ก |
| เข้าเซิร์ฟเวอร์สาธารณะได้ไหม | ได้ — รายการเซิร์ฟเวอร์ในหน้าต่าง KCD:MP | ไม่มีรายการสาธารณะ ต้องรู้ที่อยู่ของเพื่อน |
| ด่าน | เลือกตามเซิร์ฟเวอร์: `trosecko` (Trosky), `kutnohorsko` (Kuttenberg), `klaster` (Sedletz Monastery) | ตามเซฟของแต่ละคน |
| Game Pass ต้องใช้ | **ตัวติดตั้งชุดนี้** + zip ของ KCD:MP | **`KingdomCome-Coop-Setup`** จาก repo นั้น |
| เพื่อน Steam ต้องใช้ | KCD:MP ตัวปกติจาก kcd-mp.com (ไม่ต้องลงอะไรจากที่นี่) | Together/KCDMP 0.18.2 หรือ Co-op + Modding Tools |
| สถานะ | ทดสอบแล้ว 1 คน บนเซิร์ฟเวอร์ส่วนตัว | ทดสอบทาง Game Pass แล้ว; ทาง Steam/Host World ยังไม่เคยรัน |

สรุปสั้น ๆ:
- เพื่อนบอกว่า "เข้าเซิร์ฟ KCD:MP" / ส่ง `ip:7777` มา / เห็นชื่อเซิร์ฟในหน้าต่าง KCD:MP → **ชุดนี้**
- เพื่อนบอกว่า "เปิด Together / KCDMP แล้วส่ง `ip:7778` มา" / อยากเล่นเนื้อเรื่องด้วยกัน → **Kingdom Come: Co-op**
- ลงทั้งสองชุดคู่กันได้ (คนละโฟลเดอร์ เครื่องที่ทดสอบก็ลงทั้งคู่) แต่ในหนึ่งรอบเกมเล่นได้ทีละแบบ

## ต้องมีอะไร

- Windows 10/11 และ **Kingdom Come: Deliverance II จาก Xbox app / PC Game Pass เวอร์ชัน 1.5.6.0** (ตัวเปิดตรวจ `WHGame.dll` ให้ — ต้องเป็น sha256 `74126a4c…`; ถ้าเกมอัปเดต ต้องรอตารางชุดใหม่ ดู "ข้อจำกัด")
- **KCD:MP client 0.37.0** — `KcdMp-0.37.0-win-x64.zip` (ราว 161 MB เพราะมีเครื่องมือวาดหน้าเว็บในเกม) จาก https://kcd-mp.com (ดาวน์โหลดเอง ชุดนี้ไม่แจกไฟล์ของเขา)
- สิทธิ์ admin **หนึ่งครั้ง** ตอนตั้งค่าครั้งแรก (ยกเว้น Windows Defender) — ที่เหลือไม่ต้อง
- ไม่ต้องมี Steam, ไม่ต้องมี Modding Tools, ไม่ต้องมี Python

## ติดตั้ง

1. ดาวน์โหลด `KcdMp-0.37.0-win-x64.zip` จาก https://kcd-mp.com ไว้ในโฟลเดอร์ **Downloads** (ไม่ต้องแตก)
2. ดาวน์โหลด **`KcdMp-GamePass-Setup-0.37.0.1.exe`** จากหน้า [Releases](https://github.com/ILliTAH/kcdmp-gamepass/releases) แล้วรัน
   (SmartScreen อาจเตือนเพราะไม่ได้เซ็นชื่อ → More info → Run anyway) ติดตั้งลง `%LOCALAPPDATA%\KcdMp-GamePass` ไม่ต้องใช้ admin
3. เปิด **KCD MP for Game Pass** จากไอคอนบนเดสก์ท็อป — ครั้งแรกมันจะทำตามลำดับนี้ (หน้าต่างคำสั่งสีดำบอกทุกขั้น):
   1. หาเกม Game Pass ในเครื่องเอง แล้วสร้างโฟลเดอร์ `Bin\Win64MasterMasterSteamPGO` (junction ชี้กลับมาที่โฟลเดอร์เกม) — เป็นโฟลเดอร์ที่ launcher ของ KCD:MP หา
   2. ขอสิทธิ์ admin **หนึ่งครั้ง** เพื่อยกเว้นโฟลเดอร์ที่ติดตั้ง (`%LOCALAPPDATA%\KcdMp-GamePass`) ใน Windows Defender — ไม่งั้น Defender จะลบ `KcdMp_client.dll` และตัวฉีด `KCDMP_LauncherInjector.exe` (หลังเห็นมันฉีดครั้งแรก) ทิ้งเงียบ ๆ (กด No ได้ แต่ต้องยกเว้นเองทีหลัง)
      ใครลงชุด 0.35.0.1 ไว้จะถูกถามอีกหนึ่งครั้ง เพราะชุดเก่ายกเว้นแค่ `kcdmp\`
   3. แตก zip ของ KCD:MP จาก Downloads ลง `kcdmp\` ในโฟลเดอร์ที่ติดตั้ง (ไฟล์ของ KCD:MP ไม่ถูกแก้ ยกเว้น `servers.txt` ที่ชุดนี้เก็บเซิร์ฟเวอร์ที่คุณเพิ่มเองไว้ตอนอัปเกรด; ใช้แยกจากที่คุณแตกเองที่อื่น)
   4. ตรวจ `WHGame.dll` ของเกมว่าเป็นรุ่นที่ตารางรองรับ แล้วใส่รายการ build ของ Game Pass ลง `builds.json` ของ KCD:MP (ของเดิมเก็บเป็น `builds.json.orig`)
   5. ถามชื่อในเกม (จำไว้ใน `settings.json` เปลี่ยนได้ด้วย `-Name`)
   6. เปิด**หน้าต่างของ KCD:MP เอง** — เลือกเซิร์ฟเวอร์ที่นั่น (ดูข้อถัดไป)

## เล่น — สามทาง

ทุกทางจบเหมือนกัน: เกม Game Pass เปิดขึ้น**ตรงเข้าด่านของเซิร์ฟเวอร์และต่อเข้าเอง** ไม่ผ่านเมนูหลัก ไม่โหลดเซฟ ไม่แตะเซฟของคุณ

### ทาง A — หน้าต่างของ KCD:MP เอง (ค่าเริ่มต้น แนะนำ)

กดไอคอน **KCD MP for Game Pass** → หน้าต่างคำสั่งสีดำเปิดแล้วตามด้วยหน้าต่างของ KCD:MP (รายการเซิร์ฟเวอร์, favourites, direct connect, ตั้งชื่อ) → เลือกเซิร์ฟเวอร์และกดเล่น**ตามปกติเหมือนบน Steam**

**ต้องเปิดหน้าต่างคำสั่งสีดำค้างไว้ตลอดที่เล่น** — มันคือตัวที่ใส่ client ของ KCD:MP เข้าเกมทุกครั้งที่หน้าต่าง KCD:MP สั่งเปิดเกม
(launcher ของ KCD:MP ใส่เองไม่ทัน: เกม Game Pass เปิดตัวเองใหม่ผ่านแพ็กเกจของ Xbox ทำให้สิ่งที่ฉีดใส่โปรเซสแรกหายไป) ปิดหน้าต่าง KCD:MP เมื่อไร หน้าต่างดำปิดตาม

ถ้าเกมเปิดมาแล้วเป็น**เมนูหลักปกติ** แทนที่จะเข้าเซิร์ฟเวอร์ = client ไม่ได้ถูกใส่ (หน้าต่างดำถูกปิด หรือ Defender ลบ DLL) ดู "แก้ปัญหา"

### ทาง B — เมนูในหน้าต่างคำสั่ง (`-Menu`)

```
KcdMpGamePass.bat -Menu
```
แสดงเซิร์ฟเวอร์ที่เคยเข้า (พร้อมสถานะ ด่าน จำนวนคน) และรายการสาธารณะของ KCD:MP → พิมพ์หมายเลข หรือพิมพ์ `host:port` เอง
ใช้เมื่อหน้าต่าง KCD:MP เปิดไม่ขึ้น หรืออยากได้อะไรที่เบา ๆ (`-Browse` = แสดงรายการแล้วจบ ไม่เปิดเกม)

### ทาง C — เข้าเซิร์ฟเวอร์ที่รู้ที่อยู่ทันที (`-Connect`)

```
KcdMpGamePass.bat -Connect 203.0.113.5:7777
KcdMpGamePass.bat -Connect 203.0.113.5:7777 -Name "Henry" -Level kutnohorsko
```
เหมาะกับเซิร์ฟเวอร์ของเพื่อน: ทำ shortcut บนเดสก์ท็อปชี้ไปที่ `KcdMpGamePass.bat` แล้วต่อท้าย ` -Connect ip:port` → กดครั้งเดียวเข้าเลย
ด่านถามจากเซิร์ฟเวอร์เอง (`-Level` ใส่เฉพาะเมื่อเซิร์ฟเวอร์ปิดหน้าสถานะไว้) ที่อยู่ที่เคยเข้าจะไปโผล่ในเมนูของทาง B

### ตัวเลือกทั้งหมดของ `KcdMpGamePass.bat`

| ตัวเลือก | ทำอะไร |
|---|---|
| (ไม่มี) | ตั้งค่าถ้ายังไม่ทำ แล้วเปิดหน้าต่างของ KCD:MP พร้อมตัวใส่ client (ทาง A) |
| `-Menu` | เลือกเซิร์ฟเวอร์จากเมนูในหน้าต่างคำสั่ง (ทาง B) |
| `-Connect host:port` | เข้าเซิร์ฟเวอร์นี้เลย (ทาง C) |
| `-Name "ชื่อ"` | ชื่อที่คนอื่นเห็น (จำไว้ให้ครั้งต่อไป) |
| `-Level trosecko\|kutnohorsko\|klaster` | บังคับด่าน (ปกติถามจากเซิร์ฟเวอร์) |
| `-Browse` | แสดงรายการเซิร์ฟเวอร์แล้วจบ |
| `-KcdMpZip <path>` | ใช้ zip ของ KCD:MP จากที่อื่นแทน Downloads |
| `-NoDefender` | ไม่ถามเรื่องยกเว้น Defender (ต้องจัดการเอง) |
| `-PauseOnError` | ค้างหน้าต่างไว้เมื่อผิดพลาด (ไฟล์ .bat ทำอยู่แล้ว) |

**เล่นเดี่ยวตามปกติ**: เปิดเกมจาก Xbox app เหมือนเดิม — ชุดนี้ไม่ได้ติดอะไรถาวรในเกม client ของ KCD:MP ถูกใส่เฉพาะเกมที่เปิดผ่านชุดนี้เท่านั้น

## เปิดเซิร์ฟเวอร์ KCD:MP เองให้เพื่อน

เซิร์ฟเวอร์เป็นโปรแกรมแยกของ KCD:MP (ไม่ใช่ของชุดนี้) เปิดที่เครื่องใครก็ได้ ไม่ต้องมีเกมหรือ Steam บนเครื่องนั้น:

1. ดาวน์โหลด `KcdMp-server-0.37.0.zip` จาก https://kcd-mp.com แล้วแตก → รัน `windows\KcdMp.Server.exe` หนึ่งครั้ง (มันสร้าง `server.toml` จาก `server.toml.example`)
2. แก้ `server.toml` ในส่วน `[server]`: `name`, `port = 7777`, `password` (`""` = เปิด), `level = "trosecko"` (หรือ `kutnohorsko` / `klaster`), `max_players`
   - เซิร์ฟเวอร์**ส่วนตัว**ที่ไม่อยากให้โผล่ในรายการสาธารณะ: `[master]` → `url = ""`
3. เปิดพอร์ต **7777 ทั้ง TCP และ UDP** ในไฟร์วอลล์และ router (หน้าสถานะ `http://<ip>:7777/` เป็น TCP บนพอร์ตเดียวกัน — ตัวเปิดชุดนี้ใช้อ่านด่านและจำนวนคน)
4. เพื่อน Steam: direct connect `ip:7777` ในหน้าต่าง KCD:MP ตามปกติ / เพื่อน Game Pass: `-Connect ip:7777` หรือพิมพ์ในทาง B หรือ direct connect ในทาง A

ทุกคนต้องใช้ KCD:MP **เวอร์ชันเดียวกับเซิร์ฟเวอร์** (ชุดนี้ = 0.37.0) คู่มือเซิร์ฟเวอร์ฉบับเต็ม: https://docs.kcd-mp.com/getting-started/server-config/
Steam กับ Game Pass บนเซิร์ฟเวอร์เดียวกันน่าจะเล่นด้วยกันได้ (client ตัวเดียวกัน โปรโตคอลเดียวกัน) แต่**ยังไม่ได้ทดสอบจริง** — ถ้าลองแล้วเป็นอย่างไร ช่วยเปิด issue บอกด้วย

## ข้อจำกัดที่ต้องรู้

- ใช้กับ **KCD:MP 0.37.0** และเกม Game Pass **1.5.6.0** (WHGame.dll `74126a4c…`) เท่านั้น — ถ้าเกมอัปเดตหรือ KCD:MP ออกเวอร์ชันใหม่ ต้องรอตารางชุดใหม่
  (ตัวเปิดจะบอกเองว่า build ไม่ตรง หรือ KCD:MP ใหม่กว่าชุดนี้ และจะปิดฟีเจอร์ที่ไม่มีที่อยู่แทนที่จะพัง)
- **ปุ่ม Update ในหน้าต่างของ KCD:MP**: อัปเดตไฟล์ของ KCD:MP ได้ แต่หลังอัปเดตหน้าต่างนั้นเปิดตัวเองใหม่*โดยไม่มีชุดนี้* จึงขึ้นว่า "Kingdom Come: Deliverance II was not found" → ปิดมัน แล้วเปิด **KCD MP for Game Pass** ใหม่ (ชุดนี้ใส่ตาราง Game Pass กลับเข้า `builds.json` ทุกครั้งที่เปิด)
  ถ้า KCD:MP ใหม่กว่าชุดนี้ มันจะเตือนว่าที่อยู่ไม่ครบ → รอ release ใหม่ของชุดนี้ก่อน
- **อัปเกรดจากชุด 0.36.0.1 (หรือเก่ากว่า)**: วาง `KcdMp-0.37.0-win-x64.zip` ไว้ใน Downloads → ลงตัวติดตั้ง 0.37.0.1 ทับ → เปิด KCD MP for Game Pass: มันแตก KCD:MP ตัวใหม่ลงโฟลเดอร์ข้าง ๆ แล้วสลับเข้าแทนตัวเก่าเมื่อแตกครบเท่านั้น (ราว 1-2 นาที; เซิร์ฟเวอร์ที่เราเพิ่มเองใน `servers.txt` ยังอยู่)
  หรือกด Update ในหน้าต่าง KCD:MP ก็ได้ (แบบด้านบน) — ชุดนี้ใส่ตาราง Game Pass ตัวใหม่ให้ทุกครั้งที่เปิด
  ชุดนี้ไม่แตก zip ที่เก่ากว่าตัวที่มีอยู่ และไม่แตกตอนเกมหรือหน้าต่าง KCD:MP เปิดอยู่ (มันเตือนให้ปิดแล้วเปิดชุดนี้ใหม่) ถ้าแตกไม่ผ่าน (zip เสีย ดิสก์เต็ม ไฟล์ถูกใช้อยู่) KCD:MP ตัวเก่ายังอยู่ครบ และมันบอกว่าเพราะอะไร
  ทางสุดท้ายถ้ายังมีปัญหา: ปิดเกมและหน้าต่าง KCD:MP ลบโฟลเดอร์ `kcdmp\` `kcdmp.old` และ `kcdmp.new` (ถ้ามี) ในโฟลเดอร์ติดตั้ง แล้วเปิดชุดนี้ใหม่ (มันแตก zip ให้ใหม่ทั้งหมด)
- ทดสอบแล้ว: ผู้เล่น Game Pass **หนึ่งคน** บนเซิร์ฟเวอร์ส่วนตัว (freeroam, ด่าน trosecko) เข้าได้ เดินได้ปกติ ทั้งจากหน้าต่าง KCD:MP และจาก `-Connect`; client รายงาน "build gamepass-1.5.6-74126a4c (supported), 287 anchors" และช่องที่มันตรวจสอบเองตรงทุกช่อง (KCD:MP 0.35.0)
  0.36.0: ตาราง 352 จุด ย้ายได้ครบ 352/352 (287 จุดเดิมได้ที่อยู่เดียวกับชุด 0.35 ทุกจุด) — ทดสอบแล้ว: ผู้เล่น Game Pass หนึ่งคนเข้าเซิร์ฟเวอร์ RP สาธารณะ (ด่าน kutnohorsko) ได้; client รายงาน "build gamepass-1.5.6-74126a4c (supported), 352 anchors", gEnv ตรง, กล้องบุคคลที่สามเจอที่อยู่ครบ, ตารางท่าต่อสู้ 9/9, ระบบ XP/ทักษะของ 0.36 ทำงาน
  0.37.0: ตาราง 355 จุด ย้ายได้ครบ 355/355 (352 จุดของ 0.36.0 ได้ที่อยู่เดิมทุกจุด + 3 จุดของเมาส์ในหน้าเว็บ) — ทดสอบแล้ว: ผู้เล่น Game Pass หนึ่งคนเข้าเซิร์ฟเวอร์ RP สาธารณะ (ด่าน kutnohorsko) ได้; client รายงาน "build gamepass-1.5.6-74126a4c (supported), 355 anchors", ที่อยู่ของเมาส์ตรวจผ่าน, Chromium (CEF 154) ที่ client เปิดจากโฟลเดอร์ `kcdmp\cef\` ทำงานในเกม Game Pass ได้ และหน้าเว็บของเซิร์ฟเวอร์ขึ้น ใช้เมาส์และคีย์บอร์ดได้
  **ยังไม่ได้ทดสอบ**: หลายคนพร้อมกัน, Steam + Game Pass ในเซิร์ฟเวอร์เดียว, ด่าน klaster, เสียง, การต่อสู้จริง — ฟีเจอร์ของ KCD:MP ทำงานผ่านที่อยู่ที่ย้ายมา (0.36.0: 352 จุด) ถ้าจุดไหนไม่ตรง ฟีเจอร์นั้นจะปิดตัวเองและเขียนไว้ใน `%LOCALAPPDATA%\KcdMp\client.log` (0.37.0: 355 จุด)
- **สองอย่างของ KCD:MP 0.36 / 0.37 ที่ client เปิดให้เฉพาะ build Steam** (ตัดสินใน `KcdMp_client.dll` เอง ตารางของชุดนี้ช่วยไม่ได้):
  - **discovery** (สถานที่ที่ค้นพบ / หนังสือที่อ่าน ที่เซิร์ฟเวอร์เก็บให้): ปิด — `client.log` ขึ้น `discovery: OFF - game build 'gamepass-…' is not one the stores were verified on`
  - **item origin** (ตารางว่าโค้ดส่วนไหนของเกมสร้างไอเท็ม) มีแค่ของ Steam → ไอเท็มที่เกมสร้างเองบน Game Pass ไปถึงเซิร์ฟเวอร์เป็น `unmapped` ทั้งหมด บนเซิร์ฟเวอร์ที่ตั้ง `[audit] mode = "enforce"` ของที่คราฟต์ ทำอาหาร ชำแหละ จะถูกตัดสินด้วยเพดานมูลค่าที่แคบกว่าของผู้เล่น Steam และอาวุธ/เกราะ/กระสุน/เงินที่เกมสร้างเองจะถูกเอาออก เว้นแต่โหมดเกมรับไว้ (`OnPlayerNativeItem`) — ในโหมด `observe` (ค่าเริ่มต้น) แค่บันทึก ไม่เอาอะไรออก
- เกมเปิดผ่านชุดนี้จะส่ง crash report ให้ทีม KCD:MP เหมือน launcher ของเขา (`-KcdMp_reports 1`) — รายงานเหล่านั้นจะบอก build เป็น `gamepass-…`
- Windows Defender / SmartScreen อาจเตือน — ทั้งชุดนี้และ KCD:MP ไม่ได้เซ็นชื่อ
- ชุดนี้ปิด `wh_sys_AutoLoadLastSave` ใน `user.cfg` ของเกมก่อนเปิดทุกครั้ง (ไม่งั้นเกมจะโหลดเซฟแทนที่จะเข้าด่านของเซิร์ฟเวอร์) — ถ้าใช้ Kingdom Come: Co-op ด้วย launcher ของมันเปิดกลับเองตอนกด JOIN

## แก้ปัญหา

| อาการ | สาเหตุ / ทำอย่างไร |
|---|---|
| "KCD:MP's client was not found" | ยังไม่มี `KcdMp-*-win-x64.zip` ใน Downloads → ดาวน์โหลดจาก kcd-mp.com หรือชี้ด้วย `-KcdMpZip <path>` |
| `KcdMp_client.dll` หาย / เกมเปิดเป็นเมนูหลัก | Defender ลบ DLL → เปิดชุดนี้ใหม่แล้วกด Yes ที่ UAC (มันแตก zip ให้ใหม่) หรือเพิ่มข้อยกเว้นเองที่ Windows Security → Exclusions: โฟลเดอร์ `%LOCALAPPDATA%\KcdMp-GamePass` |
| "KCDMP_LauncherInjector.exe is gone" | Defender ลบตัวฉีด (`Behavior:Win32/DefenseEvasion.A!ml` — มันจับจากการที่ตัวฉีดใส่ DLL เข้าเกม) → Windows Security → Virus & threat protection → Protection history → รายการของไฟล์นั้น → Actions → **Allow on device** (หรือลงตัวติดตั้งใหม่) แล้วเปิดชุดนี้ใหม่ กด Yes ที่ UAC ให้มันยกเว้นโฟลเดอร์ |
| เกมเปิดเป็นเมนูหลัก ทั้งที่ DLL อยู่ | หน้าต่างคำสั่งสีดำถูกปิดก่อนเกมเปิด (ทาง A) → เปิดชุดนี้ใหม่ ปล่อยหน้าต่างดำไว้ |
| "WHGame.dll … does not match" / "unknown game build" | เกม Game Pass อัปเดตแล้ว ตารางชุดนี้ใช้กับ 1.5.6.0 เท่านั้น → รอ release ใหม่ (หรือย้ายตารางเองด้วย `anchor_port.py` ด้านล่าง) |
| "KCD:MP is newer than the package" / "wants N anchor(s) this package does not have" | KCD:MP ใหม่กว่า 0.37.0 → รอ release ใหม่ของชุดนี้ |
| "KCD:MP 0.x found (…), but the game or KCD:MP's window is open" | ปิดเกมและหน้าต่าง KCD:MP แล้วเปิดชุดนี้ใหม่ มันจะแตกตัวใหม่ให้ |
| "KCD:MP stays 0.x - …" | อัปเกรดไม่ผ่าน ตัวเก่ายังใช้ได้ตามเดิม: ปิดเกมและหน้าต่าง KCD:MP แล้วเปิดใหม่ ถ้าบอกว่า zip เสียให้ดาวน์โหลดใหม่ (ทางสุดท้าย: ลบโฟลเดอร์ `kcdmp\` `kcdmp.old` และ `kcdmp.new` ในโฟลเดอร์ติดตั้ง แล้วเปิดชุดนี้ใหม่) |
| หน้าต่าง KCD:MP ขึ้น "Kingdom Come: Deliverance II was not found" | หน้าต่างนั้นถูกเปิดเอง ไม่ผ่านชุดนี้ (เช่น หลังกด Update มันเปิดตัวเองใหม่) → ปิดมัน แล้วเปิด **KCD MP for Game Pass** จากไอคอน — อย่าตั้ง Game folder ใน Settings ของ KCD:MP เอง เกมที่มันเปิดตรง ๆ จะไม่มี client |
| เกมไม่เปิด / เปิดแล้วดับทันที | junction `Bin\Win64MasterMasterSteamPGO` ถูกลบหรือโฟลเดอร์เกมเขียนไม่ได้ → เปิดชุดนี้ใหม่ มันสร้างให้อีกครั้งและบอกถ้าสร้างไม่ได้ |
| ต่อเซิร์ฟเวอร์ไม่ติด แต่เกมเข้าด่านแล้ว | เซิร์ฟเวอร์ปิด / พอร์ต 7777 ไม่เปิด / เวอร์ชันไม่ตรง → ดูสถานะที่ `http://<ip>:7777/` และ `client.log` |

ไฟล์บันทึกที่ควรแนบเวลาถามปัญหา: `%LOCALAPPDATA%\KcdMp\client.log` (ของ client KCD:MP — บอกว่า build ไหน โหลดที่อยู่ครบไหม ต่อเซิร์ฟเวอร์ได้ไหม) และข้อความในหน้าต่างคำสั่งสีดำ

## ถอนการติดตั้ง

Settings → Apps → **KCD MP for Game Pass** → Uninstall — ลบไฟล์ของชุดนี้และสำเนา KCD:MP ในโฟลเดอร์ติดตั้ง (ถอนไม่ได้ขณะเกมเปิดอยู่)
สิ่งที่เหลือไว้: junction `Bin\Win64MasterMasterSteamPGO` ในโฟลเดอร์เกม (ทางลัดเปล่า ๆ ลบได้ด้วย `rmdir` — **อย่าใช้ `rd /s`** เพราะจะไล่ลบของจริงที่มันชี้ไป) และข้อยกเว้นใน Windows Defender (ลบเองใน Windows Security → Exclusions)

## ทำงานอย่างไร (สำหรับคนอยากรู้)

- KCD:MP ประกอบด้วย launcher, `KcdMp_client.dll` ที่ถูกฉีดเข้าเกม และ `builds.json` — ตารางที่อยู่หลายร้อยจุดใน `WHGame.dll` (0.35.0: 287, 0.36.0: 352, 0.37.0: 355) ต่อหนึ่ง build ของเกม (vtable, ช่องใน vtable, export, ฟังก์ชัน, ตัวแปร gEnv) client ตรวจ build จาก timestamp + PDB GUID ของ `WHGame.dll` ถ้าไม่มีในตารางก็ไม่ทำงาน — Game Pass มี `WHGame.dll` คนละไบนารีกับ Steam (เวอร์ชันเกมเดียวกัน คอมไพล์คนละครั้ง)
- `anchor_port.py` ย้ายตารางจาก `WHGame.dll` ของ Steam ไปยังของ Game Pass: vtable ตามชื่อคลาส (RTTI; คลาส `Steam::CStatistics` ที่ Game Pass ไม่มี ใช้ `GDK::CStatistics` แทน), ช่องใน vtable ตามลำดับ, export ตามชื่อ, โค้ดด้วยลายเซ็นไบต์ที่มาสก์ที่อยู่ออก (ขยายความยาวจนกว่าจะเจอที่เดียว) และ gEnv จากการที่จุดอ้างอิงทั้ง 29 จุดชี้ไปที่เดียวกัน — ได้ครบทุกจุด (0.35.0: 287/287, 0.36.0: 352/352, 0.37.0: 355/355; ทุกจุดที่ซ้ำกับรุ่นก่อนได้ที่อยู่เดิม) และใน 0.35.0 211 จาก 219 ที่อยู่โค้ดค้นกลับไปหาต้นทาง Steam ได้ (ที่เหลือเป็นฟังก์ชันเล็ก ๆ ที่คอมไพเลอร์ยุบรวม) ผลอยู่ใน `gamepass-1.5.6-74126a4c.json`
- เกม Game Pass เมื่อถูกเปิดจาก exe ตรง ๆ จะเปิดตัวเองใหม่ผ่านแพ็กเกจของ Xbox (และไม่ยอมถ้า exe อยู่นอกโฟลเดอร์แพ็กเกจ — junction จึงต้องอยู่**ใน**โฟลเดอร์เกม) DLL ที่ฉีดใส่โปรเซสแรกจึงหายไป ตัวเปิดของชุดนี้จับโปรเซสที่เปิดใหม่ อ่าน command line จาก PEB ของมันภายใน ~1 ms (WMI ใช้ 1.8 s ช้าเกิน) แล้วฉีด `KcdMp_client.dll` ให้ภายใน ~100 ms ก่อนที่ `WHGame.dll` จะถูกโหลด
- ตัวฉีดคือ `KCDMP_LauncherInjector.exe` ของโปรเจกต์ Kingdom Come: Together (GPLv3, build จาก source ใน fork Co-op)

### สำหรับนักพัฒนา: ย้ายตารางใหม่เมื่อเกมหรือ KCD:MP อัปเดต

```
pip install pefile capstone
python anchor_port.py <WHGame.dll ของ Steam> <WHGame.dll ของ Game Pass> <builds.json ของ KCD:MP> gamepass-<เวอร์ชัน>-<sha8>.json
```
ต้องใช้ `WHGame.dll` **ทั้งสองฝั่งของเกมเวอร์ชันเดียวกัน** (Steam ต้องเป็น build ที่ `builds.json` ของ KCD:MP รู้จัก) ผลลัพธ์บอก `unresolved` ถ้ามีจุดที่ย้ายไม่ได้
ผลลัพธ์**ไม่มี** `pdb_guid` / `pdb_age` (client ใช้ระบุ build) และหมายเหตุ `exe` — ถ้าเกมยังเป็น build เดิม (sha256 เดิม) ให้เอาเฉพาะ `resolved` ไปแทนในไฟล์ `gamepass-…json` เดิม แล้วแก้ `ported_by`
จากนั้นแก้ `$entryFile` ใน `KcdMpGamePass.ps1` ให้ชี้ไฟล์ใหม่ แก้จำนวนจุดใน `tests\Test-KcdMpUpgrade.ps1` แล้วรันมัน (`powershell -ExecutionPolicy Bypass -File tests\Test-KcdMpUpgrade.ps1`) ก่อน `Build-Installer.ps1 -Version <เวอร์ชัน KCD:MP>.<รอบ>` — อย่า commit `WHGame.dll` หรือไฟล์ของ KCD:MP (`.gitignore` กันไว้แล้ว)

## ไฟล์ในชุดนี้ / สัญญาอนุญาต

ดู `NOTICE.md` ว่าอะไรเป็นของใคร — สคริปต์และตารางในนี้เป็น GPLv3 (`LICENSE`); ไฟล์ของ KCD:MP และของเกมไม่อยู่ในชุดนี้และไม่ถูกแจก
