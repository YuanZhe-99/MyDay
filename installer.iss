[Setup]
AppId={{B2C3D4E5-F6A7-8901-BCDE-F12345678901}
AppName=MyDay!!!!!
AppVersion=0.4.2
AppPublisher=yuanzhe
AppPublisherURL=https://github.com/yuanzhe
DefaultDirName={autopf}\MyDay
DefaultGroupName=MyDay!!!!!
UninstallDisplayIcon={app}\my_day.exe
OutputDir=build\installer
#ifdef ARM64
OutputBaseFilename=MyDay_0.4.2_arm64_Setup
#else
OutputBaseFilename=MyDay_{#SetupSetting("AppVersion")}_Setup
#endif
Compression=lzma2
SolidCompression=yes
#ifdef ARM64
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
#ifdef ARM64
Source: "build\windows\arm64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
#else
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
#endif

[Icons]
Name: "{group}\MyDay!!!!!"; Filename: "{app}\my_day.exe"
Name: "{group}\{cm:UninstallProgram,MyDay!!!!!}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MyDay!!!!!"; Filename: "{app}\my_day.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\my_day.exe"; Description: "{cm:LaunchProgram,MyDay!!!!!}"; Flags: nowait postinstall skipifsilent
