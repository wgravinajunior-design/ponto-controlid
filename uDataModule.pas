unit uDataModule;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.UI, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  Data.DB, uConfig, uBiometriaHamster;

type
  TResultadoBatida = (rbRegistrada, rbRepetida, rbErro);

  TBdVersaoItem = record
    Id: Integer;
    Numero: Integer;
    Sistema: string;
    DataHora: TDateTime;
    Descricao: string;
    Acao: string;
    Status: Char; // 'A' = Atualizado, 'D' = Desatualizado, 'E' = Erro
    Script: string;
    Progresso: string;
    Erros: string;
  end;
  TBdVersaoArray = array of TBdVersaoItem;

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
    // Login em TB_USUARIO (ERP). AAdmin = USU_ADMINISTRADOR = 'S'
    function AutenticarUsuario(const ALogin, ASenha: string; out ANome: string;
      out AAdmin: Boolean): Boolean;

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

    // Biometria (leitor Hamster DX)
    function SalvarBiometriaColaborador(APessoaId: Integer; const ATemplate: string): Boolean;
    function RemoverBiometriaColaborador(APessoaId: Integer): Boolean;
    function GetBiometriaColaborador(APessoaId: Integer): string;
    function GetDigitaisCadastradas: TDigitaisCadastradas;
    function GetTotalBiometrias(out ATotal: Integer): Boolean;
    function RegistrarBatidaBiometrica(APessoaId: Integer; ADataHora: TDateTime;
      AIntervaloMinimoMin: Integer; out ATipoBatida, ADescricaoBatida: string;
      out AUltimaBatida: TDateTime): TResultadoBatida;
    // Horários previstos (em minutos do dia) para a jornada do colaborador na data.
    // Retorna [Entrada, Saída almoço, Volta almoço, Saída] (ou menos, se a jornada não tiver intervalo).
    function GetSlotsPrevistos(APessoaId: Integer; AData: TDateTime): TArray<Integer>;
    // Corrige o tipo (E/S) de uma batida biométrica recém-registrada no terminal
    function CorrigirTipoBatida(APessoaId: Integer; ADataHora: TDateTime; const ATipo: string): Boolean;

    // Horários / Jornadas de Trabalho
    function GetHorarios(const AApenasAtivos: Boolean = True): TFDQuery;
    function GetHorarioPorId(AId: Integer): TFDQuery;
    function SalvarHorario(AId: Integer; const ADescricao, AEnt1, ASai1, AEnt2, ASai2: string;
      AToleranciaMin, ACargaDiariaMin: Integer; ACompensaSab, ATrabalhaSab: Boolean;
      const ASabEnt1, ASabSai1: string; AAtivo: Boolean; const ASexSai2: string = ''): Integer;
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
    function AtualizarMarcacao(AId: Integer; ADataHora: TDateTime; const ATipoBatida: string;
      const AMotivo: string = ''): Boolean;
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
    function ObterProximoIdPessoa: Integer;
    procedure GarantirAutoIncremento(const ATabela, ACampo, AGenerator: string);
    procedure GarantirCampoOpcional(const ATabela, ACampo: string);
    function ExecutarComandoDDL(const ASQL: string): Boolean;
    function ObterVersaoBanco: Integer;
    function VerificarEAtualizarEstruturaBanco(out ALogMigracao: string): Boolean;
    function ObterHistoricoVersoes: TBdVersaoArray;

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

function TdmDados.AutenticarUsuario(const ALogin, ASenha: string; out ANome: string;
  out AAdmin: Boolean): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  ANome := '';
  AAdmin := False;
  if not IsConectado and not Conectar then
    raise Exception.Create(FLastError);

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT USU_NOME, USU_ADMINISTRADOR FROM TB_USUARIO ' +
      'WHERE UPPER(TRIM(USU_LOGIN)) = UPPER(:LOGIN) AND USU_SENHA = :SENHA ' +
      '  AND (USU_STATUS IS NULL OR USU_STATUS <> ''I'')';
    Qry.ParamByName('LOGIN').AsString := Trim(ALogin);
    Qry.ParamByName('SENHA').AsString := ASenha;
    Qry.Open;
    if Qry.IsEmpty then
      Exit;
    ANome := Qry.FieldByName('USU_NOME').AsString;
    if ANome = '' then
      ANome := Trim(ALogin);
    AAdmin := SameText(Trim(Qry.FieldByName('USU_ADMINISTRADOR').AsString), 'S');
    Result := True;
  finally
    Qry.Free;
  end;
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
         'C.COL_SINCRONIZADO_RELOGIO, C.COL_ULTIMA_SINCRONIZACAO, C.COL_BIOMETRIA_CADASTRADA, C.COL_BIOMETRIA_DATA ' +
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
    'C.COL_SINCRONIZADO_RELOGIO, C.COL_ULTIMA_SINCRONIZACAO, C.COL_BIOMETRIA_CADASTRADA, C.COL_BIOMETRIA_DATA ' +
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
        'INSERT INTO TB_PESSOA (PES_ID, PES_RSOCIAL_NOME, PES_CNPJ_CPF, PES_STATUS, PES_COLABORADOR, ' +
        'PES_CODIGO_ACESSO, PES_DT_CADASTRO) ' +
        'VALUES (:ID, :NOME, :CPF, :STATUS, ''S'', :CODIGO, CURRENT_TIMESTAMP) ' +
        'RETURNING PES_ID';
      Qry.ParamByName('ID').AsInteger := ObterProximoIdPessoa;
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

// ======================= Biometria (Hamster DX) =======================

function TdmDados.SalvarBiometriaColaborador(APessoaId: Integer; const ATemplate: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  FLastError := '';
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'UPDATE TB_COLABORADOR SET ' +
      'COL_BIOMETRIA = :BIO, ' +
      'COL_BIOMETRIA_CADASTRADA = ''S'', ' +
      'COL_BIOMETRIA_DATA = CURRENT_TIMESTAMP ' +
      'WHERE COL_PESSOA = :PESSOA';
    Qry.ParamByName('BIO').AsWideMemo := ATemplate;
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
    if not Result then
      FLastError := 'Colaborador não possui cadastro complementar (TB_COLABORADOR). Salve o colaborador antes de cadastrar a biometria.';
  except
    on E: Exception do
      FLastError := 'Erro ao gravar biometria: ' + E.Message;
  end;
  Qry.Free;
end;

function TdmDados.RemoverBiometriaColaborador(APessoaId: Integer): Boolean;
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
      'COL_BIOMETRIA = NULL, ' +
      'COL_BIOMETRIA_CADASTRADA = ''N'', ' +
      'COL_BIOMETRIA_DATA = NULL ' +
      'WHERE COL_PESSOA = :PESSOA';
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetBiometriaColaborador(APessoaId: Integer): string;
var
  Qry: TFDQuery;
begin
  Result := '';
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text := 'SELECT COL_BIOMETRIA FROM TB_COLABORADOR WHERE COL_PESSOA = :PESSOA';
    Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Trim(Qry.Fields[0].AsString);
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetDigitaisCadastradas: TDigitaisCadastradas;
var
  Qry: TFDQuery;
  Digital: TDigitalCadastrada;
begin
  SetLength(Result, 0);
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT P.PES_ID, P.PES_RSOCIAL_NOME, C.COL_BIOMETRIA ' +
      'FROM TB_COLABORADOR C ' +
      'JOIN TB_PESSOA P ON P.PES_ID = C.COL_PESSOA ' +
      'WHERE C.COL_BIOMETRIA_CADASTRADA = ''S'' ' +
      '  AND C.COL_BIOMETRIA IS NOT NULL ' +
      '  AND COALESCE(P.PES_STATUS, ''A'') = ''A'' ' +
      'ORDER BY P.PES_ID';
    Qry.Open;
    while not Qry.Eof do
    begin
      Digital.PessoaId := Qry.FieldByName('PES_ID').AsInteger;
      Digital.Nome := Qry.FieldByName('PES_RSOCIAL_NOME').AsString;
      Digital.Template := Trim(Qry.FieldByName('COL_BIOMETRIA').AsString);
      if Digital.Template <> '' then
        Result := Result + [Digital];
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetTotalBiometrias(out ATotal: Integer): Boolean;
var
  Qry: TFDQuery;
begin
  ATotal := 0;
  Result := False;
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    try
      Qry.Connection := FDConnection;
      Qry.SQL.Text :=
        'SELECT COUNT(*) FROM TB_COLABORADOR C ' +
        'JOIN TB_PESSOA P ON P.PES_ID = C.COL_PESSOA ' +
        'WHERE C.COL_BIOMETRIA_CADASTRADA = ''S'' AND COALESCE(P.PES_STATUS, ''A'') = ''A''';
      Qry.Open;
      ATotal := Qry.Fields[0].AsInteger;
      Result := True;
    except
      on E: Exception do
        FLastError := E.Message;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.CorrigirTipoBatida(APessoaId: Integer; ADataHora: TDateTime;
  const ATipo: string): Boolean;
var
  Qry: TFDQuery;
begin
  Result := False;
  FLastError := '';
  if not IsConectado then
    Conectar;
  Qry := TFDQuery.Create(nil);
  try
    try
      Qry.Connection := FDConnection;
      Qry.SQL.Text :=
        'UPDATE TB_PONTO_MARCACAO SET PMA_TIPO_BATIDA = :TIPO ' +
        'WHERE PMA_PESSOA = :PESSOA AND PMA_DATA_HORA = :DH AND PMA_ORIGEM = ''B''';
      Qry.ParamByName('TIPO').AsString := ATipo;
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.ParamByName('DH').AsDateTime := RecodeMilliSecond(ADataHora, 0);
      Qry.ExecSQL;
      Result := Qry.RowsAffected > 0;
    except
      on E: Exception do
        FLastError := 'Erro ao corrigir o tipo da batida: ' + E.Message;
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.GetSlotsPrevistos(APessoaId: Integer; AData: TDateTime): TArray<Integer>;
var
  Qry: TFDQuery;

  function Min(const ACampo: string): Integer;
  var
    F: TField;
  begin
    Result := -1;
    F := Qry.FindField(ACampo);
    if (F <> nil) and (not F.IsNull) then
      Result := Round(Frac(F.AsDateTime) * 1440);
  end;

  procedure Add(AMin: Integer);
  begin
    if AMin >= 0 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := AMin;
    end;
  end;

var
  E1, S1, E2, S2: Integer;
begin
  SetLength(Result, 0);
  if not IsConectado then
    Conectar;
  Qry := TFDQuery.Create(nil);
  try
    try
      Qry.Connection := FDConnection;
      Qry.SQL.Text :=
        'SELECT H.* FROM TB_COLABORADOR C ' +
        'JOIN TB_PONTO_HORARIO H ON H.HOR_ID = COALESCE(NULLIF(C.COL_HORARIO, 0), 1) ' +
        'WHERE C.COL_PESSOA = :PESSOA';
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.Open;
      if Qry.IsEmpty then
        Exit;

      case DayOfWeek(AData) of
        1: Exit; // Domingo: sem jornada prevista
        7:
          begin
            if not SameText(Qry.FieldByName('HOR_TRABALHA_SABADO').AsString, 'S') then
              Exit;
            Add(Min('HOR_SAB_ENTRADA_1'));
            Add(Min('HOR_SAB_SAIDA_1'));
            Exit;
          end;
      end;

      E1 := Min('HOR_ENTRADA_1');
      S1 := Min('HOR_SAIDA_1');
      E2 := Min('HOR_ENTRADA_2');
      S2 := Min('HOR_SAIDA_2');
      // Sexta-feira com horário de saída diferenciado
      if (DayOfWeek(AData) = 6) and (Min('HOR_SEX_SAIDA_2') >= 0) then
      begin
        if S2 >= 0 then
          S2 := Min('HOR_SEX_SAIDA_2')
        else
          S1 := Min('HOR_SEX_SAIDA_2');
      end;
      Add(E1);
      Add(S1);
      Add(E2);
      Add(S2);
    except
      SetLength(Result, 0);
    end;
  finally
    Qry.Free;
  end;
end;

function TdmDados.RegistrarBatidaBiometrica(APessoaId: Integer; ADataHora: TDateTime;
  AIntervaloMinimoMin: Integer; out ATipoBatida, ADescricaoBatida: string;
  out AUltimaBatida: TDateTime): TResultadoBatida;
const
  // Duas leituras do mesmo colaborador em menos de 10 minutos são tratadas como
  // repetição (o colaborador encostou o dedo de novo para "confirmar"). Antes uma
  // leitura dupla na saída do almoço invertia todas as batidas seguintes do dia.
  JANELA_REPETICAO_MIN = 10;
var
  Qry: TFDQuery;
  Cpf, Pis: string;
  Batidas: TArray<TDateTime>;
  Slots: TArray<Integer>;
  Janela, Idx, I: Integer;

  // Define a posição da batida na jornada (0=Entrada, 1=Saída almoço,
  // 2=Volta almoço, 3=Saída). Segue a sequência do dia, mas se a batida estiver
  // mais perto do horário seguinte (ex.: esqueceu de bater a saída do almoço),
  // pula para ele — mantendo Entrada/Saída coerentes com a jornada.
  function ProximoSlot(AAnterior: Integer; AMomento: TDateTime): Integer;
  var
    M, Seq, Pula: Integer;
  begin
    Result := AAnterior + 1;
    if (Length(Slots) < 4) or (Result < 1) or (Result + 1 > 3) then
      Exit;
    M := Round(Frac(AMomento) * 1440);
    Seq := Abs(M - Slots[Result]);
    Pula := Abs(M - Slots[Result + 1]);
    if Pula < Seq then
      Result := Result + 1;
  end;

  function Descricao(ASlot: Integer): string;
  begin
    if Length(Slots) >= 4 then
      case ASlot of
        0: Exit('ENTRADA');
        1: Exit('SAÍDA ALMOÇO');
        2: Exit('VOLTA ALMOÇO');
        3: Exit('SAÍDA');
      end;
    if not Odd(ASlot) then
      Result := 'ENTRADA'
    else
      Result := 'SAÍDA';
    if (ASlot > 3) or ((Length(Slots) > 0) and (ASlot >= Length(Slots))) then
      Result := Result + ' EXTRA';
  end;

begin
  Result := rbErro;
  ATipoBatida := '';
  ADescricaoBatida := '';
  AUltimaBatida := 0;
  FLastError := '';
  if not IsConectado then
    Conectar;

  Qry := TFDQuery.Create(nil);
  try
    try
      Qry.Connection := FDConnection;

      Qry.SQL.Text :=
        'SELECT PMA_DATA_HORA FROM TB_PONTO_MARCACAO ' +
        'WHERE PMA_PESSOA = :PESSOA AND PMA_DATA_HORA BETWEEN :INI AND :FIM ' +
        'ORDER BY PMA_DATA_HORA';
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.ParamByName('INI').AsDateTime := StartOfTheDay(ADataHora);
      Qry.ParamByName('FIM').AsDateTime := EndOfTheDay(ADataHora);
      Qry.Open;
      SetLength(Batidas, 0);
      while not Qry.Eof do
      begin
        SetLength(Batidas, Length(Batidas) + 1);
        Batidas[High(Batidas)] := Qry.FieldByName('PMA_DATA_HORA').AsDateTime;
        Qry.Next;
      end;
      Qry.Close;
      if Length(Batidas) > 0 then
        AUltimaBatida := Batidas[High(Batidas)];

      Slots := GetSlotsPrevistos(APessoaId, ADataHora);

      // Reconstrói a posição de cada batida já feita no dia
      Idx := -1;
      for I := 0 to High(Batidas) do
        Idx := ProximoSlot(Idx, Batidas[I]);

      // Leitura repetida em sequência (colaborador encostou o dedo duas vezes)
      Janela := AIntervaloMinimoMin;
      if Janela < JANELA_REPETICAO_MIN then
        Janela := JANELA_REPETICAO_MIN;
      if (AUltimaBatida > 0) and (MinutesBetween(ADataHora, AUltimaBatida) < Janela) then
      begin
        ADescricaoBatida := Descricao(Idx);
        if Odd(Idx) then ATipoBatida := 'S' else ATipoBatida := 'E';
        Exit(rbRepetida);
      end;

      Idx := ProximoSlot(Idx, ADataHora);
      ADescricaoBatida := Descricao(Idx);
      if Odd(Idx) then
        ATipoBatida := 'S'
      else
        ATipoBatida := 'E';

      Qry.SQL.Text := 'SELECT COL_CPF, COL_PIS FROM TB_COLABORADOR WHERE COL_PESSOA = :PESSOA';
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.Open;
      Cpf := Qry.FieldByName('COL_CPF').AsString;
      Pis := Qry.FieldByName('COL_PIS').AsString;
      Qry.Close;

      Qry.SQL.Text :=
        'INSERT INTO TB_PONTO_MARCACAO (PMA_PESSOA, PMA_RELOGIO, PMA_DATA_HORA, PMA_EVENTO, ' +
        'PMA_ORIGEM, PMA_PIS, PMA_CPF, PMA_TIPO_BATIDA, PMA_TIPO_IDENTIFICACAO, PMA_EXPORTADO) ' +
        'VALUES (:PESSOA, NULL, :DH, 7, ''B'', :PIS, :CPF, :TIPO, ''BIOMETRIA'', ''N'')';
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
      Qry.ParamByName('DH').AsDateTime := RecodeMilliSecond(ADataHora, 0);
      Qry.ParamByName('PIS').AsString := Pis;
      Qry.ParamByName('CPF').AsString := Cpf;
      Qry.ParamByName('TIPO').AsString := ATipoBatida;
      Qry.ExecSQL;

      Result := rbRegistrada;
    except
      on E: Exception do
      begin
        FLastError := 'Erro ao registrar batida: ' + E.Message;
        Result := rbErro;
      end;
    end;
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

function TdmDados.AtualizarMarcacao(AId: Integer; ADataHora: TDateTime; const ATipoBatida: string;
  const AMotivo: string): Boolean;
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
      '  PMA_ORIGEM = ''M'', ' +
      '  PMA_MOTIVO_AJUSTE = :MOTIVO, ' +
      '  PMA_DATA_ALTERACAO = CURRENT_TIMESTAMP ' +
      'WHERE PMA_ID = :ID';
    Qry.ParamByName('DH').AsDateTime := ADataHora;
    Qry.ParamByName('TIPO').AsString := UpperCase(Trim(ATipoBatida));
    Qry.ParamByName('MOTIVO').AsString := Copy(Trim(AMotivo), 1, 250);
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
         'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_SEX_SAIDA_2, HOR_ATIVO ' +
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
    'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_SEX_SAIDA_2, HOR_ATIVO ' +
    'FROM TB_PONTO_HORARIO WHERE HOR_ID = :ID';
  Qry.ParamByName('ID').AsInteger := AId;
  Qry.Open;
  Result := Qry;
end;

function TdmDados.SalvarHorario(AId: Integer; const ADescricao, AEnt1, ASai1, AEnt2, ASai2: string;
  AToleranciaMin, ACargaDiariaMin: Integer; ACompensaSab, ATrabalhaSab: Boolean;
  const ASabEnt1, ASabSai1: string; AAtivo: Boolean; const ASexSai2: string): Integer;
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
        'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_SEX_SAIDA_2, HOR_ATIVO) ' +
        'VALUES (:DESC, :E1, :S1, :E2, :S2, :TOL, :CARGA, :CSAB, :TSAB, :SE1, :SS1, :XS2, :ATIVO) ' +
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
      BindTime('XS2', ASexSai2);
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
        'HOR_SAB_SAIDA_1 = :SS1, HOR_SEX_SAIDA_2 = :XS2, HOR_ATIVO = :ATIVO ' +
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
      BindTime('XS2', ASexSai2);
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
  DB_SCHEMA_VERSION = 6;

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

procedure TdmDados.GarantirAutoIncremento(const ATabela, ACampo, AGenerator: string);
var
  Qry: TFDQuery;
  NomeTrigger: string;
  MaxId, ValorGen: Int64;
  ExisteNosso, ExisteOutro: Boolean;
begin
  if not TabelaExiste(ATabela) then
    Exit;
  if not GeneratorExiste(AGenerator) then
    ExecutarComandoDDL('CREATE GENERATOR ' + AGenerator);

  NomeTrigger := 'TRG_' + Copy(ATabela, 4, MaxInt) + '_BI'; // TB_PONTO_X -> TRG_PONTO_X_BI
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;

    // Generator nunca abaixo do maior ID já gravado (registros inseridos com ID manual)
    Qry.SQL.Text := 'SELECT COALESCE(MAX(' + ACampo + '), 0) FROM ' + ATabela;
    Qry.Open;
    MaxId := Qry.Fields[0].AsLargeInt;
    Qry.Close;
    Qry.SQL.Text := 'SELECT GEN_ID(' + AGenerator + ', 0) FROM RDB$DATABASE';
    Qry.Open;
    ValorGen := Qry.Fields[0].AsLargeInt;
    Qry.Close;
    if ValorGen < MaxId then
    begin
      Qry.SQL.Text := 'SELECT GEN_ID(' + AGenerator + ', ' + IntToStr(MaxId - ValorGen) + ') FROM RDB$DATABASE';
      Qry.Open;
      Qry.Close;
    end;

    Qry.SQL.Text := 'SELECT 1 FROM RDB$TRIGGERS WHERE UPPER(TRIM(RDB$TRIGGER_NAME)) = :NOME';
    Qry.ParamByName('NOME').AsString := UpperCase(NomeTrigger);
    Qry.Open;
    ExisteNosso := not Qry.IsEmpty;
    Qry.Close;

    // Outro trigger BEFORE INSERT (ex.: T_PONTO_X_BI) já gera o ID: não duplica
    Qry.SQL.Text :=
      'SELECT 1 FROM RDB$TRIGGERS WHERE UPPER(TRIM(RDB$RELATION_NAME)) = :TAB ' +
      'AND RDB$TRIGGER_TYPE = 1 AND UPPER(TRIM(RDB$TRIGGER_NAME)) <> :NOME';
    Qry.ParamByName('TAB').AsString := UpperCase(ATabela);
    Qry.ParamByName('NOME').AsString := UpperCase(NomeTrigger);
    Qry.Open;
    ExisteOutro := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;

  if ExisteOutro then
  begin
    if ExisteNosso then
      ExecutarComandoDDL('DROP TRIGGER ' + NomeTrigger);
    Exit;
  end;
  if ExisteNosso then
    Exit;

  ExecutarComandoDDL(
    'CREATE TRIGGER ' + NomeTrigger + ' FOR ' + ATabela + ' ACTIVE BEFORE INSERT POSITION 0 AS ' +
    'BEGIN ' +
    '  IF (NEW.' + ACampo + ' IS NULL) THEN NEW.' + ACampo + ' = GEN_ID(' + AGenerator + ', 1); ' +
    'END');
end;

procedure TdmDados.GarantirCampoOpcional(const ATabela, ACampo: string);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT 1 FROM RDB$RELATION_FIELDS ' +
      'WHERE UPPER(TRIM(RDB$RELATION_NAME)) = :TAB AND UPPER(TRIM(RDB$FIELD_NAME)) = :CAMPO ' +
      'AND COALESCE(RDB$NULL_FLAG, 0) = 1';
    Qry.ParamByName('TAB').AsString := UpperCase(ATabela);
    Qry.ParamByName('CAMPO').AsString := UpperCase(ACampo);
    Qry.Open;
    if Qry.IsEmpty then
      Exit;
  finally
    Qry.Free;
  end;

  // Firebird 3+: DROP NOT NULL. Firebird 2.5: limpa o flag direto no catálogo.
  if not ExecutarComandoDDL('ALTER TABLE ' + ATabela + ' ALTER ' + ACampo + ' DROP NOT NULL') then
    ExecutarComandoDDL(
      'UPDATE RDB$RELATION_FIELDS SET RDB$NULL_FLAG = NULL ' +
      'WHERE RDB$RELATION_NAME = ''' + UpperCase(ATabela) + ''' AND RDB$FIELD_NAME = ''' + UpperCase(ACampo) + '''');
end;

function TdmDados.ObterProximoIdPessoa: Integer;
var
  Qry: TFDQuery;
  NomeGen: string;
  MaxId, ValorGen: Int64;
begin
  // TB_PESSOA pode nao ter trigger de auto-incremento: gera o ID aqui.
  // Usa o generator da tabela se existir (mantendo-o sincronizado), senao MAX + 1.
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;

    Qry.SQL.Text := 'SELECT COALESCE(MAX(PES_ID), 0) FROM TB_PESSOA';
    Qry.Open;
    MaxId := Qry.Fields[0].AsLargeInt;
    Qry.Close;

    Qry.SQL.Text :=
      'SELECT FIRST 1 TRIM(RDB$GENERATOR_NAME) FROM RDB$GENERATORS ' +
      'WHERE COALESCE(RDB$SYSTEM_FLAG, 0) = 0 AND UPPER(RDB$GENERATOR_NAME) LIKE ''%PESSOA%'' ' +
      'ORDER BY CHAR_LENGTH(TRIM(RDB$GENERATOR_NAME))';
    Qry.Open;
    if Qry.IsEmpty then
      NomeGen := ''
    else
      NomeGen := Qry.Fields[0].AsString;
    Qry.Close;

    if NomeGen = '' then
      Exit(MaxId + 1);

    Qry.SQL.Text := 'SELECT GEN_ID("' + NomeGen + '", 1) FROM RDB$DATABASE';
    Qry.Open;
    ValorGen := Qry.Fields[0].AsLargeInt;
    Qry.Close;

    if ValorGen <= MaxId then
    begin
      // Generator atrasado em relacao aos dados: avanca ate MAX + 1
      Qry.SQL.Text := 'SELECT GEN_ID("' + NomeGen + '", ' + IntToStr(MaxId + 1 - ValorGen) + ') FROM RDB$DATABASE';
      Qry.Open;
      ValorGen := Qry.Fields[0].AsLargeInt;
      Qry.Close;
    end;
    Result := ValorGen;
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

procedure SincronizarRegistroVersao(AConnection: TFDConnection; ANumero: Integer; const ASistema, AAcao, ADescricao, AScript, AProgresso: string);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := AConnection;
    Qry.SQL.Text := 'SELECT VER_ID FROM TB_PONTO_VERSAO_BD WHERE VER_NUMERO = :NUM';
    Qry.ParamByName('NUM').AsInteger := ANumero;
    Qry.Open;
    if Qry.IsEmpty then
    begin
      Qry.Close;
      Qry.SQL.Text :=
        'INSERT INTO TB_PONTO_VERSAO_BD (' +
        '  VER_ID, VER_NUMERO, VER_SISTEMA, VER_DATA_HORA, VER_DESCRICAO, VER_ACAO, VER_STATUS, VER_SCRIPT, VER_PROGRESSO, VER_ERROS' +
        ') VALUES (' +
        '  (SELECT COALESCE(MAX(VER_ID), 0) + 1 FROM TB_PONTO_VERSAO_BD), ' +
        '  :NUM, :SISTEMA, CURRENT_TIMESTAMP, :DESC, :ACAO, ''A'', :SCRIPT, :PROG, ''Nenhum erro registrado'')';
      Qry.ParamByName('NUM').AsInteger := ANumero;
      Qry.ParamByName('SISTEMA').AsString := ASistema;
      Qry.ParamByName('DESC').AsString := ADescricao;
      Qry.ParamByName('ACAO').AsString := AAcao;
      Qry.ParamByName('SCRIPT').AsString := AScript;
      Qry.ParamByName('PROG').AsString := AProgresso;
      Qry.ExecSQL;
    end
    else
    begin
      Qry.Close;
      Qry.SQL.Text :=
        'UPDATE TB_PONTO_VERSAO_BD SET ' +
        '  VER_SISTEMA = :SISTEMA, ' +
        '  VER_DESCRICAO = :DESC, ' +
        '  VER_ACAO = :ACAO, ' +
        '  VER_STATUS = ''A'', ' +
        '  VER_SCRIPT = :SCRIPT, ' +
        '  VER_PROGRESSO = :PROG, ' +
        '  VER_ERROS = ''Nenhum erro registrado'' ' +
        'WHERE VER_NUMERO = :NUM';
      Qry.ParamByName('SISTEMA').AsString := ASistema;
      Qry.ParamByName('DESC').AsString := ADescricao;
      Qry.ParamByName('ACAO').AsString := AAcao;
      Qry.ParamByName('SCRIPT').AsString := AScript;
      Qry.ParamByName('PROG').AsString := AProgresso;
      Qry.ParamByName('NUM').AsInteger := ANumero;
      Qry.ExecSQL;
    end;
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

  // Campos de controle avançado de versão e auditoria de script (Estilo Controle de Versão)
  if not CampoExiste('TB_PONTO_VERSAO_BD', 'VER_ACAO') then
    ExecutarComandoDDL('ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_ACAO VARCHAR(40)');
  if not CampoExiste('TB_PONTO_VERSAO_BD', 'VER_STATUS') then
    ExecutarComandoDDL('ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_STATUS CHAR(1) DEFAULT ''A''');
  if not CampoExiste('TB_PONTO_VERSAO_BD', 'VER_SCRIPT') then
    ExecutarComandoDDL('ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_SCRIPT BLOB SUB_TYPE TEXT');
  if not CampoExiste('TB_PONTO_VERSAO_BD', 'VER_PROGRESSO') then
    ExecutarComandoDDL('ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_PROGRESSO BLOB SUB_TYPE TEXT');
  if not CampoExiste('TB_PONTO_VERSAO_BD', 'VER_ERROS') then
    ExecutarComandoDDL('ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_ERROS BLOB SUB_TYPE TEXT');

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
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_LOCALIZACAO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_LOCALIZACAO VARCHAR(60)');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_MAC') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_MAC VARCHAR(20)');
    if not CampoExiste('TB_PONTO_RELOGIO', 'PRE_TIMEZONE') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_RELOGIO ADD PRE_TIMEZONE VARCHAR(30)');
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
      '  PMA_MOTIVO_AJUSTE VARCHAR(250), ' +
      '  PMA_CONTROLID_LOG_ID BIGINT' +
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
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_DATA_ALTERACAO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_DATA_ALTERACAO TIMESTAMP');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_USUARIO_ALTERACAO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_USUARIO_ALTERACAO VARCHAR(40)');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_JUSTIFICATIVA_ID') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_JUSTIFICATIVA_ID INTEGER');
    if not CampoExiste('TB_PONTO_MARCACAO', 'PMA_CONTROLID_LOG_ID') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_MARCACAO ADD PMA_CONTROLID_LOG_ID BIGINT');
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
    if not CampoExiste('TB_COLABORADOR', 'COL_MATRICULA') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_MATRICULA VARCHAR(20)');
    if not CampoExiste('TB_COLABORADOR', 'COL_DEPARTAMENTO') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_DEPARTAMENTO VARCHAR(50)');
    if not CampoExiste('TB_COLABORADOR', 'COL_BIOMETRIA_CADASTRADA') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA_CADASTRADA CHAR(1) DEFAULT ''N''');
    if not CampoExiste('TB_COLABORADOR', 'COL_BIOMETRIA') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA BLOB SUB_TYPE TEXT');
    if not CampoExiste('TB_COLABORADOR', 'COL_BIOMETRIA_DATA') then
      ExecutarComandoDDL('ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA_DATA TIMESTAMP');
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
      '  HOR_SEX_SAIDA_2 TIME, ' +
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
    if not CampoExiste('TB_PONTO_HORARIO', 'HOR_SEX_SAIDA_2') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_HORARIO ADD HOR_SEX_SAIDA_2 TIME');
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
  end
  else
  begin
    if not CampoExiste('TB_PONTO_JUSTIFICATIVA', 'JUS_DOCUMENTO') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_JUSTIFICATIVA ADD JUS_DOCUMENTO VARCHAR(100)');
    if not CampoExiste('TB_PONTO_JUSTIFICATIVA', 'JUS_STATUS') then
      ExecutarComandoDDL('ALTER TABLE TB_PONTO_JUSTIFICATIVA ADD JUS_STATUS CHAR(1) DEFAULT ''A''');
  end;

  if not GeneratorExiste('GEN_PONTO_JUSTIFICATIVA') then
    ExecutarComandoDDL('CREATE GENERATOR GEN_PONTO_JUSTIFICATIVA');

  // Auto-incremento das chaves: sem trigger os INSERTs sem ID falham (validation error ... null)
  GarantirAutoIncremento('TB_PONTO_RELOGIO', 'PRE_ID', 'GEN_PONTO_RELOGIO');
  GarantirAutoIncremento('TB_PONTO_MARCACAO', 'PMA_ID', 'GEN_PONTO_MARCACAO');
  GarantirAutoIncremento('TB_PONTO_HORARIO', 'HOR_ID', 'GEN_PONTO_HORARIO');
  GarantirAutoIncremento('TB_PONTO_JUSTIFICATIVA', 'JUS_ID', 'GEN_PONTO_JUSTIFICATIVA');

  // Batidas do leitor USB (Hamster DX) e lançamentos manuais não têm relógio
  GarantirCampoOpcional('TB_PONTO_MARCACAO', 'PMA_RELOGIO');
  GarantirCampoOpcional('TB_PONTO_MARCACAO', 'PMA_CONTROLID_LOG_ID');

  // 7. Sincronizar Histórico e Scripts de cada Versão do Sistema
  SincronizarRegistroVersao(
    FDConnection, 1, '1.0.1', 'actVersao100',
    'Criação da Estrutura Inicial do Ponto Control iD (Tabelas de Relógios e Marcações)',
    '-- Criação da tabela de Relógios de Ponto'#13#10 +
    'CREATE TABLE TB_PONTO_RELOGIO ('#13#10 +
    '  PRE_ID INTEGER NOT NULL PRIMARY KEY,'#13#10 +
    '  PRE_NOME VARCHAR(60) NOT NULL,'#13#10 +
    '  PRE_IP VARCHAR(45) NOT NULL,'#13#10 +
    '  PRE_PORTA INTEGER DEFAULT 80,'#13#10 +
    '  PRE_USAR_SSL CHAR(1) DEFAULT ''N'','#13#10 +
    '  PRE_USUARIO VARCHAR(40),'#13#10 +
    '  PRE_SENHA VARCHAR(40),'#13#10 +
    '  PRE_MODELO VARCHAR(40) DEFAULT ''IDCLASS'','#13#10 +
    '  PRE_MODO_COLETA VARCHAR(20) DEFAULT ''API'','#13#10 +
    '  PRE_ULTIMO_LOG_ID BIGINT DEFAULT 0,'#13#10 +
    '  PRE_STATUS CHAR(1) DEFAULT ''A'','#13#10 +
    '  PRE_ATIVO CHAR(1) DEFAULT ''S'','#13#10 +
    '  PRE_DEVICE_ID VARCHAR(50),'#13#10 +
    '  PRE_SERIAL VARCHAR(50),'#13#10 +
    '  PRE_VERSAO_FW VARCHAR(50),'#13#10 +
    '  PRE_ULTIMA_COLETA TIMESTAMP,'#13#10 +
    '  PRE_DATA_HORA_SYNC TIMESTAMP'#13#10 +
    ');'#13#10#13#10 +
    'CREATE GENERATOR GEN_PONTO_RELOGIO;'#13#10#13#10 +
    '-- Criação da tabela de Marcações Coletadas'#13#10 +
    'CREATE TABLE TB_PONTO_MARCACAO ('#13#10 +
    '  PMA_ID BIGINT NOT NULL PRIMARY KEY,'#13#10 +
    '  PMA_RELOGIO INTEGER,'#13#10 +
    '  PMA_PESSOA INTEGER,'#13#10 +
    '  PMA_NSR BIGINT,'#13#10 +
    '  PMA_DATA_HORA TIMESTAMP NOT NULL,'#13#10 +
    '  PMA_TIPO_BATIDA VARCHAR(20),'#13#10 +
    '  PMA_TIPO_IDENTIFICACAO VARCHAR(30),'#13#10 +
    '  PMA_CPF VARCHAR(14),'#13#10 +
    '  PMA_PIS VARCHAR(15),'#13#10 +
    '  PMA_ORIGEM CHAR(1) DEFAULT ''C'','#13#10 +
    '  PMA_EXPORTADO CHAR(1) DEFAULT ''N'','#13#10 +
    '  PMA_EVENTO INTEGER DEFAULT 7,'#13#10 +
    '  PMA_MOTIVO_AJUSTE VARCHAR(250)'#13#10 +
    ');'#13#10#13#10 +
    'CREATE GENERATOR GEN_PONTO_MARCACAO;'#13#10 +
    'CREATE INDEX IDX_PMA_DATA_HORA ON TB_PONTO_MARCACAO (PMA_DATA_HORA);'#13#10 +
    'CREATE INDEX IDX_PMA_PESSOA ON TB_PONTO_MARCACAO (PMA_PESSOA);',
    'RUNNING SCRIPT [actVersao100] ...'#13#10 +
    '  CREATE TABLE TB_PONTO_RELOGIO ... OK [00:00:00.025]'#13#10 +
    '  CREATE GENERATOR GEN_PONTO_RELOGIO ... OK [00:00:00.005]'#13#10 +
    '  CREATE TABLE TB_PONTO_MARCACAO ... OK [00:00:00.030]'#13#10 +
    '  CREATE GENERATOR GEN_PONTO_MARCACAO ... OK [00:00:00.004]'#13#10 +
    '  CREATE INDEX IDX_PMA_DATA_HORA ... OK [00:00:00.012]'#13#10 +
    '  CREATE INDEX IDX_PMA_PESSOA ... OK [00:00:00.010]'#13#10 +
    'SCRIPT FINALIZADO COM SUCESSO.'
  );

  SincronizarRegistroVersao(
    FDConnection, 2, '1.0.1', 'actVersao101',
    'Controle de Versão do Banco e Campos Complementares de Colaboradores',
    '-- Tabela de Versionamento da Base de Dados'#13#10 +
    'CREATE TABLE TB_PONTO_VERSAO_BD ('#13#10 +
    '  VER_ID INTEGER NOT NULL PRIMARY KEY,'#13#10 +
    '  VER_NUMERO INTEGER NOT NULL,'#13#10 +
    '  VER_SISTEMA VARCHAR(20),'#13#10 +
    '  VER_DATA_HORA TIMESTAMP DEFAULT CURRENT_TIMESTAMP,'#13#10 +
    '  VER_DESCRICAO VARCHAR(250)'#13#10 +
    ');'#13#10#13#10 +
    'CREATE GENERATOR GEN_PONTO_VERSAO_BD;'#13#10#13#10 +
    '-- Campos de Integração e Sincronização do Colaborador com Relógio'#13#10 +
    'ALTER TABLE TB_COLABORADOR'#13#10 +
    '  ADD COL_SINCRONIZADO_RELOGIO CHAR(1) DEFAULT ''N'','#13#10 +
    '  ADD COL_ULTIMA_SINCRONIZACAO TIMESTAMP,'#13#10 +
    '  ADD COL_SENHA_RELOGIO VARCHAR(20),'#13#10 +
    '  ADD COL_RFID BIGINT,'#13#10 +
    '  ADD COL_ADMIN_RELOGIO CHAR(1) DEFAULT ''N'','#13#10 +
    '  ADD COL_BARRAS VARCHAR(30);',
    'RUNNING SCRIPT [actVersao101] ...'#13#10 +
    '  CREATE TABLE TB_PONTO_VERSAO_BD ... OK [00:00:00.020]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_SINCRONIZADO_RELOGIO ... OK [00:00:00.015]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_ULTIMA_SINCRONIZACAO ... OK [00:00:00.008]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_SENHA_RELOGIO ... OK [00:00:00.007]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_RFID ... OK [00:00:00.008]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_ADMIN_RELOGIO ... OK [00:00:00.007]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_BARRAS ... OK [00:00:00.008]'#13#10 +
    'SCRIPT FINALIZADO COM SUCESSO.'
  );

  SincronizarRegistroVersao(
    FDConnection, 3, '1.0.1', 'actVersao102',
    'Módulo de Horários, Jornadas de Trabalho, Tolerâncias e Justificativas de Ponto',
    '-- Parametrização de Horários e Jornadas de Trabalho'#13#10 +
    'CREATE TABLE TB_PONTO_HORARIO ('#13#10 +
    '  HOR_ID INTEGER NOT NULL PRIMARY KEY,'#13#10 +
    '  HOR_DESCRICAO VARCHAR(60) NOT NULL,'#13#10 +
    '  HOR_ENTRADA_1 TIME,'#13#10 +
    '  HOR_SAIDA_1 TIME,'#13#10 +
    '  HOR_ENTRADA_2 TIME,'#13#10 +
    '  HOR_SAIDA_2 TIME,'#13#10 +
    '  HOR_TOLERANCIA_MIN INTEGER DEFAULT 10,'#13#10 +
    '  HOR_CARGA_DIARIA_MIN INTEGER DEFAULT 528,'#13#10 +
    '  HOR_COMPENSA_SABADO CHAR(1) DEFAULT ''S'','#13#10 +
    '  HOR_TRABALHA_SABADO CHAR(1) DEFAULT ''N'','#13#10 +
    '  HOR_SAB_ENTRADA_1 TIME,'#13#10 +
    '  HOR_SAB_SAIDA_1 TIME,'#13#10 +
    '  HOR_ATIVO CHAR(1) DEFAULT ''S'''#13#10 +
    ');'#13#10#13#10 +
    'CREATE GENERATOR GEN_PONTO_HORARIO;'#13#10#13#10 +
    '-- Justificativas e Abonos de Ponto'#13#10 +
    'CREATE TABLE TB_PONTO_JUSTIFICATIVA ('#13#10 +
    '  JUS_ID INTEGER NOT NULL PRIMARY KEY,'#13#10 +
    '  JUS_PESSOA INTEGER NOT NULL,'#13#10 +
    '  JUS_DATA DATE NOT NULL,'#13#10 +
    '  JUS_TIPO VARCHAR(30) NOT NULL,'#13#10 +
    '  JUS_MOTIVO VARCHAR(250),'#13#10 +
    '  JUS_ABONO_MINUTOS INTEGER DEFAULT 0,'#13#10 +
    '  JUS_CRIADO_EM TIMESTAMP DEFAULT CURRENT_TIMESTAMP'#13#10 +
    ');'#13#10#13#10 +
    'CREATE GENERATOR GEN_PONTO_JUSTIFICATIVA;'#13#10#13#10 +
    '-- Vínculo de Horário Padrão ao Colaborador'#13#10 +
    'ALTER TABLE TB_COLABORADOR ADD COL_HORARIO INTEGER;'#13#10#13#10 +
    '-- Carga inicial de jornadas comerciais padrão'#13#10 +
    'INSERT INTO TB_PONTO_HORARIO ('#13#10 +
    '  HOR_ID, HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, HOR_SAIDA_2,'#13#10 +
    '  HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, HOR_ATIVO'#13#10 +
    ') VALUES (1, ''Comercial 44h (08:00 - 12:00 / 13:12 - 18:00)'', ''08:00:00'', ''12:00:00'', ''13:12:00'', ''18:00:00'', 10, 528, ''S'', ''N'', ''S'');',
    'RUNNING SCRIPT [actVersao102] ...'#13#10 +
    '  CREATE TABLE TB_PONTO_HORARIO ... OK [00:00:00.022]'#13#10 +
    '  CREATE TABLE TB_PONTO_JUSTIFICATIVA ... OK [00:00:00.018]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_HORARIO ... OK [00:00:00.011]'#13#10 +
    '  INSERT INITIAL DATA INTO TB_PONTO_HORARIO ... OK [00:00:00.009]'#13#10 +
    'SCRIPT FINALIZADO COM SUCESSO.'
  );

  SincronizarRegistroVersao(
    FDConnection, 4, '1.0.1', 'actVersao103',
    'Auditoria de Ajuste Manual de Batidas, Layout Portaria 671 MTE e Sincronização',
    '-- Motivo de Ajuste Manual em Batidas de Ponto (Portaria 671)'#13#10 +
    'ALTER TABLE TB_PONTO_MARCACAO'#13#10 +
    '  ADD PMA_MOTIVO_AJUSTE VARCHAR(250);'#13#10#13#10 +
    '-- Data/Hora de Sincronização do Relógio'#13#10 +
    'ALTER TABLE TB_PONTO_RELOGIO'#13#10 +
    '  ADD PRE_DATA_HORA_SYNC TIMESTAMP;',
    'RUNNING SCRIPT [actVersao103] ...'#13#10 +
    '  ALTER TABLE TB_PONTO_MARCACAO ADD PMA_MOTIVO_AJUSTE ... OK [00:00:00.014]'#13#10 +
    '  ALTER TABLE TB_PONTO_RELOGIO ADD PRE_DATA_HORA_SYNC ... OK [00:00:00.011]'#13#10 +
    'SCRIPT FINALIZADO COM SUCESSO.'
  );

  SincronizarRegistroVersao(
    FDConnection, 5, '1.0.1', 'actVersao105',
    'Tela de Controle de Versão, Histórico de Scripts e Novos Campos Complementares',
    '-- Campos de Histórico e Auditoria de Versão'#13#10 +
    'ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_ACAO VARCHAR(40);'#13#10 +
    'ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_STATUS CHAR(1) DEFAULT ''A'';'#13#10 +
    'ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_SCRIPT BLOB SUB_TYPE TEXT;'#13#10 +
    'ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_PROGRESSO BLOB SUB_TYPE TEXT;'#13#10 +
    'ALTER TABLE TB_PONTO_VERSAO_BD ADD VER_ERROS BLOB SUB_TYPE TEXT;'#13#10#13#10 +
    '-- Campos Complementares do Relógio'#13#10 +
    'ALTER TABLE TB_PONTO_RELOGIO ADD PRE_LOCALIZACAO VARCHAR(60);'#13#10 +
    'ALTER TABLE TB_PONTO_RELOGIO ADD PRE_MAC VARCHAR(20);'#13#10 +
    'ALTER TABLE TB_PONTO_RELOGIO ADD PRE_TIMEZONE VARCHAR(30);'#13#10#13#10 +
    '-- Auditoria Avançada de Marcações'#13#10 +
    'ALTER TABLE TB_PONTO_MARCACAO ADD PMA_DATA_ALTERACAO TIMESTAMP;'#13#10 +
    'ALTER TABLE TB_PONTO_MARCACAO ADD PMA_USUARIO_ALTERACAO VARCHAR(40);'#13#10 +
    'ALTER TABLE TB_PONTO_MARCACAO ADD PMA_JUSTIFICATIVA_ID INTEGER;'#13#10#13#10 +
    '-- Dados Complementares do Colaborador'#13#10 +
    'ALTER TABLE TB_COLABORADOR ADD COL_MATRICULA VARCHAR(20);'#13#10 +
    'ALTER TABLE TB_COLABORADOR ADD COL_DEPARTAMENTO VARCHAR(50);'#13#10 +
    'ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA_CADASTRADA CHAR(1) DEFAULT ''N'';'#13#10#13#10 +
    '-- Justificativas e Atestados Médicos'#13#10 +
    'ALTER TABLE TB_PONTO_JUSTIFICATIVA ADD JUS_DOCUMENTO VARCHAR(100);'#13#10 +
    'ALTER TABLE TB_PONTO_JUSTIFICATIVA ADD JUS_STATUS CHAR(1) DEFAULT ''A'';',
    'RUNNING SCRIPT [actVersao105] ...'#13#10 +
    '  ALTER TABLE TB_PONTO_VERSAO_BD ... OK [00:00:00.016]'#13#10 +
    '  ALTER TABLE TB_PONTO_RELOGIO ... OK [00:00:00.012]'#13#10 +
    '  ALTER TABLE TB_PONTO_MARCACAO ... OK [00:00:00.015]'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ... OK [00:00:00.011]'#13#10 +
    '  ALTER TABLE TB_PONTO_JUSTIFICATIVA ... OK [00:00:00.009]'#13#10 +
    'SCRIPT FINALIZADO COM SUCESSO.'
  );

  SincronizarRegistroVersao(
    FDConnection, 6, '1.0.1', 'actVersao106',
    'Integração com Leitor Biométrico Nitgen Hamster DX (Template da Digital do Colaborador)',
    '-- Template (FIR texto NBioBSP) da digital do colaborador'#13#10 +
    'ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA BLOB SUB_TYPE TEXT;'#13#10 +
    'ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA_DATA TIMESTAMP;'#13#10#13#10 +
    '-- Marcações do leitor biométrico: PMA_ORIGEM = ''B'', PMA_TIPO_IDENTIFICACAO = ''BIOMETRIA''',
    'RUNNING SCRIPT [actVersao106] ...'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA ... OK'#13#10 +
    '  ALTER TABLE TB_COLABORADOR ADD COL_BIOMETRIA_DATA ... OK'#13#10 +
    'SCRIPT FINALIZADO COM SUCESSO.'
  );

  ALogMigracao := Format('Base de dados atualizada com sucesso para a versão de schema %d.', [DB_SCHEMA_VERSION]);
end;

function TdmDados.ObterHistoricoVersoes: TBdVersaoArray;
var
  Qry: TFDQuery;
  Count: Integer;
begin
  SetLength(Result, 0);
  if not IsConectado then
    Conectar;
  if not TabelaExiste('TB_PONTO_VERSAO_BD') then
    Exit;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FDConnection;
    Qry.SQL.Text :=
      'SELECT VER_ID, VER_NUMERO, VER_SISTEMA, VER_DATA_HORA, VER_DESCRICAO, ' +
      '       COALESCE(VER_ACAO, ''actVersao'' || VER_NUMERO) AS VER_ACAO, ' +
      '       COALESCE(VER_STATUS, ''A'') AS VER_STATUS, ' +
      '       VER_SCRIPT, VER_PROGRESSO, VER_ERROS ' +
      'FROM TB_PONTO_VERSAO_BD ' +
      'ORDER BY VER_NUMERO DESC, VER_ID DESC';
    Qry.Open;
    Count := 0;
    while not Qry.Eof do
    begin
      Inc(Count);
      SetLength(Result, Count);
      Result[Count - 1].Id := Qry.FieldByName('VER_ID').AsInteger;
      Result[Count - 1].Numero := Qry.FieldByName('VER_NUMERO').AsInteger;
      Result[Count - 1].Sistema := Qry.FieldByName('VER_SISTEMA').AsString;
      Result[Count - 1].DataHora := Qry.FieldByName('VER_DATA_HORA').AsDateTime;
      Result[Count - 1].Descricao := Qry.FieldByName('VER_DESCRICAO').AsString;
      Result[Count - 1].Acao := Qry.FieldByName('VER_ACAO').AsString;
      if Qry.FieldByName('VER_STATUS').AsString <> '' then
        Result[Count - 1].Status := Qry.FieldByName('VER_STATUS').AsString[1]
      else
        Result[Count - 1].Status := 'A';
      Result[Count - 1].Script := Qry.FieldByName('VER_SCRIPT').AsString;
      Result[Count - 1].Progresso := Qry.FieldByName('VER_PROGRESSO').AsString;
      Result[Count - 1].Erros := Qry.FieldByName('VER_ERROS').AsString;
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

end.
