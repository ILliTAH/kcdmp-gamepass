# Which KCD:MP zip to unpack, and how. Dot-sourced by KcdMpGamePass.ps1; checked by tests\Test-KcdMpUpgrade.ps1.
#
# Up to 0.36.0.1 the package unpacked KCD:MP's zip only into an empty kcdmp\, so a player who downloaded a newer KCD:MP
# kept the old one (KCD:MP's own Update button was the only way on). Now a newer KCD:MP in Downloads is unpacked over
# the old one: never an older one, never while the game or KCD:MP's own programs hold the files. The zip goes into
# kcdmp.new and is swapped in only whole, so a broken zip, a full disk or a file in use leaves the old install as it
# was; the servers the player added to servers.txt go along.

# 'KcdMp-0.37.0-win-x64.zip' -> [version] 0.37.0; any other name (the server zip, a renamed copy) -> $null
function Get-KcdMpZipVersion([string] $path) {
    if ((Split-Path -Leaf $path) -match '^KcdMp-(\d+\.\d+\.\d+)-win-x64\.zip$') { return [version]$Matches[1] }
    return $null
}

# the zip of the highest KCD:MP in a folder - not the newest file: a player may download an older one again
function Select-KcdMpZip([string] $folder) {
    $zips = @(Get-ChildItem -LiteralPath $folder -Filter 'KcdMp-*-win-x64.zip' -File -ErrorAction SilentlyContinue |
              Where-Object { Get-KcdMpZipVersion $_.Name })
    if ($zips.Count -eq 0) { return $null }
    return ($zips | Sort-Object -Property @{ Expression = { Get-KcdMpZipVersion $_.Name }; Descending = $true },
                                          @{ Expression = 'LastWriteTime'; Descending = $true } | Select-Object -First 1).FullName
}

# the unpacked KCD:MP's version: its launcher's file version; $null when there is none or it cannot be read
function Get-KcdMpUnpackedVersion([string] $kcdmpDir) {
    $exe = Join-Path $kcdmpDir 'KcdMp_launcher.exe'
    if (-not (Test-Path -LiteralPath $exe)) { return $null }
    $v = [string](Get-Item -LiteralPath $exe).VersionInfo.FileVersion
    if ($v -match '^(\d+\.\d+\.\d+)') { return [version]$Matches[1] }
    return $null
}

# 'unpack' (nothing unpacked yet), 'upgrade' (the zip is a newer KCD:MP), 'busy' (newer, but the game or KCD:MP's own
# programs hold the files), 'keep' (the same or an older KCD:MP, or a version not known on either side)
function Get-KcdMpUnpackDecision($zipVersion, $unpackedVersion, [bool] $unpacked, [bool] $busy) {
    if (-not $unpacked) { return 'unpack' }
    if ($null -eq $zipVersion -or $null -eq $unpackedVersion -or $zipVersion -le $unpackedVersion) { return 'keep' }
    if ($busy) { return 'busy' }
    return 'upgrade'
}

# the game, or KCD:MP's window or web engine running from this kcdmp\: they hold its files
function Test-KcdMpBusy([string] $kcdmpDir) {
    if (Get-Process -Name KingdomCome -ErrorAction SilentlyContinue) { return $true }
    $prefix = [IO.Path]::GetFullPath($kcdmpDir).TrimEnd('\') + '\'
    return [bool](Get-Process -Name KcdMp_launcher, KcdMp_web -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) })
}

# servers.txt after an upgrade: the new file as it comes, then each server line the player had added. Lines compare
# without their comments (a bare default line is no new server); comments and empty lines of the old file stay behind.
function Merge-KcdMpServerList([string[]] $old, [string[]] $new) {
    $have = @{}
    foreach ($line in $new) { $key = ($line -replace '\s*#.*$', '').Trim(); if ($key) { $have[$key] = $true } }
    $added = @($old | Where-Object { $key = ($_ -replace '\s*#.*$', '').Trim(); $key -and -not $have.ContainsKey($key) })
    return @($new) + $added
}

# a rename, tried a few times: an antivirus scan holds freshly written files for a moment
function Rename-KcdMpRetry([string] $path, [string] $newName) {
    for ($i = 0; $i -lt 5; $i++) {
        try { Rename-Item -LiteralPath $path -NewName $newName -ErrorAction Stop; return $true } catch { Start-Sleep -Milliseconds 400 }
    }
    return $false
}
function Remove-KcdMpQuietly([string] $path) {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue }
}
function Test-KcdMpZipHas([string] $zip, [string] $name) {
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $z = [IO.Compression.ZipFile]::OpenRead($zip)
        try { return [bool]($z.Entries | Where-Object { $_.FullName -eq $name }) } finally { $z.Dispose() }
    } catch { return $false }
}

# A zip into kcdmp\, whole or not at all: unpacked into kcdmp.new, which must hold the launcher and the client, with the
# player's servers merged in; then kcdmp\ becomes kcdmp.old (a folder rename fails while a file in it is open, and then
# nothing has changed) and kcdmp.new becomes kcdmp\ - or, if that cannot be done, kcdmp.old goes back. Returns $true, or
# why the old install was kept. $afterUnpack (tests) runs on kcdmp.new right after the unpack.
function Install-KcdMpZip([string] $zip, [string] $kcdmpDir, [scriptblock] $afterUnpack = $null) {
    $new = "$kcdmpDir.new"
    $old = "$kcdmpDir.old"
    foreach ($d in $new, $old) {
        if (Test-Path -LiteralPath $d) {
            try { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction Stop }
            catch { return "a copy left from an earlier unpack ($(Split-Path -Leaf $d)) is still in use: close the game and KCD:MP's window" }
        }
    }
    try {
        Expand-Archive -LiteralPath $zip -DestinationPath $new -Force -ErrorAction Stop
    } catch {
        Remove-KcdMpQuietly $new
        return "the zip could not be unpacked ($($_.Exception.Message))"
    }
    if ($afterUnpack) { & $afterUnpack $new }
    foreach ($f in 'KcdMp_launcher.exe', 'KcdMp_client.dll') {
        if (-not (Test-Path -LiteralPath (Join-Path $new $f))) {
            Remove-KcdMpQuietly $new
            if (Test-KcdMpZipHas $zip $f) { return "$f was taken away as soon as it was unpacked (Windows Defender): exclude $(Split-Path -Parent $kcdmpDir) in Windows Security > Exclusions, then start again" }
            return "the zip has no $f"
        }
    }
    $mine = Join-Path $kcdmpDir 'servers.txt'
    $theirs = Join-Path $new 'servers.txt'
    if ((Test-Path -LiteralPath $mine) -and (Test-Path -LiteralPath $theirs)) {
        $utf8 = New-Object Text.UTF8Encoding($false)
        $now = @([IO.File]::ReadAllLines($theirs, $utf8))
        $merged = @(Merge-KcdMpServerList @([IO.File]::ReadAllLines($mine, $utf8)) $now)
        if ($merged.Count -gt $now.Count) { [IO.File]::WriteAllText($theirs, (($merged -join "`n") + "`n"), $utf8) }
    }
    if ((Test-Path -LiteralPath $kcdmpDir) -and -not (Rename-KcdMpRetry $kcdmpDir (Split-Path -Leaf $old))) {
        Remove-KcdMpQuietly $new
        return "KCD:MP's files are in use (the game, KCD:MP's window or its web engine)"
    }
    if (-not (Rename-KcdMpRetry $new (Split-Path -Leaf $kcdmpDir))) {
        if (Test-Path -LiteralPath $old) { [void](Rename-KcdMpRetry $old (Split-Path -Leaf $kcdmpDir)) }
        Remove-KcdMpQuietly $new
        return "the new files could not be put in place (something held them - an antivirus scan?): start again in a moment"
    }
    Remove-KcdMpQuietly $old
    return $true
}

# What an unpack left behind, set right at the start. kcdmp\ gone between the two renames is finished with kcdmp.new
# (whole by then: it is checked before them); a kcdmp.old alone - kcdmp\ deleted by hand, or a half-deleted copy - is
# never brought back (a fresh unpack follows); leftovers beside kcdmp\ go. $true when kcdmp\ was put in place.
function Repair-KcdMpSwap([string] $kcdmpDir) {
    $old = "$kcdmpDir.old"
    $new = "$kcdmpDir.new"
    $finished = $false
    if (-not (Test-Path -LiteralPath $kcdmpDir) -and (Test-Path -LiteralPath $old) -and
        (Test-Path -LiteralPath (Join-Path $new 'KcdMp_launcher.exe')) -and (Test-Path -LiteralPath (Join-Path $new 'KcdMp_client.dll'))) {
        $finished = Rename-KcdMpRetry $new (Split-Path -Leaf $kcdmpDir)
        if (-not $finished) { return $false }   # held: both copies stay for the next start (the player's servers too)
    }
    Remove-KcdMpQuietly $new
    Remove-KcdMpQuietly $old
    return $finished
}

# --- staying current by itself (0.39.1.1): a player installs this package once ---------------------------------------
# KCD:MP releases often, and every release changes its protocol: the servers move at once, so an old client cannot join.
# At each start the launcher asks KCD:MP's own release page for the newest client and, if it is newer than the one
# here, downloads its zip into Downloads (checked against its .sha256) - the unpack above then moves to it as from any
# zip there. And it asks this project for the newest Game Pass table (a release that wants new anchors gets one, ported
# here: the port needs the Steam game's WHGame.dll, which a Game Pass player does not have). No network: both skip.
# $fetch / $download (tests) stand in for the web: $fetch returns the text at a URL, $download writes a URL to a file.
$KcdMpReleaseApi = 'https://api.github.com/repos/dintech-rappy/kcd-mp-releases/releases/latest'
$GamePassTableBase = 'https://raw.githubusercontent.com/ILliTAH/kcdmp-gamepass/main/'

function Enable-KcdMpTls { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 }
function Get-KcdMpWebText([string] $url) {
    Enable-KcdMpTls
    return (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -Headers @{ 'User-Agent' = 'kcdmp-gamepass' }).Content
}
function Save-KcdMpWebFile([string] $url, [string] $path) {
    Enable-KcdMpTls
    $old = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'   # the progress bar makes PowerShell 5 crawl
    try { Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing -TimeoutSec 900 -Headers @{ 'User-Agent' = 'kcdmp-gamepass' } }
    finally { $ProgressPreference = $old }
}

# the newest KCD:MP client on its release page: @{ Version; Name; Url; ShaUrl }, or $null (offline, or no client zip there)
function Get-KcdMpLatestRelease([scriptblock] $fetch = $null) {
    if (-not $fetch) { $fetch = { param($u) Get-KcdMpWebText $u } }
    try { $rel = (& $fetch $KcdMpReleaseApi) | ConvertFrom-Json } catch { return $null }
    $zip = @($rel.assets) | Where-Object { Get-KcdMpZipVersion $_.name } | Select-Object -First 1
    if (-not $zip) { return $null }
    $sha = @($rel.assets) | Where-Object { $_.name -eq "$($zip.name).sha256" } | Select-Object -First 1
    if (-not $sha) { return $null }   # never a zip that cannot be checked
    return @{ Version = (Get-KcdMpZipVersion $zip.name); Name = $zip.name; Url = $zip.browser_download_url; ShaUrl = $sha.browser_download_url }
}

# The release's zip into $folder, checked against its .sha256 - written as .part and named only once it checks out.
# Returns the zip's path, or why not.
function Save-KcdMpRelease($release, [string] $folder, [scriptblock] $fetch = $null, [scriptblock] $download = $null) {
    if (-not $fetch) { $fetch = { param($u) Get-KcdMpWebText $u } }
    if (-not $download) { $download = { param($u, $p) Save-KcdMpWebFile $u $p } }
    $final = Join-Path $folder $release.Name
    $part = "$final.part"
    try {
        $want = ("$(& $fetch $release.ShaUrl)".Trim() -split '\s+')[0].ToLower()
        if ($want -notmatch '^[0-9a-f]{64}$') { return 'its .sha256 is unreadable' }
        & $download $release.Url $part
        $got = (Get-FileHash -LiteralPath $part -Algorithm SHA256).Hash.ToLower()
        if ($got -ne $want) { Remove-KcdMpQuietly $part; return "the download does not match its .sha256 ($($got.Substring(0,8)) is not $($want.Substring(0,8)))" }
        if (Test-Path -LiteralPath $final) { Remove-Item -LiteralPath $final -Force }
        Move-Item -LiteralPath $part -Destination $final
        return $final
    } catch {
        Remove-KcdMpQuietly $part
        return "the download failed: $($_.Exception.Message)"
    }
}

# an anchor as anchor_port.py writes one: an address (rva, or a vtable for an RTTI entry) or a runtime value, and every
# address field in hex
function Test-GamePassAnchor($a) {
    if (-not $a) { return $false }
    foreach ($f in 'rva', 'vtable', 'site') {
        $v = $a.PSObject.Properties[$f]
        if ($v -and $null -ne $v.Value -and "$($v.Value)" -notmatch '^0x[0-9a-fA-F]+$') { return $false }
    }
    if ("$($a.rva)" -match '^0x' -or "$($a.vtable)" -match '^0x') { return $true }
    return ($a.method -eq 'runtime' -and "$($a.value)" -match '^\d+$')
}

# The project's newest Game Pass table over the one here: only one for the same game build (its id, and the sha256 of
# this PC's WHGame.dll), every anchor with an address. Returns 'updated (N anchors)', 'current' or why the one here stays.
function Update-GamePassTable([string] $entryFile, [string] $whgameSha, [scriptblock] $fetch = $null) {
    if (-not $fetch) { $fetch = { param($u) Get-KcdMpWebText $u } }
    try { $text = "$(& $fetch ($GamePassTableBase + (Split-Path -Leaf $entryFile)))" } catch { return 'offline' }
    try { $remote = @(($text | ConvertFrom-Json).builds)[0] } catch { return 'unreadable' }
    $local = @((Get-Content -LiteralPath $entryFile -Raw | ConvertFrom-Json).builds)[0]
    if (-not $remote -or $remote.id -ne $local.id -or $remote.store -ne 'gamepass' -or "$($remote.whgame.sha256)".ToLower() -ne $whgameSha.ToLower()) { return 'not for this game' }
    $anchors = @($remote.resolved.PSObject.Properties)
    if ($anchors.Count -eq 0) { return 'no anchors' }
    foreach ($a in $anchors) { if (-not (Test-GamePassAnchor $a.Value)) { return "a bad anchor ($($a.Name))" } }
    if (($remote | ConvertTo-Json -Depth 8 -Compress) -eq ($local | ConvertTo-Json -Depth 8 -Compress)) { return 'current' }
    # never a step back: a table that lacks an anchor the one here has is older (an installer newer than the project's page)
    foreach ($n in $local.resolved.PSObject.Properties.Name) { if (-not $remote.resolved.PSObject.Properties[$n]) { return 'older than the one here' } }
    $tmp = "$entryFile.new"
    [IO.File]::WriteAllText($tmp, $text, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $entryFile -Force
    return "updated ($($anchors.Count) anchors)"
}
