unit uDataModule;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.UI, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  Data.DB, uConfig;

type
  TdmDados = class(TDataModule)
    FDConnection: TFDConnection;
    FDPhysFBDriverLink: TFDPhysFBDriverLink;
    FDGUIxWaitCursor: TFDGUIxWaitCursor;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FLastError: string;
    FLastMigracaoLog: string;
    procedure ConfigureConnection;
  public
    function Conectar: Boolean;
    procedure Desconectar;
    function IsConectado: Boolean;
    function TestarConexao(out AErro: string): Boolean;

    // Relógios
    function GetRelogios(const AApenasAtivos: Boolean = False): TFDQuery;
    function GetRelogioPorId(AId: Integer): TFDQuery;
    function SalvarRelogio(AId: Integer; const ANome, AIP: string; APorta: Integer;
      AUsarSSL: Boolean; const AUsuario, ASenha, AModelo, AModoColeta: string;
      AAtivo: Boolean): Integer;
    procedure ExcluirRelogio(AId: Integer);
    procedure AtualizarUltimoLogRelogio(ARelogioId: Integer; AUltimoLogId: Int64;
      const ASerial, AFWVersion: string);

    // Colaboradores / Pessoas
    function GetColaboradores(const AApenasAtivos: Boolean = True): TFDQuery;
    function GetPessoaPorId(APessoaId: Integer): TFDQuery;
    function BuscarPessoaPorPisOuCpf(const APis, ACpf: string): Integer;
    function SalvarColaborador(var APessoaId: Integer; const ANome, ACpf, APis, AMatricula,
      AFuncao, ACodigoAcesso: string; AAtivo: Boolean; AHorarioId: Integer = 0): Boolean;
    function ExcluirColaborador(APessoaId: Integer; out AErro: string; out AInativado: Boolean): Boolean;
    procedure MarcarColaboradorSincronizado(APessoaId: Integer);
    procedure MarcarColaboradorNaoSincronizado(APessoaId: Integer);

    // Horários / Jornadas de Trabalho
    function GetHorarios(const AApenasAtivos: Boolean = True): TFDQuery;
    function GetHorarioPorId(AId: Integer): TFDQuery;
    function SalvarHorario(AId: Integer; const ADescricao, AEnt1, ASai1, AEnt2, ASai2: string;
      AToleranciaMin, ACargaDiariaMin: Integer; ACompensaSab, ATrabalhaSab: Boolean;
      const ASabEnt1, ASabSai1: string; AAtivo: Boolean): Integer;
    function ExcluirHorario(AId: Integer; out AErro: string): Boolean;

    // Justificativas / Ocorrências (Portaria 671)
    function SalvarJustificativa(APessoaId: Integer; AData: TDateTime; const ATipo, AMotivo: string;
      AAbonoMin: Integer): Boolean;
    function ExcluirJustificativa(AJusId: Integer): Boolean;
    function GetJustificativasPeriodo(APessoaId: Integer; ADataIni, ADataFim: TDateTime): TFDQuery;

    // Empresa / Empregador (Portaria 671 / 1510)
    function GetEmpresaPrincipal(out ARazao, ACnpj, AEndereco, ACei, ACpfResp: string): Boolean;
    function SalvarEmpresaPrincipal(const ARazao, ACnpj, AEndereco: string): Boolean;

    // Marcações
    function GravarMarcacao(APessoaId, ARelogioId: Integer; ADataHora: TDateTime;
      AEvento: Integer; AControlIdLogId: Int64; const AOrigem: string;
      ANsr: Int64; const APis, ACpf, ATipoBatida, ATipoIdent: string): Boolean;
    function GetMarcacoes(ADataIni, ADataFim: TDateTime; ARelogioId: Integer = 0;
      APessoaId: Integer = 0): TFDQuery;
    function ExcluirMarcacao(AMarcacaoId: Integer): Boolean;
    function AtualizarMarcacao(AId: Integer; ADataHora: TDateTime; const ATipoBatida: string): Boolean;
    function InserirMarcacaoManual(APessoaId, ARelogioId: Integer; ADataHora: TDateTime;
      const ATipoBatida: string): Integer;

    // Estatísticas para Dashboard
    function GetTotalMarcacoesHoje(out ATotal: Integer): Boolean;
    function GetTotalColaboradores(out ATotal: Integer): Boolean;
    function GetTotalRelogiosAtivos(out ATotal: Integer): Boolean;

    // Migração e Verificação de Estrutura da Base de Dados
    function TabelaExiste(const ANomeTabela: string): Boolean;
    function CampoExiste(const ANomeTabela, ANomeCampo: string): Boolean;
    function GeneratorExiste(const ANomeGen: string): Boolean;
    function ExecutarComandoDDL(const ASQL: string): Boolean;
    function ObterVersaoBanco: Integer;
    function VerificarEAtualizarEstruturaBanco(out ALogMigracao: string): Boolean;

    property LastError: string read FLastError;
    property LastMigracaoLog: string read FLastMigracaoLog;
  end;

var
  dmDados: TdmDados;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TdmDados }

procedure TdmDados.DataModuleCreate(Sender: TObject);
begin
  ConfigureConnection;
end;

procedure TdmDados.DataModuleDestroy(Sender: TObject);
begin
  Desconectar;
end;

procedure TdmDados.ConfigureConnection;
var
  Cfg: TFirebirdConfig;
begin
  Cfg := AppConfig.Firebird;
  FDPhysFBDriverLink.VendorLib := Cfg.VendorLib;

  FDConnection.Close;
  FDConnection.Params.Clear;
  FDConnection.Params.Add('DriverID=FB');
  FDConnection.Params.Add('Database=' + Cfg.Database);
  FDConnection.Params.Add('Server=' + Cfg.Server);
  FDConnection.Params.Add('Port=' + IntToStr(Cfg.Port));
  FDConnection.Params.Add('User_Name=' + Cfg.User);
  FDConnection.Params.Add('Password=' + Cfg.Password);
  FDConnection.Params.Add('CharacterSet=' + Cfg.Charset);
  FDConnection.LoginPrompt := False;
end;

function TdmDados.Conectar: Boolean;
var
  LogMig: string;
begin
  Result := False;
  FLastError := '';
  try
    ConfigureConnection;
    FDConnection.Open;
    Result := FDConnection.Connected;
    if Result then
    begin
      VerificarEAtualizarEstruturaBanco(LogMig);
      FLastMigracaoLog := LogMig;
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Falha ao conectar no banco de dados Firebird: ' + E.Message;
      Result := False;
    end;
  end;
end;

procedure TdmDados.Desconectar;
begin
  try
    if FDConnection.Connected then
      FDConnection.Close;
  except
  end;
end;

function TdmDados.IsConectado: Boolean;
begin
  Result := FDConnection.Connected;
end;

function TdmDados.TestarConexao(out AErro: string): Boolean;
begin
  AErro := '';
  Result := Conectar;
  if not Result then
    AErro := FLastError;
end;

function TdmDados.GetRelogios(const AApenasAtivos: Boolean): TFDQuery;
var
  Qry: TFDQuery;
  SQL: string;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;

  SQL := 'SELECT PRE_ID, PRE_NOME, PRE_IP, PRE_PORTA, PRE_USAR_SSL, PRE_USUARIO, ' +
         'PRE_SENHA, PRE_MODELO, PRE_MODO_COLETA, PRE_ULTIMO_LOG_ID, PRE_STATUS, ' +
         'PRE_ATIVO, PRE_DEVICE_ID, PRE_SERIAL, PRE_VERSAO_FW, PRE_ULTIMA_COLETA ' +
         'FROM TB_PONTO_RELOGIO ';

  if AApenasAtivos then
    SQL := SQL + 'WHERE PRE_ATIVO = ''S'' AND PRE_STATUS = ''A'' ';

  SQL := SQL + 'ORDER BY PRE_NOME';

  Qry.SQL.Text := SQL;
  Qry.Open;
  Result := Qry;
end;

function TdmDados.GetRelogioPorId(AId: Integer): TFDQuery;
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;
  Qry.SQL.Text := 'SELECT * FROM TB_PONTO_RELOGIO WHERE PRE_ID = :ID';
  Qry.ParamByName('ID').AsInteger := AId;
  Qry.Open;
  Result := Qry;
end;

function TdmDados.SalvarRelogio(AId: Integer; const ANome, AIP: string; APorta: Integer;
  AUsarSSL: Boolean; const AUsuario, ASenha, AModelo, AModoColeta: string;
  AAtivo: Boolean): Integer;
var
  Qry: TFDQuery;
  AtivoStr, SSLStr: string;
begin
  Result := AId;
  if not IsConectado then
    Conectar;

  if AAtivo then
    AtivoStr := 'S'
  else
    AtivoStr := 'N';

  if AUsarSSL then
    SSLStr := 'S'
  else
    SSLStr := 'N';

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    if AId <= 0 then
    begin
      Qry.SQL.Text :=
        'INSERT INTO TB_PONTO_RELOGIO (PRE_NOME, PRE_IP, PRE_PORTA, PRE_USAR_SSL, ' +
        'PRE_USUARIO, PRE_SENHA, PRE_MODELO, PRE_MODO_COLETA, PRE_ATIVO, PRE_STATUS, PRE_ULTIMO_LOG_ID) ' +
        'VALUES (:NOME, :IP, :PORTA, :SSL, :USUARIO, :SENHA, :MODELO, :MODOCOLETA, :ATIVO, ''A'', 0) ' +
        'RETURNING PRE_ID';
      Qry.ParamByName('NOME').AsString := ANome;
      Qry.ParamByName('IP').AsString := AIP;
      Qry.ParamByName('PORTA').AsInteger := APorta;
      Qry.ParamByName('SSL').AsString := SSLStr;
      Qry.ParamByName('USUARIO').AsString := AUsuario;
      Qry.ParamByName('SENHA').AsString := ASenha;
      Qry.ParamByName('MODELO').AsString := AModelo;
      Qry.ParamByName('MODOCOLETA').AsString := AModoColeta;
      Qry.ParamByName('ATIVO').AsString := AtivoStr;
      Qry.Open;
      if not Qry.IsEmpty then
        Result := Qry.Fields[0].AsInteger;
    end
    else
    begin
      Qry.SQL.Text :=
        'UPDATE TB_PONTO_RELOGIO SET ' +
        'PRE_NOME = :NOME, PRE_IP = :IP, PRE_PORTA = :PORTA, PRE_USAR_SSL = :SSL, ' +
        'PRE_USUARIO = :USUARIO, PRE_SENHA = :SENHA, PRE_MODELO = :MODELO, ' +
        'PRE_MODO_COLETA = :MODOCOLETA, PRE_ATIVO = :ATIVO ' +
        'WHERE PRE_ID = :ID';
      Qry.ParamByName('NOME').AsString := ANome;
      Qry.ParamByName('IP').AsString := AIP;
      Qry.ParamByName('PORTA').AsInteger := APorta;
      Qry.ParamByName('SSL').AsString := SSLStr;
      Qry.ParamByName('USUARIO').AsString := AUsuario;
      Qry.ParamByName('SENHA').AsString := ASenha;
      Qry.ParamByName('MODELO').AsString := AModelo;
      Qry.ParamByName('MODOCOLETA').AsString := AModoColeta;
      Qry.ParamByName('ATIVO').AsString := AtivoStr;
      Qry.ParamByName('ID').AsInteger := AId;
      Qry.ExecSQL;
      Result := AId;
    end;
  finally
    Qry.Free;
  end;
end;

procedure TdmDados.ExcluirRelogio(AId: Integer);
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'DELETE FROM TB_PONTO_RELOGIO WHERE PRE_ID = :ID';
    Qry.ParamByName('ID').AsInteger := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

procedure TdmDados.AtualizarUltimoLogRelogio(ARelogioId: Integer; AUltimoLogId: Int64;
  const ASerial, AFWVersion: string);
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'UPDATE TB_PONTO_RELOGIO SET ' +
      'PRE_ULTIMO_LOG_ID = :LOGID, ' +
      'PRE_ULTIMA_COLETA = CURRENT_TIMESTAMP ' +
      'WHERE PRE_ID = :ID';
    Qry.ParamByName('LOGID').AsLargeInt := AUltimoLogId;
    Qry.ParamByName('ID').AsInteger := ARelogioId;
    Qry.ExecSQL;

    if (ASerial <> '') or (AFWVersion <> '') then
    begin
      Qry.SQL.Text :=
        'UPDATE TB_PONTO_RELOGIO SET ' +
        'PRE_SERIAL = COALESCE(NULLIF(:SERIAL, ''''), PRE_SERIAL), ' +
        'PRE_VERSAO_FW = COALESCE(NULLIF(:FW, ''''), PRE_VERSAO_FW) ' +
        'WHERE PRE_ID = :ID';
      Qry.ParamByName('SERIAL').AsString := ASerial;
      Qry.ParamByName('FW').AsString := AFWVersion;
      Qry.ParamByName('ID').AsInteger := ARelogioId;
      Qry.ExecSQL;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetColaboradores(const AApenasAtivos: Boolean): TFDQuery;
var
  Qry: TFDQuery;
  SQL: string;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;

  SQL := 'SELECT P.PES_ID, P.PES_RSOCIAL_NOME, P.PES_CNPJ_CPF, P.PES_STATUS, P.PES_CODIGO_ACESSO, ' +
         'C.COL_PIS, C.COL_CPF, C.COL_CARTAO_PONTO, C.COL_FUNCAO, C.COL_HORARIO, H.HOR_DESCRICAO, ' +
         'C.COL_SINCRONIZADO_RELOGIO, C.COL_ULTIMA_SINCRONIZACAO ' +
         'FROM TB_PESSOA P ' +
         'LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID ' +
         'LEFT JOIN TB_PONTO_HORARIO H ON H.HOR_ID = C.COL_HORARIO ' +
         'WHERE (P.PES_COLABORADOR = ''S'' OR C.COL_PESSOA IS NOT NULL) ';

  if AApenasAtivos then
    SQL := SQL + 'AND COALESCE(P.PES_STATUS, ''A'') = ''A'' ';

  SQL := SQL + 'ORDER BY P.PES_RSOCIAL_NOME';

  Qry.SQL.Text := SQL;
  Qry.Open;
  Result := Qry;
end;

function TdmDados.GetPessoaPorId(APessoaId: Integer): TFDQuery;
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;
  Qry.SQL.Text :=
    'SELECT P.PES_ID, P.PES_RSOCIAL_NOME, P.PES_CNPJ_CPF, P.PES_STATUS, P.PES_CODIGO_ACESSO, ' +
    'C.COL_PIS, C.COL_CPF, C.COL_CARTAO_PONTO, C.COL_FUNCAO, C.COL_HORARIO, H.HOR_DESCRICAO, ' +
    'C.COL_SINCRONIZADO_RELOGIO, C.COL_ULTIMA_SINCRONIZACAO ' +
    'FROM TB_PESSOA P ' +
    'LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID ' +
    'LEFT JOIN TB_PONTO_HORARIO H ON H.HOR_ID = C.COL_HORARIO ' +
    'WHERE P.PES_ID = :ID';
  Qry.ParamByName('ID').AsInteger := APessoaId;
  Qry.Open;
  Result := Qry;
end;

function TdmDados.SalvarColaborador(var APessoaId: Integer; const ANome, ACpf, APis, AMatricula,
  AFuncao, ACodigoAcesso: string; AAtivo: Boolean; AHorarioId: Integer): Boolean;
var
  Qry: TFDQuery;
  CleanCpf, CleanPis, StatusStr: string;
begin
  Result := False;
  if not IsConectado then
    Conectar;

  CleanCpf := Trim(StringReplace(StringReplace(StringReplace(ACpf, '.', '', [rfReplaceAll]), '-', '', [rfReplaceAll]), '/', '', [rfReplaceAll]));
  CleanPis := Trim(StringReplace(StringReplace(APis, '.', '', [rfReplaceAll]), '-', '', [rfReplaceAll]));

  if AAtivo then
    StatusStr := 'A'
  else
    StatusStr := 'I';

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;

    if APessoaId <= 0 then
    begin
      // 1. Inserir em TB_PESSOA
      Qry.SQL.Text :=
        'INSERT INTO TB_PESSOA (PES_RSOCIAL_NOME, PES_CNPJ_CPF, PES_STATUS, PES_COLABORADOR, ' +
        'PES_CODIGO_ACESSO, PES_DT_CADASTRO) ' +
        'VALUES (:NOME, :CPF, :STATUS, ''S'', :CODIGO, CURRENT_TIMESTAMP) ' +
        'RETURNING PES_ID';
      Qry.ParamByName('NOME').AsString := Trim(ANome);
      Qry.ParamByName('CPF').AsString := CleanCpf;
      Qry.ParamByName('STATUS').AsString := StatusStr;
      Qry.ParamByName('CODIGO').AsString := Trim(ACodigoAcesso);
      Qry.Open;
      if not Qry.IsEmpty then
        APessoaId := Qry.Fields[0].AsInteger
      else
        Exit;
      Qry.Close;

      // 2. Inserir em TB_COLABORADOR
      Qry.SQL.Text :=
        'INSERT INTO TB_COLABORADOR (COL_PESSOA, COL_EMPRESA, COL_CPF, COL_PIS, ' +
        'COL_CARTAO_PONTO, COL_FUNCAO, COL_STATUS, COL_HORARIO, COL_SINCRONIZADO_RELOGIO, COL_DT_CADASTRO) ' +
        'VALUES (:PESSOA, 1, :CPF, :PIS, :CARTAO, :FUNCAO, :STATUS, :HORARIO, ''N'', CURRENT_TIMESTAMP)';
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.ParamByName('CPF').AsString := CleanCpf;
      Qry.ParamByName('PIS').AsString := CleanPis;
      Qry.ParamByName('CARTAO').AsString := Trim(AMatricula);
      Qry.ParamByName('FUNCAO').AsString := Trim(AFuncao);
      Qry.ParamByName('STATUS').AsString := StatusStr;
      if AHorarioId > 0 then
        Qry.ParamByName('HORARIO').AsInteger := AHorarioId
      else
        Qry.ParamByName('HORARIO').Clear;
      Qry.ExecSQL;
      Result := True;
    end
    else
    begin
      // 1. Atualizar TB_PESSOA
      Qry.SQL.Text :=
        'UPDATE TB_PESSOA SET ' +
        'PES_RSOCIAL_NOME = :NOME, ' +
        'PES_CNPJ_CPF = :CPF, ' +
        'PES_STATUS = :STATUS, ' +
        'PES_COLABORADOR = ''S'', ' +
        'PES_CODIGO_ACESSO = :CODIGO ' +
        'WHERE PES_ID = :ID';
      Qry.ParamByName('NOME').AsString := Trim(ANome);
      Qry.ParamByName('CPF').AsString := CleanCpf;
      Qry.ParamByName('STATUS').AsString := StatusStr;
      Qry.ParamByName('CODIGO').AsString := Trim(ACodigoAcesso);
      Qry.ParamByName('ID').AsInteger := APessoaId;
      Qry.ExecSQL;

      // 2. Atualizar ou inserir TB_COLABORADOR
      Qry.SQL.Text :=
        'UPDATE TB_COLABORADOR SET ' +
        'COL_CPF = :CPF, ' +
        'COL_PIS = :PIS, ' +
        'COL_CARTAO_PONTO = :CARTAO, ' +
        'COL_FUNCAO = :FUNCAO, ' +
        'COL_STATUS = :STATUS, ' +
        'COL_HORARIO = :HORARIO, ' +
        'COL_SINCRONIZADO_RELOGIO = ''N'' ' +
        'WHERE COL_PESSOA = :PESSOA';
      Qry.ParamByName('CPF').AsString := CleanCpf;
      Qry.ParamByName('PIS').AsString := CleanPis;
      Qry.ParamByName('CARTAO').AsString := Trim(AMatricula);
      Qry.ParamByName('FUNCAO').AsString := Trim(AFuncao);
      Qry.ParamByName('STATUS').AsString := StatusStr;
      if AHorarioId > 0 then
        Qry.ParamByName('HORARIO').AsInteger := AHorarioId
      else
        Qry.ParamByName('HORARIO').Clear;
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.ExecSQL;

      if Qry.RowsAffected = 0 then
      begin
        Qry.SQL.Text :=
          'INSERT INTO TB_COLABORADOR (COL_PESSOA, COL_EMPRESA, COL_CPF, COL_PIS, ' +
          'COL_CARTAO_PONTO, COL_FUNCAO, COL_STATUS, COL_HORARIO, COL_SINCRONIZADO_RELOGIO, COL_DT_CADASTRO) ' +
          'VALUES (:PESSOA, 1, :CPF, :PIS, :CARTAO, :FUNCAO, :STATUS, :HORARIO, ''N'', CURRENT_TIMESTAMP)';
        Qry.ParamByName('PESSOA').AsInteger := APessoaId;
        Qry.ParamByName('CPF').AsString := CleanCpf;
        Qry.ParamByName('PIS').AsString := CleanPis;
        Qry.ParamByName('CARTAO').AsString := Trim(AMatricula);
        Qry.ParamByName('FUNCAO').AsString := Trim(AFuncao);
        Qry.ParamByName('STATUS').AsString := StatusStr;
        if AHorarioId > 0 then
          Qry.ParamByName('HORARIO').AsInteger := AHorarioId
        else
          Qry.ParamByName('HORARIO').Clear;
        Qry.ExecSQL;
      end;
      Result := True;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.BuscarPessoaPorPisOuCpf(const APis, ACpf: string): Integer;
var
  Qry: TFDQuery;
  CleanPis, CleanCpf: string;
begin
  Result := 0;
  CleanPis := Trim(StringReplace(StringReplace(APis, '.', '', [rfReplaceAll]), '-', '', [rfReplaceAll]));
  CleanCpf := Trim(StringReplace(StringReplace(StringReplace(ACpf, '.', '', [rfReplaceAll]), '-', '', [rfReplaceAll]), '/', '', [rfReplaceAll]));

  if (CleanPis = '') and (CleanCpf = '') then
    Exit;

  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT FIRST 1 P.PES_ID FROM TB_PESSOA P ' +
      'LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID ' +
      'WHERE (:PIS <> '''' AND (C.COL_PIS = :PIS OR C.COL_PIS CONTAINING :PIS)) ' +
      '   OR (:CPF <> '''' AND (P.PES_CNPJ_CPF = :CPF OR C.COL_CPF = :CPF OR C.COL_PIS = :CPF))';
    Qry.ParamByName('PIS').AsString := CleanPis;
    Qry.ParamByName('CPF').AsString := CleanCpf;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('PES_ID').AsInteger;
  finally
    Qry.Free;
  end;
end;

procedure TdmDados.MarcarColaboradorSincronizado(APessoaId: Integer);
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    // Garante que existe registro em TB_COLABORADOR
    Qry.SQL.Text :=
      'UPDATE TB_COLABORADOR SET ' +
      'COL_SINCRONIZADO_RELOGIO = ''S'', ' +
      'COL_ULTIMA_SINCRONIZACAO = CURRENT_TIMESTAMP ' +
      'WHERE COL_PESSOA = :PESSOA';
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.ExecSQL;

    if Qry.RowsAffected = 0 then
    begin
      Qry.SQL.Text :=
        'INSERT INTO TB_COLABORADOR (COL_PESSOA, COL_EMPRESA, COL_STATUS, ' +
        'COL_SINCRONIZADO_RELOGIO, COL_ULTIMA_SINCRONIZACAO) ' +
        'VALUES (:PESSOA, 1, ''A'', ''S'', CURRENT_TIMESTAMP)';
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.ExecSQL;
    end;
  finally
    Qry.Free;
  end;
end;

procedure TdmDados.MarcarColaboradorNaoSincronizado(APessoaId: Integer);
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'UPDATE TB_COLABORADOR SET ' +
      'COL_SINCRONIZADO_RELOGIO = ''N'' ' +
      'WHERE COL_PESSOA = :PESSOA';
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

function TdmDados.ExcluirColaborador(APessoaId: Integer; out AErro: string; out AInativado: Boolean): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  AErro := '';
  AInativado := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    // 1. Tenta exclusão física direta
    try
      Qry.SQL.Text := 'DELETE FROM TB_COLABORADOR WHERE COL_PESSOA = :ID';
      Qry.ParamByName('ID').AsInteger := APessoaId;
      Qry.ExecSQL;

      Qry.SQL.Text := 'DELETE FROM TB_PESSOA WHERE PES_ID = :ID';
      Qry.ParamByName('ID').AsInteger := APessoaId;
      Qry.ExecSQL;

      Result := True;
    except
      on E: Exception do
      begin
        // Se houver amarração com marcações de ponto ou outras tabelas, inativa para manter integridade
        try
          Qry.SQL.Text := 'UPDATE TB_COLABORADOR SET COL_STATUS = ''I'' WHERE COL_PESSOA = :ID';
          Qry.ParamByName('ID').AsInteger := APessoaId;
          Qry.ExecSQL;

          Qry.SQL.Text := 'UPDATE TB_PESSOA SET PES_STATUS = ''I'' WHERE PES_ID = :ID';
          Qry.ParamByName('ID').AsInteger := APessoaId;
          Qry.ExecSQL;

          AInativado := True;
          Result := True;
        except
          on E2: Exception do
          begin
            AErro := E2.Message;
            Result := False;
          end;
        end;
      end;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetEmpresaPrincipal(out ARazao, ACnpj, AEndereco, ACei, ACpfResp: string): Boolean;
var
  Qry: TFDQuery;
  EndCompleto, Num, Bairro: string;
begin
  Result := False;
  ARazao := '';
  ACnpj := '';
  AEndereco := '';
  ACei := '';
  ACpfResp := '';

  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'SELECT FIRST 1 EMP_RAZAO_SOCIAL, EMP_CNPJ, EMP_ENDERECO, EMP_NUMERO, EMP_BAIRRO FROM TB_EMPRESA WHERE EMP_STATUS = ''A'' OR EMP_STATUS IS NULL';
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      ARazao := Trim(Qry.FieldByName('EMP_RAZAO_SOCIAL').AsString);
      ACnpj := Trim(Qry.FieldByName('EMP_CNPJ').AsString);
      EndCompleto := Trim(Qry.FieldByName('EMP_ENDERECO').AsString);
      Num := Trim(Qry.FieldByName('EMP_NUMERO').AsString);
      Bairro := Trim(Qry.FieldByName('EMP_BAIRRO').AsString);

      if Num <> '' then
        EndCompleto := EndCompleto + ', ' + Num;
      if Bairro <> '' then
        EndCompleto := EndCompleto + ' - ' + Bairro;

      AEndereco := EndCompleto;
      Result := True;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.SalvarEmpresaPrincipal(const ARazao, ACnpj, AEndereco: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'UPDATE TB_EMPRESA SET ' +
      'EMP_RAZAO_SOCIAL = :RAZAO, ' +
      'EMP_CNPJ = :CNPJ, ' +
      'EMP_ENDERECO = :ENDERECO ' +
      'WHERE EMP_ID = (SELECT FIRST 1 EMP_ID FROM TB_EMPRESA)';
    Qry.ParamByName('RAZAO').AsString := ARazao;
    Qry.ParamByName('CNPJ').AsString := ACnpj;
    Qry.ParamByName('ENDERECO').AsString := AEndereco;
    Qry.ExecSQL;
    Result := (Qry.RowsAffected > 0);
  finally
    Qry.Free;
  end;
end;

function TdmDados.GravarMarcacao(APessoaId, ARelogioId: Integer; ADataHora: TDateTime;
  AEvento: Integer; AControlIdLogId: Int64; const AOrigem: string;
  ANsr: Int64; const APis, ACpf, ATipoBatida, ATipoIdent: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;

    // Verificar se já existe a marcação para este relógio e ID de Log
    Qry.SQL.Text :=
      'SELECT PMA_ID FROM TB_PONTO_MARCACAO ' +
      'WHERE PMA_RELOGIO = :RELOGIO AND PMA_CONTROLID_LOG_ID = :LOGID';
    Qry.ParamByName('RELOGIO').AsInteger := ARelogioId;
    Qry.ParamByName('LOGID').AsLargeInt := AControlIdLogId;
    Qry.Open;

    if not Qry.IsEmpty then
    begin
      // Já gravado anteriormente
      Result := True;
      Exit;
    end;

    Qry.Close;
    Qry.SQL.Text :=
      'INSERT INTO TB_PONTO_MARCACAO (PMA_PESSOA, PMA_RELOGIO, PMA_DATA_HORA, ' +
      'PMA_EVENTO, PMA_CONTROLID_LOG_ID, PMA_ORIGEM, PMA_NSR, PMA_PIS, PMA_CPF, ' +
      'PMA_TIPO_BATIDA, PMA_TIPO_IDENTIFICACAO, PMA_EXPORTADO) ' +
      'VALUES (:PESSOA, :RELOGIO, :DATAHORA, :EVENTO, :LOGID, :ORIGEM, :NSR, ' +
      ':PIS, :CPF, :TIPOBATIDA, :TIPOIDENT, ''N'')';

    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.ParamByName('RELOGIO').AsInteger := ARelogioId;
    Qry.ParamByName('DATAHORA').AsDateTime := ADataHora;
    Qry.ParamByName('EVENTO').AsInteger := AEvento;
    Qry.ParamByName('LOGID').AsLargeInt := AControlIdLogId;
    Qry.ParamByName('ORIGEM').AsString := Copy(AOrigem, 1, 1);
    Qry.ParamByName('NSR').AsLargeInt := ANsr;
    Qry.ParamByName('PIS').AsString := APis;
    Qry.ParamByName('CPF').AsString := ACpf;
    Qry.ParamByName('TIPOBATIDA').AsString := ATipoBatida;
    Qry.ParamByName('TIPOIDENT').AsString := ATipoIdent;
    Qry.ExecSQL;

    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Erro ao gravar marcação: ' + E.Message;
      Result := False;
    end;
  end;
  Qry.Free;
end;

function TdmDados.GetMarcacoes(ADataIni, ADataFim: TDateTime; ARelogioId, APessoaId: Integer): TFDQuery;
var
  Qry: TFDQuery;
  SQL: string;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;

  SQL := 'SELECT M.PMA_ID, M.PMA_DATA_HORA, M.PMA_EVENTO, M.PMA_CONTROLID_LOG_ID, ' +
         'M.PMA_NSR, M.PMA_PIS, M.PMA_CPF, M.PMA_TIPO_BATIDA, M.PMA_TIPO_IDENTIFICACAO, ' +
         'M.PMA_ORIGEM, M.PMA_EXPORTADO, ' +
         'R.PRE_NOME AS RELOGIO_NOME, ' +
         'COALESCE(P.PES_RSOCIAL_NOME, ''NÃO IDENTIFICADO'') AS PESSOA_NOME ' +
         'FROM TB_PONTO_MARCACAO M ' +
         'LEFT JOIN TB_PONTO_RELOGIO R ON R.PRE_ID = M.PMA_RELOGIO ' +
         'LEFT JOIN TB_PESSOA P ON P.PES_ID = M.PMA_PESSOA ' +
         'WHERE M.PMA_DATA_HORA BETWEEN :DTINI AND :DTFIM ';

  if ARelogioId > 0 then
    SQL := SQL + 'AND M.PMA_RELOGIO = :RELOGIO ';

  if APessoaId > 0 then
    SQL := SQL + 'AND M.PMA_PESSOA = :PESSOA ';

  SQL := SQL + 'ORDER BY M.PMA_DATA_HORA DESC, M.PMA_ID DESC';

  Qry.SQL.Text := SQL;
  Qry.ParamByName('DTINI').AsDateTime := StartOfTheDay(ADataIni);
  Qry.ParamByName('DTFIM').AsDateTime := EndOfTheDay(ADataFim);

  if ARelogioId > 0 then
    Qry.ParamByName('RELOGIO').AsInteger := ARelogioId;

  if APessoaId > 0 then
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;

  Qry.Open;
  Result := Qry;
end;

function TdmDados.ExcluirMarcacao(AMarcacaoId: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'DELETE FROM TB_PONTO_MARCACAO WHERE PMA_ID = :ID';
    Qry.ParamByName('ID').AsInteger := AMarcacaoId;
    Qry.ExecSQL;
    Result := (Qry.RowsAffected > 0);
  finally
    Qry.Free;
  end;
end;

function TdmDados.AtualizarMarcacao(AId: Integer; ADataHora: TDateTime; const ATipoBatida: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'UPDATE TB_PONTO_MARCACAO SET ' +
      '  PMA_DATA_HORA = :DH, ' +
      '  PMA_TIPO_BATIDA = :TIPO, ' +
      '  PMA_ORIGEM = ''M'' ' +
      'WHERE PMA_ID = :ID';
    Qry.ParamByName('DH').AsDateTime := ADataHora;
    Qry.ParamByName('TIPO').AsString := UpperCase(Trim(ATipoBatida));
    Qry.ParamByName('ID').AsInteger := AId;
    Qry.ExecSQL;
    Result := (Qry.RowsAffected > 0);
  finally
    Qry.Free;
  end;
end;

function TdmDados.InserirMarcacaoManual(APessoaId, ARelogioId: Integer; ADataHora: TDateTime;
  const ATipoBatida: string): Integer;
var
  Qry: TFDQuery;
begin
  Result := 0;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'INSERT INTO TB_PONTO_MARCACAO (' +
      '  PMA_PESSOA, PMA_RELOGIO, PMA_DATA_HORA, PMA_TIPO_BATIDA, PMA_ORIGEM, PMA_EVENTO, PMA_EXPORTADO' +
      ') VALUES (' +
      '  :PESSOA, :RELOGIO, :DH, :TIPO, ''M'', 7, ''N''' +
      ') RETURNING PMA_ID';
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    if ARelogioId > 0 then
      Qry.ParamByName('RELOGIO').AsInteger := ARelogioId
    else
      Qry.ParamByName('RELOGIO').Clear;
    Qry.ParamByName('DH').AsDateTime := ADataHora;
    Qry.ParamByName('TIPO').AsString := UpperCase(Trim(ATipoBatida));
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.Fields[0].AsInteger;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetTotalMarcacoesHoje(out ATotal: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  ATotal := 0;
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL FROM TB_PONTO_MARCACAO ' +
      'WHERE PMA_DATA_HORA >= :HOJE';
    Qry.ParamByName('HOJE').AsDateTime := StartOfTheDay(Date);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      ATotal := Qry.FieldByName('TOTAL').AsInteger;
      Result := True;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetTotalColaboradores(out ATotal: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  ATotal := 0;
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL FROM TB_PESSOA P ' +
      'LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID ' +
      'WHERE P.PES_COLABORADOR = ''S'' OR C.COL_PESSOA IS NOT NULL';
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      ATotal := Qry.FieldByName('TOTAL').AsInteger;
      Result := True;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetTotalRelogiosAtivos(out ATotal: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  ATotal := 0;
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL FROM TB_PONTO_RELOGIO ' +
      'WHERE PRE_ATIVO = ''S'' AND PRE_STATUS = ''A''';
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      ATotal := Qry.FieldByName('TOTAL').AsInteger;
      Result := True;
    end;
  finally
    Qry.Free;
  end;
end;

// =============================================================================
// HORÁRIOS / JORNADAS DE TRABALHO
// =============================================================================

function TdmDados.GetHorarios(const AApenasAtivos: Boolean): TFDQuery;
var
  Qry: TFDQuery;
  SQL: string;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;
  SQL := 'SELECT HOR_ID, HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, HOR_SAIDA_2, ' +
         'HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, ' +
         'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_ATIVO ' +
         'FROM TB_PONTO_HORARIO ';
  if AApenasAtivos then
    SQL := SQL + 'WHERE COALESCE(HOR_ATIVO, ''S'') = ''S'' ';
  SQL := SQL + 'ORDER BY HOR_DESCRICAO';

  Qry.SQL.Text := SQL;
  Qry.Open;
  Result := Qry;
end;

function TdmDados.GetHorarioPorId(AId: Integer): TFDQuery;
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;
  Qry.SQL.Text :=
    'SELECT HOR_ID, HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, HOR_SAIDA_2, ' +
    'HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, ' +
    'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_ATIVO ' +
    'FROM TB_PONTO_HORARIO WHERE HOR_ID = :ID';
  Qry.ParamByName('ID').AsInteger := AId;
  Qry.Open;
  Result := Qry;
end;

function TdmDados.SalvarHorario(AId: Integer; const ADescricao, AEnt1, ASai1, AEnt2, ASai2: string;
  AToleranciaMin, ACargaDiariaMin: Integer; ACompensaSab, ATrabalhaSab: Boolean;
  const ASabEnt1, ASabSai1: string; AAtivo: Boolean): Integer;
var
  Qry: TFDQuery;
  AtivoStr, CompSabStr, TrabSabStr: string;
begin
  Result := AId;
  if not IsConectado then
    Conectar;

  if AAtivo then AtivoStr := 'S' else AtivoStr := 'N';
  if ACompensaSab then CompSabStr := 'S' else CompSabStr := 'N';
  if ATrabalhaSab then TrabSabStr := 'S' else TrabSabStr := 'N';

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;

    // Helper interno para validar e vincular horas TIME de forma segura (sem conversion error de string vazia)
    var BindTime := procedure(const AParamName, AVal: string)
    var
      V: string;
    begin
      V := Trim(AVal);
      if V = '' then
        Qry.ParamByName(AParamName).Clear
      else
      begin
        if Length(V) = 5 then
          V := V + ':00';
        Qry.ParamByName(AParamName).AsString := V;
      end;
    end;

    if AId <= 0 then
    begin
      Qry.SQL.Text :=
        'INSERT INTO TB_PONTO_HORARIO (HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, HOR_SAIDA_2, ' +
        'HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, ' +
        'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_ATIVO) ' +
        'VALUES (:DESC, :E1, :S1, :E2, :S2, :TOL, :CARGA, :CSAB, :TSAB, :SE1, :SS1, :ATIVO) ' +
        'RETURNING HOR_ID';
      Qry.ParamByName('DESC').AsString := Trim(ADescricao);
      BindTime('E1', AEnt1);
      BindTime('S1', ASai1);
      BindTime('E2', AEnt2);
      BindTime('S2', ASai2);
      Qry.ParamByName('TOL').AsInteger := AToleranciaMin;
      Qry.ParamByName('CARGA').AsInteger := ACargaDiariaMin;
      Qry.ParamByName('CSAB').AsString := CompSabStr;
      Qry.ParamByName('TSAB').AsString := TrabSabStr;
      BindTime('SE1', ASabEnt1);
      BindTime('SS1', ASabSai1);
      Qry.ParamByName('ATIVO').AsString := AtivoStr;
      Qry.Open;
      if not Qry.IsEmpty then
        Result := Qry.Fields[0].AsInteger;
    end
    else
    begin
      Qry.SQL.Text :=
        'UPDATE TB_PONTO_HORARIO SET ' +
        'HOR_DESCRICAO = :DESC, HOR_ENTRADA_1 = :E1, HOR_SAIDA_1 = :S1, ' +
        'HOR_ENTRADA_2 = :E2, HOR_SAIDA_2 = :S2, HOR_TOLERANCIA_MIN = :TOL, ' +
        'HOR_CARGA_DIARIA_MIN = :CARGA, HOR_COMPENSA_SABADO = :CSAB, ' +
        'HOR_TRABALHA_SABADO = :TSAB, HOR_SAB_ENTRADA_1 = :SE1, ' +
        'HOR_SAB_SAIDA_1 = :SS1, HOR_ATIVO = :ATIVO ' +
        'WHERE HOR_ID = :ID';
      Qry.ParamByName('DESC').AsString := Trim(ADescricao);
      BindTime('E1', AEnt1);
      BindTime('S1', ASai1);
      BindTime('E2', AEnt2);
      BindTime('S2', ASai2);
      Qry.ParamByName('TOL').AsInteger := AToleranciaMin;
      Qry.ParamByName('CARGA').AsInteger := ACargaDiariaMin;
      Qry.ParamByName('CSAB').AsString := CompSabStr;
      Qry.ParamByName('TSAB').AsString := TrabSabStr;
      BindTime('SE1', ASabEnt1);
      BindTime('SS1', ASabSai1);
      Qry.ParamByName('ATIVO').AsString := AtivoStr;
      Qry.ParamByName('ID').AsInteger := AId;
      Qry.ExecSQL;
      Result := AId;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.ExcluirHorario(AId: Integer; out AErro: string): Boolean;
var
  Qry: TFDQuery;
begin
  AErro := '';
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    // Verificar se há colaboradores usando
    Qry.SQL.Text := 'SELECT COUNT(*) AS QTD FROM TB_COLABORADOR WHERE COL_HORARIO = :ID';
    Qry.ParamByName('ID').AsInteger := AId;
    Qry.Open;
    if (not Qry.IsEmpty) and (Qry.FieldByName('QTD').AsInteger > 0) then
    begin
      // Apenas inativa
      Qry.Close;
      Qry.SQL.Text := 'UPDATE TB_PONTO_HORARIO SET HOR_ATIVO = ''N'' WHERE HOR_ID = :ID';
      Qry.ParamByName('ID').AsInteger := AId;
      Qry.ExecSQL;
      AErro := 'O horário possui colaboradores vinculados e foi inativado para preservar o histórico.';
      Result := True;
      Exit;
    end;

    Qry.Close;
    Qry.SQL.Text := 'DELETE FROM TB_PONTO_HORARIO WHERE HOR_ID = :ID';
    Qry.ParamByName('ID').AsInteger := AId;
    Qry.ExecSQL;
    Result := True;
  except
    on E: Exception do
    begin
      AErro := 'Erro ao excluir horário: ' + E.Message;
      Result := False;
    end;
  end;
  Qry.Free;
end;

// =============================================================================
// JUSTIFICATIVAS / OCORRÊNCIAS (PORTARIA 671)
// =============================================================================

function TdmDados.SalvarJustificativa(APessoaId: Integer; AData: TDateTime; const ATipo, AMotivo: string;
  AAbonoMin: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    // Remove qualquer justificativa anterior da mesma pessoa no mesmo dia
    Qry.SQL.Text := 'DELETE FROM TB_PONTO_JUSTIFICATIVA WHERE JUS_PESSOA = :PESSOA AND JUS_DATA = :DATA';
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.ParamByName('DATA').AsDate := Trunc(AData);
    Qry.ExecSQL;

    Qry.SQL.Text :=
      'INSERT INTO TB_PONTO_JUSTIFICATIVA (JUS_PESSOA, JUS_DATA, JUS_TIPO, JUS_MOTIVO, JUS_ABONO_MINUTOS) ' +
      'VALUES (:PESSOA, :DATA, :TIPO, :MOTIVO, :ABONO)';
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.ParamByName('DATA').AsDate := Trunc(AData);
    Qry.ParamByName('TIPO').AsString := Trim(ATipo);
    Qry.ParamByName('MOTIVO').AsString := Trim(AMotivo);
    Qry.ParamByName('ABONO').AsInteger := AAbonoMin;
    Qry.ExecSQL;
    Result := True;
  finally
    Qry.Free;
  end;
end;

function TdmDados.ExcluirJustificativa(AJusId: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'DELETE FROM TB_PONTO_JUSTIFICATIVA WHERE JUS_ID = :ID';
    Qry.ParamByName('ID').AsInteger := AJusId;
    Qry.ExecSQL;
    Result := True;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetJustificativasPeriodo(APessoaId: Integer; ADataIni, ADataFim: TDateTime): TFDQuery;
var
  Qry: TFDQuery;
begin
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  Qry.Connection := FDConnection;
  Qry.SQL.Text :=
    'SELECT JUS_ID, JUS_PESSOA, JUS_DATA, JUS_TIPO, JUS_MOTIVO, JUS_ABONO_MINUTOS, JUS_CRIADO_EM ' +
    'FROM TB_PONTO_JUSTIFICATIVA ' +
    'WHERE JUS_PESSOA = :PESSOA AND JUS_DATA >= :INI AND JUS_DATA <= :FIM ' +
    'ORDER BY JUS_DATA';
  Qry.ParamByName('PESSOA').AsInteger := APessoaId;
  Qry.ParamByName('INI').AsDate := Trunc(ADataIni);
  Qry.ParamByName('FIM').AsDate := Trunc(ADataFim);
  Qry.Open;
  Result := Qry;
end;

const
  DB_SCHEMA_VERSION = 3;

function TdmDados.TabelaExiste(const ANomeTabela: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'SELECT 1 FROM RDB$RELATIONS WHERE UPPER(TRIM(RDB$RELATION_NAME)) = UPPER(TRIM(:TAB))';
    Qry.ParamByName('TAB').AsString := ANomeTabela;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

function TdmDados.CampoExiste(const ANomeTabela, ANomeCampo: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'SELECT 1 FROM RDB$RELATION_FIELDS WHERE UPPER(TRIM(RDB$RELATION_NAME)) = UPPER(TRIM(:TAB)) ' +
                    'AND UPPER(TRIM(RDB$FIELD_NAME)) = UPPER(TRIM(:COL))';
    Qry.ParamByName('TAB').AsString := ANomeTabela;
    Qry.ParamByName('COL').AsString := ANomeCampo;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GeneratorExiste(const ANomeGen: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'SELECT 1 FROM RDB$GENERATORS WHERE UPPER(TRIM(RDB$GENERATOR_NAME)) = UPPER(TRIM(:GEN))';
    Qry.ParamByName('GEN').AsString := ANomeGen;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

function TdmDados.ExecutarComandoDDL(const ASQL: string): Boolean;
begin
  Result := False;
  try
    FDConnection.ExecSQL(ASQL);
    Result := True;
  except
    on E: Exception do
      FLastError := E.Message;
  end;
end;

function TdmDados.ObterVersaoBanco: Integer;
var
  Qry: TFDQuery;
begin
  Result := 0;
  if not TabelaExiste('TB_PONTO_VERSAO_BD') then
    Exit;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'SELECT COALESCE(MAX(VER_NUMERO), 0) AS ATUAL FROM TB_PONTO_VERSAO_BD';
    Qry.Open;
    Result := Qry.FieldByName('ATUAL').AsInteger;
  finally
    Qry.Free;
  end;
end;

function TdmDados.VerificarEAtualizarEstruturaBanco(out ALogMigracao: string): Boolean;
var
  VersaoAtual: Integer;
  Alterou: Boolean;
  Qry: TFDQuery;
begin
  Result := True;
  ALogMigracao := '';
  Alterou := False;

  // 1. Garantir existência da tabela de controle de versão
  if not TabelaExiste('TB_PONTO_VERSAO_BD') then
  begin
    ExecutarComandoDDL(
      'CREATE TABLE TB_PONTO_VERSAO_BD (' +
      '  VER_ID INTEGER NOT NULL PRIMARY KEY, ' +
      '  VER_NUMERO INTEGER NOT NULL, ' +
      '  VER_SISTEMA VARCHAR(20), ' +
      '  VER_DATA_HORA TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
      '  VER_DESCRICAO VARCHAR(250)' +
      ')');
    Alterou := True;
  end;

  if not GeneratorExiste('GEN_PONTO_VERSAO_BD') then
    ExecutarComandoDDL('CREATE GENERATOR GEN_PONTO_VERSAO_BD');

  VersaoAtual := ObterVersaoBanco;

  // 2. TB_PONTO_RELOGIO e campos
  if not TabelaExiste('TB_PONTO_RELOGIO') then
  begin
    ExecutarComandoDDL(
      'CREATE TABLE TB_PONTO_RELOGIO (' +
      '  PRE_ID INTEGER NOT NULL PRIMARY KEY, ' +
      '  PRE_NOME VARCHAR(60) NOT NULL, ' +
      '  PRE_IP VARCHAR(45) NOT NULL, ' +
      '  PRE_PORTA INTEGER DEFAULT 80, ' +
      '  PRE_USAR_SSL CHAR(1) DEFAULT ''N'', ' +
      '  PRE_USUARIO VARCHAR(40), ' +
      '  PRE_SENHA VARCHAR(40), ' +
      '  PRE_MODELO VARCHAR(40) DEFAULT ''IDCLASS'', ' +
      '  PRE_MODO_COLETA VARCHAR(20) DEFAULT ''API'', ' +
      '  PRE_ULTIMO_LOG_ID BIGINT DEFAULT 0, ' +
      '  PRE_STATUS CHAR(1) DEFAULT ''A'', ' +
      '  PRE_ATIVO CHAR(1) DEFAULT ''S'', ' +
      '  PRE_DEVICE_ID VARCHAR(50), ' +
      '  PRE_SERIAL VARCHAR(50), ' +
      '  PRE_VERSAO_FW VARCHAR(50), ' +
      '  PRE_ULTIMA_COLETA TIMESTAMP, ' +
      '  PRE_DATA_HORA_SYNC TIMESTAMP' +
      ')');
    Alterou := True;
  end
  else
  begin
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_PORTA') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_PORTA INTEGER DEFAULT 80');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_USAR_SSL') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_USAR_SSL CHAR(1) DEFAULT ''N''');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_MODELO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_MODELO VARCHAR(40) DEFAULT ''IDCLASS''');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_MODO_COLETA') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_MODO_COLETA VARCHAR(20) DEFAULT ''API''');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_ULTIMA_COLETA') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_ULTIMA_COLETA TIMESTAMP');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_SERIAL') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_SERIAL VARCHAR(50)');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_VERSAO_FW') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_VERSAO_FW VARCHAR(50)');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_ATIVO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_ATIVO CHAR(1) DEFAULT ''S''');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_DATA_HORA_SYNC') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_DATA_HORA_SYNC TIMESTAMP');
  end;

  if not GeneratorExiste('GEN_PONTO_RELOGIO') then
    ExecutarComandoDDL('CREATE GENERATOR GEN_PONTO_RELOGIO');

  // 3. TB_PONTO_MARCACAO e campos
  if not TabelaExiste('TB_PONTO_MARCACAO') then
  begin
    ExecutarComandoDDL(
      'CREATE TABLE TB_PONTO_MARCACAO (' +
      '  PMA_ID BIGINT NOT NULL PRIMARY KEY, ' +
      '  PMA_RELOGIO INTEGER, ' +
      '  PMA_PESSOA INTEGER, ' +
      '  PMA_NSR BIGINT, ' +
      '  PMA_DATA_HORA TIMESTAMP NOT NULL, ' +
      '  PMA_TIPO_BATIDA VARCHAR(20), ' +
      '  PMA_TIPO_IDENTIFICACAO VARCHAR(30), ' +
      '  PMA_CPF VARCHAR(14), ' +
      '  PMA_PIS VARCHAR(15), ' +
      '  PMA_ORIGEM CHAR(1) DEFAULT ''C'', ' +
      '  PMA_EXPORTADO CHAR(1) DEFAULT ''N'', ' +
      '  PMA_EVENTO INTEGER DEFAULT 7, ' +
      '  PMA_MOTIVO_AJUSTE VARCHAR(250)' +
      ')');
    Alterou := True;
  end
  else
  begin
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_NSR') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_NSR BIGINT');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_PIS') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_PIS VARCHAR(15)');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_CPF') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_CPF VARCHAR(14)');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_TIPO_BATIDA') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_TIPO_BATIDA VARCHAR(20)');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_TIPO_IDENTIFICACAO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_TIPO_IDENTIFICACAO VARCHAR(30)');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_ORIGEM') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_ORIGEM CHAR(1) DEFAULT ''C''');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_EXPORTADO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_EXPORTADO CHAR(1) DEFAULT ''N''');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_EVENTO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_EVENTO INTEGER DEFAULT 7');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_MOTIVO_AJUSTE') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_MOTIVO_AJUSTE VARCHAR(250)');
  end;

  if not GeneratorExiste('GEN_PONTO_MARCACAO') then
    ExecutarComandoDDL('CREATE GENERATOR GEN_PONTO_MARCACAO');

  // Índices para otimização de consultas de ponto
  ExecutarComandoDDL('CREATE INDEX IDX_PMA_DATA_HORA ON TB_PONTO_MARCACAO (PMA_DATA_HORA)');
  ExecutarComandoDDL('CREATE INDEX IDX_PMA_PESSOA ON TB_PONTO_MARCACAO (PMA_PESSOA)');

  // 4. TB_COLABORADOR e campos complementares
  if TabelaExiste('TB_COLABORADOR') then
  begin
    if not CampoExiste('TB_COLABORADOR', 'COL_SINCRONIZADO_RELOGIO') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_SINCRONIZADO_RELOGIO CHAR(1) DEFAULT ''N''');
    if not CampoExiste('TB_COLABORADOR', 'COL_ULTIMA_SINCRONIZACAO') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_ULTIMA_SINCRONIZACAO TIMESTAMP');
    if not CampoExiste('TB_COLABORADOR', 'COL_HORARIO') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_HORARIO INTEGER');
    if not CampoExiste('TB_COLABORADOR', 'COL_SENHA_RELOGIO') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_SENHA_RELOGIO VARCHAR(20)');
    if not CampoExiste('TB_COLABORADOR', 'COL_RFID') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_RFID BIGINT');
    if not CampoExiste('TB_COLABORADOR', 'COL_ADMIN_RELOGIO') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_ADMIN_RELOGIO CHAR(1) DEFAULT ''N''');
    if not CampoExiste('TB_COLABORADOR', 'COL_BARRAS') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_BARRAS VARCHAR(30)');
  end;

  // 5. TB_PONTO_HORARIO e faixas
  if not TabelaExiste('TB_PONTO_HORARIO') then
  begin
    ExecutarComandoDDL(
      'CREATE TABLE TB_PONTO_HORARIO (' +
      '  HOR_ID INTEGER NOT NULL PRIMARY KEY, ' +
      '  HOR_DESCRICAO VARCHAR(60) NOT NULL, ' +
      '  HOR_ENTRADA_1 TIME, ' +
      '  HOR_SAIDA_1 TIME, ' +
      '  HOR_ENTRADA_2 TIME, ' +
      '  HOR_SAIDA_2 TIME, ' +
      '  HOR_TOLERANCIA_MIN INTEGER DEFAULT 10, ' +
      '  HOR_CARGA_DIARIA_MIN INTEGER DEFAULT 528, ' +
      '  HOR_COMPENSA_SABADO CHAR(1) DEFAULT ''S'', ' +
      '  HOR_TRABALHA_SABADO CHAR(1) DEFAULT ''N'', ' +
      '  HOR_SAB_ENTRADA_1 TIME, ' +
      '  HOR_SAB_SAIDA_1 TIME, ' +
      '  HOR_ATIVO CHAR(1) DEFAULT ''S''' +
      ')');
    Alterou := True;
  end
  else
  begin
    if not CampoExiste('TB_PONTO_HORARIO', 'HOR_SAB_ENTRADA_1') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_HORARIO ADD HOR_SAB_ENTRADA_1 TIME');
    if not CampoExiste('TB_PONTO_HORARIO', 'HOR_SAB_SAIDA_1') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_HORARIO ADD HOR_SAB_SAIDA_1 TIME');
    if not CampoExiste('TB_PONTO_HORARIO', 'HOR_COMPENSA_SABADO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_HORARIO ADD HOR_COMPENSA_SABADO CHAR(1) DEFAULT ''S''');
    if not CampoExiste('TB_PONTO_HORARIO', 'HOR_TRABALHA_SABADO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_HORARIO ADD HOR_TRABALHA_SABADO CHAR(1) DEFAULT ''N''');
    if not CampoExiste('TB_PONTO_HORARIO', 'HOR_ATIVO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_HORARIO ADD HOR_ATIVO CHAR(1) DEFAULT ''S''');
  end;

  if not GeneratorExiste('GEN_PONTO_HORARIO') then
    ExecutarComandoDDL('CREATE GENERATOR GEN_PONTO_HORARIO');

  // Horários Padrão caso não existam
  if TabelaExiste('TB_PONTO_HORARIO') then
  begin
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := FDConnection;
      Qry.SQL.Text := 'SELECT COUNT(*) AS QTD FROM TB_PONTO_HORARIO';
      Qry.Open;
      if Qry.FieldByName('QTD').AsInteger = 0 then
      begin
        ExecutarComandoDDL(
          'INSERT INTO TB_PONTO_HORARIO (' +
          '  HOR_ID, HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, HOR_SAIDA_2, ' +
          '  HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, HOR_ATIVO' +
          ') VALUES (' +
          '  1, ''Comercial 44h (08:00 - 12:00 / 13:12 - 18:00)'', ''08:00:00'', ''12:00:00'', ''13:12:00'', ''18:00:00'', ' +
          '  10, 528, ''S'', ''N'', ''S''' +
          ')');

        ExecutarComandoDDL(
          'INSERT INTO TB_PONTO_HORARIO (' +
          '  HOR_ID, HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, HOR_SAIDA_2, ' +
          '  HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, ' +
          '  HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_ATIVO' +
          ') VALUES (' +
          '  2, ''Comercial 44h com Sabado (08:00 - 12:00 / 14:00 - 18:00 + Sab 08:00 - 12:00)'', ''08:00:00'', ''12:00:00'', ''14:00:00'', ''18:00:00'', ' +
          '  10, 480, ''N'', ''S'', ''08:00:00'', ''12:00:00'', ''S''' +
          ')');
        Alterou := True;
      end;
    finally
      Qry.Free;
    end;
  end;

  // 6. TB_PONTO_JUSTIFICATIVA
  if not TabelaExiste('TB_PONTO_JUSTIFICATIVA') then
  begin
    ExecutarComandoDDL(
      'CREATE TABLE TB_PONTO_JUSTIFICATIVA (' +
      '  JUS_ID INTEGER NOT NULL PRIMARY KEY, ' +
      '  JUS_PESSOA INTEGER NOT NULL, ' +
      '  JUS_DATA DATE NOT NULL, ' +
      '  JUS_TIPO VARCHAR(30) NOT NULL, ' +
      '  JUS_MOTIVO VARCHAR(250), ' +
      '  JUS_ABONO_MINUTOS INTEGER DEFAULT 0, ' +
      '  JUS_CRIADO_EM TIMESTAMP DEFAULT CURRENT_TIMESTAMP' +
      ')');
    Alterou := True;
  end;

  if not GeneratorExiste('GEN_PONTO_JUSTIFICATIVA') then
    ExecutarComandoDDL('CREATE GENERATOR GEN_PONTO_JUSTIFICATIVA');

  // 7. Atualizar Registro de Versão se a versão for menor que a atual
  if (VersaoAtual < DB_SCHEMA_VERSION) or Alterou then
  begin
    ExecutarComandoDDL(
      'INSERT INTO TB_PONTO_VERSAO_BD (VER_ID, VER_NUMERO, VER_SISTEMA, VER_DATA_HORA, VER_DESCRICAO) ' +
      'VALUES (' +
      '  (SELECT COALESCE(MAX(VER_ID), 0) + 1 FROM TB_PONTO_VERSAO_BD), ' +
      IntToStr(DB_SCHEMA_VERSION) + ', ''1.1.0'', CURRENT_TIMESTAMP, ' +
      '''Atualização automática de tabelas, campos e índices do Ponto Control iD''' +
      ')');
    ALogMigracao := Format('Base de dados atualizada com sucesso para a versão de schema %d.', [DB_SCHEMA_VERSION]);
  end;
end;

end.
