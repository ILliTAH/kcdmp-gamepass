# Checks for the package's KCD:MP upgrade rules (KcdMpUpgrade.ps1) and its Game Pass build entry.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File tests\Test-KcdMpUpgrade.ps1
#
# A player on an older package keeps KCD:MP's files in kcdmp\ and unpacked the zip only when kcdmp\ was empty, so a
# newer zip in Downloads was never used. Now the package unpacks a newer KCD:MP over the old one - never an older one,
# never while the game or KCD:MP's window holds the files - and keeps the servers the player added to servers.txt.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'KcdMpUpgrade.ps1')
$script:fails = 0
function Check([string] $name, $got, $want) {
    if ("$got" -ceq "$want") { Write-Host "ok   $name" }
    else { Write-Host "FAIL $name - want '$want', got '$got'"; $script:fails++ }
}

# --- the version a zip carries in its name -----------------------------------
Check 'a client zip names its version' (Get-KcdMpZipVersion 'C:\Users\x\Downloads\KcdMp-0.37.0-win-x64.zip') '0.37.0'
Check 'the server zip is no client' (Get-KcdMpZipVersion 'KcdMp-server-0.37.0.zip') ''
Check 'a renamed copy is not trusted' (Get-KcdMpZipVersion 'KcdMp-0.37.0-win-x64 (1).zip') ''

# --- which zip in Downloads: the highest KCD:MP, not the newest file -----------
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('kcdmp-upgrade-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Check 'no zip, no choice' (Select-KcdMpZip $tmp) ''
    $a = New-Item -ItemType File -Path (Join-Path $tmp 'KcdMp-0.37.0-win-x64.zip')
    $a.LastWriteTime = (Get-Date).AddDays(-3)
    $b = New-Item -ItemType File -Path (Join-Path $tmp 'KcdMp-0.36.0-win-x64.zip')   # downloaded again later
    $b.LastWriteTime = Get-Date
    Check 'the highest version wins over the newest file' (Split-Path -Leaf (Select-KcdMpZip $tmp)) 'KcdMp-0.37.0-win-x64.zip'
    $c = New-Item -ItemType File -Path (Join-Path $tmp 'KcdMp-0.100.0-win-x64.zip')   # as text, '0.100.0' sorts below '0.37.0'
    $c.LastWriteTime = (Get-Date).AddDays(-9)
    Check 'versions compare as numbers' (Split-Path -Leaf (Select-KcdMpZip $tmp)) 'KcdMp-0.100.0-win-x64.zip'
} finally { Remove-Item -LiteralPath $tmp -Recurse -Force }

# --- unpack, upgrade, keep or wait ---------------------------------------------
$v36 = [version]'0.36.0'; $v37 = [version]'0.37.0'
Check 'nothing unpacked yet: unpack' (Get-KcdMpUnpackDecision $v37 $null $false $false) 'unpack'
Check 'nothing unpacked, the game open: unpack all the same' (Get-KcdMpUnpackDecision $v37 $null $false $true) 'unpack'
Check 'a newer zip: upgrade' (Get-KcdMpUnpackDecision $v37 $v36 $true $false) 'upgrade'
Check 'a newer zip while the game or the window is open: wait' (Get-KcdMpUnpackDecision $v37 $v36 $true $true) 'busy'
Check 'the same version: keep' (Get-KcdMpUnpackDecision $v37 $v37 $true $false) 'keep'
Check 'an older zip: never a downgrade' (Get-KcdMpUnpackDecision $v36 $v37 $true $false) 'keep'
Check 'a zip of no known version: keep' (Get-KcdMpUnpackDecision $null $v36 $true $false) 'keep'
Check 'an unpacked KCD:MP of no known version: keep' (Get-KcdMpUnpackDecision $v37 $null $true $false) 'keep'

# --- the unpacked KCD:MP's version: its launcher's ----------------------------
Check 'no launcher, no version' (Get-KcdMpUnpackedVersion (Join-Path ([IO.Path]::GetTempPath()) 'no-such-kcdmp-folder')) ''

# --- servers.txt: the new file, then the servers the player added ---------------
$new = @('# KCD:MP server list ...', '@https://kcd-mp.com/server-list   # the public server list')
$old = @('# KCD:MP server list ...', '@https://kcd-mp.com/server-list   # the public server list', '', '203.0.113.7:7777   # a friend')
Check 'a server the player added stays' ((Merge-KcdMpServerList $old $new) -join '|') (($new + '203.0.113.7:7777   # a friend') -join '|')
Check 'nothing added: the new file as it is' ((Merge-KcdMpServerList $new $new) -join '|') ($new -join '|')
Check 'the old comments do not come along' ((Merge-KcdMpServerList @('# an old comment', 'x.example:7777') @('# the new one')) -join '|') '# the new one|x.example:7777'
Check 'a bare default line does not come twice' ((Merge-KcdMpServerList @('@https://kcd-mp.com/server-list') $new) -join '|') ($new -join '|')

# --- the unpack: into kcdmp.new, swapped in only whole; on any failure the old install stays --------------
$utf8 = New-Object Text.UTF8Encoding($false)
$thai = -join [char[]](0x0E40, 0x0E0B, 0x0E34, 0x0E23, 0x0E4C, 0x0E1F)   # a friend's server, named in Thai
function New-TestZip([string] $path, [hashtable] $files) {
    $src = Join-Path ([IO.Path]::GetTempPath()) ('kcdmp-zipsrc-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $src | Out-Null
    foreach ($name in $files.Keys) {
        $f = Join-Path $src $name
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $f) | Out-Null
        [IO.File]::WriteAllText($f, $files[$name], $utf8)
    }
    Compress-Archive -Path (Join-Path $src '*') -DestinationPath $path -Force
    Remove-Item -LiteralPath $src -Recurse -Force
}
$work = Join-Path ([IO.Path]::GetTempPath()) ('kcdmp-install-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$k = Join-Path $work 'kcdmp'
function Reset-Old {
    foreach ($d in $k, "$k.new", "$k.old") { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force } }
    New-Item -ItemType Directory -Path $k | Out-Null
    [IO.File]::WriteAllText((Join-Path $k 'KcdMp_launcher.exe'), 'old launcher', $utf8)
    [IO.File]::WriteAllText((Join-Path $k 'KcdMp_client.dll'), 'old client', $utf8)
    [IO.File]::WriteAllText((Join-Path $k 'stale.txt'), 'from the old version', $utf8)
    [IO.File]::WriteAllText((Join-Path $k 'servers.txt'), "# list`n@https://kcd-mp.com/server-list`n203.0.113.7:7777   # $thai`n", $utf8)
}
function Left([string] $dir) { (@(Get-ChildItem -LiteralPath $dir -Directory | ForEach-Object Name) | Sort-Object) -join ',' }
try {
    $good = Join-Path $work 'KcdMp-0.37.0-win-x64.zip'
    New-TestZip $good @{ 'KcdMp_launcher.exe' = 'new launcher'; 'KcdMp_client.dll' = 'new client';
                         'servers.txt' = "# list`n@https://kcd-mp.com/server-list   # public`n"; 'cef\154\libcef.dll' = 'engine' }
    Reset-Old
    Check 'a whole zip goes in' (Install-KcdMpZip $good $k) 'True'
    Check 'the new files' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'new launcher'
    Check 'the engine comes along' (Test-Path -LiteralPath (Join-Path $k 'cef\154\libcef.dll')) 'True'
    Check 'the old version''s files go' (Test-Path -LiteralPath (Join-Path $k 'stale.txt')) 'False'
    Check 'the player''s server stays, its Thai whole' (@([IO.File]::ReadAllLines((Join-Path $k 'servers.txt'), $utf8)) -contains "203.0.113.7:7777   # $thai") 'True'
    Check 'nothing left beside it' (Left $work) 'kcdmp'

    Reset-Old
    $bad = Join-Path $work 'KcdMp-0.38.0-win-x64.zip'
    [IO.File]::WriteAllBytes($bad, [byte[]](1..200))   # a download cut short
    Check 'a broken zip is refused' ((Install-KcdMpZip $bad $k) -ne $true) 'True'
    Check 'the old install stays (a broken zip)' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'old launcher'
    Check 'nothing left beside it (a broken zip)' (Left $work) 'kcdmp'

    $nolauncher = Join-Path $work 'nolauncher.zip'
    New-TestZip $nolauncher @{ 'KcdMp_client.dll' = 'a client alone' }
    Check 'a zip without the launcher is refused' ((Install-KcdMpZip $nolauncher $k) -ne $true) 'True'
    Check 'the old install stays (no launcher)' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'old launcher'

    Reset-Old
    $held = [IO.File]::Open((Join-Path $k 'KcdMp_client.dll'), 'Open', 'Read', 'None')   # the game or KCD:MP holds it
    try { Check 'files in use: refused' ((Install-KcdMpZip $good $k) -ne $true) 'True' } finally { $held.Dispose() }
    Check 'the old install stays (in use)' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'old launcher'
    Check 'nothing left beside it (in use)' (Left $work) 'kcdmp'

    # Defender takes the client as it is unpacked (before the exclusion): said so, the old install kept
    Reset-Old
    $defender = { param($dir) Remove-Item -LiteralPath (Join-Path $dir 'KcdMp_client.dll') -Force }
    $why = Install-KcdMpZip $good $k $defender
    Check 'a client taken as it is unpacked: refused, naming Defender' ("$why" -like '*Defender*') 'True'
    Check 'the old install stays (Defender)' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'old launcher'
    Check 'nothing left beside it (Defender)' (Left $work) 'kcdmp'

    # the new folder held as it is put in place (a scan of the fresh files): the old install put back
    Reset-Old
    $script:scan = $null
    $hold = { param($dir) $script:scan = [IO.File]::Open((Join-Path $dir 'KcdMp_launcher.exe'), 'Open', 'Read', 'None') }
    try { $why = Install-KcdMpZip $good $k $hold } finally { if ($script:scan) { $script:scan.Dispose() } }
    Check 'the new folder held: refused' ($why -ne $true) 'True'
    Check 'the old install put back' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'old launcher'
    [void](Repair-KcdMpSwap $k)   # the held copy goes at the next start
    Check 'nothing left beside it (held)' (Left $work) 'kcdmp'

    # a leftover still in use (a launcher running from a half-deleted kcdmp.old): refused, no crash
    Reset-Old
    New-Item -ItemType Directory -Path "$k.old" | Out-Null
    $stuck = [IO.File]::Open((Join-Path "$k.old" 'KcdMp_web.exe') , 'Create', 'ReadWrite', 'None')
    try { Check 'a leftover in use: refused' ((Install-KcdMpZip $good $k) -ne $true) 'True' } finally { $stuck.Dispose() }
    Check 'the old install stays (leftover)' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'old launcher'

    # the repair at the start
    Reset-Old
    Rename-Item -LiteralPath $k -NewName 'kcdmp.old'                        # cut short between the two renames
    Expand-Archive -LiteralPath $good -DestinationPath "$k.new"             # kcdmp.new is whole by then
    Check 'a swap cut short is finished' (Repair-KcdMpSwap $k) 'True'
    Check 'with the new files' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'new launcher'
    Check 'and nothing left beside it (finished)' (Left $work) 'kcdmp'
    Reset-Old
    Rename-Item -LiteralPath $k -NewName 'kcdmp.old'                        # cut short, and the finish held too
    Expand-Archive -LiteralPath $good -DestinationPath "$k.new"
    $held = [IO.File]::Open((Join-Path "$k.new" 'KcdMp_launcher.exe'), 'Open', 'Read', 'None')
    try { Check 'a finish held: nothing put in place yet' (Repair-KcdMpSwap $k) 'False' } finally { $held.Dispose() }
    Check 'and both copies kept for the next start' (Left $work) 'kcdmp.new,kcdmp.old'
    Check 'the next start finishes it' (Repair-KcdMpSwap $k) 'True'
    Check 'with the new files (later)' ([IO.File]::ReadAllText((Join-Path $k 'KcdMp_launcher.exe'))) 'new launcher'
    Reset-Old
    Rename-Item -LiteralPath $k -NewName 'kcdmp.old'                        # kcdmp\ deleted by hand, a stale copy left
    Check 'a stale copy alone is not brought back' (Repair-KcdMpSwap $k) 'False'
    Check 'it goes, for a fresh unpack' (Left $work) ''
    Reset-Old
    New-Item -ItemType Directory -Path "$k.new" | Out-Null
    New-Item -ItemType Directory -Path "$k.old" | Out-Null
    Check 'leftovers beside a whole install: nothing put back' (Repair-KcdMpSwap $k) 'False'
    Check 'the leftovers go' (Left $work) 'kcdmp'
    Check 'nothing to repair: nothing done' (Repair-KcdMpSwap $k) 'False'
} finally { Remove-Item -LiteralPath $work -Recurse -Force }

# --- the Game Pass build entry: KCD:MP 0.38.0's anchors (the same 355 as 0.37.0's) -------------------------
$entry = (Get-Content -LiteralPath (Join-Path $root 'gamepass-1.5.6-74126a4c.json') -Raw | ConvertFrom-Json).builds[0]
Check 'the entry is the Game Pass build' "$($entry.id) $($entry.store)" 'gamepass-1.5.6-74126a4c gamepass'
Check 'for the Game Pass WHGame.dll' $entry.whgame.sha256 '74126a4c88e819a2a2d046a2011f69ede0335833fef25c28b660ef953abb2e8d'
Check 'the hand-kept fields stay' "$($entry.whgame.pdb_guid)/$($entry.whgame.pdb_age)/$([bool]$entry.exe.note)" '1BE3EC0F2EED4095A3A779B272F03C93/2/True'
Check 'all of 0.38.0 Steam entry''s anchors' @($entry.resolved.PSObject.Properties).Count 355
Check 'the mouse pointer''s three' @('IncrementCounter', 'DecrementCounter', 'ConfineCursor' |
    Where-Object { $entry.resolved.PSObject.Properties["WHGame.IHardwareMouse.$_"] }).Count 3
Check 'ported from 0.38.0' ($entry.ported_by -like "*KCD:MP 0.38.0's steam-1.5.6-bdf8f9e4 entry") 'True'

if ($script:fails) { Write-Host "$($script:fails) failed"; exit 1 }
Write-Host 'PASS: the upgrade rules, the unpack and the 0.38.0 entry'
exit 0
