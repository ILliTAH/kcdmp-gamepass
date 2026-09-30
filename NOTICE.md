# What is in here, and whose it is

- `KcdMpGamePass.ps1`, `KcdMpGamePass.bat`, `anchor_port.py`, `installer/KcdMpGamePass.iss`,
  `Build-Installer.ps1`, `README.md` — this project. GPLv3 (`LICENSE`).
- `KcdmpCommon.ps1`, `bin/KCDMP_LauncherInjector.exe`, `bin/app.ico` — from the
  Kingdom Come: Co-op fork of Kingdom Come: Together (GPLv3):
  https://github.com/ILliTAH/KingdomCome-Together (branch `hostworld`). The
  injector is built there from `native/KCDMP_LauncherInjector` with Visual
  Studio 2019.
- `gamepass-1.5.6-74126a4c.json` — 287 addresses in the Xbox Game Pass build
  of Kingdom Come: Deliverance II (v1.5.6, WHGame.dll sha256 `74126a4c…`),
  derived by `anchor_port.py` from the Steam entry in KCD:MP 0.35.0's
  `builds.json`. The anchor *names* are KCD:MP's; the addresses were computed
  here.
- Not included, by design: any file of KCD:MP (kcd-mp.com; the player
  downloads their zip) and any file of the game.

Kingdom Come: Deliverance is a trademark of Warhorse Studios. This is a
non-commercial fan project, not affiliated with Warhorse Studios or with the
KCD:MP team.
