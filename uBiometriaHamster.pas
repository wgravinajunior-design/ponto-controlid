unit uBiometriaHamster;

{
  Integração com o leitor biométrico Nitgen Hamster DX (USB).

  Utiliza o SDK NBioBSP (eNBSP) da Nitgen via COM (NBioBSPCOM.dll, ProgID
  'NBioBSPCOM.NBioBSP'), com late binding - o projeto compila sem o SDK e,
  em tempo de execução, o driver do Hamster DX + eNBSP precisam estar instalados.

  O leitor é usado apenas para LEITURA: o template (FIR) de cada colaborador é
  capturado no cadastro e gravado no banco; no terminal de ponto a digital lida
  é identificada (1:N) contra os templates cadastrados.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants, System.StrUtils,
  System.IOUtils, System.Win.Registry, System.Win.ComObj, Winapi.ActiveX;

const
  NBIO_PROGID = 'NBioBSPCOM.NBioBSP';

  NBioAPI_DEVICE_ID_AUTO_DETECT = 255;

  NBioAPI_FIR_PURPOSE_VERIFY   = 1;
  NBioAPI_FIR_PURPOSE_IDENTIFY = 2;
  NBioAPI_FIR_PURPOSE_ENROLL   = 3;

  NBioAPI_WINDOW_STYLE_POPUP     = 0;
  NBioAPI_WINDOW_STYLE_INVISIBLE = 1;

  NBioAPIERROR_NONE = 0;

type
  TDigitalCadastrada = record
    PessoaId: Integer;
    Nome: string;
    Template: string;
  end;
  TDigitaisCadastradas = TArray<TDigitalCadastrada>;

  THamsterDX = class
  private
    FBSP: OleVariant;
    FDevice: OleVariant;
    FExtraction: OleVariant;
    FMatching: OleVariant;
    FIndexSearch: OleVariant;
    FCriado: Boolean;
    FAberto: Boolean;
    FUsaIndexSearch: Boolean;
    FDigitais: TDigitaisCadastradas;
    FUltimoErro: string;
    function CriarObjetos: Boolean;
    function ErroDe(const AObj: OleVariant; const AOperacao: string): Boolean;
  public
    destructor Destroy; override;

    class function SdkInstalado: Boolean;
    class function DriverInstalado: Boolean;

    // Instaladores (driver UBio Hamster X e eNBSP SDK 32 bits). Procuram em AExtras e nas
    // pastas padrão: <exe>\Instaladores, Área de Trabalho e Downloads.
    class function LocalizarInstaladorDriver(const AExtras: array of string): string;
    class function LocalizarInstaladorSdk(const AExtras: array of string): string;
    class function LerSerialSdk(const AInstaladorSdk: string): string;

    function Abrir: Boolean;
    procedure Fechar;

    // Cadastro guiado pelo assistente do SDK (várias leituras) - devolve o template em texto
    function Cadastrar(out ATemplate: string): Boolean;
    // Leitura única. AExibirJanela = False captura sem a janela do SDK (terminal de ponto)
    function Capturar(out ATemplate: string; AExibirJanela: Boolean): Boolean;
    // Verificação 1:1
    function Comparar(const ACapturado, AArmazenado: string): Boolean;

    // Identificação 1:N
    procedure CarregarDigitais(const ADigitais: TDigitaisCadastradas);
    function Identificar(const ACapturado: string; ANivelSeguranca: Integer;
      out ADigital: TDigitalCadastrada): Boolean;

    property Aberto: Boolean read FAberto;
    property UltimoErro: string read FUltimoErro;
  end;

implementation

{ THamsterDX }

destructor THamsterDX.Destroy;
begin
  Fechar;
  FIndexSearch := Unassigned;
  FMatching := Unassigned;
  FExtraction := Unassigned;
  FDevice := Unassigned;
  FBSP := Unassigned;
  inherited;
end;

class function THamsterDX.SdkInstalado: Boolean;
var
  ClsId: TGUID;
begin
  Result := Succeeded(CLSIDFromProgID(PWideChar(WideString(NBIO_PROGID)), ClsId));
end;

class function THamsterDX.DriverInstalado: Boolean;
var
  Reg: TRegistry;
begin
  // O driver do Hamster (UBio/Nitgen) instala o serviço de kernel FPUSB
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    Result := Reg.KeyExists('SYSTEM\CurrentControlSet\Services\FPUSB');
  finally
    Reg.Free;
  end;
end;

function PastasDeBusca(const AExtras: array of string): TArray<string>;
var
  Perfil, Pasta: string;
  Lista: TStringList;
begin
  Perfil := GetEnvironmentVariable('USERPROFILE');
  Lista := TStringList.Create;
  try
    for Pasta in AExtras do
      if Pasta <> '' then
        Lista.Add(Pasta);
    Lista.Add(ExtractFilePath(ParamStr(0)) + 'Instaladores');
    Lista.Add(TPath.Combine(Perfil, 'OneDrive\Desktop'));
    Lista.Add(TPath.Combine(Perfil, 'Desktop'));
    Lista.Add(TPath.Combine(Perfil, 'Downloads'));
    Result := Lista.ToStringArray;
  finally
    Lista.Free;
  end;
end;

function LocalizarExe(const APastas: TArray<string>; const AFiltro: TFunc<string, Boolean>): string;
var
  Pasta, Arquivo: string;
begin
  Result := '';
  for Pasta in APastas do
  begin
    if not TDirectory.Exists(Pasta) then
      Continue;
    try
      for Arquivo in TDirectory.GetFiles(Pasta, '*.exe', TSearchOption.soAllDirectories) do
        if AFiltro(Arquivo) then
          Exit(Arquivo);
    except
      // Pasta sem permissão de leitura: segue para a próxima
    end;
  end;
end;

class function THamsterDX.LocalizarInstaladorDriver(const AExtras: array of string): string;
var
  Nome: string;
begin
  if TOSVersion.Architecture in [arIntelX64, arARM64] then
    Nome := 'UBio_Hamster_X_Driver_Setup_x64.exe'
  else
    Nome := 'UBio_Hamster_X_Driver_Setup_x86.exe';
  Result := LocalizarExe(PastasDeBusca(AExtras),
    function(AArquivo: string): Boolean
    begin
      Result := SameText(ExtractFileName(AArquivo), Nome);
    end);
end;

class function THamsterDX.LocalizarInstaladorSdk(const AExtras: array of string): string;
begin
  // O sistema é 32 bits: usa sempre o instalador "Master CD\for 32bit\setup.exe" do eNBSP
  Result := LocalizarExe(PastasDeBusca(AExtras),
    function(AArquivo: string): Boolean
    begin
      Result := SameText(ExtractFileName(AArquivo), 'setup.exe') and
        ContainsText(AArquivo, 'eNBSP') and ContainsText(AArquivo, '32bit');
    end);
end;

class function THamsterDX.LerSerialSdk(const AInstaladorSdk: string): string;
var
  Pasta, Arquivo: string;
  I: Integer;
begin
  // O pacote do eNBSP traz o SERIAL.txt alguns níveis acima do setup.exe
  Result := '';
  Pasta := ExtractFileDir(AInstaladorSdk);
  for I := 0 to 3 do
  begin
    Arquivo := TPath.Combine(Pasta, 'SERIAL.txt');
    if FileExists(Arquivo) then
      Exit(Trim(TFile.ReadAllText(Arquivo)));
    Pasta := ExtractFileDir(Pasta);
    if Pasta = '' then
      Break;
  end;
end;

function THamsterDX.CriarObjetos: Boolean;
var
  Skin: string;
begin
  Result := FCriado;
  if FCriado then
    Exit;

  if not SdkInstalado then
  begin
    FUltimoErro := 'SDK Nitgen NBioBSP (eNBSP) não encontrado. Instale o driver do Hamster DX ' +
      'e o eNBSP SDK (NBioBSPCOM.dll registrado) nesta máquina.';
    Exit;
  end;

  try
    FBSP := CreateOleObject(NBIO_PROGID);
    FDevice := FBSP.Device;
    FExtraction := FBSP.Extraction;
    FMatching := FBSP.Matching;

    // Tradução do assistente de cadastro, se o recurso de idioma estiver junto do executável
    Skin := ExtractFilePath(ParamStr(0)) + 'NBSP2Por.dll';
    if FileExists(Skin) then
    begin
      try
        FBSP.SetSkinResource(Skin);
      except
      end;
    end;

    FCriado := True;
    Result := True;
  except
    on E: Exception do
      FUltimoErro := 'Falha ao iniciar o SDK NBioBSP: ' + E.Message;
  end;
end;

function THamsterDX.ErroDe(const AObj: OleVariant; const AOperacao: string): Boolean;
var
  Codigo: Integer;
  Descricao: string;
begin
  Codigo := AObj.ErrorCode;
  Result := Codigo <> NBioAPIERROR_NONE;
  if Result then
  begin
    Descricao := '';
    try
      Descricao := AObj.ErrorDescription;
    except
    end;
    if Descricao <> '' then
      FUltimoErro := Format('%s: %s (código %d)', [AOperacao, Descricao, Codigo])
    else
      FUltimoErro := Format('%s: código de erro NBioBSP %d', [AOperacao, Codigo]);
  end;
end;

function THamsterDX.Abrir: Boolean;
begin
  Result := FAberto;
  if FAberto then
    Exit;
  if not CriarObjetos then
    Exit;

  try
    FDevice.Open(NBioAPI_DEVICE_ID_AUTO_DETECT);
    if ErroDe(FDevice, 'Não foi possível abrir o leitor Hamster DX') then
      Exit;
    FAberto := True;
    Result := True;
  except
    on E: Exception do
      FUltimoErro := 'Não foi possível abrir o leitor Hamster DX: ' + E.Message;
  end;
end;

procedure THamsterDX.Fechar;
begin
  if not FAberto then
    Exit;
  try
    FDevice.Close(NBioAPI_DEVICE_ID_AUTO_DETECT);
  except
  end;
  FAberto := False;
end;

function THamsterDX.Cadastrar(out ATemplate: string): Boolean;
begin
  Result := False;
  ATemplate := '';
  if not Abrir then
    Exit;

  try
    FExtraction.WindowStyle := NBioAPI_WINDOW_STYLE_POPUP;
  except
  end;

  try
    FExtraction.Enroll(Null, Null);
    if ErroDe(FExtraction, 'Cadastro da digital não concluído') then
      Exit;
    ATemplate := FExtraction.TextEncodeFIR;
    Result := ATemplate <> '';
    if not Result then
      FUltimoErro := 'O leitor não retornou o template da digital.';
  except
    on E: Exception do
      FUltimoErro := 'Erro no cadastro da digital: ' + E.Message;
  end;
end;

function THamsterDX.Capturar(out ATemplate: string; AExibirJanela: Boolean): Boolean;
begin
  Result := False;
  ATemplate := '';
  if not Abrir then
    Exit;

  try
    if AExibirJanela then
      FExtraction.WindowStyle := NBioAPI_WINDOW_STYLE_POPUP
    else
      FExtraction.WindowStyle := NBioAPI_WINDOW_STYLE_INVISIBLE;
  except
  end;

  try
    FExtraction.Capture(NBioAPI_FIR_PURPOSE_VERIFY);
    if ErroDe(FExtraction, 'Leitura da digital') then
      Exit;
    ATemplate := FExtraction.TextEncodeFIR;
    Result := ATemplate <> '';
  except
    on E: Exception do
      FUltimoErro := 'Erro na leitura da digital: ' + E.Message;
  end;
end;

function THamsterDX.Comparar(const ACapturado, AArmazenado: string): Boolean;
begin
  Result := False;
  if (ACapturado = '') or (AArmazenado = '') or not CriarObjetos then
    Exit;
  try
    FMatching.VerifyMatch(ACapturado, AArmazenado);
    if ErroDe(FMatching, 'Comparação de digitais') then
      Exit;
    Result := Integer(FMatching.MatchingResult) <> 0;
  except
    on E: Exception do
      FUltimoErro := 'Erro na comparação de digitais: ' + E.Message;
  end;
end;

procedure THamsterDX.CarregarDigitais(const ADigitais: TDigitaisCadastradas);
var
  I: Integer;
begin
  FDigitais := Copy(ADigitais);
  FUsaIndexSearch := False;
  if not CriarObjetos then
    Exit;

  // IndexSearch = identificação 1:N rápida do SDK. Se indisponível, compara 1:1 com cada digital.
  try
    FIndexSearch := FBSP.IndexSearch;
    FIndexSearch.ClearDB;
    for I := 0 to High(FDigitais) do
      FIndexSearch.AddFIR(FDigitais[I].Template, I + 1);
    FUsaIndexSearch := True;
  except
    FIndexSearch := Unassigned;
    FUsaIndexSearch := False;
  end;
end;

function THamsterDX.Identificar(const ACapturado: string; ANivelSeguranca: Integer;
  out ADigital: TDigitalCadastrada): Boolean;
var
  I, Indice: Integer;
begin
  Result := False;
  ADigital := Default(TDigitalCadastrada);
  if (ACapturado = '') or (Length(FDigitais) = 0) then
    Exit;

  if FUsaIndexSearch then
  begin
    try
      FIndexSearch.IdentifyUser(ACapturado, ANivelSeguranca);
      if Integer(FIndexSearch.ErrorCode) = NBioAPIERROR_NONE then
      begin
        Indice := Integer(FIndexSearch.UserID) - 1;
        if (Indice >= 0) and (Indice <= High(FDigitais)) then
        begin
          ADigital := FDigitais[Indice];
          Result := True;
        end;
      end;
      Exit;
    except
      // Falha no motor 1:N: segue para a comparação 1:1
      FUsaIndexSearch := False;
    end;
  end;

  for I := 0 to High(FDigitais) do
  begin
    if Comparar(ACapturado, FDigitais[I].Template) then
    begin
      ADigital := FDigitais[I];
      Exit(True);
    end;
  end;
end;

end.
