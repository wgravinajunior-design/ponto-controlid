unit uPontoService;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, Data.DB,
  FireDAC.Comp.Client,
  uConfig, uControlIDClient, uDataModule;

type
  TLogCallback = reference to procedure(const AMsg: string; AIsError: Boolean = False);

  TPontoService = class
  private
    FLogCallback: TLogCallback;
    procedure Log(const AMsg: string; AIsError: Boolean = False);
    function CriarClienteParaRelogio(AQryRelogio: TFDQuery): TControlIDClient;
  public
    constructor Create(ALogCallback: TLogCallback = nil);

    function TestarRelogio(ARelogioId: Integer): Boolean;
    function SincronizarHorario(ARelogioId: Integer): Boolean;
    function SincronizarColaboradores(ARelogioId: Integer; const APessoaIds: TArray<Integer>;
      out ASucessos, AFalhas: Integer): Boolean;
    function EnviarColaboradorIndividual(ARelogioId, APessoaId: Integer; const ASenha: string = '';
      ARfid: Int64 = 0; AAdmin: Boolean = False; const ABarras: string = ''): Boolean;
    function RemoverColaboradorDoRelogio(ARelogioId: Integer; APessoaId: Integer): Boolean;
    function LimparTodosColaboradoresDoRelogio(ARelogioId: Integer; out ATotalRemovidos: Integer): Boolean;
    function ImportarUsuariosDoRelogio(ARelogioId: Integer; out AImportados: Integer): Boolean;
    function EnviarEmpregador(ARelogioId: Integer; const ACompany: TControlIDCompany): Boolean;
    function ObterEmpregador(ARelogioId: Integer; out ACompany: TControlIDCompany): Boolean;
    function SincronizarJornadaRelogio(ARelogioId, AJornadaId: Integer;
      const ADesc, AEnt1, ASai1, AEnt2, ASai2: string): Boolean;
    function ColetarMarcacoes(ARelogioId: Integer; out ANovasMarcacoes: Integer): Boolean;
    function ColetarTodosRelogios(out ATotalMarcacoes: Integer): Boolean;

    property LogCallback: TLogCallback read FLogCallback write FLogCallback;
  end;

implementation

{ TPontoService }

constructor TPontoService.Create(ALogCallback: TLogCallback);
begin
  inherited Create;
  FLogCallback := ALogCallback;
end;

procedure TPontoService.Log(const AMsg: string; AIsError: Boolean);
var
  Timestamped: string;
begin
  Timestamped := FormatDateTime('[hh:nn:ss] ', Now) + AMsg;
  if Assigned(FLogCallback) then
    FLogCallback(Timestamped, AIsError);
end;

function TPontoService.CriarClienteParaRelogio(AQryRelogio: TFDQuery): TControlIDClient;
var
  IP, Usuario, Senha: string;
  Porta: Integer;
  UsarSSL: Boolean;
begin
  IP := AQryRelogio.FieldByName('PRE_IP').AsString;
  Porta := AQryRelogio.FieldByName('PRE_PORTA').AsInteger;
  if Porta <= 0 then
    Porta := 80;
  UsarSSL := SameText(AQryRelogio.FieldByName('PRE_USAR_SSL').AsString, 'S');
  Usuario := AQryRelogio.FieldByName('PRE_USUARIO').AsString;
  Senha := AQryRelogio.FieldByName('PRE_SENHA').AsString;

  Result := TControlIDClient.Create(IP, Porta, UsarSSL);
  Result.User := Usuario;
  Result.Password := Senha;
end;

function TPontoService.TestarRelogio(ARelogioId: Integer): Boolean;
var
  Qry: TFDQuery;
  Client: TControlIDClient;
  Nome, Serial, FW, DevId: string;
  DevTime: TDateTime;
begin
  Result := False;
  Qry := dmDados.GetRelogioPorId(ARelogioId);
  try
    if Qry.IsEmpty then
    begin
      Log(Format('⚠️ Não foi possível localizar o cadastro do relógio #%d no banco de dados.', [ARelogioId]), True);
      Exit;
    end;

    Nome := Qry.FieldByName('PRE_NOME').AsString;
    Log(Format('🔍 Testando comunicação com [%s] (%s:%d)...',
      [Nome, Qry.FieldByName('PRE_IP').AsString, Qry.FieldByName('PRE_PORTA').AsInteger]));

    Client := CriarClienteParaRelogio(Qry);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Não foi possível comunicar com o relógio [%s]: %s',
          [Nome, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      Log(Format('🔑 Conexão estabelecida com sucesso com o equipamento [%s]!', [Nome]));

      if Client.GetSystemInformation(Serial, FW, DevId, DevTime) then
      begin
        Log(Format('✅ Equipamento [%s] online e pronto para uso!', [Nome]));
        Log(Format('   📋 Informações: Nº Série: %s | Firmware: %s | Horário do Relógio: %s',
          [Serial, FW, FormatDateTime('dd/mm/yyyy hh:nn:ss', DevTime)]));
        dmDados.AtualizarUltimoLogRelogio(ARelogioId, Qry.FieldByName('PRE_ULTIMO_LOG_ID').AsLargeInt, Serial, FW);
        Result := True;
      end
      else
        Log(Format('⚠️ Conexão OK, mas não foi possível ler os dados do sistema em [%s]: %s',
          [Nome, FormatarErroAmigavel(Client.LastError)]), True);

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    Qry.Free;
  end;
end;

function TPontoService.SincronizarHorario(ARelogioId: Integer): Boolean;
var
  Qry: TFDQuery;
  Client: TControlIDClient;
  Nome: string;
  Agora: TDateTime;
begin
  Result := False;
  Qry := dmDados.GetRelogioPorId(ARelogioId);
  try
    if Qry.IsEmpty then
      Exit;

    Nome := Qry.FieldByName('PRE_NOME').AsString;
    Agora := Now;
    Log(Format('🕒 Sincronizando horário do relógio [%s] com o computador (%s)...',
      [Nome, FormatDateTime('hh:nn:ss', Agora)]));

    Client := CriarClienteParaRelogio(Qry);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Não foi possível autenticar no relógio [%s]: %s',
          [Nome, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      if Client.SetSystemTime(Agora) then
      begin
        Log(Format('✅ Horário do relógio [%s] sincronizado com sucesso para %s!',
          [Nome, FormatDateTime('dd/mm/yyyy hh:nn:ss', Agora)]));
        Result := True;
      end
      else
        Log(Format('❌ Falha ao atualizar o horário em [%s]: %s',
          [Nome, FormatarErroAmigavel(Client.LastError)]), True);

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    Qry.Free;
  end;
end;

function TPontoService.SincronizarColaboradores(ARelogioId: Integer; const APessoaIds: TArray<Integer>;
  out ASucessos, AFalhas: Integer): Boolean;
var
  QryRelogio, QryPessoa: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio, Matricula, NomePessoa: string;
  PessoaId, I: Integer;
  User: TControlIDUser;
  NewId: Int64;
begin
  ASucessos := 0;
  AFalhas := 0;
  Result := False;

  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
      Exit;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;
    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Não foi possível conectar ao relógio [%s] para envio de colaboradores: %s',
          [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      Log(Format('📤 Enviando %d colaborador(es) para o relógio [%s]...',
        [Length(APessoaIds), NomeRelogio]));

      for I := 0 to High(APessoaIds) do
      begin
        PessoaId := APessoaIds[I];
        QryPessoa := dmDados.GetPessoaPorId(PessoaId);
        try
          if not QryPessoa.IsEmpty then
          begin
            NomePessoa := Trim(QryPessoa.FieldByName('PES_RSOCIAL_NOME').AsString);
            Matricula := Trim(QryPessoa.FieldByName('COL_CARTAO_PONTO').AsString);
            if Matricula = '' then
              Matricula := Trim(QryPessoa.FieldByName('COL_PIS').AsString);
            if Matricula = '' then
              Matricula := Trim(QryPessoa.FieldByName('COL_CPF').AsString);
            if Matricula = '' then
              Matricula := IntToStr(PessoaId);

            FillChar(User, SizeOf(User), 0);
            User.Id := PessoaId;
            User.Name := NomePessoa;
            User.Cpf := Trim(QryPessoa.FieldByName('PES_CNPJ_CPF').AsString);
            User.Pis := Trim(QryPessoa.FieldByName('COL_PIS').AsString);
            User.Registration := Matricula;
            User.Bars := Matricula;
            User.Code := StrToInt64Def(Trim(QryPessoa.FieldByName('PES_CODIGO_ACESSO').AsString),
                         StrToInt64Def(Matricula, PessoaId));
            User.Admin := False;

            // Tenta adicionar
            if Client.AddUser(User, NewId) then
            begin
              dmDados.MarcarColaboradorSincronizado(PessoaId);
              Inc(ASucessos);
              Log(Format('  ✅ [%s] cadastrado com sucesso no relógio (Matrícula: %s).', [NomePessoa, Matricula]));
            end
            else
            begin
              // Se já existir, tenta modificar
              if Client.ModifyUser(User) then
              begin
                dmDados.MarcarColaboradorSincronizado(PessoaId);
                Inc(ASucessos);
                Log(Format('  🔄 [%s] dados cadastrais atualizados no relógio (Matrícula: %s).', [NomePessoa, Matricula]));
              end
              else
              begin
                Inc(AFalhas);
                Log(Format('  ⚠️ Não foi possível cadastrar [%s]: %s',
                  [NomePessoa, FormatarErroAmigavel(Client.LastError)]), True);
              end;
            end;
          end;
        finally
          QryPessoa.Free;
        end;
      end;

      if AFalhas = 0 then
        Log(Format('🎉 Todos os %d colaboradores foram sincronizados com sucesso no relógio [%s]!',
          [ASucessos, NomeRelogio]))
      else
        Log(Format('🏁 Envio de colaboradores finalizado em [%s]: %d enviados com sucesso, %d pendência(s).',
          [NomeRelogio, ASucessos, AFalhas]));

      Result := (ASucessos > 0);
      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.EnviarColaboradorIndividual(ARelogioId, APessoaId: Integer; const ASenha: string;
  ARfid: Int64; AAdmin: Boolean; const ABarras: string): Boolean;
var
  QryRelogio, QryPessoa: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio, NomePessoa, CpfPessoa, PisPessoa, Matricula, CodigoAcesso: string;
  User: TControlIDUser;
  NewId: Int64;
begin
  Result := False;
  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
    begin
      Log('❌ Relógio selecionado não encontrado.', True);
      Exit;
    end;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;
    QryPessoa := dmDados.GetPessoaPorId(APessoaId);
    try
      if QryPessoa.IsEmpty then
      begin
        Log('❌ Colaborador não localizado no banco de dados.', True);
        Exit;
      end;

      NomePessoa := Trim(QryPessoa.FieldByName('PES_RSOCIAL_NOME').AsString);
      CpfPessoa := Trim(QryPessoa.FieldByName('PES_CNPJ_CPF').AsString);
      PisPessoa := Trim(QryPessoa.FieldByName('COL_PIS').AsString);
      Matricula := Trim(QryPessoa.FieldByName('COL_CARTAO_PONTO').AsString);
      if Matricula = '' then
        Matricula := IntToStr(APessoaId);
      CodigoAcesso := Trim(QryPessoa.FieldByName('PES_CODIGO_ACESSO').AsString);

      FillChar(User, SizeOf(User), 0);
      User.Id := APessoaId;
      User.Name := NomePessoa;
      User.Cpf := CpfPessoa;
      User.Pis := PisPessoa;
      User.Registration := Matricula;
      if ABarras <> '' then
        User.Bars := ABarras
      else
        User.Bars := Matricula;
      User.Rfid := ARfid;
      User.Code := StrToInt64Def(CodigoAcesso, StrToInt64Def(Matricula, APessoaId));
      User.Password := ASenha;
      User.Admin := AAdmin;

      Client := CriarClienteParaRelogio(QryRelogio);
      try
        if not Client.Login(Client.User, Client.Password) then
        begin
          Log(Format('❌ Não foi possível conectar ao relógio [%s]: %s',
            [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
          Exit;
        end;

        Log(Format('📤 Enviando cadastro de [%s] para o relógio [%s]...', [NomePessoa, NomeRelogio]));

        if Client.AddUser(User, NewId) or Client.ModifyUser(User) then
        begin
          dmDados.MarcarColaboradorSincronizado(APessoaId);
          Log(Format('✅ Colaborador [%s] sincronizado com sucesso no relógio [%s] (Matrícula: %s)!',
            [NomePessoa, NomeRelogio, Matricula]));
          Result := True;
        end
        else
        begin
          Log(Format('❌ Falha ao enviar [%s] para [%s]: %s',
            [NomePessoa, NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        end;

        Client.Logout;
      finally
        Client.Free;
      end;
    finally
      QryPessoa.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.RemoverColaboradorDoRelogio(ARelogioId: Integer; APessoaId: Integer): Boolean;
var
  QryRelogio, QryPessoa: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio: string;
  DelId: Int64;
begin
  Result := False;
  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
      Exit;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;

    DelId := APessoaId;
    QryPessoa := dmDados.GetPessoaPorId(APessoaId);
    try
      if not QryPessoa.IsEmpty then
      begin
        DelId := StrToInt64Def(QryPessoa.FieldByName('COL_PIS').AsString,
                 StrToInt64Def(QryPessoa.FieldByName('PES_CNPJ_CPF').AsString, APessoaId));
      end;
    finally
      QryPessoa.Free;
    end;

    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Não foi possível conectar ao relógio [%s]: %s',
          [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      if Client.DestroyUser(DelId) or Client.DestroyUser(APessoaId) then
      begin
        Log(Format('🗑️ Colaborador (ID %d) removido com sucesso da memória do relógio [%s].',
          [APessoaId, NomeRelogio]));
        dmDados.MarcarColaboradorNaoSincronizado(APessoaId);
        Result := True;
      end
      else
        Log(Format('❌ Não foi possível remover o colaborador (ID %d) de [%s]: %s',
          [APessoaId, NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.LimparTodosColaboradoresDoRelogio(ARelogioId: Integer; out ATotalRemovidos: Integer): Boolean;
var
  QryRelogio: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio: string;
begin
  Result := False;
  ATotalRemovidos := 0;
  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
    begin
      Log('❌ Relógio não encontrado.', True);
      Exit;
    end;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;
    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Falha ao autenticar em [%s]: %s', [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      Log(Format('🧹 Iniciando limpeza de todos os colaboradores do relógio [%s]...', [NomeRelogio]));
      if Client.ClearAllUsers(ATotalRemovidos) then
      begin
        Log(Format('✅ Memória do relógio [%s] limpa com sucesso! Total de %d colaborador(es) removido(s).',
          [NomeRelogio, ATotalRemovidos]));
        Result := True;
      end
      else
      begin
        Log(Format('ℹ️ Não havia colaboradores para remover ou memória já limpa em [%s].', [NomeRelogio]));
        Result := True;
      end;

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.EnviarEmpregador(ARelogioId: Integer; const ACompany: TControlIDCompany): Boolean;
var
  QryRelogio: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio: string;
begin
  Result := False;
  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
    begin
      Log('❌ Relógio não encontrado para envio de empregador.', True);
      Exit;
    end;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;
    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Falha ao autenticar em [%s]: %s', [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      Log(Format('🏢 Enviando dados do empregador [%s] para o relógio [%s]...', [ACompany.Name, NomeRelogio]));
      if Client.SetCompany(ACompany) then
      begin
        Log(Format('✅ Empregador [%s] (CNPJ/CPF %s) atualizado com sucesso no relógio [%s]!',
          [ACompany.Name, ACompany.CpfCnpj, NomeRelogio]));
        Result := True;
      end
      else
        Log(Format('❌ Falha ao gravar empregador em [%s]: %s', [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.ObterEmpregador(ARelogioId: Integer; out ACompany: TControlIDCompany): Boolean;
var
  QryRelogio: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio: string;
begin
  Result := False;
  FillChar(ACompany, SizeOf(ACompany), 0);
  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
    begin
      Log('❌ Relógio não encontrado.', True);
      Exit;
    end;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;
    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Falha ao autenticar em [%s]: %s', [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      if Client.GetCompany(ACompany) then
      begin
        Log(Format('🔍 Dados do empregador consultados no relógio [%s]: %s (CNPJ: %s).',
          [NomeRelogio, ACompany.Name, ACompany.CpfCnpj]));
        Result := True;
      end
      else
        Log(Format('❌ Falha ao ler empregador de [%s]: %s', [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.SincronizarJornadaRelogio(ARelogioId, AJornadaId: Integer;
  const ADesc, AEnt1, ASai1, AEnt2, ASai2: string): Boolean;
var
  QryRelogio: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio: string;
begin
  Result := False;
  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
    begin
      Log('❌ Relógio não encontrado para sincronização de horários.', True);
      Exit;
    end;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;
    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Falha ao autenticar em [%s]: %s', [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      Log(Format('⏰ Sincronizando jornada [%s] (ID %d) e ajustando relógio [%s]...', [ADesc, AJornadaId, NomeRelogio]));
      if Client.SyncTimeZone(AJornadaId, ADesc, AEnt1, ASai1, AEnt2, ASai2) then
      begin
        Client.SetSystemTime(Now);
        Log(Format('✅ Jornada [%s] e data/hora atualizados com sucesso no relógio [%s]!', [ADesc, NomeRelogio]));
        Result := True;
      end
      else
        Log(Format('⚠️ Falha ao registrar jornada em [%s]: %s', [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.ImportarUsuariosDoRelogio(ARelogioId: Integer; out AImportados: Integer): Boolean;
var
  QryRelogio: TFDQuery;
  Client: TControlIDClient;
  Users: TArray<TControlIDUser>;
  I: Integer;
begin
  AImportados := 0;
  Result := False;

  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
      Exit;

    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Não foi possível conectar ao relógio para ler usuários: %s',
          [FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      if Client.GetUsers(Users) then
      begin
        AImportados := Length(Users);
        if AImportados = 0 then
          Log(Format('ℹ️ O relógio [%s] está sem colaboradores cadastrados na memória.',
            [QryRelogio.FieldByName('PRE_NOME').AsString]))
        else
        begin
          Log(Format('📋 Leitura concluída: %d colaborador(es) cadastrado(s) no relógio [%s]:',
            [AImportados, QryRelogio.FieldByName('PRE_NOME').AsString]));
          for I := 0 to High(Users) do
            Log(Format('   👤 ID: %d | Nome: %s | Matrícula: %s',
              [Users[I].Id, Users[I].Name, Users[I].Registration]));
        end;
        Result := True;
      end
      else
        Log(Format('❌ Não foi possível obter os usuários do relógio [%s]: %s',
          [QryRelogio.FieldByName('PRE_NOME').AsString, FormatarErroAmigavel(Client.LastError)]), True);

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.ColetarMarcacoes(ARelogioId: Integer; out ANovasMarcacoes: Integer): Boolean;
var
  QryRelogio: TFDQuery;
  Client: TControlIDClient;
  NomeRelogio, ModoColeta, Serial, FW, DevId: string;
  UltimoLogId, MaxLogId: Int64;
  Logs: TArray<TControlIDAccessLog>;
  Afds: TArray<TAfdRecord>;
  AfdContent: string;
  I: Integer;
  PessoaId: Integer;
  DevTime: TDateTime;
  Is671: Boolean;
begin
  ANovasMarcacoes := 0;
  Result := False;

  QryRelogio := dmDados.GetRelogioPorId(ARelogioId);
  try
    if QryRelogio.IsEmpty then
      Exit;

    NomeRelogio := QryRelogio.FieldByName('PRE_NOME').AsString;
    ModoColeta := UpperCase(Trim(QryRelogio.FieldByName('PRE_MODO_COLETA').AsString));
    if ModoColeta = '' then
      ModoColeta := 'API';

    UltimoLogId := QryRelogio.FieldByName('PRE_ULTIMO_LOG_ID').AsLargeInt;
    MaxLogId := UltimoLogId;

    Log(Format('📥 Buscando novas marcações no relógio [%s] (a partir do registro #%d)...',
      [NomeRelogio, UltimoLogId]));

    Client := CriarClienteParaRelogio(QryRelogio);
    try
      if not Client.Login(Client.User, Client.Password) then
      begin
        Log(Format('❌ Não foi possível conectar ao relógio [%s]: %s',
          [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
        Exit;
      end;

      Client.GetSystemInformation(Serial, FW, DevId, DevTime);

      // MODO 1: Coleta via API (access_logs)
      if ModoColeta = 'API' then
      begin
        if Client.GetAccessLogs(UltimoLogId, Logs) then
        begin
          for I := 0 to High(Logs) do
          begin
            PessoaId := Logs[I].UserId;
            // Se o ID for > 0, tenta validar se existe no banco
            if PessoaId > 0 then
            begin
              if dmDados.GetPessoaPorId(PessoaId).IsEmpty then
                PessoaId := 0;
            end;

            if dmDados.GravarMarcacao(PessoaId, ARelogioId, Logs[I].Time, Logs[I].Event,
              Logs[I].Id, 'C', Logs[I].Id, '', '', 'Batida Ponto', 'Control iD API') then
            begin
              Inc(ANovasMarcacoes);
              if Logs[I].Id > MaxLogId then
                MaxLogId := Logs[I].Id;
            end;
          end;

          if MaxLogId > UltimoLogId then
            dmDados.AtualizarUltimoLogRelogio(ARelogioId, MaxLogId, Serial, FW);

          if ANovasMarcacoes > 0 then
            Log(Format('✅ Coleta finalizada com sucesso em [%s]: %d nova(s) batida(s) de ponto gravada(s)!',
              [NomeRelogio, ANovasMarcacoes]))
          else
            Log(Format('ℹ️ O relógio [%s] já está em dia (nenhuma nova batida encontrada).',
              [NomeRelogio]));
          Result := True;
        end
        else
          Log(Format('❌ Falha ao obter registros de acesso em [%s]: %s',
            [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
      end
      // MODO 2: Coleta via AFD (REP Oficial Portaria 671 / 1510)
      else
      begin
        Is671 := (ModoColeta = 'AFD_671') or (ModoColeta = 'AFD');
        if Client.GetAFD(UltimoLogId + 1, Is671, AfdContent) then
        begin
          Afds := TControlIDClient.ParseAFD(AfdContent);
          for I := 0 to High(Afds) do
          begin
            PessoaId := dmDados.BuscarPessoaPorPisOuCpf(Afds[I].Pis, Afds[I].Cpf);

            if dmDados.GravarMarcacao(PessoaId, ARelogioId, Afds[I].DataHora, 7,
              Afds[I].Nsr, 'C', Afds[I].Nsr, Afds[I].Pis, Afds[I].Cpf, 'Batida Ponto', 'REP AFD') then
            begin
              Inc(ANovasMarcacoes);
              if Afds[I].Nsr > MaxLogId then
                MaxLogId := Afds[I].Nsr;
            end;
          end;

          if MaxLogId > UltimoLogId then
            dmDados.AtualizarUltimoLogRelogio(ARelogioId, MaxLogId, Serial, FW);

          if ANovasMarcacoes > 0 then
            Log(Format('✅ Coleta via AFD finalizada em [%s]: %d batida(s) processada(s) e gravada(s)!',
              [NomeRelogio, ANovasMarcacoes]))
          else
            Log(Format('ℹ️ O relógio [%s] já está em dia (nenhuma nova batida no arquivo AFD).',
              [NomeRelogio]));
          Result := True;
        end
        else
          Log(Format('❌ Falha ao exportar registros AFD em [%s]: %s',
            [NomeRelogio, FormatarErroAmigavel(Client.LastError)]), True);
      end;

      Client.Logout;
    finally
      Client.Free;
    end;
  finally
    QryRelogio.Free;
  end;
end;

function TPontoService.ColetarTodosRelogios(out ATotalMarcacoes: Integer): Boolean;
var
  Qry: TFDQuery;
  Qtd: Integer;
begin
  ATotalMarcacoes := 0;
  Result := True;
  Qry := dmDados.GetRelogios(True); // apenas ativos
  try
    if Qry.IsEmpty then
    begin
      Log('ℹ️ Nenhum relógio de ponto ativo configurado para coleta.');
      Exit;
    end;

    while not Qry.Eof do
    begin
      Qtd := 0;
      if ColetarMarcacoes(Qry.FieldByName('PRE_ID').AsInteger, Qtd) then
        ATotalMarcacoes := ATotalMarcacoes + Qtd
      else
        Result := False;
      Qry.Next;
    end;

    if ATotalMarcacoes > 0 then
      Log(Format('🎉 Coleta geral finalizada: %d nova(s) batida(s) importada(s) no total!', [ATotalMarcacoes]))
    else
      Log('ℹ️ Coleta geral finalizada: todos os relógios estão em dia (nenhuma batida pendente).');
  finally
    Qry.Free;
  end;
end;

end.
