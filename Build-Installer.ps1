# Builds release\KcdMp-GamePass-Setup-<version>.exe from this folder.
# Needs Inno Setup 6 (winget install JRSoftware.InnoSetup).
#   powershell -ExecutionPolicy Bypass -File Build-Installer.ps1
param(
    # The KCD:MP version the build entry was made for, then this package's revision.
    [string] $Version = '0.39.1.1'
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $root 'release\payload'
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $out | Out-Null
Copy-Item (Join-Path $root 'KcdMpGamePass.ps1'), (Join-Path $root 'KcdMpGamePass.bat'), (Join-Path $root 'KcdmpCommon.ps1'), (Join-Path $root 'KcdMpUpgrade.ps1'),
          (Join-Path $root 'README.md'), (Join-Path $root 'gamepass-1.5.6-74126a4c.json'), (Join-Path $root 'anchor_port.py') $out
Copy-Item (Join-Path $root 'bin\KCDMP_LauncherInjector.exe'), (Join-Path $root 'bin\app.ico') $out
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $out 'LICENSE.txt')

$iscc = foreach ($c in @("${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe", "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
                         "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe")) { if (Test-Path $c) { $c; break } }
if (-not $iscc) { throw 'Inno Setup 6 not found (winget install JRSoftware.InnoSetup)' }
& $iscc "/DAppVersion=$Version" (Join-Path $root 'installer\KcdMpGamePass.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }
Remove-Item $out -Recurse -Force
Write-Host "Installer: $(Join-Path $root "release\KcdMp-GamePass-Setup-$Version.exe")"
