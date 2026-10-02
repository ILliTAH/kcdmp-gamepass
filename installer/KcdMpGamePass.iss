; KCD:MP for Game Pass -- installs this project's scripts and injector that
; make the third-party KCD:MP client run on the Xbox Game Pass build of KCD2.
; KCD:MP's own files are NOT in here: the first run unpacks the zip the player
; downloaded from kcd-mp.com. Compile with Build-Installer.ps1.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#define AppName "KCD MP for Game Pass"
#define AppPublisher "Kingdom Come: Co-op (ILliTAH/KingdomCome-Together)"
#define AppUrl "https://github.com/ILliTAH/kcdmp-gamepass"

[Setup]
AppId={{7B3E2C41-5D0A-4F8E-9C2B-6E1A0D4F9B27}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
DefaultDirName={localappdata}\KcdMp-GamePass
DisableDirPage=yes
PrivilegesRequired=lowest
UsePreviousAppDir=yes
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
OutputDir=..\release
OutputBaseFilename=KcdMp-GamePass-Setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
UninstallDisplayName={#AppName}
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\release\payload\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\KcdMpGamePass.bat"; WorkingDir: "{app}"; IconFilename: "{app}\app.ico"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\KcdMpGamePass.bat"; WorkingDir: "{app}"; IconFilename: "{app}\app.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\KcdMpGamePass.bat"; WorkingDir: "{app}"; Description: "Set up and pick a server now"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; kcdmp\ (KCD:MP's unpacked files), settings.json and the merged table are made at run time.
Type: filesandordirs; Name: "{app}"

[Code]
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
    WizardForm.FinishedLabel.Caption :=
      'Before the first start, download the KCD:MP client (KcdMp-<version>-win-x64.zip)' + #13#10 +
      'from kcd-mp.com into your Downloads folder. The first start unpacks it, asks once' + #13#10 +
      'for admin rights (a Windows Defender exclusion for this package''s folder), adds the Game Pass' + #13#10 +
      'build to its table, asks your name and shows the servers.';
end;

function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  Exec(ExpandConstant('{cmd}'), '/c tasklist /fi "imagename eq KingdomCome.exe" /nh | find /i "KingdomCome.exe"',
       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if ResultCode = 0 then
  begin
    MsgBox('The game is running. Close it first.', mbError, MB_OK);
    Result := False;
  end;
end;
