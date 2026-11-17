#define AppNome "Go Up Ponto"
#ifndef AppVersao
  #define AppVersao "2.0.0"
#endif

[Setup]
AppId={{7B1C2E64-5A3D-4F0B-9E27-60A1D0C0FA11}
AppName={#AppNome}
AppVersion={#AppVersao}
AppPublisher=Go Up Gestão de Sistemas
DefaultDirName={autopf}\Go Up Ponto
DefaultGroupName={#AppNome}
OutputDir=.
OutputBaseFilename=GoUpPonto_Instalador_{#AppVersao}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\GoUpPonto.exe
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
WizardStyle=modern
ShowLanguageDialog=no

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: desktop; Description: "Criar atalho na Área de Trabalho"; Flags: checkedonce
Name: iniciar; Description: "Iniciar o Go Up Ponto junto com o Windows"; Flags: unchecked

[Files]
; Tudo da pasta Release, exceto configuração e dados locais (preservados em atualizações)
Source: "arquivos\*"; DestDir: "{app}"; Excludes: "Config.ini,*.log,*.fdb"; Flags: recursesubdirs createallsubdirs ignoreversion

[Dirs]
; O aplicativo grava Config.ini, backups e atualizações na própria pasta
Name: "{app}"; Permissions: users-modify

[Icons]
Name: "{group}\{#AppNome}"; Filename: "{app}\GoUpPonto.exe"
Name: "{group}\Desinstalar {#AppNome}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppNome}"; Filename: "{app}\GoUpPonto.exe"; Tasks: desktop
Name: "{commonstartup}\{#AppNome}"; Filename: "{app}\GoUpPonto.exe"; Tasks: iniciar

[Run]
Filename: "{app}\GoUpPonto.exe"; Description: "Abrir o {#AppNome}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill"; Parameters: "/F /IM GoUpPonto.exe"; Flags: runhidden; RunOnceId: "fechar1"
Filename: "taskkill"; Parameters: "/F /IM GoUpPontoServico.exe"; Flags: runhidden; RunOnceId: "fechar2"
