[Setup]
AppName=Droppy
AppVersion=1.0
DefaultDirName={pf}\Droppy
DefaultGroupName=Droppy
OutputDir=Output
OutputBaseFilename=DroppyInstaller

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Droppy"; Filename: "{app}\file_dropper.exe"
Name: "{commondesktop}\Droppy"; Filename: "{app}\file_dropper.exe"