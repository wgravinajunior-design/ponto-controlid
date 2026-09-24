unit uControlIDClient;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.JSON,
  System.Generics.Collections, System.NetConsts,
  System.Net.HttpClient, System.Net.URLClient;

type
  TControlIDUser = record
    Id: Int64;
    Name: string;
    Cpf: string;
    Pis: string;
    Registration: string;
    Bars: string;
    Rfid: Int64;
    Code: Int64;
    Password: string;
    Admin: Boolean;
    UserTypeId: Integer;
  end;

  TControlIDAccessLog = record
    Id: Int64;
    Time: TDateTime;
    UserId: Int64;
    Event: Integer;
    DeviceId: Int64;
    PortalId: Integer;
    IdentificationRuleId: Integer;
  end;

  TAfdRecord = record
    Nsr: Int64;
    Tipo: Integer;
    DataHora: TDateTime;
    Pis: string;
    Cpf: string;
    RawLine: string;
  end;

  TControlIDCompany = record
    DocType: Integer; // 1 = CNPJ, 2 = CPF
    CpfCnpj: string;
    Name: string;
    Address: string;
    Cei: string;
    CpfResp: string;
  end;

  TControlIDClient = class
  private
    FHost: string;
    FPort: Integer;
    FUseSSL: Boolean;
    FUser: string;
    FPassword: string;
    FSessionToken: string;
    FLastError: string;
    FTimeoutSec: Integer;

    procedure DoValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest;
      const Certificate: TCertificate; var Accepted: Boolean);
    function GetBaseURL: string;
  public
    function BuildURL(const AEndpoint: string; const AIncludeSession: Boolean = True; const AExtraParams: string = ''): string;
    function ExecutePost(const AURL: string; const AJsonBody: string; out AResponseText: string): Integer;
    constructor Create(const AHost: string = '192.168.1.200'; APort: Integer = 80; AUseSSL: Boolean = False);
    destructor Destroy; override;

    function Login(const AUser, APass: string): Boolean;
    function SessionIsValid: Boolean;
    procedure Logout;
    function EnsureSession: Boolean;

    function GetSystemInformation(out ASerial, AFWVersion, ADeviceId: string; out ATime: TDateTime): Boolean;
    function SetSystemTime(const ADateTime: TDateTime): Boolean;

    // Empregador (Portaria 671 / 1510)
    function GetCompany(out ACompany: TControlIDCompany): Boolean;
    function SetCompany(const ACompany: TControlIDCompany): Boolean;

    function GetUsers(out AUsers: TArray<TControlIDUser>): Boolean;
    function AddUser(const AUser: TControlIDUser; out ANewId: Int64): Boolean;
    function ModifyUser(const AUser: TControlIDUser): Boolean;
    function DestroyUser(AId: Int64): Boolean;
    function ClearAllUsers(out ARemovedCount: Integer): Boolean;

    function GetAccessLogs(AFromLogId: Int64; out ALogs: TArray<TControlIDAccessLog>): Boolean;
    function GetAFD(AInitialNSR: Int64; APortaria671: Boolean; out AAfdContent: string): Boolean;
    function SyncTimeZone(AId: Integer; const AName, AEnt1, ASai1, AEnt2, ASai2: string): Boolean;

    class function ParseAFD(const AAfdContent: string): TArray<TAfdRecord>; static;

    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
    property UseSSL: Boolean read FUseSSL write FUseSSL;
    property User: string read FUser write FUser;
    property Password: string read FPassword write FPassword;
    property SessionToken: string read FSessionToken write FSessionToken;
    property LastError: string read FLastError write FLastError;
    property TimeoutSec: Integer read FTimeoutSec write FTimeoutSec;
    property BaseURL: string read GetBaseURL;
  end;

function FormatarErroAmigavel(const ARawError: string): string;
function OnlyDigits(const S: string): string;

implementation

function FormatarErroAmigavel(const ARawError: string): string;
var
  Low: string;
  PosErr: Integer;
begin
  Low := LowerCase(ARawError);

  if Pos('cadastre empregador', Low) > 0 then
    Result := 'O relógio de ponto (REP) exige o cadastro prévio do Empregador (CNPJ e Razão Social) no equipamento antes de receber colaboradores.'
  else if Pos('invalid command', Low) > 0 then
    Result := 'O comando solicitado não é suportado pelo firmware deste modelo de equipamento.'
  else if (Pos('12007', Low) > 0) or (Pos('não pôde ser resolvido', Low) > 0) or (Pos('nao pode ser resolvido', Low) > 0) then
    Result := 'Endereço IP não localizado. Verifique se o IP informado está correto na rede local.'
  else if (Pos('12029', Low) > 0) or (Pos('conexão com o servidor não pôde ser estabelecida', Low) > 0) or
          (Pos('conexao com o servidor nao pode ser estabelecida', Low) > 0) then
    Result := 'Não foi possível conectar ao relógio. Verifique se o equipamento está ligado e com o cabo de rede conectado.'
  else if (Pos('12002', Low) > 0) or (Pos('tempo limite', Low) > 0) or (Pos('timeout', Low) > 0) or (Pos('timed out', Low) > 0) then
    Result := 'Tempo limite de resposta esgotado. O relógio demorou para responder; tente novamente.'
  else if (Pos('12175', Low) > 0) or (Pos('certificado ssl', Low) > 0) then
    Result := 'Falha no certificado SSL/HTTPS. Desmarque a opção SSL se o equipamento estiver configurado para HTTP comum (porta 80).'
  else if (Pos('status http 401', Low) > 0) or (Pos('status 401', Low) > 0) or (Pos('unauthorized', Low) > 0) or (Pos('invalid credentials', Low) > 0) then
    Result := 'Usuário ou senha incorretos. Por favor, confira as credenciais de acesso cadastradas.'
  else if (Pos('duplicate key', Low) > 0) or (Pos('já existe', Low) > 0) then
    Result := 'Já existe um cadastro com estes dados na memória do relógio.'
  else if Pos('user not found', Low) > 0 then
    Result := 'Colaborador não localizado na memória do relógio.'
  else if Pos('status -1', Low) > 0 then
    Result := 'O relógio não retornou resposta. Verifique se o endereço IP e a porta estão corretos.'
  else if Pos('status http 500', Low) > 0 then
    Result := 'O relógio encontrou uma falha interna temporária ao processar a solicitação.'
  else if (Pos('{"error":', Low) > 0) then
  begin
    PosErr := Pos('"error":"', ARawError);
    if PosErr > 0 then
    begin
      Result := Copy(ARawError, PosErr + 9, MaxInt);
      if Pos('"', Result) > 0 then
        Result := Copy(Result, 1, Pos('"', Result) - 1);
      Result := 'O relógio informou: ' + Result;
    end
    else
      Result := ARawError;
  end
  else
    Result := ARawError;
end;

function OnlyDigits(const S: string): string;
var
  C: Char;
begin
  Result := '';
  for C in S do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

{ TControlIDClient }

constructor TControlIDClient.Create(const AHost: string; APort: Integer; AUseSSL: Boolean);
begin
  inherited Create;
  FHost := AHost;
  FPort := APort;
  FUseSSL := AUseSSL;
  FUser := 'admin';
  FPassword := 'admin';
  FSessionToken := '';
  FLastError := '';
  FTimeoutSec := 5;
end;

destructor TControlIDClient.Destroy;
begin
  inherited;
end;

procedure TControlIDClient.DoValidateServerCertificate(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate; var Accepted: Boolean);
begin
  Accepted := True; // Aceita certificado autoassinado do equipamento Control iD
end;

function TControlIDClient.GetBaseURL: string;
var
  Proto: string;
  CleanHost: string;
begin
  CleanHost := Trim(FHost);
  if FUseSSL or (FPort = 443) then
    Proto := 'https://'
  else
    Proto := 'http://';

  if (FPort = 80) and (not FUseSSL) then
    Result := Proto + CleanHost
  else if (FPort = 443) and (FUseSSL or (Proto = 'https://')) then
    Result := Proto + CleanHost
  else
    Result := Format('%s%s:%d', [Proto, CleanHost, FPort]);
end;

function TControlIDClient.BuildURL(const AEndpoint: string; const AIncludeSession: Boolean; const AExtraParams: string): string;
var
  Sep: string;
begin
  Result := GetBaseURL;
  if not AEndpoint.StartsWith('/') then
    Result := Result + '/';
  Result := Result + AEndpoint;

  Sep := '?';
  if AIncludeSession and (FSessionToken <> '') then
  begin
    Result := Result + Sep + 'session=' + FSessionToken;
    Sep := '&';
  end;

  if AExtraParams <> '' then
    Result := Result + Sep + AExtraParams;
end;

function TControlIDClient.ExecutePost(const AURL: string; const AJsonBody: string; out AResponseText: string): Integer;
var
  HTTP: THTTPClient;
  StringStream: TStringStream;
  Response: IHTTPResponse;
begin
  AResponseText := '';
  Result := 0;
  HTTP := THTTPClient.Create;
  try
    HTTP.OnValidateServerCertificate := DoValidateServerCertificate;
    HTTP.HandleRedirects := True;
    HTTP.ConnectionTimeout := FTimeoutSec * 1000;
    HTTP.ResponseTimeout := FTimeoutSec * 1000;
    HTTP.ContentType := 'application/json; charset=utf-8';
    HTTP.Accept := 'application/json, text/plain, */*';

    StringStream := TStringStream.Create(AJsonBody, TEncoding.UTF8);
    try
      try
        Response := HTTP.Post(AURL, StringStream);
        Result := Response.StatusCode;
        AResponseText := Response.ContentAsString(TEncoding.UTF8);
      except
        on E: Exception do
        begin
          FLastError := 'Falha de comunicação (' + AURL + '): ' + E.Message +
            ' | Verifique se o equipamento está ligado na rede e confirme o IP na tela do relógio (Menu > Configurações > Rede).';
          Result := -1;
        end;
      end;
    finally
      StringStream.Free;
    end;
  finally
    HTTP.Free;
  end;
end;

function TControlIDClient.Login(const AUser, APass: string): Boolean;
var
  URL, Body, Resp: string;
  Code: Integer;
  JSON: TJSONObject;
begin
  Result := False;
  FUser := AUser;
  FPassword := APass;
  FSessionToken := '';
  FLastError := '';

  URL := BuildURL('login.fcgi', False);
  Body := Format('{"login":"%s","password":"%s"}', [AUser, APass]);

  Code := ExecutePost(URL, Body, Resp);
  if Code = 200 then
  begin
    JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Assigned(JSON) then
    try
      if JSON.TryGetValue<string>('session', FSessionToken) then
        Result := True
      else
        FLastError := 'Resposta de login não continha token de sessão: ' + Resp;
    finally
      JSON.Free;
    end
    else
      FLastError := 'Falha ao interpretar JSON retornado no login: ' + Resp;
  end
  else
  begin
    if (Code = -1) and (FLastError <> '') then
      // Mantém mensagem detalhada de erro de rede gerada em ExecutePost
    else
      FLastError := Format('Falha no login (Status HTTP %d): %s', [Code, Resp]);
  end;
end;

function TControlIDClient.SessionIsValid: Boolean;
var
  URL, Resp: string;
  Code: Integer;
  JSON: TJSONObject;
  IsValid: Boolean;
begin
  Result := False;
  if FSessionToken = '' then
    Exit;

  URL := BuildURL('session_is_valid.fcgi', True);
  Code := ExecutePost(URL, '{}', Resp);
  if Code = 200 then
  begin
    JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Assigned(JSON) then
    try
      if JSON.TryGetValue<Boolean>('session_is_valid', IsValid) then
        Result := IsValid;
    finally
      JSON.Free;
    end;
  end;
end;

procedure TControlIDClient.Logout;
var
  URL, Resp: string;
begin
  if FSessionToken = '' then
    Exit;
  try
    URL := BuildURL('logout.fcgi', True);
    ExecutePost(URL, '{}', Resp);
  finally
    FSessionToken := '';
  end;
end;

function TControlIDClient.EnsureSession: Boolean;
begin
  if (FSessionToken <> '') and SessionIsValid then
    Result := True
  else
    Result := Login(FUser, FPassword);
end;

function TControlIDClient.GetSystemInformation(out ASerial, AFWVersion, ADeviceId: string; out ATime: TDateTime): Boolean;
var
  URL, Resp: string;
  Code: Integer;
  JSON: TJSONObject;
  UnixTime: Int64;
  FWNum: Integer;
begin
  Result := False;
  ASerial := '';
  AFWVersion := '';
  ADeviceId := '';
  ATime := 0;

  if not EnsureSession then
    Exit;

  // 1. Tenta get_about.fcgi (específico do REP iDClass)
  URL := BuildURL('get_about.fcgi', True);
  Code := ExecutePost(URL, '{}', Resp);
  if Code = 200 then
  begin
    JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Assigned(JSON) then
    try
      JSON.TryGetValue<string>('nSerie', ASerial);
      if JSON.TryGetValue<Integer>('versionFW', FWNum) then
        AFWVersion := Format('v.%d', [FWNum])
      else
        JSON.TryGetValue<string>('versionFW', AFWVersion);
      JSON.TryGetValue<string>('mac', ADeviceId);
      ATime := Now;
      Result := True;
    finally
      JSON.Free;
    end;
  end;

  // 2. Se get_about não respondeu, tenta system_information.fcgi (linha de acesso iDAccess/iDFace)
  if not Result then
  begin
    URL := BuildURL('system_information.fcgi', True);
    Code := ExecutePost(URL, '{}', Resp);
    if Code = 200 then
    begin
      JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
      if Assigned(JSON) then
      try
        JSON.TryGetValue<string>('serial', ASerial);
        JSON.TryGetValue<string>('version', AFWVersion);
        JSON.TryGetValue<string>('device_id', ADeviceId);
        if JSON.TryGetValue<Int64>('time', UnixTime) and (UnixTime > 0) then
          ATime := TTimeZone.Local.ToLocalTime(UnixToDateTime(UnixTime))
        else
          ATime := Now;
        Result := True;
      finally
        JSON.Free;
      end;
    end
    else
      FLastError := Format('Erro ao obter informações do sistema (Status %d): %s', [Code, Resp]);
  end;
end;

function TControlIDClient.SetSystemTime(const ADateTime: TDateTime): Boolean;
var
  URL, Body, Resp, TZStr: string;
  Y, M, D, H, Min, Sec, MS: Word;
  Code, DiffMin: Integer;
  LocalDT, UtcDT: TDateTime;
begin
  Result := False;
  if not EnsureSession then
    Exit;

  DecodeDateTime(ADateTime, Y, M, D, H, Min, Sec, MS);

  // Calcula o offset de timezone no formato exigido pela Control iD (ex: "-0300")
  try
    LocalDT := ADateTime;
    UtcDT := TTimeZone.Local.ToUniversalTime(LocalDT);
    DiffMin := Round((LocalDT - UtcDT) * 1440);
    if DiffMin < 0 then
      TZStr := Format('-%02.2d%02.2d', [Abs(DiffMin) div 60, Abs(DiffMin) mod 60])
    else
      TZStr := Format('+%02.2d%02.2d', [DiffMin div 60, DiffMin mod 60]);
  except
    TZStr := '-0300';
  end;

  // 1. Tenta set_system_date_time.fcgi?mode=671 com timezone (padrão oficial REP iDClass / Portaria 671)
  URL := BuildURL('set_system_date_time.fcgi', True, 'mode=671');
  Body := Format('{"day":%d,"month":%d,"year":%d,"hour":%d,"minute":%d,"second":%d,"timezone":"%s"}',
                 [D, M, Y, H, Min, Sec, TZStr]);
  Code := ExecutePost(URL, Body, Resp);
  if (Code = 200) or (Code = 204) then
  begin
    Result := True;
    Exit;
  end;

  // 2. Tenta set_system_date_time.fcgi (sem mode=671) com timezone
  URL := BuildURL('set_system_date_time.fcgi', True);
  Code := ExecutePost(URL, Body, Resp);
  if (Code = 200) or (Code = 204) then
  begin
    Result := True;
    Exit;
  end;

  // 3. Tenta set_system_date_time.fcgi sem timezone
  Body := Format('{"day":%d,"month":%d,"year":%d,"hour":%d,"minute":%d,"second":%d}',
                 [D, M, Y, H, Min, Sec]);
  URL := BuildURL('set_system_date_time.fcgi', True, 'mode=671');
  Code := ExecutePost(URL, Body, Resp);
  if (Code = 200) or (Code = 204) then
  begin
    Result := True;
    Exit;
  end;

  // 4. Tenta set_system_time.fcgi (apenas linha iDAccess de controle de acesso)
  URL := BuildURL('set_system_time.fcgi', True);
  Code := ExecutePost(URL, Body, Resp);
  if (Code = 200) or (Code = 204) then
    Result := True
  else
    FLastError := Format('Erro ao ajustar data/hora (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.GetCompany(out ACompany: TControlIDCompany): Boolean;
var
  URL, Resp: string;
  Code: Integer;
  JSON, CompObj: TJSONObject;
  DocNum, CeiNum, CpfNum: Int64;
begin
  Result := False;
  FillChar(ACompany, SizeOf(ACompany), 0);
  ACompany.DocType := 1;
  if not EnsureSession then
    Exit;

  URL := BuildURL('load_company.fcgi', True);
  Code := ExecutePost(URL, '{}', Resp);
  if Code = 200 then
  begin
    JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Assigned(JSON) then
    try
      CompObj := JSON.GetValue<TJSONObject>('company');
      if Assigned(CompObj) then
      begin
        CompObj.TryGetValue<Integer>('tipo_doc', ACompany.DocType);
        if CompObj.TryGetValue<Int64>('cpf_cnpj', DocNum) and (DocNum > 0) then
          ACompany.CpfCnpj := IntToStr(DocNum)
        else
          CompObj.TryGetValue<string>('cpf_cnpj', ACompany.CpfCnpj);

        CompObj.TryGetValue<string>('name', ACompany.Name);
        CompObj.TryGetValue<string>('address', ACompany.Address);

        if CompObj.TryGetValue<Int64>('cei', CeiNum) and (CeiNum > 0) then
          ACompany.Cei := IntToStr(CeiNum)
        else
          CompObj.TryGetValue<string>('cei', ACompany.Cei);

        if CompObj.TryGetValue<Int64>('cpf', CpfNum) and (CpfNum > 0) then
          ACompany.CpfResp := IntToStr(CpfNum)
        else
          CompObj.TryGetValue<string>('cpf', ACompany.CpfResp);

        Result := True;
        Exit;
      end;
    finally
      JSON.Free;
    end;
  end;

  FLastError := Format('Erro ao carregar dados do empregador no relógio (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.SetCompany(const ACompany: TControlIDCompany): Boolean;
var
  URL, Body, Resp: string;
  Code: Integer;
  DocNum, CeiNum, CpfNum: Int64;
  CleanDoc, CleanCei, CleanCpf: string;
begin
  Result := False;
  if not EnsureSession then
    Exit;

  CleanDoc := OnlyDigits(ACompany.CpfCnpj);
  CleanCei := OnlyDigits(ACompany.Cei);
  CleanCpf := OnlyDigits(ACompany.CpfResp);

  DocNum := StrToInt64Def(CleanDoc, 0);
  CeiNum := StrToInt64Def(CleanCei, 0);
  CpfNum := StrToInt64Def(CleanCpf, 0);

  // Se for CNPJ e o CPF do responsável não foi informado mas o documento tem 11 dígitos
  if (ACompany.DocType = 1) and (CpfNum = 0) and (Length(CleanDoc) = 11) then
    CpfNum := DocNum;

  Body := Format('{"company":{"tipo_doc":%d,"cpf_cnpj":%d,"name":"%s","address":"%s","cei":%d,"cpf":%d}}',
    [ACompany.DocType, DocNum, ACompany.Name, ACompany.Address, CeiNum, CpfNum]);

  URL := BuildURL('edit_company.fcgi', True);
  Code := ExecutePost(URL, Body, Resp);
  if (Code = 200) or (Code = 204) then
  begin
    Result := True;
    Exit;
  end;

  FLastError := Format('Erro ao salvar dados do empregador no relógio (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.GetUsers(out AUsers: TArray<TControlIDUser>): Boolean;
var
  URL, Body, Resp: string;
  Code, I: Integer;
  JSON, UserObj: TJSONObject;
  UserArr: TJSONArray;
  Item: TControlIDUser;
  PisNum, RegNum: Int64;
begin
  Result := False;
  SetLength(AUsers, 0);

  if not EnsureSession then
    Exit;

  // 1. Tenta load_users.fcgi (padrão oficial REP iDClass - Portaria 671 / 1510)
  URL := BuildURL('load_users.fcgi', True);
  Body := '{"limit":1000,"offset":0}';
  Code := ExecutePost(URL, Body, Resp);
  if Code = 200 then
  begin
    JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Assigned(JSON) then
    try
      UserArr := JSON.GetValue<TJSONArray>('users');
      if Assigned(UserArr) then
      begin
        SetLength(AUsers, UserArr.Count);
        for I := 0 to UserArr.Count - 1 do
        begin
          UserObj := UserArr.Items[I] as TJSONObject;
          FillChar(Item, SizeOf(Item), 0);
          UserObj.TryGetValue<string>('name', Item.Name);

          PisNum := 0;
          if UserObj.TryGetValue<Int64>('pis', PisNum) and (PisNum > 0) then
          begin
            Item.Pis := Format('%.11d', [PisNum]);
            Item.Cpf := Item.Pis;
            Item.Id := PisNum;
          end;

          RegNum := 0;
          if UserObj.TryGetValue<Int64>('registration', RegNum) and (RegNum > 0) then
          begin
            Item.Registration := IntToStr(RegNum);
            if Item.Id = 0 then
              Item.Id := RegNum;
          end
          else
            UserObj.TryGetValue<string>('registration', Item.Registration);

          UserObj.TryGetValue<string>('bars', Item.Bars);
          UserObj.TryGetValue<Int64>('rfid', Item.Rfid);
          UserObj.TryGetValue<Int64>('code', Item.Code);
          UserObj.TryGetValue<string>('password', Item.Password);
          UserObj.TryGetValue<Boolean>('admin', Item.Admin);

          AUsers[I] := Item;
        end;
        Result := True;
        Exit;
      end;
    finally
      JSON.Free;
    end;
  end;

  // 2. Se falhar ou for equipamento de controle de acesso (iDFace / iDAccess), tenta load_objects.fcgi
  URL := BuildURL('load_objects.fcgi', True);
  Body := '{"object":"users"}';
  Code := ExecutePost(URL, Body, Resp);
  if Code = 200 then
  begin
    JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Assigned(JSON) then
    try
      UserArr := JSON.GetValue<TJSONArray>('users');
      if Assigned(UserArr) then
      begin
        SetLength(AUsers, UserArr.Count);
        for I := 0 to UserArr.Count - 1 do
        begin
          UserObj := UserArr.Items[I] as TJSONObject;
          FillChar(Item, SizeOf(Item), 0);
          UserObj.TryGetValue<Int64>('id', Item.Id);
          UserObj.TryGetValue<string>('name', Item.Name);
          UserObj.TryGetValue<string>('registration', Item.Registration);
          UserObj.TryGetValue<string>('password', Item.Password);
          UserObj.TryGetValue<Integer>('user_type_id', Item.UserTypeId);
          AUsers[I] := Item;
        end;
        Result := True;
      end;
    finally
      JSON.Free;
    end;
  end
  else
    FLastError := Format('Erro ao carregar usuários do relógio (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.AddUser(const AUser: TControlIDUser; out ANewId: Int64): Boolean;
var
  URL, Body, Resp, AdminStr: string;
  Code: Integer;
  JSON: TJSONObject;
  IdsArr: TJSONArray;
  PisVal, RegVal, CodeVal: Int64;
begin
  Result := False;
  ANewId := 0;

  if not EnsureSession then
    Exit;

  PisVal := StrToInt64Def(OnlyDigits(AUser.Pis), StrToInt64Def(OnlyDigits(AUser.Cpf), 0));
  RegVal := StrToInt64Def(OnlyDigits(AUser.Registration), AUser.Id);
  CodeVal := AUser.Code;
  if CodeVal <= 0 then
    CodeVal := RegVal;

  if AUser.Admin then
    AdminStr := 'true'
  else
    AdminStr := 'false';

  // 1. Tenta add_users.fcgi (padrão oficial REP iDClass - Portaria 671 / 1510)
  Body := Format('{"users":[{"name":"%s","pis":%d,"registration":%d,"bars":"%s","rfid":%d,"code":%d,"password":"%s","admin":%s}]}',
    [AUser.Name, PisVal, RegVal, AUser.Bars, AUser.Rfid, CodeVal, AUser.Password, AdminStr]);
  URL := BuildURL('add_users.fcgi', True);
  Code := ExecutePost(URL, Body, Resp);

  if (Code = 200) or (Code = 204) then
  begin
    if RegVal > 0 then
      ANewId := RegVal
    else
      ANewId := PisVal;
    Result := True;
    Exit;
  end;

  // Se já existir no relógio, tenta atualizar via update_users.fcgi
  if (Code = 400) and ((Pos('já existe', LowerCase(Resp)) > 0) or (Pos('duplicate', LowerCase(Resp)) > 0)) then
  begin
    URL := BuildURL('update_users.fcgi', True);
    Code := ExecutePost(URL, Body, Resp);
    if (Code = 200) or (Code = 204) then
    begin
      ANewId := RegVal;
      Result := True;
      Exit;
    end;
  end;

  // 2. Se o comando não for suportado (iDFace / iDAccess), tenta create_objects.fcgi
  if (Code = 400) and (Pos('invalid command', LowerCase(Resp)) > 0) then
  begin
    URL := BuildURL('create_objects.fcgi', True);
    if AUser.Id > 0 then
      Body := Format('{"object":"users","values":[{"id":%d,"name":"%s","registration":"%s","password":"%s"}]}',
                     [AUser.Id, AUser.Name, AUser.Registration, AUser.Password])
    else
      Body := Format('{"object":"users","values":[{"name":"%s","registration":"%s","password":"%s"}]}',
                     [AUser.Name, AUser.Registration, AUser.Password]);

    Code := ExecutePost(URL, Body, Resp);
    if Code = 200 then
    begin
      JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
      if Assigned(JSON) then
      try
        IdsArr := JSON.GetValue<TJSONArray>('ids');
        if Assigned(IdsArr) and (IdsArr.Count > 0) then
          ANewId := (IdsArr.Items[0] as TJSONNumber).AsInt64
        else
          ANewId := AUser.Id;
        Result := True;
      finally
        JSON.Free;
      end;

      if Result and (AUser.Rfid > 0) and (ANewId > 0) then
      begin
        URL := BuildURL('create_objects.fcgi', True);
        Body := Format('{"object":"cards","values":[{"value":%d,"user_id":%d}]}', [AUser.Rfid, ANewId]);
        ExecutePost(URL, Body, Resp);
      end;
      Exit;
    end;
  end;

  FLastError := Format('Erro ao cadastrar colaborador no relógio (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.ModifyUser(const AUser: TControlIDUser): Boolean;
var
  URL, Body, Resp, AdminStr: string;
  Code: Integer;
  PisVal, RegVal, CodeVal: Int64;
begin
  Result := False;
  if not EnsureSession then
    Exit;

  PisVal := StrToInt64Def(OnlyDigits(AUser.Pis), StrToInt64Def(OnlyDigits(AUser.Cpf), 0));
  RegVal := StrToInt64Def(OnlyDigits(AUser.Registration), AUser.Id);
  CodeVal := AUser.Code;
  if CodeVal <= 0 then
    CodeVal := RegVal;

  if AUser.Admin then
    AdminStr := 'true'
  else
    AdminStr := 'false';

  // 1. Tenta update_users.fcgi (padrão REP iDClass)
  Body := Format('{"users":[{"name":"%s","pis":%d,"registration":%d,"bars":"%s","rfid":%d,"code":%d,"password":"%s","admin":%s}]}',
    [AUser.Name, PisVal, RegVal, AUser.Bars, AUser.Rfid, CodeVal, AUser.Password, AdminStr]);
  URL := BuildURL('update_users.fcgi', True);
  Code := ExecutePost(URL, Body, Resp);
  if (Code = 200) or (Code = 204) then
  begin
    Result := True;
    Exit;
  end;

  // 2. Se for iDAccess / iDFace, tenta modify_objects.fcgi
  if (Code = 400) and (Pos('invalid command', LowerCase(Resp)) > 0) then
  begin
    URL := BuildURL('modify_objects.fcgi', True);
    Body := Format('{"object":"users","values":{"name":"%s","registration":"%s","password":"%s"},"where":{"users":{"id":%d}}}',
                   [AUser.Name, AUser.Registration, AUser.Password, AUser.Id]);
    Code := ExecutePost(URL, Body, Resp);
    if (Code = 200) or (Code = 204) then
    begin
      Result := True;
      Exit;
    end;
  end;

  FLastError := Format('Erro ao atualizar colaborador no relógio (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.DestroyUser(AId: Int64): Boolean;
var
  URL, Body, Resp: string;
  Code: Integer;
begin
  Result := False;
  if not EnsureSession then
    Exit;

  // 1. Tenta remove_users.fcgi (padrão REP iDClass aceita array de números PIS/CPF ou Registration)
  Body := Format('{"users":[%d]}', [AId]);
  URL := BuildURL('remove_users.fcgi', True);
  Code := ExecutePost(URL, Body, Resp);
  if (Code = 200) or (Code = 204) then
  begin
    Result := True;
    Exit;
  end;

  // 2. Se for iDAccess / iDFace, tenta destroy_objects.fcgi
  if (Code = 400) and (Pos('invalid command', LowerCase(Resp)) > 0) then
  begin
    URL := BuildURL('destroy_objects.fcgi', True);
    Body := Format('{"object":"users","where":{"users":{"id":%d}}}', [AId]);
    Code := ExecutePost(URL, Body, Resp);
    if (Code = 200) or (Code = 204) then
    begin
      Result := True;
      Exit;
    end;
  end;

  FLastError := Format('Erro ao remover colaborador do relógio (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.ClearAllUsers(out ARemovedCount: Integer): Boolean;
var
  Users: TArray<TControlIDUser>;
  I: Integer;
begin
  ARemovedCount := 0;
  Result := False;
  if not GetUsers(Users) then
    Exit;

  if Length(Users) = 0 then
  begin
    Result := True;
    Exit;
  end;

  for I := 0 to High(Users) do
  begin
    if DestroyUser(Users[I].Id) then
      Inc(ARemovedCount);
  end;

  Result := (ARemovedCount > 0);
end;

function TControlIDClient.GetAccessLogs(AFromLogId: Int64; out ALogs: TArray<TControlIDAccessLog>): Boolean;
var
  URL, Body, Resp: string;
  Code, I: Integer;
  JSON, LogObj: TJSONObject;
  LogArr: TJSONArray;
  Item: TControlIDAccessLog;
  UnixTime: Int64;
begin
  Result := False;
  SetLength(ALogs, 0);

  if not EnsureSession then
    Exit;

  URL := BuildURL('load_objects.fcgi', True);
  if AFromLogId > 0 then
    Body := Format('{"object":"access_logs","where":[{"object":"access_logs","field":"id","operator":">","value":%d}],"order":["ascending","id"]}', [AFromLogId])
  else
    Body := '{"object":"access_logs","order":["ascending","id"]}';

  Code := ExecutePost(URL, Body, Resp);
  if Code = 200 then
  begin
    JSON := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Assigned(JSON) then
    try
      LogArr := JSON.GetValue<TJSONArray>('access_logs');
      if Assigned(LogArr) then
      begin
        SetLength(ALogs, LogArr.Count);
        for I := 0 to LogArr.Count - 1 do
        begin
          LogObj := LogArr.Items[I] as TJSONObject;
          FillChar(Item, SizeOf(Item), 0);
          LogObj.TryGetValue<Int64>('id', Item.Id);
          if LogObj.TryGetValue<Int64>('time', UnixTime) and (UnixTime > 0) then
            Item.Time := TTimeZone.Local.ToLocalTime(UnixToDateTime(UnixTime));
          LogObj.TryGetValue<Int64>('user_id', Item.UserId);
          LogObj.TryGetValue<Integer>('event', Item.Event);
          LogObj.TryGetValue<Int64>('device_id', Item.DeviceId);
          LogObj.TryGetValue<Integer>('portal_id', Item.PortalId);
          LogObj.TryGetValue<Integer>('identification_rule_id', Item.IdentificationRuleId);
          ALogs[I] := Item;
        end;
        Result := True;
      end;
    finally
      JSON.Free;
    end;
  end
  else
    FLastError := Format('Erro ao carregar logs de acesso (Status %d): %s', [Code, Resp]);
end;

function TControlIDClient.GetAFD(AInitialNSR: Int64; APortaria671: Boolean; out AAfdContent: string): Boolean;
var
  URL, Extra, Body, Resp: string;
  Code: Integer;
begin
  Result := False;
  AAfdContent := '';

  if not EnsureSession then
    Exit;

  if APortaria671 then
    Extra := 'mode=671'
  else
    Extra := '';

  URL := BuildURL('export_afd.fcgi', True, Extra);

  if AInitialNSR > 0 then
    Body := Format('{"initial_nsr":%d}', [AInitialNSR])
  else
    Body := '{}';

  Code := ExecutePost(URL, Body, Resp);
  if Code = 200 then
  begin
    AAfdContent := Resp;
    Result := True;
  end
  else
    FLastError := Format('Erro ao exportar AFD (Status %d): %s', [Code, Resp]);
end;

class function TControlIDClient.ParseAFD(const AAfdContent: string): TArray<TAfdRecord>;
var
  Lines: TStringList;
  I: Integer;
  Line: string;
  Rec: TAfdRecord;
  Count: Integer;
  Dia, Mes, Ano, Hora, Min: Word;
begin
  SetLength(Result, 0);
  if AAfdContent = '' then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := AAfdContent;
    Count := 0;
    SetLength(Result, Lines.Count);

    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);
      if (Length(Line) >= 33) and (Line[10] = '3') then
      begin
        FillChar(Rec, SizeOf(Rec), 0);
        Rec.RawLine := Line;
        Rec.Nsr := StrToInt64Def(Copy(Line, 1, 9), 0);
        Rec.Tipo := 3;

        Dia := StrToIntDef(Copy(Line, 11, 2), 1);
        Mes := StrToIntDef(Copy(Line, 13, 2), 1);
        Ano := StrToIntDef(Copy(Line, 15, 4), 2000);
        Hora := StrToIntDef(Copy(Line, 19, 2), 0);
        Min := StrToIntDef(Copy(Line, 21, 2), 0);

        try
          Rec.DataHora := EncodeDateTime(Ano, Mes, Dia, Hora, Min, 0, 0);
        except
          Rec.DataHora := Now;
        end;

        // Portaria 1510 tem PIS com 12 digitos (23..34)
        // Portaria 671 tem CPF com 11 digitos (23..33)
        if Length(Line) >= 34 then
          Rec.Pis := Trim(Copy(Line, 23, 12));
        Rec.Cpf := Trim(Copy(Line, 23, 11));

        Result[Count] := Rec;
        Inc(Count);
      end;
    end;
    SetLength(Result, Count);
  finally
    Lines.Free;
  end;
end;

function TControlIDClient.SyncTimeZone(AId: Integer; const AName, AEnt1, ASai1, AEnt2, ASai2: string): Boolean;
var
  URL, Body, Resp: string;
  Code: Integer;
  SecE1, SecS1, SecE2, SecS2: Integer;

  function TimeToSec(const ATimeStr: string): Integer;
  var
    H, M: Integer;
  begin
    Result := 0;
    if Length(Trim(ATimeStr)) >= 5 then
    begin
      H := StrToIntDef(Copy(ATimeStr, 1, 2), 0);
      M := StrToIntDef(Copy(ATimeStr, 4, 2), 0);
      Result := (H * 3600) + (M * 60);
    end;
  end;

begin
  Result := False;
  if not EnsureSession then
    Exit;

  // 1. Tenta criar o time_zone (se já existir, ignora erro de duplicate)
  URL := BuildURL('create_objects.fcgi', True, 'object=time_zones');
  Body := Format('{"values":[{"id":%d,"name":"%s"}]}', [AId, AName]);
  Code := ExecutePost(URL, Body, Resp);

  // 2. Criar intervalos em time_spans
  SecE1 := TimeToSec(AEnt1);
  SecS1 := TimeToSec(ASai1);
  SecE2 := TimeToSec(AEnt2);
  SecS2 := TimeToSec(ASai2);

  URL := BuildURL('create_objects.fcgi', True, 'object=time_spans');
  if (SecS1 > SecE1) and (SecS2 > SecE2) then
    Body := Format('{"values":[{"time_zone_id":%d,"start":%d,"end":%d},{"time_zone_id":%d,"start":%d,"end":%d}]}',
                   [AId, SecE1, SecS1, AId, SecE2, SecS2])
  else if (SecS1 > SecE1) then
    Body := Format('{"values":[{"time_zone_id":%d,"start":%d,"end":%d}]}', [AId, SecE1, SecS1])
  else if (SecS2 > SecE2) then
    Body := Format('{"values":[{"time_zone_id":%d,"start":%d,"end":%d}]}', [AId, SecE2, SecS2])
  else
    Body := '';

  if Body <> '' then
    ExecutePost(URL, Body, Resp);

  Result := True;
end;

end.
