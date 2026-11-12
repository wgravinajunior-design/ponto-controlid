unit uConfig;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, uBuildInfo;

const
  // Versão e build são gerados pelo build.ps1 (ver version.json / uBuildInfo.pas)
  APP_VERSION = BUILD_VERSION;
  APP_BUILD = BUILD_NUMBER;
  APP_BUILD_DATE = BUILD_DATE;
  GITHUB_OWNER = 'wgravinajunior-design';
  GITHUB_REPO = 'ponto-controlid';

type
  TUpdateInfo = record
    HasUpdate: Boolean;
    LatestVersion: string;
    LatestBuild: Integer;
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

  TAtualizacaoConfig = record
    AutoAtualizar: Boolean;
    IntervaloVerificacaoMin: Integer;
  end;

  // Integrações de relógio de ponto suportadas
  TTipoRelogio = (trControlID, trHamsterDX);

  TRelogioConfig = record
    Tipo: TTipoRelogio;
    NivelSeguranca: Integer;           // 1 (mais tolerante) a 9 (mais rigoroso) - Nitgen NBioBSP
    IntervaloMinimoBatidaMin: Integer; // ignora leituras repetidas do mesmo colaborador
    AbrirTerminalAoIniciar: Boolean;
  end;

  TAppConfig = class
  private
    FIniPath: string;
    FFirebird: TFirebirdConfig;
    FControlID: TControlIDDefaultConfig;
    FAtualizacao: TAtualizacaoConfig;
    FRelogio: TRelogioConfig;
  public
    constructor Create(const AIniPath: string = '');
    procedure Load;
    procedure Save;

    property Firebird: TFirebirdConfig read FFirebird write FFirebird;
    property ControlID: TControlIDDefaultConfig read FControlID write FControlID;
    property Atualizacao: TAtualizacaoConfig read FAtualizacao write FAtualizacao;
    property Relogio: TRelogioConfig read FRelogio write FRelogio;
    property IniPath: string read FIniPath;
  end;

function AppConfig: TAppConfig;
function VersaoCompleta: string;
function TipoRelogioParaStr(ATipo: TTipoRelogio): string;
function StrParaTipoRelogio(const AValor: string): TTipoRelogio;
function TipoRelogioDescricao(ATipo: TTipoRelogio): string;
function ModoHamsterDX: Boolean;

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

function VersaoCompleta: string;
begin
  Result := Format('v%s  •  Build %d', [APP_VERSION, APP_BUILD]);
end;

function TipoRelogioParaStr(ATipo: TTipoRelogio): string;
begin
  case ATipo of
    trHamsterDX: Result := 'HAMSTER_DX';
  else
    Result := 'CONTROLID';
  end;
end;

function StrParaTipoRelogio(const AValor: string): TTipoRelogio;
begin
  if SameText(Trim(AValor), 'HAMSTER_DX') then
    Result := trHamsterDX
  else
    Result := trControlID;
end;

function TipoRelogioDescricao(ATipo: TTipoRelogio): string;
begin
  case ATipo of
    trHamsterDX: Result := 'Leitor Biométrico Nitgen Hamster DX (USB)';
  else
    Result := 'Relógio de Ponto Control iD (Rede / API)';
  end;
end;

function ModoHamsterDX: Boolean;
begin
  Result := AppConfig.Relogio.Tipo = trHamsterDX;
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

  FAtualizacao.AutoAtualizar := True;
  FAtualizacao.IntervaloVerificacaoMin := 60;

  FRelogio.Tipo := trControlID;
  FRelogio.NivelSeguranca := 5;
  FRelogio.IntervaloMinimoBatidaMin := 2;
  FRelogio.AbrirTerminalAoIniciar := False;

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

    FAtualizacao.AutoAtualizar := SameText(Ini.ReadString('ATUALIZACAO', 'AutoAtualizar', 'S'), 'S');
    FAtualizacao.IntervaloVerificacaoMin := Ini.ReadInteger('ATUALIZACAO', 'IntervaloVerificacaoMin', FAtualizacao.IntervaloVerificacaoMin);
    if FAtualizacao.IntervaloVerificacaoMin < 5 then
      FAtualizacao.IntervaloVerificacaoMin := 5;

    FRelogio.Tipo := StrParaTipoRelogio(Ini.ReadString('RELOGIO', 'Tipo', TipoRelogioParaStr(FRelogio.Tipo)));
    FRelogio.NivelSeguranca := Ini.ReadInteger('RELOGIO', 'NivelSeguranca', FRelogio.NivelSeguranca);
    if (FRelogio.NivelSeguranca < 1) or (FRelogio.NivelSeguranca > 9) then
      FRelogio.NivelSeguranca := 5;
    FRelogio.IntervaloMinimoBatidaMin := Ini.ReadInteger('RELOGIO', 'IntervaloMinimoBatidaMin', FRelogio.IntervaloMinimoBatidaMin);
    if FRelogio.IntervaloMinimoBatidaMin < 0 then
      FRelogio.IntervaloMinimoBatidaMin := 0;
    FRelogio.AbrirTerminalAoIniciar := SameText(Ini.ReadString('RELOGIO', 'AbrirTerminalAoIniciar', 'N'), 'S');
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

    if FAtualizacao.AutoAtualizar then
      Ini.WriteString('ATUALIZACAO', 'AutoAtualizar', 'S')
    else
      Ini.WriteString('ATUALIZACAO', 'AutoAtualizar', 'N');
    Ini.WriteInteger('ATUALIZACAO', 'IntervaloVerificacaoMin', FAtualizacao.IntervaloVerificacaoMin);

    Ini.WriteString('RELOGIO', 'Tipo', TipoRelogioParaStr(FRelogio.Tipo));
    Ini.WriteInteger('RELOGIO', 'NivelSeguranca', FRelogio.NivelSeguranca);
    Ini.WriteInteger('RELOGIO', 'IntervaloMinimoBatidaMin', FRelogio.IntervaloMinimoBatidaMin);
    if FRelogio.AbrirTerminalAoIniciar then
      Ini.WriteString('RELOGIO', 'AbrirTerminalAoIniciar', 'S')
    else
      Ini.WriteString('RELOGIO', 'AbrirTerminalAoIniciar', 'N');
  finally
    Ini.Free;
  end;
end;

initialization

finalization
  if GAppConfig <> nil then
    GAppConfig.Free;

end.
