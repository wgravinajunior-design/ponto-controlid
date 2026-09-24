unit uConfig;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles;

const
  APP_VERSION = '1.0.4';
  GITHUB_OWNER = 'wgravinajunior-design';
  GITHUB_REPO = 'ponto-controlid';

type
  TUpdateInfo = record
    HasUpdate: Boolean;
    LatestVersion: string;
    ReleaseName: string;
    ReleaseNotes: string;
    DownloadUrl: string;
    AssetFileName: string;
    AssetSize: Int64;
    PublishedAt: string;
  end;

  TFirebirdConfig = record
    Database: string;
    Server: string;
    Port: Integer;
    User: string;
    Password: string;
    VendorLib: string;
    Charset: string;
  end;

  TControlIDDefaultConfig = record
    IP: string;
    Porta: Integer;
    UsarSSL: Boolean;
    Usuario: string;
    Senha: string;
    IntervaloColetaSegundos: Integer;
    ModoColeta: string;
    Portaria671: Boolean;
    AutoIniciarColeta: Boolean;
  end;

  TAppConfig = class
  private
    FIniPath: string;
    FFirebird: TFirebirdConfig;
    FControlID: TControlIDDefaultConfig;
  public
    constructor Create(const AIniPath: string = '');
    procedure Load;
    procedure Save;

    property Firebird: TFirebirdConfig read FFirebird write FFirebird;
    property ControlID: TControlIDDefaultConfig read FControlID write FControlID;
    property IniPath: string read FIniPath;
  end;

function AppConfig: TAppConfig;

implementation

uses
  Vcl.Forms;

var
  GAppConfig: TAppConfig = nil;

function AppConfig: TAppConfig;
begin
  if GAppConfig = nil then
    GAppConfig := TAppConfig.Create;
  Result := GAppConfig;
end;

{ TAppConfig }

constructor TAppConfig.Create(const AIniPath: string);
begin
  inherited Create;
  if AIniPath <> '' then
    FIniPath := AIniPath
  else
    FIniPath := ExtractFilePath(Application.ExeName) + 'Config.ini';

  // Default values
  FFirebird.Database := 'D:\OneDrive\DADOS\DUSUCO\DADOS.FDB';
  FFirebird.Server := 'localhost';
  FFirebird.Port := 3060;
  FFirebird.User := 'SYSDBA';
  FFirebird.Password := 'masterkey';
  FFirebird.VendorLib := 'C:\Program Files\Firebird\Firebird_5_0\fbclient.dll';
  FFirebird.Charset := 'WIN1252';

  FControlID.IP := '192.168.1.200';
  FControlID.Porta := 80;
  FControlID.UsarSSL := False;
  FControlID.Usuario := 'admin';
  FControlID.Senha := 'admin';
  FControlID.IntervaloColetaSegundos := 60;
  FControlID.ModoColeta := 'API';
  FControlID.Portaria671 := True;
  FControlID.AutoIniciarColeta := False;

  Load;
end;

procedure TAppConfig.Load;
var
  Ini: TIniFile;
begin
  if not FileExists(FIniPath) then
  begin
    Save;
    Exit;
  end;

  Ini := TIniFile.Create(FIniPath);
  try
    FFirebird.Database := Ini.ReadString('FIREBIRD', 'Database', FFirebird.Database);
    FFirebird.Server := Ini.ReadString('FIREBIRD', 'Server', FFirebird.Server);
    FFirebird.Port := Ini.ReadInteger('FIREBIRD', 'Port', FFirebird.Port);
    FFirebird.User := Ini.ReadString('FIREBIRD', 'User', FFirebird.User);
    FFirebird.Password := Ini.ReadString('FIREBIRD', 'Password', FFirebird.Password);
    FFirebird.VendorLib := Ini.ReadString('FIREBIRD', 'VendorLib', FFirebird.VendorLib);
    if not FileExists(FFirebird.VendorLib) then
    begin
      if FileExists(ExtractFilePath(Application.ExeName) + 'fbclient.dll') then
        FFirebird.VendorLib := ExtractFilePath(Application.ExeName) + 'fbclient.dll'
      else if FileExists('C:\Program Files\Firebird\Firebird_5_0\wow64\fbclient.dll') then
        FFirebird.VendorLib := 'C:\Program Files\Firebird\Firebird_5_0\wow64\fbclient.dll';
    end;
    FFirebird.Charset := Ini.ReadString('FIREBIRD', 'Charset', FFirebird.Charset);

    FControlID.IP := Ini.ReadString('CONTROLID', 'IP', FControlID.IP);
    FControlID.Porta := Ini.ReadInteger('CONTROLID', 'Porta', FControlID.Porta);
    FControlID.UsarSSL := SameText(Ini.ReadString('CONTROLID', 'UsarSSL', 'N'), 'S');
    FControlID.Usuario := Ini.ReadString('CONTROLID', 'Usuario', FControlID.Usuario);
    FControlID.Senha := Ini.ReadString('CONTROLID', 'Senha', FControlID.Senha);
    FControlID.IntervaloColetaSegundos := Ini.ReadInteger('CONTROLID', 'IntervaloColetaSegundos', FControlID.IntervaloColetaSegundos);
    FControlID.ModoColeta := Ini.ReadString('CONTROLID', 'ModoColeta', FControlID.ModoColeta);
    FControlID.Portaria671 := SameText(Ini.ReadString('CONTROLID', 'Portaria671', 'S'), 'S');
    FControlID.AutoIniciarColeta := SameText(Ini.ReadString('CONTROLID', 'AutoIniciarColeta', 'N'), 'S');
  finally
    Ini.Free;
  end;
end;

procedure TAppConfig.Save;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Ini.WriteString('FIREBIRD', 'Database', FFirebird.Database);
    Ini.WriteString('FIREBIRD', 'Server', FFirebird.Server);
    Ini.WriteInteger('FIREBIRD', 'Port', FFirebird.Port);
    Ini.WriteString('FIREBIRD', 'User', FFirebird.User);
    Ini.WriteString('FIREBIRD', 'Password', FFirebird.Password);
    Ini.WriteString('FIREBIRD', 'VendorLib', FFirebird.VendorLib);
    Ini.WriteString('FIREBIRD', 'Charset', FFirebird.Charset);

    Ini.WriteString('CONTROLID', 'IP', FControlID.IP);
    Ini.WriteInteger('CONTROLID', 'Porta', FControlID.Porta);
    if FControlID.UsarSSL then
      Ini.WriteString('CONTROLID', 'UsarSSL', 'S')
    else
      Ini.WriteString('CONTROLID', 'UsarSSL', 'N');

    Ini.WriteString('CONTROLID', 'Usuario', FControlID.Usuario);
    Ini.WriteString('CONTROLID', 'Senha', FControlID.Senha);
    Ini.WriteInteger('CONTROLID', 'IntervaloColetaSegundos', FControlID.IntervaloColetaSegundos);
    Ini.WriteString('CONTROLID', 'ModoColeta', FControlID.ModoColeta);

    if FControlID.Portaria671 then
      Ini.WriteString('CONTROLID', 'Portaria671', 'S')
    else
      Ini.WriteString('CONTROLID', 'Portaria671', 'N');

    if FControlID.AutoIniciarColeta then
      Ini.WriteString('CONTROLID', 'AutoIniciarColeta', 'S')
    else
      Ini.WriteString('CONTROLID', 'AutoIniciarColeta', 'N');
  finally
    Ini.Free;
  end;
end;

initialization

finalization
  if GAppConfig <> nil then
    GAppConfig.Free;

end.
