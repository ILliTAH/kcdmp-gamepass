# KCD:MP (kcd-mp.com) on the Xbox Game Pass build of Kingdom Come: Deliverance II.
#
# KCD:MP is a third party's multiplayer mod (closed source): a launcher, a
# client DLL it injects into the game, and a table of addresses per game
# build (builds.json). It supports the Steam build only. This script makes it
# run on the Game Pass build with three things of ours:
#
#   1. a table entry for the Game Pass WHGame.dll, made by anchor_port.py from
#      KCD:MP's own Steam entry (gamepass-1.5.6-74126a4c.json), merged into
#      KCD:MP's builds.json;
#   2. a Steam-shaped path inside the game folder (Content\Bin\Win64Master
#      MasterSteamPGO -> Content, a junction), which is the only shape the
#      KCD:MP launcher accepts and the only place the Game Pass bootstrap
#      will start the game from;
#   3. our own start: the Game Pass game re-launches itself through its
#      package, so a DLL injected into the process one starts is lost. The
#      client's options ride on the command line (they survive the
#      re-launch), and the client is injected into the re-launched process
#      as soon as it appears -- in time, before WHGame.dll is mapped.
#
# Usage (KcdMpGamePass.bat runs this):
#   KcdMpGamePass.bat                        set up on first run, then KCD:MP's own window: pick a
#                                            server there; this window stays behind it and puts the
#                                            client into the game each time the window starts one
#   KcdMpGamePass.bat -Menu                  no window: pick a server from a list here
#   KcdMpGamePass.bat -Connect host:port     join that server at once
#   KcdMpGamePass.bat -Browse                only list the servers
#
# Tested: one Game Pass player on a private freeroam server, level trosecko.
[CmdletBinding()]
param(
    [string] $Connect  = '',       # host:port to join at once
    [string] $Name     = '',       # the name other players see (remembered)
    [string] $Level    = '',       # trosecko | kutnohorsko | klaster; empty = asked from the server
    [string] $KcdMpZip = '',       # KCD:MP's client zip; empty = the highest KcdMp-<version>-win-x64.zip in Downloads
    [switch] $Browse,              # list the servers and stop
    [switch] $Menu,                # pick a server here instead of in KCD:MP's window
    [switch] $NoDefender,          # do not offer the Windows Defender exclusion
    [switch] $NoUpdate,            # do not look online for a newer KCD:MP or Game Pass table
    [switch] $PauseOnError
)
$ErrorActionPreference = 'Stop'
trap {
    Write-Host ''
    Write-Host "ERROR: $_" -ForegroundColor Red
    if ($PauseOnError) { Read-Host 'Press Enter to close' | Out-Null }
    exit 1
}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'KcdmpCommon.ps1')

$kcdmpDir     = Join-Path $here 'kcdmp'                 # KCD:MP's own files, unpacked from their zip
$entryFile    = Join-Path $here 'gamepass-1.5.6-74126a4c.json'
$injector     = Join-Path $here 'KCDMP_LauncherInjector.exe'
$settingsFile = Join-Path $here 'settings.json'
$levelIds     = @{ 'kuttenberg' = 'kutnohorsko'; 'trosky' = 'trosecko'; 'sedletz monastery' = 'klaster' }

function Read-Settings {
    if (Test-Path -LiteralPath $settingsFile) {
        try { return (Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json) } catch { }
    }
    return [pscustomobject]@{ Name = ''; Servers = @() }
}
function Save-Settings($s) { $s | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $settingsFile -Encoding UTF8 }

# --- 1. the game -------------------------------------------------------------
$exe = Find-GamePassExe
if (-not $exe) { throw 'Kingdom Come: Deliverance II from Xbox Game Pass was not found on this PC.' }
$content = Split-Path -Parent $exe
$whgame  = Join-Path $content 'WHGame.dll'
$steamShaped = Join-Path $content 'Bin\Win64MasterMasterSteamPGO'
if (-not (Test-Path -LiteralPath $steamShaped)) {
    New-Item -ItemType Directory -Force -Path (Join-Path $content 'Bin') | Out-Null
    New-Item -ItemType Junction -Path $steamShaped -Target $content | Out-Null
    Write-Host "Made $steamShaped (a junction to the game folder)."
}
Write-Host "Game: $content"

# --- 2. Windows Defender, before anything of KCD:MP is unpacked -----------------
# Defender removes KcdMp_client.dll (it is an unsigned DLL made to be injected
# into a game) and, once it has watched an injection, this package's injector
# too (Behavior:Win32/DefenseEvasion.A!ml). One exclusion for this whole folder
# -- the injector, and KCD:MP's files under kcdmp\ -- needs one elevation.
# Whether the exclusion is there cannot be read without admin rights, so it is
# asked for once per folder (remembered), and again whenever the DLL has gone
# missing. Packages up to 0.35.0.1 excluded kcdmp\ only: those players are
# asked once more. It is asked for before the first unpack: under Defender the client
# went as it was written, and the unpack refused that zip at every start.
$settings = Read-Settings
function Request-Exclusion {
    Write-Host 'Windows Defender deletes KCD:MP''s client DLL and this package''s injector. Adding an exclusion for this folder (one admin prompt)...'
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command',
            "Add-MpPreference -ExclusionPath '$($here -replace "'", "''")'"
        $settings | Add-Member -NotePropertyName DefenderExclusionFolder -NotePropertyValue $here -Force
        Save-Settings $settings
    } catch { Write-Warning "No exclusion was added ($($_.Exception.Message)). If files keep disappearing, add $here under Windows Security > Exclusions." }
}
if (-not $NoDefender -and $settings.DefenderExclusionFolder -ne $here) { Request-Exclusion }

# --- 3. KCD:MP's files -------------------------------------------------------
# A newer KCD:MP in Downloads is unpacked over the old one (KcdMpUpgrade.ps1): never an older one, never while the
# game or KCD:MP's own programs hold the files, and through kcdmp.new - swapped in only whole, so a failure keeps the old
# install. KCD:MP's own Update button works too; either way step 4 puts our entry back.
. (Join-Path $here 'KcdMpUpgrade.ps1')
function Get-KcdMpZip {
    if ($KcdMpZip) { return $KcdMpZip }
    return Select-KcdMpZip (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads')
}
# the first unpack, or one after Defender took the client: with nothing to keep, a failure stops the start
function Expand-KcdMp([string] $zip) {
    if (-not $zip -or -not (Test-Path -LiteralPath $zip)) {
        throw "KCD:MP's client was not found. Download KcdMp-<version>-win-x64.zip from https://kcd-mp.com into your Downloads folder and run this again."
    }
    Write-Host "Unpacking $(Split-Path -Leaf $zip) (from 0.37 it brings a web engine: about 350 MB, a minute or two)..."
    $result = Install-KcdMpZip $zip $kcdmpDir
    if ($result -ne $true -and "$result" -like '*Windows Defender*' -and -not $NoDefender) {
        Request-Exclusion   # remembered, but not there (removed since, or the admin window failed): asked again, once
        $result = Install-KcdMpZip $zip $kcdmpDir
    }
    if ($result -ne $true) { throw "KCD:MP could not be unpacked: $result" }
}
$dll = Join-Path $kcdmpDir 'KcdMp_client.dll'
if (Repair-KcdMpSwap $kcdmpDir) { Write-Host 'An unpack was cut short last time: it is finished now.' }
# KCD:MP's newest client from its own release page, into Downloads when it is newer than the one here and than any zip
# there: the unpack below moves to it like to any zip in Downloads (0.39.1.1: install this package once)
if (-not $NoUpdate -and -not $KcdMpZip) {
    $latest = Get-KcdMpLatestRelease
    if ($latest) {
        $downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
        $haveNow = Get-KcdMpUnpackedVersion $kcdmpDir
        $inDownloads = Select-KcdMpZip $downloads
        $offeredNow = if ($inDownloads) { Get-KcdMpZipVersion $inDownloads } else { $null }
        if ((-not $haveNow -or $latest.Version -gt $haveNow) -and (-not $offeredNow -or $latest.Version -gt $offeredNow)) {
            Write-Host "KCD:MP $($latest.Version) is out: downloading $($latest.Name) into Downloads (about 170 MB, a few minutes)..."
            $got = Save-KcdMpRelease $latest $downloads
            if (Test-Path -LiteralPath "$got") { Write-Host 'Downloaded, and it matches its .sha256.' }
            else { Write-Warning "KCD:MP $($latest.Version) was not downloaded - $got. This start keeps the KCD:MP here." }
        }
    }
}
$zip = Get-KcdMpZip
$offered = if ($zip) { Get-KcdMpZipVersion $zip } else { $null }
$have = Get-KcdMpUnpackedVersion $kcdmpDir
switch (Get-KcdMpUnpackDecision $offered $have (Test-Path -LiteralPath (Join-Path $kcdmpDir 'KcdMp_launcher.exe')) (Test-KcdMpBusy $kcdmpDir)) {
    'unpack'  { Expand-KcdMp $zip }
    'upgrade' {
        Write-Host "KCD:MP $offered found ($(Split-Path -Leaf $zip)); this package had $have. Moving to it (about 350 MB, a minute or two)..."
        $result = Install-KcdMpZip $zip $kcdmpDir
        if ($result -eq $true) { Write-Host "KCD:MP is $offered now." }
        else { Write-Warning "KCD:MP stays $have - $result. Close the game and KCD:MP's window and start this again, or download the zip again if it is broken." }
    }
    'busy'    { Write-Warning "KCD:MP $offered found ($(Split-Path -Leaf $zip)), but the game or KCD:MP's window is open: close them and start this again to move from $have." }
}

if (-not (Test-Path -LiteralPath $dll)) {
    Write-Host 'KcdMp_client.dll is missing (Defender took it).'
    if (-not $NoDefender) { Request-Exclusion }
    if (Test-KcdMpBusy $kcdmpDir) { throw "KcdMp_client.dll is gone, and the game or KCD:MP's window is open: close them and start this again." }
    $have = Get-KcdMpUnpackedVersion $kcdmpDir
    if ($have -and $offered -and $offered -lt $have) {   # never an older KCD:MP than the one here
        throw "KcdMp_client.dll is gone, and the zip in Downloads ($offered) is older than KCD:MP here ($have). Give the DLL back in Windows Security > Virus & threat protection > Protection history (the entry for it > Actions > Allow on device), or download KCD:MP $have again, then start this again."
    }
    Expand-KcdMp $zip
    if (-not (Test-Path -LiteralPath $dll)) { throw "KcdMp_client.dll is removed as soon as it is unpacked. Restore it in Windows Security > Protection history and exclude $here." }
}
# The installer put the injector here; only Defender takes it away, and only the player can give it back.
if (-not $Browse -and -not (Test-Path -LiteralPath $injector)) {
    throw "KCDMP_LauncherInjector.exe is gone from $here (Windows Defender removed it). Give it back in Windows Security > Virus & threat protection > Protection history (the entry for it > Actions > Allow on device), or run the installer again, then start this again."
}

# --- 4. the build table ------------------------------------------------------
$hash = (Get-FileHash -LiteralPath $whgame -Algorithm SHA256).Hash.ToLower()
# the project's newest table for this game build: a KCD:MP release that wants new anchors gets one (0.39.1.1)
if (-not $NoUpdate) {
    $tableNews = Update-GamePassTable $entryFile $hash
    if ($tableNews -like 'updated*') { Write-Host "The Game Pass table is the project's newest now: $tableNews." }
}
$entry = (Get-Content -LiteralPath $entryFile -Raw | ConvertFrom-Json).builds[0]
if ($hash -ne $entry.whgame.sha256) {
    throw "This game's WHGame.dll ($($hash.Substring(0,8))...) is not the build this package knows ($($entry.id)). The game was updated: a new table entry is needed (tools\kcdmp-gamepass\anchor_port.py in the project)."
}
$tablePath = Join-Path $kcdmpDir 'builds.json'
$table = Get-Content -LiteralPath $tablePath -Raw | ConvertFrom-Json
# KCD:MP's own update rewrites builds.json (our entry gone), and a package for a
# newer KCD:MP brings a bigger entry than the one merged before: either way ours
# goes in, replacing any older copy. The original is kept only while it is KCD:MP's.
$current = $table.builds | Where-Object { $_.id -eq $entry.id } | Select-Object -First 1
if (-not $current -or ($current | ConvertTo-Json -Depth 8 -Compress) -ne ($entry | ConvertTo-Json -Depth 8 -Compress)) {
    if (-not $current) { Copy-Item -LiteralPath $tablePath -Destination "$tablePath.orig" -Force }
    $table.builds = @(@($table.builds | Where-Object { $_.id -ne $entry.id }) + $entry)
    $table | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $tablePath -Encoding UTF8
    Write-Host "Put $($entry.id) ($(@($entry.resolved.PSObject.Properties).Count) anchors) into KCD:MP's builds.json (the original is builds.json.orig)."
}
# KCD:MP's own Steam entry says which anchors this KCD:MP version wants.
$steam = $table.builds | Where-Object { $_.store -eq 'steam' } | Select-Object -First 1
if ($steam) {
    $missing = @($steam.resolved.PSObject.Properties.Name | Where-Object { -not $entry.resolved.PSObject.Properties[$_] })
    if ($missing.Count -gt 0) { Write-Warning "This KCD:MP version wants $($missing.Count) anchor(s) this package does not have (KCD:MP is newer than the package): those features stay off." }
}

# --- 5. who ----------------------------------------------------------------
if (-not $Name) { $Name = $settings.Name }
if (-not $Name) {
    $Name = (Read-Host 'Your name in the game').Trim()
    if (-not $Name) { throw 'A name is needed.' }
}
$settings.Name = $Name

# --- 6. which server -----------------------------------------------------------
function Get-ServerStatus([string] $address) {
    try { return (Invoke-RestMethod -Uri "http://$address/" -TimeoutSec 4) } catch { return $null }
}
function Show-Servers {
    $rows = @()
    $n = 0
    foreach ($s in @($settings.Servers)) {
        $n++; $st = Get-ServerStatus $s
        $rows += [pscustomobject]@{ '#' = $n; server = $(if ($st) { $st.name } else { '(no answer)' }); level = $(if ($st) { $st.level } else { '-' });
                                   players = $(if ($st) { "$($st.players)/$($st.maxPlayers)" } else { '-' }); address = $s }
    }
    $launcher = Join-Path $kcdmpDir 'KcdMp_launcher.exe'
    Write-Host 'Asking the public list...'
    $out = & $launcher --browse --game $content 2>&1
    foreach ($line in $out) {
        if ($line -match '^\s*(\d+)\s+(.*?)\s{2,}(\S.*?)\s{2,}(\d+/\d+|-)\s+(\d+|-)\s+(\S+)\s*$') {
            $n++
            $rows += [pscustomobject]@{ '#' = $n; server = $Matches[2].Trim(); level = $Matches[3].Trim(); players = $Matches[4]; address = $Matches[6] }
        }
    }
    $rows | Format-Table -AutoSize | Out-String -Width 160 | Write-Host
    return $rows
}
if ($Browse) { Show-Servers | Out-Null; exit 0 }

# The one place an injection is late: the game re-launched through its package.
function Inject-Into([System.Diagnostics.Process] $p) {
    & $injector --pid $p.Id --dll $dll
    if ($LASTEXITCODE -ne 0) { throw "The client was not injected (exit code $LASTEXITCODE)." }
    Write-Host ("KCD:MP's client is in the game (pid {0}, {1:N0} ms after it started)." -f $p.Id, ((Get-Date) - $p.StartTime).TotalMilliseconds)
}
function Get-ProcessPath([System.Diagnostics.Process] $p) { try { return $p.MainModule.FileName } catch { return '' } }

# A process's command line straight from its memory (its PEB): about a
# millisecond. WMI's answer took almost two seconds, and by then WHGame.dll
# was already mapped and the client too late for its first hook.
Add-Type -Namespace KcdMpGp -Name Native -MemberDefinition @'
[DllImport("ntdll.dll")] public static extern int NtQueryInformationProcess(System.IntPtr h, int cls, out PBI info, int len, out int ret);
[DllImport("kernel32.dll", SetLastError = true)] public static extern bool ReadProcessMemory(System.IntPtr h, System.IntPtr addr, byte[] buf, int len, out System.IntPtr read);
[DllImport("kernel32.dll", SetLastError = true)] public static extern System.IntPtr OpenProcess(uint access, bool inherit, int pid);
[DllImport("kernel32.dll")] public static extern bool CloseHandle(System.IntPtr h);
[StructLayout(LayoutKind.Sequential)] public struct PBI { public System.IntPtr Reserved1; public System.IntPtr PebBaseAddress; public System.IntPtr R2a; public System.IntPtr R2b; public System.IntPtr UniqueProcessId; public System.IntPtr Reserved3; }
public static string CommandLineOf(int pid) {
    System.IntPtr h = OpenProcess(0x0410, false, pid);   // PROCESS_QUERY_INFORMATION | PROCESS_VM_READ
    if (h == System.IntPtr.Zero) return null;
    try {
        PBI pbi; int ret;
        if (NtQueryInformationProcess(h, 0, out pbi, System.Runtime.InteropServices.Marshal.SizeOf(typeof(PBI)), out ret) != 0) return null;
        byte[] b = new byte[8]; System.IntPtr n;
        if (!ReadProcessMemory(h, pbi.PebBaseAddress + 0x20, b, 8, out n)) return null;         // PEB.ProcessParameters
        System.IntPtr pp = (System.IntPtr)System.BitConverter.ToInt64(b, 0);
        byte[] us = new byte[16];
        if (!ReadProcessMemory(h, pp + 0x70, us, 16, out n)) return null;                        // RTL_USER_PROCESS_PARAMETERS.CommandLine
        int len = System.BitConverter.ToUInt16(us, 0);
        System.IntPtr buf = (System.IntPtr)System.BitConverter.ToInt64(us, 8);
        if (len <= 0 || len > 65536) return null;
        byte[] chars = new byte[len];
        if (!ReadProcessMemory(h, buf, chars, len, out n)) return null;
        return System.Text.Encoding.Unicode.GetString(chars);
    } finally { CloseHandle(h); }
}
'@
function Get-CommandLineFast([int] $processId) {
    for ($i = 0; $i -lt 20; $i++) {          # the parameters block is there a few ms after the process is
        $c = [KcdMpGp.Native]::CommandLineOf($processId)
        if ($c) { return $c }
        Start-Sleep -Milliseconds 5
    }
    return ''
}

# --- KCD:MP's own window -------------------------------------------------------
# Its Join starts the game from the Steam-shaped path and injects the client
# into that process -- the Game Pass bootstrap, which re-launches the game
# through the package and exits at once, taking the client with it. So while
# the window is open, every new game process is looked at: one whose command
# line carries KCD:MP's own switches (-KcdMp_connect ...; the re-launch keeps
# them) gets the client. A game started any other way is left alone.
if (-not $Menu -and -not $Connect) {
    Save-Settings $settings
    try { Set-AutoLoadLastSave $exe $false } catch { }
    $launcher = Join-Path $kcdmpDir 'KcdMp_launcher.exe'
    Write-Host "Opening KCD:MP's window. Pick a server there; keep this window open while you play (it puts the client into the game)."
    $gui = Start-Process -FilePath $launcher -ArgumentList '--gui', '--game', "`"$content`"", '--name', "`"$Name`"" -WorkingDirectory $kcdmpDir -PassThru
    $seen = @{}
    foreach ($p in Get-Process KingdomCome -ErrorAction SilentlyContinue) { $seen[$p.Id] = $true }
    while (-not $gui.HasExited) {
        foreach ($p in Get-Process KingdomCome -ErrorAction SilentlyContinue) {
            if ($seen.ContainsKey($p.Id)) { continue }
            $seen[$p.Id] = $true
            if ((Get-ProcessPath $p) -notlike '*WindowsApps*') { continue }   # the bootstrap, or not readable yet
            $cmd = Get-CommandLineFast $p.Id
            if ($cmd -match '-KcdMp_') { Inject-Into $p }
            else { Write-Host "game process $($p.Id) was not started by KCD:MP: left alone" }
        }
        Start-Sleep -Milliseconds 15
    }
    Write-Host 'KCD:MP''s window was closed.'
    exit 0
}

if (-not $Connect) {
    $rows = Show-Servers
    $pick = (Read-Host 'Number to join, or host:port').Trim()
    if ($pick -match '^\d+$') {
        $row = $rows | Where-Object { $_.'#' -eq [int]$pick }
        if (-not $row) { throw "There is no server $pick in the list." }
        $Connect = $row.address
    } elseif ($pick -match '^[^\s:]+:\d+$') { $Connect = $pick }
    else { throw 'That is neither a number from the list nor host:port.' }
}
if ($Connect -notmatch '^[^\s:]+:\d+$') { throw "-Connect wants host:port, not '$Connect'." }
if (@($settings.Servers) -notcontains $Connect) { $settings.Servers = @(@($settings.Servers) + $Connect) }
Save-Settings $settings

# --- 7. which level ------------------------------------------------------------
if (-not $Level) {
    $st = Get-ServerStatus $Connect
    if ($st -and $st.level) { $Level = [string]$st.level }
    elseif ($rows) {
        $shown = ($rows | Where-Object { $_.address -eq $Connect } | Select-Object -First 1).level
        if ($shown -and $levelIds[$shown.ToLower()]) { $Level = $levelIds[$shown.ToLower()] }
    }
}
if (-not $Level) { $Level = (Read-Host 'The server did not say its level. Which is it (trosecko, kutnohorsko or klaster)').Trim().ToLower() }
if ($Level -notin 'trosecko', 'kutnohorsko', 'klaster') { throw "'$Level' is not a level KCD:MP runs." }

# --- 8. start and inject ---------------------------------------------------------
if (Test-GameRunning) { throw 'The game is already running. Close it, then run this again.' }
# The game boots straight onto the level; a save loading itself on top of it is not wanted.
try { Set-AutoLoadLastSave $exe $false } catch { }

$gameArgs = @("+map $Level", "-KcdMp_connect $Connect", "-KcdMp_name `"$Name`"", '-KcdMp_reports 1')
Write-Host "Starting the game on $Level, joining $Connect as $Name..."
$before = @(Get-Process KingdomCome -ErrorAction SilentlyContinue | ForEach-Object Id)
$boot = Start-Process -FilePath (Join-Path $steamShaped 'KingdomCome.exe') -ArgumentList $gameArgs -WorkingDirectory $content -PassThru

$deadline = (Get-Date).AddSeconds(90)
$target = $null
while ((Get-Date) -lt $deadline -and -not $target) {
    foreach ($p in Get-Process KingdomCome -ErrorAction SilentlyContinue) {
        if ($p.Id -eq $boot.Id -or $before -contains $p.Id) { continue }
        if ((Get-ProcessPath $p) -like '*WindowsApps*') { $target = $p; break }
    }
    if (-not $target) { Start-Sleep -Milliseconds 15 }
}
if (-not $target) { throw 'The game did not start (its re-launch through the Xbox app never appeared).' }
Inject-Into $target
Write-Host 'The game connects by itself; this window can be closed.'
Write-Host "Its log: $env:LOCALAPPDATA\KcdMp\client.log"
