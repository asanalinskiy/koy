[Setup]
AppName=Koy Programming Language
AppVersion=1.0.0
DefaultDirName={userpf}\Koy
DefaultGroupName=Koy
UninstallDisplayIcon={app}\koy.exe
Compression=lzma2
SolidCompression=yes
OutputBaseFilename=KoySetup
ChangesEnvironment=yes

; 🎨 Иконка для самого инсталлятора KoySetup.exe
SetupIconFile=koy.ico

[Files]
; Основной бинарник и иконка программы
Source: "koy.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "koy.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; 🚀 1. Ярлык "Koy Terminal" (запускает кастомную консоль с логотипом, заголовком и REPL)
Name: "{group}\Koy Terminal"; Filename: "cmd.exe"; Parameters: "/K ""title Koy Terminal & {app}\koy.exe"""; WorkingDir: "{userdocs}"; IconFilename: "{app}\koy.ico"; Comment: "Koy Interactive Shell"

; 📌 2. Ярлык деинсталлятора
Name: "{group}\Uninstall Koy"; Filename: "{uninstallexe}"

[Code]
// 🛠 Автоматическое добавление Koy в системную переменную PATH
procedure CurStepChanged(CurStep: TSetupStep);
var
  OldPath: string;
  AppDir: string;
begin
  if CurStep = ssPostInstall then
  begin
    AppDir := ExpandConstant('{app}');
    if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OldPath) then
    begin
      if Pos(AppDir, OldPath) = 0 then
      begin
        RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OldPath + ';' + AppDir);
      end;
    end
    else
    begin
      RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', AppDir);
    end;
  end;
end;