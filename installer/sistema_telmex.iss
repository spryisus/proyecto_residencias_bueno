; Script de instalador Inno Setup para Sistema Telmex
; Requiere Inno Setup: https://jrsoftware.org/isinfo.php

#define MyAppName "Sistema Telmex"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Telmex"
#define MyAppExeName "proyecto_telmex.exe"
#define MyAppDescription "Sistema de Inventarios y Envíos Telmex"

[Setup]
; Información básica
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://telmex.com
AppSupportURL=https://telmex.com/soporte
AppUpdatesURL=https://telmex.com/actualizaciones
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=LICENSE.txt
InfoBeforeFile=README.txt
OutputDir=dist
OutputBaseFilename=SistemaTelmexInstaller
SetupIconFile=icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

; Información de la aplicación
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppDescription}
VersionInfoCopyright=Copyright (C) 2024 {#MyAppPublisher}

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; Archivo principal
Source: "proyecto_telmex.exe"; DestDir: "{app}"; Flags: ignoreversion
; Datos de la aplicación
Source: "data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Librerías
Source: "lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs createallsubdirs
; Icono
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion
; Documentación
Source: "README.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; IconFilename: "{app}\icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  // Verificar si ya está instalado
  if RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}_is1') then
  begin
    if MsgBox('El Sistema Telmex ya está instalado. ¿Desea desinstalarlo primero?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Ejecutar desinstalador
      Exec('msiexec.exe', '/x{old}', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Crear entrada en el registro para desinstalación
    RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}_is1', 'DisplayName', '{#MyAppName}');
    RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}_is1', 'DisplayVersion', '{#MyAppVersion}');
    RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}_is1', 'Publisher', '{#MyAppPublisher}');
    RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppName}_is1', 'UninstallString', '"' + ExpandConstant('{uninstallexe}') + '"');
  end;
end;
