unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes, System.Types, System.IOUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  uConfig, uControlIDClient, uDataModule, uPontoService, uPontoCalculoService, uSkiaButtons,
  uFrmUpdate;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    imgTopLogo: TImage;
    lblTitle: TLabel;
    lblHeaderVersion: TLabel;
    btnTopConfig: TButton;
    btnTopUpdate: TButton;
    pnlQuickActions: TPanel;
    btnQuickTest: TButton;
    btnQuickSyncTime: TButton;
    btnQuickCollect: TButton;
    btnQuickAuto: TButton;
    pgcMain: TPageControl;
    tabDashboard: TTabSheet;
    pnlCards: TPanel;
    pnlCard1: TPanel;
    lblCard1Title: TLabel;
    lblCard1Val: TLabel;
    pnlCard2: TPanel;
    lblCard2Title: TLabel;
    lblCard2Val: TLabel;
    pnlCard3: TPanel;
    lblCard3Title: TLabel;
    lblCard3Val: TLabel;
    pnlCard4: TPanel;
    lblCard4Title: TLabel;
    lblCard4Val: TLabel;
    pnlLogHeader: TPanel;
    lblLogTitle: TLabel;
    btnClearLog: TButton;
    btnSaveLog: TButton;
    mmoLog: TMemo;
    tabRelogios: TTabSheet;
    pnlRelogiosGrid: TPanel;
    dbgRelogios: TDBGrid;
    pnlRelogiosTop: TPanel;
    btnNovoRelogio: TButton;
    btnAtualizarRelogios: TButton;
    splRelogio: TSplitter;
    pnlRelogioForm: TPanel;
    lblFormTitle: TLabel;
    lblRelNome: TLabel;
    edtRelNome: TEdit;
    lblRelIP: TLabel;
    edtRelIP: TEdit;
    lblRelPorta: TLabel;
    edtRelPorta: TEdit;
    chkRelSSL: TCheckBox;
    lblRelUser: TLabel;
    edtRelUser: TEdit;
    lblRelSenha: TLabel;
    edtRelSenha: TEdit;
    lblRelModelo: TLabel;
    cmbRelModelo: TComboBox;
    lblRelModoColeta: TLabel;
    cmbRelModoColeta: TComboBox;
    chkRelAtivo: TCheckBox;
    grpInfoHardware: TGroupBox;
    lblSerial: TLabel;
    edtSerial: TEdit;
    lblFW: TLabel;
    edtFW: TEdit;
    lblUltimoLog: TLabel;
    edtUltimoLog: TEdit;
    pnlRelogioBtns: TPanel;
    btnSalvarRelogio: TButton;
    btnExcluirRelogio: TButton;
    btnTestarEsteRelogio: TButton;
    btnSincHoraEste: TButton;
    btnColetarEste: TButton;
    tabColaboradores: TTabSheet;
    splColaborador: TSplitter;
    pnlColaboradoresGrid: TPanel;
    pnlColabTop: TPanel;
    lblBuscaColab: TLabel;
    edtBuscaColab: TEdit;
    btnAtualizarColab: TButton;
    btnEnviarTodosPendentes: TButton;
    btnImportarDoRelogio: TButton;
    btnLimparTodosRelogio: TButton;
    btnEnviarColabRelogio: TButton;
    btnRemoverColabRelogio: TButton;
    dbgColaboradores: TDBGrid;
    pnlColaboradorForm: TPanel;
    lblColabFormTitle: TLabel;
    lblColabNome: TLabel;
    edtColabNome: TEdit;
    lblColabCPF: TLabel;
    edtColabCPF: TEdit;
    lblColabPIS: TLabel;
    edtColabPIS: TEdit;
    lblColabMatricula: TLabel;
    edtColabMatricula: TEdit;
    lblColabFuncao: TLabel;
    edtColabFuncao: TEdit;
    lblColabCodigo: TLabel;
    edtColabCodigo: TEdit;
    lblColabSenha: TLabel;
    edtColabSenha: TEdit;
    lblColabRFID: TLabel;
    edtColabRFID: TEdit;
    lblColabBarras: TLabel;
    edtColabBarras: TEdit;
    lblColabHorario: TLabel;
    cmbColabHorario: TComboBox;
    chkColabAdmin: TCheckBox;
    chkColabAtivo: TCheckBox;
    grpInfoSinc: TGroupBox;
    lblColabRelogioDestino: TLabel;
    cmbColabRelogioDestino: TComboBox;
    lblColabSyncStatusLabel: TLabel;
    lblColabSyncStatus: TLabel;
    lblColabUltimaSyncLabel: TLabel;
    lblColabUltimaSync: TLabel;
    pnlColabBtns: TPanel;
    btnSalvarColab: TButton;
    btnSalvarEnviarColab: TButton;
    btnNovoColab: TButton;
    btnRemoverColabForm: TButton;
    btnExcluirColabBanco: TButton;
    tabMarcacoes: TTabSheet;
    pnlMarcacoesFiltro: TPanel;
    lblDtIni: TLabel;
    dtpIni: TDateTimePicker;
    lblDtFim: TLabel;
    dtpFim: TDateTimePicker;
    lblFiltroRelogio: TLabel;
    cmbFiltroRelogio: TComboBox;
    btnFiltrarMarcacoes: TButton;
    btnEditarMarcacao: TButton;
    btnNovaMarcacao: TButton;
    btnExportarAFD: TButton;
    btnExcluirMarcacao: TButton;
    lblTotalMarcacoesGrid: TLabel;
    dbgMarcacoes: TDBGrid;
    tabConfig: TTabSheet;
    btnConfigVoltar: TButton;
    grpBanco: TGroupBox;
    lblCfgServer: TLabel;
    edtCfgServer: TEdit;
    lblCfgPorta: TLabel;
    edtCfgPorta: TEdit;
    lblCfgDatabase: TLabel;
    edtCfgDatabase: TEdit;
    lblCfgUser: TLabel;
    edtCfgUser: TEdit;
    lblCfgPass: TLabel;
    edtCfgPass: TEdit;
    lblCfgVendor: TLabel;
    edtCfgVendor: TEdit;
    grpColetaAuto: TGroupBox;
    lblIntervalo: TLabel;
    edtIntervalo: TEdit;
    chkAutoIniciar: TCheckBox;
    btnSalvarConfig: TButton;
    btnTestarConexaoFB: TButton;
    grpEmpregador: TGroupBox;
    lblEmpTipoDoc: TLabel;
    cmbEmpTipoDoc: TComboBox;
    lblEmpCpfCnpj: TLabel;
    edtEmpCpfCnpj: TEdit;
    lblEmpRazaoSocial: TLabel;
    edtEmpRazaoSocial: TEdit;
    lblEmpCpfResp: TLabel;
    edtEmpCpfResp: TEdit;
    lblEmpCEI: TLabel;
    edtEmpCEI: TEdit;
    lblEmpEndereco: TLabel;
    edtEmpEndereco: TEdit;
    lblEmpRelogioDestino: TLabel;
    cmbEmpRelogioDestino: TComboBox;
    btnCarregarEmpBanco: TButton;
    btnSalvarEmpBanco: TButton;
    btnEnviarEmpRelogio: TButton;
    btnLerEmpRelogio: TButton;
    lblEmpInfo: TLabel;
    tabHorarios: TTabSheet;
    pnlHorariosGrid: TPanel;
    pnlHorariosTop: TPanel;
    btnNovoHorario: TButton;
    btnAtualizarHorarios: TButton;
    dbgHorarios: TDBGrid;
    splHorario: TSplitter;
    pnlHorarioForm: TPanel;
    lblHorFormTitle: TLabel;
    lblHorDescricao: TLabel;
    edtHorDescricao: TEdit;
    lblHorEntrada1: TLabel;
    edtHorEntrada1: TEdit;
    lblHorSaida1: TLabel;
    edtHorSaida1: TEdit;
    lblHorEntrada2: TLabel;
    edtHorEntrada2: TEdit;
    lblHorSaida2: TLabel;
    edtHorSaida2: TEdit;
    lblHorTolerancia: TLabel;
    edtHorTolerancia: TEdit;
    lblHorCarga: TLabel;
    edtHorCarga: TEdit;
    chkHorCompensaSab: TCheckBox;
    chkHorTrabalhaSab: TCheckBox;
    lblHorSabEntrada1: TLabel;
    edtHorSabEntrada1: TEdit;
    lblHorSabSaida1: TLabel;
    edtHorSabSaida1: TEdit;
    chkHorAtivo: TCheckBox;
    pnlHorarioBtns: TPanel;
    btnSalvarHorario: TButton;
    btnSalvarEnviarHorario: TButton;
    btnExcluirHorario: TButton;
    btnNovoHorarioForm: TButton;
    tabEspelho: TTabSheet;
    pnlEspelhoTop: TPanel;
    lblEspelhoColab: TLabel;
    cmbEspelhoColab: TComboBox;
    lblEspelhoPeriodo: TLabel;
    dtpEspelhoIni: TDateTimePicker;
    lblEspelhoAte: TLabel;
    dtpEspelhoFim: TDateTimePicker;
    btnCalcularEspelho: TButton;
    btnLancarJustificativa: TButton;
    btnExportarEspelhoHTML: TButton;
    btnCorrigirBatidaEspelho: TButton;
    grdEspelho: TStringGrid;
    pnlEspelhoResumo: TPanel;
    pnlCardEsp1: TPanel;
    lblCardEsp1Title: TLabel;
    lblCardEsp1Val: TLabel;
    pnlCardEsp2: TPanel;
    lblCardEsp2Title: TLabel;
    lblCardEsp2Val: TLabel;
    pnlCardEsp3: TPanel;
    lblCardEsp3Title: TLabel;
    lblCardEsp3Val: TLabel;
    pnlCardEsp4: TPanel;
    lblCardEsp4Title: TLabel;
    lblCardEsp4Val: TLabel;
    pnlCardEsp5: TPanel;
    lblCardEsp5Title: TLabel;
    lblCardEsp5Val: TLabel;
    pnlFooter: TPanel;
    pnlFooterLine: TPanel;
    lblFootVersion: TLabel;
    lblFootSep1: TLabel;
    lblFootColeta: TLabel;
    lblFootEmpregador: TLabel;
    tmrAutoColeta: TTimer;
    dlgSave: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrAutoColetaTimer(Sender: TObject);

    // Ações Rápidas
    procedure btnQuickTestClick(Sender: TObject);
    procedure btnQuickSyncTimeClick(Sender: TObject);
    procedure btnQuickCollectClick(Sender: TObject);
    procedure btnQuickAutoClick(Sender: TObject);

    // Log
    procedure btnClearLogClick(Sender: TObject);
    procedure btnSaveLogClick(Sender: TObject);

    // Relógios
    procedure btnNovoRelogioClick(Sender: TObject);
    procedure btnAtualizarRelogiosClick(Sender: TObject);
    procedure dbgRelogiosCellClick(Column: TColumn);
    procedure btnSalvarRelogioClick(Sender: TObject);
    procedure btnExcluirRelogioClick(Sender: TObject);
    procedure btnTestarEsteRelogioClick(Sender: TObject);
    procedure btnSincHoraEsteClick(Sender: TObject);
    procedure btnColetarEsteClick(Sender: TObject);

    // Colaboradores
    procedure btnAtualizarColabClick(Sender: TObject);
    procedure edtBuscaColabChange(Sender: TObject);
    procedure btnEnviarColabRelogioClick(Sender: TObject);
    procedure btnRemoverColabRelogioClick(Sender: TObject);
    procedure btnEnviarTodosPendentesClick(Sender: TObject);
    procedure btnImportarDoRelogioClick(Sender: TObject);
    procedure btnLimparTodosRelogioClick(Sender: TObject);
    procedure dbgColaboradoresCellClick(Column: TColumn);
    procedure btnSalvarColabClick(Sender: TObject);
    procedure btnSalvarEnviarColabClick(Sender: TObject);
    procedure btnNovoColabClick(Sender: TObject);
    procedure btnRemoverColabFormClick(Sender: TObject);
    procedure btnExcluirColabBancoClick(Sender: TObject);

    // Marcações
    procedure btnFiltrarMarcacoesClick(Sender: TObject);
    procedure btnEditarMarcacaoClick(Sender: TObject);
    procedure btnNovaMarcacaoClick(Sender: TObject);
    procedure btnExportarAFDClick(Sender: TObject);
    procedure btnExcluirMarcacaoClick(Sender: TObject);

    // Configurações & Empregador
    procedure btnSalvarConfigClick(Sender: TObject);
    procedure btnTestarConexaoFBClick(Sender: TObject);
    procedure btnCarregarEmpBancoClick(Sender: TObject);
    procedure btnSalvarEmpBancoClick(Sender: TObject);
    procedure btnEnviarEmpRelogioClick(Sender: TObject);
    procedure btnLerEmpRelogioClick(Sender: TObject);
    procedure pgcMainChange(Sender: TObject);

    // Horários & Jornadas
    procedure btnNovoHorarioClick(Sender: TObject);
    procedure btnAtualizarHorariosClick(Sender: TObject);
    procedure btnSalvarHorarioClick(Sender: TObject);
    procedure btnSalvarEnviarHorarioClick(Sender: TObject);
    procedure btnExcluirHorarioClick(Sender: TObject);
    procedure dbgHorariosCellClick(Column: TColumn);

    // Espelho de Ponto
    procedure btnCalcularEspelhoClick(Sender: TObject);
    procedure btnLancarJustificativaClick(Sender: TObject);
    procedure btnCorrigirBatidaEspelhoClick(Sender: TObject);
    procedure btnExportarEspelhoHTMLClick(Sender: TObject);
    procedure grdEspelhoDrawCell(Sender: TObject; ACol, ARow: Longint; Rect: TRect; State: TGridDrawState);

    // Visual e Desenho das Grids
    procedure dbgGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure FormResize(Sender: TObject);

    // Ações de Topo (Configurações e Atualizações)
    procedure btnTopConfigClick(Sender: TObject);
    procedure btnTopUpdateClick(Sender: TObject);
    procedure btnConfigVoltarClick(Sender: TObject);
  private
    FPontoService: TPontoService;
    FdsRelogios: TDataSource;
    FdsColaboradores: TDataSource;
    FdsMarcacoes: TDataSource;
    FdsHorarios: TDataSource;
    FSelectedRelogioId: Integer;
    FSelectedColabId: Integer;
    FSelectedHorarioId: Integer;
    FUltimoEspelho: TEspelhoPonto;
    FPreviousTab: TTabSheet;
    FLatestUpdateInfo: TUpdateInfo;

    procedure ChecarAtualizacaoSistemaAsync;
    procedure LogMessage(const AMsg: string; AIsError: Boolean = False);
    procedure CarregarConfigNaTela;
    procedure AtualizarDashboard;
    procedure CarregarRelogios;
    procedure CarregarColaboradores;
    procedure CarregarMarcacoes;
    procedure CarregarHorarios;
    procedure ConfigurarGridHorarios;
    procedure LimparFormHorario;
    procedure PreencherFormHorario(AQry: TDataSet);
    procedure CarregarComboHorariosColab;
    procedure CarregarComboColaboradoresEspelho;
    procedure PreencherGridEspelho(AEspelho: TEspelhoPonto);
    procedure CriarBotoesSkia;
    procedure ConfigurarGridRelogios;
    procedure ConfigurarGridColaboradores;
    procedure ConfigurarGridMarcacoes;
    procedure ArredondarControles;
    procedure LimparFormRelogio;
    procedure PreencherFormRelogio(AQry: TFDQuery);
    function ObterRelogioAtivoId: Integer;
    procedure LimparFormColaborador;
    procedure PreencherFormColaborador(AQry: TDataSet);
    procedure CarregarRelogiosNoComboDestino;
    procedure AtualizarStatusColeta(const ATexto: string; AAtiva: Boolean = False);
    procedure AtualizarStatusMsg(const AMsg: string);
    procedure AtualizarEmpregadorRodape(const ARazao, ACnpj: string);
  public
    // Botões Modernos Skia com Emojis Coloridos
    skTopConfig: TSkModernButton;
    skTopUpdate: TSkModernButton;
    skConfigVoltar: TSkModernButton;
    skQuickTest: TSkModernButton;
    skQuickSyncTime: TSkModernButton;
    skQuickCollect: TSkModernButton;
    skQuickAuto: TSkModernButton;
    skClearLog: TSkModernButton;
    skSaveLog: TSkModernButton;
    skNovoRelogio: TSkModernButton;
    skAtualizarRelogios: TSkModernButton;
    skSalvarRelogio: TSkModernButton;
    skExcluirRelogio: TSkModernButton;
    skTestarEsteRelogio: TSkModernButton;
    skSincHoraEste: TSkModernButton;
    skColetarEste: TSkModernButton;
    skAtualizarColab: TSkModernButton;
    skEnviarColabRelogio: TSkModernButton;
    skRemoverColabRelogio: TSkModernButton;
    skEnviarTodosPendentes: TSkModernButton;
    skImportarDoRelogio: TSkModernButton;
    skLimparTodosRelogio: TSkModernButton;
    skSalvarColab: TSkModernButton;
    skSalvarEnviarColab: TSkModernButton;
    skNovoColab: TSkModernButton;
    skRemoverColabForm: TSkModernButton;
    skExcluirColabBanco: TSkModernButton;
    skFiltrarMarcacoes: TSkModernButton;
    skEditarMarcacao: TSkModernButton;
    skNovaMarcacao: TSkModernButton;
    skExportarAFD: TSkModernButton;
    skExcluirMarcacao: TSkModernButton;
    skSalvarConfig: TSkModernButton;
    skTestarConexaoFB: TSkModernButton;
    skCarregarEmpBanco: TSkModernButton;
    skSalvarEmpBanco: TSkModernButton;
    skEnviarEmpRelogio: TSkModernButton;
    skLerEmpRelogio: TSkModernButton;
    skNovoHorario: TSkModernButton;
    skAtualizarHorarios: TSkModernButton;
    skSalvarHorario: TSkModernButton;
    skSalvarEnviarHorario: TSkModernButton;
    skExcluirHorario: TSkModernButton;
    skNovoHorarioForm: TSkModernButton;
    skCalcularEspelho: TSkModernButton;
    skLancarJustificativa: TSkModernButton;
    skCorrigirBatidaEspelho: TSkModernButton;
    skExportarEspelhoHTML: TSkModernButton;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  WindowState := wsMaximized;

  // Carregar ícone da aplicação e janela (Desktop e Barra de Tarefas)
  try
    if FileExists(ExtractFilePath(Application.ExeName) + 'PontoControlID_Icon.ico') then
    begin
      Icon.LoadFromFile(ExtractFilePath(Application.ExeName) + 'PontoControlID_Icon.ico');
      Application.Icon.LoadFromFile(ExtractFilePath(Application.ExeName) + 'PontoControlID_Icon.ico');
    end
    else
    begin
      Icon.Handle := LoadIcon(HInstance, 'MAINICON');
      Application.Icon.Handle := LoadIcon(HInstance, 'MAINICON');
    end;

    if Icon.Handle <> 0 then
    begin
      SendMessage(Handle, WM_SETICON, 1 {ICON_BIG}, Icon.Handle);
      SendMessage(Handle, WM_SETICON, 0 {ICON_SMALL}, Icon.Handle);
      SetClassLong(Handle, -14 {GCL_HICON}, Icon.Handle);
      SetClassLong(Handle, -34 {GCL_HICONSM}, Icon.Handle);
    end;
  except
  end;

  // Carregar logo visual no cabeçalho superior esquerdo
  try
    if FileExists(ExtractFilePath(Application.ExeName) + 'app_logo.png') then
      imgTopLogo.Picture.LoadFromFile(ExtractFilePath(Application.ExeName) + 'app_logo.png')
    else if FileExists(ExtractFilePath(Application.ExeName) + 'logo.jpg') then
      imgTopLogo.Picture.LoadFromFile(ExtractFilePath(Application.ExeName) + 'logo.jpg');
  except
  end;

  FPontoService := TPontoService.Create(LogMessage);

  FdsRelogios := TDataSource.Create(Self);
  dbgRelogios.DataSource := FdsRelogios;

  FdsColaboradores := TDataSource.Create(Self);
  dbgColaboradores.DataSource := FdsColaboradores;

  FdsMarcacoes := TDataSource.Create(Self);
  dbgMarcacoes.DataSource := FdsMarcacoes;

  FdsHorarios := TDataSource.Create(Self);
  dbgHorarios.DataSource := FdsHorarios;

  FSelectedRelogioId := 0;
  FSelectedColabId := 0;
  FSelectedHorarioId := 0;
  FUltimoEspelho := nil;

  dtpIni.Date := StartOfTheMonth(Date);
  dtpFim.Date := Date;

  dtpEspelhoIni.Date := StartOfTheMonth(Date);
  dtpEspelhoFim.Date := EndOfTheMonth(Date);

  // Inicializar cabeçalhos e larguras do grid de Espelho de Ponto
  grdEspelho.Cells[0, 0] := 'Data';
  grdEspelho.Cells[1, 0] := 'Dia da Semana';
  grdEspelho.Cells[2, 0] := '1ª Entrada';
  grdEspelho.Cells[3, 0] := '1ª Saída';
  grdEspelho.Cells[4, 0] := '2ª Entrada';
  grdEspelho.Cells[5, 0] := '2ª Saída';
  grdEspelho.Cells[6, 0] := 'Outras Batidas';
  grdEspelho.Cells[7, 0] := 'Carga Prevista';
  grdEspelho.Cells[8, 0] := 'Horas Realizadas';
  grdEspelho.Cells[9, 0] := 'Horas Extras';
  grdEspelho.Cells[10, 0] := 'Faltas e Atrasos';
  grdEspelho.Cells[11, 0] := 'Saldo Diário';
  grdEspelho.Cells[12, 0] := 'Ocorrência / Justificativa Legal';

  grdEspelho.ColWidths[0] := 85;
  grdEspelho.ColWidths[1] := 105;
  grdEspelho.ColWidths[2] := 85;
  grdEspelho.ColWidths[3] := 85;
  grdEspelho.ColWidths[4] := 85;
  grdEspelho.ColWidths[5] := 85;
  grdEspelho.ColWidths[6] := 105;
  grdEspelho.ColWidths[7] := 95;
  grdEspelho.ColWidths[8] := 115;
  grdEspelho.ColWidths[9] := 95;
  grdEspelho.ColWidths[10] := 110;
  grdEspelho.ColWidths[11] := 95;
  grdEspelho.ColWidths[12] := 450;

  CriarBotoesSkia;
  LimparFormColaborador;
  LimparFormHorario;
  ConfigurarGridRelogios;
  ConfigurarGridColaboradores;
  ConfigurarGridMarcacoes;
  ConfigurarGridHorarios;

  CarregarConfigNaTela;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  Err: string;
begin
  WindowState := wsMaximized;
  ShowWindow(Handle, SW_MAXIMIZE);
  ArredondarControles;
  lblHeaderVersion.Caption := 'v' + APP_VERSION;
  lblFootVersion.Caption := '🏷️ v' + APP_VERSION;
  AtualizarStatusColeta('🔄 Coleta: Desativada', False);

  if Icon.Handle <> 0 then
  begin
    SendMessage(Handle, WM_SETICON, 1, Icon.Handle);
    SendMessage(Handle, WM_SETICON, 0, Icon.Handle);
  end;

  if dmDados.TestarConexao(Err) then
  begin
    if dmDados.LastMigracaoLog <> '' then
      LogMessage('📦 ' + dmDados.LastMigracaoLog);
    CarregarRelogios;
    CarregarRelogiosNoComboDestino;
    CarregarHorarios;
    CarregarComboHorariosColab;
    CarregarColaboradores;
    CarregarComboColaboradoresEspelho;
    CarregarMarcacoes;
    AtualizarDashboard;
    btnCarregarEmpBancoClick(nil);
    ChecarAtualizacaoSistemaAsync;

    if FindCmdLineSwitch('tab_colab') then
      pgcMain.ActivePage := tabColaboradores
    else if FindCmdLineSwitch('tab_marc') then
      pgcMain.ActivePage := tabMarcacoes
    else if FindCmdLineSwitch('tab_cfg') then
      pgcMain.ActivePage := tabConfig
    else if FindCmdLineSwitch('tab_hor') then
      pgcMain.ActivePage := tabHorarios
    else if FindCmdLineSwitch('tab_esp') then
      pgcMain.ActivePage := tabEspelho
    else if FindCmdLineSwitch('tab_rel') then
      pgcMain.ActivePage := tabRelogios;

    if AppConfig.ControlID.AutoIniciarColeta then
    begin
      tmrAutoColeta.Interval := AppConfig.ControlID.IntervaloColetaSegundos * 1000;
      tmrAutoColeta.Enabled := True;
      if Assigned(skQuickAuto) then
      begin
        skQuickAuto.Caption := '🔄 Auto: ON';
        skQuickAuto.Kind := sbkSuccess;
      end;
      btnQuickAuto.Caption := 'Auto: ON';
      AtualizarStatusColeta(Format('🔄 Coleta: Ativa (%ds)', [AppConfig.ControlID.IntervaloColetaSegundos]), True);
    end;
  end
  else
  begin
    LogMessage('⚠️ Não foi possível conectar ao banco de dados Firebird: ' + FormatarErroAmigavel(Err), True);
    ShowMessage('Atenção: Verifique os parâmetros de conexão com o banco Firebird na aba Configurações.'#13#10 + Err);
    pgcMain.ActivePage := tabConfig;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrAutoColeta.Enabled := False;
  if Assigned(FUltimoEspelho) then
  begin
    FUltimoEspelho.Free;
    FUltimoEspelho := nil;
  end;
  FPontoService.Free;
end;

procedure TfrmMain.LogMessage(const AMsg: string; AIsError: Boolean);
var
  FormattedMsg: string;
begin
  if AMsg.StartsWith('[') then
    FormattedMsg := AMsg
  else
    FormattedMsg := FormatDateTime('[hh:nn:ss] ', Now) + AMsg;

  mmoLog.Lines.Add(FormattedMsg);
  AtualizarStatusMsg(AMsg);
end;

procedure TfrmMain.AtualizarStatusColeta(const ATexto: string; AAtiva: Boolean);
begin
  if Assigned(lblFootColeta) then
  begin
    lblFootColeta.Caption := ATexto;
    if AAtiva then
      lblFootColeta.Font.Color := $0066FF66
    else
      lblFootColeta.Font.Color := 16297272;
  end;
end;

procedure TfrmMain.AtualizarStatusMsg(const AMsg: string);
begin
  // Mensagem de status no rodapé removida conforme solicitado pelo usuário
end;

procedure TfrmMain.AtualizarEmpregadorRodape(const ARazao, ACnpj: string);
var
  DocFmt, Digits, RazaoLimpa: string;
begin
  if not Assigned(lblFootEmpregador) then Exit;

  Digits := OnlyDigits(ACnpj);
  if Length(Digits) = 14 then
    DocFmt := Format('%s.%s.%s/%s-%s', [Copy(Digits, 1, 2), Copy(Digits, 3, 3), Copy(Digits, 6, 3), Copy(Digits, 9, 4), Copy(Digits, 13, 2)])
  else if Length(Digits) = 11 then
    DocFmt := Format('%s.%s.%s-%s', [Copy(Digits, 1, 3), Copy(Digits, 4, 3), Copy(Digits, 7, 3), Copy(Digits, 10, 2)])
  else
    DocFmt := ACnpj;

  RazaoLimpa := Trim(ARazao);
  if RazaoLimpa <> '' then
  begin
    if Trim(DocFmt) <> '' then
      lblFootEmpregador.Caption := Format('🏢 %s   •   CNPJ: %s', [RazaoLimpa, DocFmt])
    else
      lblFootEmpregador.Caption := Format('🏢 %s', [RazaoLimpa]);
  end
  else
    lblFootEmpregador.Caption := '🏢 Empregador não cadastrado';
end;

procedure TfrmMain.CarregarConfigNaTela;
begin
  edtCfgServer.Text := AppConfig.Firebird.Server;
  edtCfgPorta.Text := IntToStr(AppConfig.Firebird.Port);
  edtCfgDatabase.Text := AppConfig.Firebird.Database;
  edtCfgUser.Text := AppConfig.Firebird.User;
  edtCfgPass.Text := AppConfig.Firebird.Password;
  edtCfgVendor.Text := AppConfig.Firebird.VendorLib;

  edtIntervalo.Text := IntToStr(AppConfig.ControlID.IntervaloColetaSegundos);
  chkAutoIniciar.Checked := AppConfig.ControlID.AutoIniciarColeta;
end;

procedure TfrmMain.AtualizarDashboard;
var
  TotalRel, TotalMarc, TotalColab: Integer;
begin
  if dmDados.GetTotalRelogiosAtivos(TotalRel) then
    lblCard1Val.Caption := IntToStr(TotalRel);

  if dmDados.GetTotalMarcacoesHoje(TotalMarc) then
    lblCard2Val.Caption := IntToStr(TotalMarc);

  if dmDados.GetTotalColaboradores(TotalColab) then
    lblCard3Val.Caption := IntToStr(TotalColab);
end;

procedure TfrmMain.CarregarRelogios;
var
  Qry: TFDQuery;
  OldDs: TDataSet;
begin
  OldDs := FdsRelogios.DataSet;
  Qry := dmDados.GetRelogios(False);
  FdsRelogios.DataSet := Qry;
  if Assigned(OldDs) then
    OldDs.Free;

  ConfigurarGridRelogios;

  // Atualizar ComboBox de Relógios do filtro
  cmbFiltroRelogio.Items.Clear;
  cmbFiltroRelogio.Items.AddObject('Todos os Relógios', TObject(0));
  Qry.First;
  while not Qry.Eof do
  begin
    cmbFiltroRelogio.Items.AddObject(Qry.FieldByName('PRE_NOME').AsString,
      TObject(NativeInt(Qry.FieldByName('PRE_ID').AsInteger)));
    Qry.Next;
  end;
  cmbFiltroRelogio.ItemIndex := 0;

  CarregarRelogiosNoComboDestino;

  if not Qry.IsEmpty then
  begin
    Qry.First;
    PreencherFormRelogio(Qry);
  end
  else
    LimparFormRelogio;
end;

procedure TfrmMain.CarregarColaboradores;
var
  Qry: TFDQuery;
  OldDs: TDataSet;
begin
  OldDs := FdsColaboradores.DataSet;
  Qry := dmDados.GetColaboradores(False);
  FdsColaboradores.DataSet := Qry;
  if Assigned(OldDs) then
    OldDs.Free;

  ConfigurarGridColaboradores;

  if not Qry.IsEmpty then
  begin
    if (FSelectedColabId > 0) and Qry.Locate('PES_ID', FSelectedColabId, []) then
      PreencherFormColaborador(Qry)
    else
    begin
      Qry.First;
      PreencherFormColaborador(Qry);
    end;
  end
  else
    LimparFormColaborador;
end;

procedure TfrmMain.CarregarMarcacoes;
var
  Qry: TFDQuery;
  OldDs: TDataSet;
  RelId: Integer;
begin
  RelId := 0;
  if cmbFiltroRelogio.ItemIndex > 0 then
    RelId := Integer(NativeInt(cmbFiltroRelogio.Items.Objects[cmbFiltroRelogio.ItemIndex]));

  OldDs := FdsMarcacoes.DataSet;
  Qry := dmDados.GetMarcacoes(dtpIni.Date, dtpFim.Date, RelId, 0);
  FdsMarcacoes.DataSet := Qry;
  if Assigned(OldDs) then
    OldDs.Free;

  ConfigurarGridMarcacoes;
  lblTotalMarcacoesGrid.Caption := Format('Total: %d marcações', [Qry.RecordCount]);
end;

procedure TfrmMain.LimparFormRelogio;
begin
  FSelectedRelogioId := 0;
  edtRelNome.Text := 'Novo Relógio Control iD';
  edtRelIP.Text := '192.168.1.200';
  edtRelPorta.Text := '80';
  chkRelSSL.Checked := False;
  edtRelUser.Text := 'admin';
  edtRelSenha.Text := 'admin';
  cmbRelModelo.ItemIndex := 0;
  cmbRelModoColeta.ItemIndex := 0;
  chkRelAtivo.Checked := True;
  edtSerial.Text := '';
  edtFW.Text := '';
  edtUltimoLog.Text := '0';
end;

procedure TfrmMain.PreencherFormRelogio(AQry: TFDQuery);
var
  Modelo, Modo: string;
begin
  if AQry.IsEmpty then
  begin
    LimparFormRelogio;
    Exit;
  end;

  FSelectedRelogioId := AQry.FieldByName('PRE_ID').AsInteger;
  edtRelNome.Text := AQry.FieldByName('PRE_NOME').AsString;
  edtRelIP.Text := AQry.FieldByName('PRE_IP').AsString;
  edtRelPorta.Text := IntToStr(AQry.FieldByName('PRE_PORTA').AsInteger);
  chkRelSSL.Checked := SameText(AQry.FieldByName('PRE_USAR_SSL').AsString, 'S');
  edtRelUser.Text := AQry.FieldByName('PRE_USUARIO').AsString;
  edtRelSenha.Text := AQry.FieldByName('PRE_SENHA').AsString;
  chkRelAtivo.Checked := SameText(AQry.FieldByName('PRE_ATIVO').AsString, 'S');

  Modelo := UpperCase(AQry.FieldByName('PRE_MODELO').AsString);
  if Pos('IDCLASS', Modelo) > 0 then
    cmbRelModelo.ItemIndex := 0
  else if Pos('IDFACE', Modelo) > 0 then
    cmbRelModelo.ItemIndex := 1
  else if Pos('IDACCESS', Modelo) > 0 then
    cmbRelModelo.ItemIndex := 2
  else if Pos('IDBLOCK', Modelo) > 0 then
    cmbRelModelo.ItemIndex := 3
  else
    cmbRelModelo.ItemIndex := 0;

  Modo := UpperCase(AQry.FieldByName('PRE_MODO_COLETA').AsString);
  if Pos('671', Modo) > 0 then
    cmbRelModoColeta.ItemIndex := 1
  else if Pos('1510', Modo) > 0 then
    cmbRelModoColeta.ItemIndex := 2
  else
    cmbRelModoColeta.ItemIndex := 0;

  edtSerial.Text := AQry.FieldByName('PRE_SERIAL').AsString;
  edtFW.Text := AQry.FieldByName('PRE_VERSAO_FW').AsString;
  edtUltimoLog.Text := IntToStr(AQry.FieldByName('PRE_ULTIMO_LOG_ID').AsLargeInt);
end;

function TfrmMain.ObterRelogioAtivoId: Integer;
begin
  if FSelectedRelogioId > 0 then
    Result := FSelectedRelogioId
  else if Assigned(FdsRelogios.DataSet) and (not FdsRelogios.DataSet.IsEmpty) then
    Result := FdsRelogios.DataSet.FieldByName('PRE_ID').AsInteger
  else
    Result := 0;
end;

// ======================= Ações de Topo =======================

procedure TfrmMain.btnQuickTestClick(Sender: TObject);
var
  RelId: Integer;
begin
  RelId := ObterRelogioAtivoId;
  if RelId <= 0 then
  begin
    ShowMessage('Cadastre ou selecione um relógio de ponto primeiro.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    FPontoService.TestarRelogio(RelId);
    CarregarRelogios;
    AtualizarDashboard;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnQuickSyncTimeClick(Sender: TObject);
var
  RelId: Integer;
begin
  RelId := ObterRelogioAtivoId;
  if RelId <= 0 then
  begin
    ShowMessage('Cadastre ou selecione um relógio de ponto primeiro.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    FPontoService.SincronizarHorario(RelId);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnQuickCollectClick(Sender: TObject);
var
  TotalNovas: Integer;
begin
  Screen.Cursor := crHourGlass;
  try
    LogMessage('📥 Iniciando verificação de novas batidas de ponto em todos os relógios ativos...');
    FPontoService.ColetarTodosRelogios(TotalNovas);
    lblCard4Val.Caption := FormatDateTime('hh:nn:ss', Now);
    AtualizarDashboard;
    CarregarMarcacoes;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnQuickAutoClick(Sender: TObject);
begin
  tmrAutoColeta.Enabled := not tmrAutoColeta.Enabled;
  if tmrAutoColeta.Enabled then
  begin
    tmrAutoColeta.Interval := AppConfig.ControlID.IntervaloColetaSegundos * 1000;
    if Assigned(skQuickAuto) then
    begin
      skQuickAuto.Caption := '🔄 Auto: ON';
      skQuickAuto.Kind := sbkSuccess;
    end;
    btnQuickAuto.Caption := 'Auto: ON';
    AtualizarStatusColeta(Format('🔄 Coleta: Ativa (%ds)', [AppConfig.ControlID.IntervaloColetaSegundos]), True);
    LogMessage(Format('▶️ Coleta automática ativada! Verificando marcações a cada %d segundos.', [AppConfig.ControlID.IntervaloColetaSegundos]));
  end
  else
  begin
    if Assigned(skQuickAuto) then
    begin
      skQuickAuto.Caption := '🔄 Auto: OFF';
      skQuickAuto.Kind := sbkDark;
    end;
    btnQuickAuto.Caption := 'Auto: OFF';
    AtualizarStatusColeta('🔄 Coleta: Desativada', False);
    LogMessage('⏸️ Coleta automática pausada pelo usuário.');
  end;
end;

procedure TfrmMain.tmrAutoColetaTimer(Sender: TObject);
var
  TotalNovas: Integer;
begin
  tmrAutoColeta.Enabled := False;
  try
    FPontoService.ColetarTodosRelogios(TotalNovas);
    lblCard4Val.Caption := FormatDateTime('hh:nn:ss', Now);
    AtualizarDashboard;
  finally
    tmrAutoColeta.Enabled := True;
  end;
end;

// ======================= Log =======================

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  mmoLog.Clear;
  LogMessage('✨ Histórico de atividades limpo.');
end;

procedure TfrmMain.btnSaveLogClick(Sender: TObject);
begin
  dlgSave.FileName := 'Log_Ponto_ControlID_' + FormatDateTime('yyyymmdd_hhnn', Now) + '.txt';
  if dlgSave.Execute then
  begin
    mmoLog.Lines.SaveToFile(dlgSave.FileName, TEncoding.UTF8);
    LogMessage('💾 Histórico de atividades salvo com sucesso em: ' + dlgSave.FileName);
  end;
end;

// ======================= Relógios =======================

procedure TfrmMain.dbgRelogiosCellClick(Column: TColumn);
begin
  if Assigned(FdsRelogios.DataSet) and (not FdsRelogios.DataSet.IsEmpty) then
    PreencherFormRelogio(FdsRelogios.DataSet as TFDQuery);
end;

procedure TfrmMain.btnNovoRelogioClick(Sender: TObject);
begin
  LimparFormRelogio;
  edtRelNome.SetFocus;
end;

procedure TfrmMain.btnAtualizarRelogiosClick(Sender: TObject);
begin
  CarregarRelogios;
end;

procedure TfrmMain.btnSalvarRelogioClick(Sender: TObject);
var
  Porta, NovoId: Integer;
  Modelo, Modo: string;
begin
  if Trim(edtRelNome.Text) = '' then
  begin
    ShowMessage('Informe o nome do relógio.');
    edtRelNome.SetFocus;
    Exit;
  end;

  if Trim(edtRelIP.Text) = '' then
  begin
    ShowMessage('Informe o endereço IP do relógio.');
    edtRelIP.SetFocus;
    Exit;
  end;

  Porta := StrToIntDef(edtRelPorta.Text, 80);

  case cmbRelModelo.ItemIndex of
    0: Modelo := 'IDCLASS';
    1: Modelo := 'IDFACE';
    2: Modelo := 'IDACCESS';
    3: Modelo := 'IDBLOCK';
  else
    Modelo := 'OUTRO';
  end;

  case cmbRelModoColeta.ItemIndex of
    0: Modo := 'API';
    1: Modo := 'AFD_671';
    2: Modo := 'AFD_1510';
  else
    Modo := 'API';
  end;

  NovoId := dmDados.SalvarRelogio(FSelectedRelogioId, Trim(edtRelNome.Text),
    Trim(edtRelIP.Text), Porta, chkRelSSL.Checked, Trim(edtRelUser.Text),
    Trim(edtRelSenha.Text), Modelo, Modo, chkRelAtivo.Checked);

  LogMessage(Format('💾 Relógio [%s] salvo com sucesso no banco de dados (ID: %d).', [Trim(edtRelNome.Text), NovoId]));
  CarregarRelogios;
  AtualizarDashboard;
end;

procedure TfrmMain.btnExcluirRelogioClick(Sender: TObject);
begin
  if FSelectedRelogioId <= 0 then
  begin
    ShowMessage('Selecione um relógio para excluir.');
    Exit;
  end;

  if MessageDlg(Format('Deseja realmente excluir o relógio [%s]?', [edtRelNome.Text]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    dmDados.ExcluirRelogio(FSelectedRelogioId);
    LogMessage(Format('🗑️ Relógio [%s] (ID %d) excluído do sistema.', [Trim(edtRelNome.Text), FSelectedRelogioId]));
    CarregarRelogios;
    AtualizarDashboard;
  end;
end;

procedure TfrmMain.btnTestarEsteRelogioClick(Sender: TObject);
begin
  if FSelectedRelogioId <= 0 then
  begin
    ShowMessage('Selecione ou salve o relógio primeiro.');
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    FPontoService.TestarRelogio(FSelectedRelogioId);
    CarregarRelogios;
    AtualizarDashboard;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnSincHoraEsteClick(Sender: TObject);
begin
  if FSelectedRelogioId <= 0 then
  begin
    ShowMessage('Selecione ou salve o relógio primeiro.');
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    FPontoService.SincronizarHorario(FSelectedRelogioId);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnColetarEsteClick(Sender: TObject);
var
  Qtd: Integer;
begin
  if FSelectedRelogioId <= 0 then
  begin
    ShowMessage('Selecione ou salve o relógio primeiro.');
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    FPontoService.ColetarMarcacoes(FSelectedRelogioId, Qtd);
    CarregarRelogios;
    CarregarMarcacoes;
    AtualizarDashboard;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ======================= Colaboradores =======================

procedure TfrmMain.btnAtualizarColabClick(Sender: TObject);
begin
  CarregarColaboradores;
end;

procedure TfrmMain.edtBuscaColabChange(Sender: TObject);
var
  Filtro: string;
begin
  Filtro := Trim(edtBuscaColab.Text);
  if Assigned(FdsColaboradores.DataSet) then
  begin
    if Filtro = '' then
      FdsColaboradores.DataSet.Filtered := False
    else
    begin
      FdsColaboradores.DataSet.Filter :=
        Format('PES_RSOCIAL_NOME LIKE ''%%%s%%'' OR PES_CNPJ_CPF LIKE ''%%%s%%'' OR COL_PIS LIKE ''%%%s%%''',
        [Filtro, Filtro, Filtro]);
      FdsColaboradores.DataSet.Filtered := True;
    end;
  end;
end;

procedure TfrmMain.btnEnviarColabRelogioClick(Sender: TObject);
var
  RelId, PessoaId, Suc, Falh: Integer;
  Ids: TArray<Integer>;
begin
  RelId := ObterRelogioAtivoId;
  if RelId <= 0 then
  begin
    ShowMessage('Nenhum relógio selecionado para envio.');
    Exit;
  end;

  if (not Assigned(FdsColaboradores.DataSet)) or FdsColaboradores.DataSet.IsEmpty then
  begin
    ShowMessage('Selecione um colaborador na grade.');
    Exit;
  end;

  PessoaId := FdsColaboradores.DataSet.FieldByName('PES_ID').AsInteger;
  SetLength(Ids, 1);
  Ids[0] := PessoaId;

  Screen.Cursor := crHourGlass;
  try
    FPontoService.SincronizarColaboradores(RelId, Ids, Suc, Falh);
    CarregarColaboradores;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnRemoverColabRelogioClick(Sender: TObject);
var
  RelId, PessoaId: Integer;
  Nome: string;
begin
  RelId := ObterRelogioAtivoId;
  if RelId <= 0 then
  begin
    ShowMessage('Nenhum relógio selecionado.');
    Exit;
  end;

  if (not Assigned(FdsColaboradores.DataSet)) or FdsColaboradores.DataSet.IsEmpty then
  begin
    ShowMessage('Selecione um colaborador na grade.');
    Exit;
  end;

  PessoaId := FdsColaboradores.DataSet.FieldByName('PES_ID').AsInteger;
  Nome := FdsColaboradores.DataSet.FieldByName('PES_RSOCIAL_NOME').AsString;

  if MessageDlg(Format('Deseja realmente remover o colaborador [%s] (ID %d) da memória do relógio?', [Nome, PessoaId]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    if FPontoService.RemoverColaboradorDoRelogio(RelId, PessoaId) then
    begin
      ShowMessage(Format('Colaborador [%s] removido com sucesso do relógio.', [Nome]));
      CarregarColaboradores;
    end
    else
      ShowMessage('Não foi possível remover o colaborador do relógio. Verifique o log de atividades.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnEnviarTodosPendentesClick(Sender: TObject);
var
  RelId, Suc, Falh: Integer;
  Qry: TFDQuery;
  Ids: TArray<Integer>;
  Count: Integer;
begin
  RelId := ObterRelogioAtivoId;
  if RelId <= 0 then
  begin
    ShowMessage('Nenhum relógio selecionado para envio.');
    Exit;
  end;

  Qry := dmDados.GetColaboradores(True);
  try
    SetLength(Ids, Qry.RecordCount);
    Count := 0;
    while not Qry.Eof do
    begin
      if not SameText(Qry.FieldByName('COL_SINCRONIZADO_RELOGIO').AsString, 'S') then
      begin
        Ids[Count] := Qry.FieldByName('PES_ID').AsInteger;
        Inc(Count);
      end;
      Qry.Next;
    end;
    SetLength(Ids, Count);

    if Count = 0 then
    begin
      ShowMessage('Não há colaboradores pendentes de sincronização.');
      Exit;
    end;

    Screen.Cursor := crHourGlass;
    try
      FPontoService.SincronizarColaboradores(RelId, Ids, Suc, Falh);
      CarregarColaboradores;
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    Qry.Free;
  end;
end;

procedure TfrmMain.btnImportarDoRelogioClick(Sender: TObject);
var
  RelId, Total: Integer;
begin
  RelId := ObterRelogioAtivoId;
  if RelId <= 0 then
  begin
    ShowMessage('Nenhum relógio selecionado.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    FPontoService.ImportarUsuariosDoRelogio(RelId, Total);
    pgcMain.ActivePage := tabDashboard;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.dbgColaboradoresCellClick(Column: TColumn);
begin
  if Assigned(FdsColaboradores.DataSet) and (not FdsColaboradores.DataSet.IsEmpty) then
    PreencherFormColaborador(FdsColaboradores.DataSet);
end;

procedure TfrmMain.LimparFormColaborador;
begin
  FSelectedColabId := 0;
  edtColabNome.Text := '';
  edtColabCPF.Text := '';
  edtColabPIS.Text := '';
  edtColabMatricula.Text := '';
  edtColabFuncao.Text := '';
  edtColabCodigo.Text := '';
  edtColabSenha.Text := '';
  edtColabRFID.Text := '';
  edtColabBarras.Text := '';
  chkColabAdmin.Checked := False;
  chkColabAtivo.Checked := True;
  if cmbColabHorario.Items.Count > 0 then
    cmbColabHorario.ItemIndex := 0;
  lblColabSyncStatus.Caption := '⏳ Pendente de Sincronização';
  lblColabSyncStatus.Font.Color := $00247BA0; // Laranja/Aviso
  lblColabUltimaSync.Caption := 'Nunca enviado';
  if (cmbColabRelogioDestino.Items.Count > 0) and (cmbColabRelogioDestino.ItemIndex < 0) then
    cmbColabRelogioDestino.ItemIndex := 0;
end;

procedure TfrmMain.PreencherFormColaborador(AQry: TDataSet);
var
  HorId, Idx, I: Integer;
begin
  if (AQry = nil) or AQry.IsEmpty then
  begin
    LimparFormColaborador;
    Exit;
  end;

  FSelectedColabId := AQry.FieldByName('PES_ID').AsInteger;
  edtColabNome.Text := AQry.FieldByName('PES_RSOCIAL_NOME').AsString;
  edtColabCPF.Text := AQry.FieldByName('PES_CNPJ_CPF').AsString;

  if AQry.FindField('COL_PIS') <> nil then
    edtColabPIS.Text := AQry.FieldByName('COL_PIS').AsString
  else
    edtColabPIS.Text := '';

  if AQry.FindField('COL_CARTAO_PONTO') <> nil then
    edtColabMatricula.Text := AQry.FieldByName('COL_CARTAO_PONTO').AsString
  else
    edtColabMatricula.Text := IntToStr(FSelectedColabId);

  if AQry.FindField('COL_FUNCAO') <> nil then
    edtColabFuncao.Text := AQry.FieldByName('COL_FUNCAO').AsString
  else
    edtColabFuncao.Text := '';

  if AQry.FindField('PES_CODIGO_ACESSO') <> nil then
    edtColabCodigo.Text := AQry.FieldByName('PES_CODIGO_ACESSO').AsString
  else
    edtColabCodigo.Text := '';

  edtColabSenha.Text := '';
  edtColabRFID.Text := '';
  edtColabBarras.Text := edtColabMatricula.Text;
  chkColabAdmin.Checked := False;

  if AQry.FindField('COL_STATUS') <> nil then
    chkColabAtivo.Checked := SameText(AQry.FieldByName('COL_STATUS').AsString, 'A')
  else
    chkColabAtivo.Checked := True;

  // Selecionar Jornada / Horário de Trabalho
  if AQry.FindField('COL_HORARIO') <> nil then
  begin
    HorId := AQry.FieldByName('COL_HORARIO').AsInteger;
    Idx := -1;
    for I := 0 to cmbColabHorario.Items.Count - 1 do
    begin
      if Integer(NativeInt(cmbColabHorario.Items.Objects[I])) = HorId then
      begin
        Idx := I;
        Break;
      end;
    end;
    if Idx >= 0 then
      cmbColabHorario.ItemIndex := Idx
    else if cmbColabHorario.Items.Count > 0 then
      cmbColabHorario.ItemIndex := 0;
  end;

  // Informações de Sincronização
  if (AQry.FindField('COL_SINCRONIZADO_RELOGIO') <> nil) and
     SameText(AQry.FieldByName('COL_SINCRONIZADO_RELOGIO').AsString, 'S') then
  begin
    lblColabSyncStatus.Caption := '✅ Sincronizado no Relógio';
    lblColabSyncStatus.Font.Color := $001A8C2B; // Verde
  end
  else
  begin
    lblColabSyncStatus.Caption := '⏳ Pendente de Sincronização';
    lblColabSyncStatus.Font.Color := $00247BA0; // Laranja/Aviso
  end;

  if (AQry.FindField('COL_ULTIMA_SINCRONIZACAO') <> nil) and
     (not AQry.FieldByName('COL_ULTIMA_SINCRONIZACAO').IsNull) then
    lblColabUltimaSync.Caption := FormatDateTime('dd/mm/yyyy hh:nn:ss', AQry.FieldByName('COL_ULTIMA_SINCRONIZACAO').AsDateTime)
  else
    lblColabUltimaSync.Caption := 'Nunca enviado';
end;

procedure TfrmMain.CarregarRelogiosNoComboDestino;
var
  Qry: TFDQuery;
  PrevIdColab, PrevIdEmp, Idx, I: Integer;
begin
  PrevIdColab := 0;
  if (cmbColabRelogioDestino.ItemIndex >= 0) and (cmbColabRelogioDestino.Items.Count > 0) then
    PrevIdColab := Integer(NativeInt(cmbColabRelogioDestino.Items.Objects[cmbColabRelogioDestino.ItemIndex]));

  PrevIdEmp := 0;
  if (cmbEmpRelogioDestino.ItemIndex >= 0) and (cmbEmpRelogioDestino.Items.Count > 0) then
    PrevIdEmp := Integer(NativeInt(cmbEmpRelogioDestino.Items.Objects[cmbEmpRelogioDestino.ItemIndex]));

  cmbColabRelogioDestino.Items.Clear;
  cmbEmpRelogioDestino.Items.Clear;
  Qry := dmDados.GetRelogios(True);
  try
    while not Qry.Eof do
    begin
      cmbColabRelogioDestino.Items.AddObject(
        Format('%s (%s:%d)', [Qry.FieldByName('PRE_NOME').AsString,
                              Qry.FieldByName('PRE_IP').AsString,
                              Qry.FieldByName('PRE_PORTA').AsInteger]),
        TObject(NativeInt(Qry.FieldByName('PRE_ID').AsInteger))
      );
      cmbEmpRelogioDestino.Items.AddObject(
        Format('%s (%s:%d)', [Qry.FieldByName('PRE_NOME').AsString,
                              Qry.FieldByName('PRE_IP').AsString,
                              Qry.FieldByName('PRE_PORTA').AsInteger]),
        TObject(NativeInt(Qry.FieldByName('PRE_ID').AsInteger))
      );
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;

  if cmbColabRelogioDestino.Items.Count > 0 then
  begin
    Idx := 0;
    if PrevIdColab > 0 then
    begin
      for I := 0 to cmbColabRelogioDestino.Items.Count - 1 do
      begin
        if Integer(NativeInt(cmbColabRelogioDestino.Items.Objects[I])) = PrevIdColab then
        begin
          Idx := I;
          Break;
        end;
      end;
    end;
    cmbColabRelogioDestino.ItemIndex := Idx;
  end;

  if cmbEmpRelogioDestino.Items.Count > 0 then
  begin
    Idx := 0;
    if PrevIdEmp > 0 then
    begin
      for I := 0 to cmbEmpRelogioDestino.Items.Count - 1 do
      begin
        if Integer(NativeInt(cmbEmpRelogioDestino.Items.Objects[I])) = PrevIdEmp then
        begin
          Idx := I;
          Break;
        end;
      end;
    end;
    cmbEmpRelogioDestino.ItemIndex := Idx;
  end;
end;

procedure TfrmMain.btnSalvarColabClick(Sender: TObject);
var
  PessoaId, HorarioId: Integer;
  Nome, Cpf, Pis, Matricula, Funcao, CodAcesso: string;
  Ativo: Boolean;
begin
  Nome := Trim(edtColabNome.Text);
  if Nome = '' then
  begin
    ShowMessage('Informe o nome do colaborador.');
    edtColabNome.SetFocus;
    Exit;
  end;

  Cpf := Trim(edtColabCPF.Text);
  Pis := Trim(edtColabPIS.Text);
  Matricula := Trim(edtColabMatricula.Text);
  Funcao := Trim(edtColabFuncao.Text);
  CodAcesso := Trim(edtColabCodigo.Text);
  Ativo := chkColabAtivo.Checked;

  HorarioId := 0;
  if cmbColabHorario.ItemIndex >= 0 then
    HorarioId := Integer(NativeInt(cmbColabHorario.Items.Objects[cmbColabHorario.ItemIndex]));

  if (Cpf = '') and (Pis = '') then
  begin
    ShowMessage('Informe ao menos o CPF ou PIS do colaborador para o cadastro de ponto.');
    edtColabCPF.SetFocus;
    Exit;
  end;

  PessoaId := FSelectedColabId;
  Screen.Cursor := crHourGlass;
  try
    if dmDados.SalvarColaborador(PessoaId, Nome, Cpf, Pis, Matricula, Funcao, CodAcesso, Ativo, HorarioId) then
    begin
      FSelectedColabId := PessoaId;
      LogMessage(Format('💾 Colaborador [%s] (ID %d) salvo com sucesso no banco de dados.', [Nome, PessoaId]));
      CarregarColaboradores;
      AtualizarDashboard;
      ShowMessage('Colaborador salvo com sucesso!');
    end
    else
      ShowMessage('Não foi possível salvar o colaborador. Verifique se o banco de dados está acessível.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnSalvarEnviarColabClick(Sender: TObject);
var
  PessoaId, RelId, HorarioId: Integer;
  Nome, Cpf, Pis, Matricula, Funcao, CodAcesso, Senha, Barras: string;
  Rfid: Int64;
  Admin, Ativo: Boolean;
begin
  Nome := Trim(edtColabNome.Text);
  if Nome = '' then
  begin
    ShowMessage('Informe o nome do colaborador.');
    edtColabNome.SetFocus;
    Exit;
  end;

  Cpf := Trim(edtColabCPF.Text);
  Pis := Trim(edtColabPIS.Text);
  Matricula := Trim(edtColabMatricula.Text);
  Funcao := Trim(edtColabFuncao.Text);
  CodAcesso := Trim(edtColabCodigo.Text);
  Senha := Trim(edtColabSenha.Text);
  Barras := Trim(edtColabBarras.Text);
  Rfid := StrToInt64Def(Trim(edtColabRFID.Text), 0);
  Admin := chkColabAdmin.Checked;
  Ativo := chkColabAtivo.Checked;

  HorarioId := 0;
  if cmbColabHorario.ItemIndex >= 0 then
    HorarioId := Integer(NativeInt(cmbColabHorario.Items.Objects[cmbColabHorario.ItemIndex]));

  if (Cpf = '') and (Pis = '') then
  begin
    ShowMessage('Informe ao menos o CPF ou PIS do colaborador para cadastro no relógio de ponto.');
    edtColabCPF.SetFocus;
    Exit;
  end;

  // 1. Obter relógio de destino
  RelId := 0;
  if cmbColabRelogioDestino.ItemIndex >= 0 then
    RelId := Integer(NativeInt(cmbColabRelogioDestino.Items.Objects[cmbColabRelogioDestino.ItemIndex]));
  if RelId <= 0 then
    RelId := ObterRelogioAtivoId;

  if RelId <= 0 then
  begin
    ShowMessage('Nenhum relógio de ponto disponível para envio. Cadastre ou ative um relógio primeiro.');
    Exit;
  end;

  PessoaId := FSelectedColabId;
  Screen.Cursor := crHourGlass;
  try
    // 2. Salvar localmente primeiro
    if not dmDados.SalvarColaborador(PessoaId, Nome, Cpf, Pis, Matricula, Funcao, CodAcesso, Ativo, HorarioId) then
    begin
      ShowMessage('Falha ao salvar dados no banco local antes do envio.');
      Exit;
    end;
    FSelectedColabId := PessoaId;

    // 3. Enviar ao relógio selecionado
    if FPontoService.EnviarColaboradorIndividual(RelId, PessoaId, Senha, Rfid, Admin, Barras) then
    begin
      LogMessage(Format('🎉 Cadastro de [%s] enviado e ativado no relógio com sucesso!', [Nome]));
      CarregarColaboradores;
      AtualizarDashboard;
      ShowMessage(Format('Colaborador [%s] salvo e enviado ao relógio com sucesso!', [Nome]));
    end
    else
    begin
      CarregarColaboradores;
      ShowMessage('Colaborador salvo localmente, mas ocorreu uma falha ao enviar para o relógio.'#13#10 +
                  'Consulte o painel de log para mais detalhes.');
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnNovoColabClick(Sender: TObject);
begin
  LimparFormColaborador;
  edtColabNome.SetFocus;
end;

procedure TfrmMain.btnRemoverColabFormClick(Sender: TObject);
var
  RelId: Integer;
  Nome: string;
begin
  if FSelectedColabId <= 0 then
  begin
    ShowMessage('Selecione um colaborador primeiro.');
    Exit;
  end;

  RelId := 0;
  if cmbColabRelogioDestino.ItemIndex >= 0 then
    RelId := Integer(NativeInt(cmbColabRelogioDestino.Items.Objects[cmbColabRelogioDestino.ItemIndex]));
  if RelId <= 0 then
    RelId := ObterRelogioAtivoId;

  if RelId <= 0 then
  begin
    ShowMessage('Nenhum relógio selecionado para remoção.');
    Exit;
  end;

  Nome := Trim(edtColabNome.Text);
  if Nome = '' then
    Nome := Format('ID %d', [FSelectedColabId]);

  if MessageDlg(Format('Deseja realmente remover o colaborador [%s] da memória do relógio de ponto?', [Nome]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    if FPontoService.RemoverColaboradorDoRelogio(RelId, FSelectedColabId) then
    begin
      ShowMessage(Format('Colaborador [%s] removido com sucesso do relógio.', [Nome]));
      CarregarColaboradores;
    end
    else
      ShowMessage('Não foi possível remover o colaborador do relógio. Verifique o log de atividades.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnLimparTodosRelogioClick(Sender: TObject);
var
  RelId, TotalRemovidos: Integer;
begin
  RelId := ObterRelogioAtivoId;
  if RelId <= 0 then
  begin
    ShowMessage('Nenhum relógio selecionado.');
    Exit;
  end;

  if MessageDlg('⚠️ ATENÇÃO: Deseja realmente remover TODOS os colaboradores da memória do relógio de ponto?'#13#10 +
                'Esta operação apagará todos os cadastros no relógio e não pode ser desfeita no equipamento.',
                mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    if FPontoService.LimparTodosColaboradoresDoRelogio(RelId, TotalRemovidos) then
    begin
      ShowMessage(Format('Memória do relógio limpa com sucesso!'#13#10'Total de %d colaborador(es) removido(s).', [TotalRemovidos]));
      CarregarColaboradores;
    end
    else
      ShowMessage('Não foi possível limpar a memória do relógio. Verifique o log de atividades.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnExcluirColabBancoClick(Sender: TObject);
var
  PessoaId: Integer;
  Nome, Erro: string;
  Inativado: Boolean;
begin
  if FSelectedColabId <= 0 then
  begin
    ShowMessage('Selecione um colaborador primeiro.');
    Exit;
  end;

  PessoaId := FSelectedColabId;
  Nome := Trim(edtColabNome.Text);
  if Nome = '' then
    Nome := Format('ID %d', [PessoaId]);

  if MessageDlg(Format('Deseja realmente excluir o colaborador [%s] (ID %d) do banco de dados?', [Nome, PessoaId]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    if dmDados.ExcluirColaborador(PessoaId, Erro, Inativado) then
    begin
      if Inativado then
      begin
        LogMessage(Format('⚠️ Colaborador [%s] possui vínculos/marcações históricas e foi INATIVADO no banco.', [Nome]));
        ShowMessage(Format('O colaborador [%s] possui histórico de marcações de ponto ou lançamentos e não pode ser apagado fisicamente.'#13#10 +
                           'O seu cadastro foi INATIVADO com sucesso para preservar o histórico fiscal.', [Nome]));
      end
      else
      begin
        LogMessage(Format('🗑️ Colaborador [%s] (ID %d) excluído com sucesso do banco de dados.', [Nome, PessoaId]));
        ShowMessage(Format('Colaborador [%s] excluído com sucesso do banco de dados!', [Nome]));
      end;
      LimparFormColaborador;
      CarregarColaboradores;
      AtualizarDashboard;
    end
    else
    begin
      LogMessage('❌ Falha ao excluir colaborador: ' + FormatarErroAmigavel(Erro), True);
      ShowMessage('Não foi possível excluir o colaborador:'#13#10 + Erro);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ======================= Marcações =======================

procedure TfrmMain.btnFiltrarMarcacoesClick(Sender: TObject);
begin
  CarregarMarcacoes;
end;

procedure TfrmMain.btnExportarAFDClick(Sender: TObject);
var
  Qry: TFDQuery;
  Linhas: TStringList;
  Linha: string;
begin
  if (not Assigned(FdsMarcacoes.DataSet)) or FdsMarcacoes.DataSet.IsEmpty then
  begin
    ShowMessage('Não há marcações para exportar no período filtrado.');
    Exit;
  end;

  dlgSave.FileName := 'Marcacoes_Ponto_' + FormatDateTime('yyyymmdd', dtpIni.Date) +
    '_a_' + FormatDateTime('yyyymmdd', dtpFim.Date) + '.txt';

  if dlgSave.Execute then
  begin
    Linhas := TStringList.Create;
    try
      Qry := FdsMarcacoes.DataSet as TFDQuery;
      Qry.DisableControls;
      try
        Qry.First;
        // Cabeçalho CSV/TXT
        Linhas.Add('DATA_HORA;PESSOA_ID;COLABORADOR;PIS;CPF;RELOGIO;NSR;ORIGEM');
        while not Qry.Eof do
        begin
          Linha := Format('%s;%d;%s;%s;%s;%s;%s;%s', [
            FormatDateTime('dd/mm/yyyy hh:nn:ss', Qry.FieldByName('PMA_DATA_HORA').AsDateTime),
            Qry.FieldByName('PMA_PESSOA').AsInteger,
            Qry.FieldByName('PESSOA_NOME').AsString,
            Qry.FieldByName('PMA_PIS').AsString,
            Qry.FieldByName('PMA_CPF').AsString,
            Qry.FieldByName('RELOGIO_NOME').AsString,
            Qry.FieldByName('PMA_NSR').AsString,
            Qry.FieldByName('PMA_ORIGEM').AsString
          ]);
          Linhas.Add(Linha);
          Qry.Next;
        end;
      finally
        Qry.EnableControls;
      end;
      Linhas.SaveToFile(dlgSave.FileName, TEncoding.UTF8);
      LogMessage(Format('📄 Arquivo de registros exportado com sucesso! %d marcação(ões) salva(s) em: %s', [Linhas.Count - 1, dlgSave.FileName]));
      ShowMessage(Format('Arquivo exportado com sucesso! Total de %d marcações.', [Linhas.Count - 1]));
    finally
      Linhas.Free;
    end;
  end;
end;

procedure TfrmMain.btnExcluirMarcacaoClick(Sender: TObject);
var
  MarcId: Integer;
  Colab, DataHoraStr: string;
begin
  if (not Assigned(FdsMarcacoes.DataSet)) or FdsMarcacoes.DataSet.IsEmpty then
  begin
    ShowMessage('Selecione uma marcação na grade para excluir.');
    Exit;
  end;

  MarcId := FdsMarcacoes.DataSet.FieldByName('PMA_ID').AsInteger;
  Colab := FdsMarcacoes.DataSet.FieldByName('PESSOA_NOME').AsString;
  DataHoraStr := FormatDateTime('dd/mm/yyyy hh:nn:ss', FdsMarcacoes.DataSet.FieldByName('PMA_DATA_HORA').AsDateTime);

  if MessageDlg(Format('Deseja realmente excluir a marcação selecionada do banco de dados?'#13#10#13#10 +
                       'Colaborador: %s'#13#10 +
                       'Data e Hora: %s'#13#10 +
                       'ID Registro: %d', [Colab, DataHoraStr, MarcId]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    if dmDados.ExcluirMarcacao(MarcId) then
    begin
      LogMessage(Format('🗑️ Marcação #%d (%s - %s) excluída do banco de dados.', [MarcId, Colab, DataHoraStr]));
      CarregarMarcacoes;
      AtualizarDashboard;
      ShowMessage('Marcação excluída com sucesso!');
    end
    else
    begin
      LogMessage(Format('❌ Falha ao excluir marcação #%d: %s', [MarcId, FormatarErroAmigavel(dmDados.LastError)]), True);
      ShowMessage('Não foi possível excluir a marcação selecionada.');
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnEditarMarcacaoClick(Sender: TObject);
var
  PmaId: Integer;
  DataHoraAtual: TDateTime;
  TipoAtual, NomeColab: string;
  Prompts, Values: array of string;
  NovaDataStr, NovaHoraStr, NovoTipoStr, NovoMotivoStr: string;
  NovaData, NovaHora, NovaDataHora: TDateTime;
  Qry: TDataSet;
begin
  Qry := FdsMarcacoes.DataSet;
  if (Qry = nil) or Qry.IsEmpty then
  begin
    ShowMessage('Selecione uma marcação de ponto na lista para corrigir.');
    Exit;
  end;

  PmaId := Qry.FieldByName('PMA_ID').AsInteger;
  DataHoraAtual := Qry.FieldByName('PMA_DATA_HORA').AsDateTime;
  TipoAtual := UpperCase(Trim(Qry.FieldByName('PMA_TIPO_BATIDA').AsString));
  if TipoAtual = '' then TipoAtual := 'E';
  NomeColab := Qry.FieldByName('PESSOA_NOME').AsString;

  SetLength(Prompts, 4);
  SetLength(Values, 4);

  Prompts[0] := 'Data da Batida (DD/MM/AAAA):';
  Values[0] := FormatDateTime('dd/mm/yyyy', DataHoraAtual);

  Prompts[1] := 'Hora da Batida (HH:MM:SS):';
  Values[1] := FormatDateTime('hh:nn:ss', DataHoraAtual);

  Prompts[2] := 'Tipo de Batida (E = Entrada, S = Saída):';
  Values[2] := TipoAtual;

  Prompts[3] := 'Motivo da Correção (Portaria 671 MTE):';
  Values[3] := 'Esquecimento de registro';

  if not InputQuery(Format('Corrigir Batida de Ponto - [%s] (ID %d)', [NomeColab, PmaId]), Prompts, Values) then
    Exit;

  NovaDataStr := Trim(Values[0]);
  NovaHoraStr := Trim(Values[1]);
  NovoTipoStr := UpperCase(Trim(Values[2]));
  NovoMotivoStr := Trim(Values[3]);

  if not TryStrToDate(NovaDataStr, NovaData) then
  begin
    ShowMessage('Data informada é inválida. Utilize o formato DD/MM/AAAA.');
    Exit;
  end;

  if not TryStrToTime(NovaHoraStr, NovaHora) then
  begin
    ShowMessage('Hora informada é inválida. Utilize o formato HH:MM:SS.');
    Exit;
  end;

  if (NovoTipoStr <> 'E') and (NovoTipoStr <> 'S') then
  begin
    ShowMessage('Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
    Exit;
  end;

  NovaDataHora := Trunc(NovaData) + Frac(NovaHora);

  Screen.Cursor := crHourGlass;
  try
    if dmDados.AtualizarMarcacao(PmaId, NovaDataHora, NovoTipoStr) then
    begin
      LogMessage(Format('✏️ Batida ID %d corrigida para %s (%s) - Colaborador: %s [Motivo: %s]',
        [PmaId, FormatDateTime('dd/mm/yyyy hh:nn:ss', NovaDataHora), NovoTipoStr, NomeColab, NovoMotivoStr]));
      CarregarMarcacoes;
      ShowMessage('Marcação de ponto corrigida com sucesso no sistema!');
    end
    else
      ShowMessage('Não foi possível atualizar a marcação de ponto no banco de dados.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnNovaMarcacaoClick(Sender: TObject);
var
  Prompts, Values: array of string;
  ColabBusca, NovaDataStr, NovaHoraStr, NovoTipoStr, NovoMotivoStr: string;
  NovaData, NovaHora, NovaDataHora: TDateTime;
  PessoaId, NovoId: Integer;
  NomeColab: string;
  Qry: TFDQuery;
begin
  SetLength(Prompts, 5);
  SetLength(Values, 5);

  Prompts[0] := 'CPF ou Código do Colaborador:';
  Values[0] := '';

  Prompts[1] := 'Data da Batida (DD/MM/AAAA):';
  Values[1] := FormatDateTime('dd/mm/yyyy', Date);

  Prompts[2] := 'Hora da Batida (HH:MM:SS):';
  Values[2] := FormatDateTime('hh:nn:ss', Now);

  Prompts[3] := 'Tipo de Batida (E = Entrada, S = Saída):';
  Values[3] := 'E';

  Prompts[4] := 'Motivo da Inclusão (Portaria 671 MTE):';
  Values[4] := 'Esquecimento de registro';

  if not InputQuery('Incluir Nova Batida Manual de Ponto', Prompts, Values) then
    Exit;

  ColabBusca := Trim(Values[0]);
  NovaDataStr := Trim(Values[1]);
  NovaHoraStr := Trim(Values[2]);
  NovoTipoStr := UpperCase(Trim(Values[3]));
  NovoMotivoStr := Trim(Values[4]);

  if ColabBusca = '' then
  begin
    ShowMessage('Informe o CPF ou código do colaborador.');
    Exit;
  end;

  if not TryStrToDate(NovaDataStr, NovaData) then
  begin
    ShowMessage('Data informada é inválida. Utilize o formato DD/MM/AAAA.');
    Exit;
  end;

  if not TryStrToTime(NovaHoraStr, NovaHora) then
  begin
    ShowMessage('Hora informada é inválida. Utilize o formato HH:MM:SS.');
    Exit;
  end;

  if (NovoTipoStr <> 'E') and (NovoTipoStr <> 'S') then
  begin
    ShowMessage('Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
    Exit;
  end;

  // Localizar Pessoa
  PessoaId := 0;
  NomeColab := '';
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := dmDados.FDConnection;
    Qry.SQL.Text :=
      'SELECT FIRST 1 PES_CODIGO, PES_NOME FROM TB_PESSOA ' +
      'WHERE PES_CODIGO = :COD OR PES_CNPJ_CPF = :CPF OR PES_CNPJ_CPF = :DIG';
    Qry.ParamByName('COD').AsInteger := StrToIntDef(ColabBusca, 0);
    Qry.ParamByName('CPF').AsString := ColabBusca;
    Qry.ParamByName('DIG').AsString := OnlyDigits(ColabBusca);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      PessoaId := Qry.FieldByName('PES_CODIGO').AsInteger;
      NomeColab := Qry.FieldByName('PES_NOME').AsString;
    end;
  finally
    Qry.Free;
  end;

  if PessoaId <= 0 then
  begin
    ShowMessage('Colaborador não localizado com o identificador informado: ' + ColabBusca);
    Exit;
  end;

  NovaDataHora := Trunc(NovaData) + Frac(NovaHora);

  Screen.Cursor := crHourGlass;
  try
    NovoId := dmDados.InserirMarcacaoManual(PessoaId, ObterRelogioAtivoId, NovaDataHora, NovoTipoStr);
    if NovoId > 0 then
    begin
      LogMessage(Format('➕ Batida manual ID %d incluída para %s (%s) - Colaborador: %s [Motivo: %s]',
        [NovoId, FormatDateTime('dd/mm/yyyy hh:nn:ss', NovaDataHora), NovoTipoStr, NomeColab, NovoMotivoStr]));
      CarregarMarcacoes;
      ShowMessage(Format('Batida manual incluída com sucesso para %s!', [NomeColab]));
    end
    else
      ShowMessage('Não foi possível gravar a batida manual no banco de dados.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ======================= Configurações e Atualizações =======================

procedure TfrmMain.btnTopConfigClick(Sender: TObject);
begin
  if pgcMain.ActivePage = tabConfig then
  begin
    if FPreviousTab <> nil then
      pgcMain.ActivePage := FPreviousTab
    else
      pgcMain.ActivePage := tabDashboard;
  end
  else
  begin
    FPreviousTab := pgcMain.ActivePage;
    pgcMain.ActivePage := tabConfig;
  end;
end;

procedure TfrmMain.btnConfigVoltarClick(Sender: TObject);
begin
  if FPreviousTab <> nil then
    pgcMain.ActivePage := FPreviousTab
  else
    pgcMain.ActivePage := tabDashboard;
end;

procedure TfrmMain.btnTopUpdateClick(Sender: TObject);
begin
  TfrmUpdate.ExecutarAtualizacao(Self, FLatestUpdateInfo);
end;

procedure TfrmMain.ChecarAtualizacaoSistemaAsync;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Info: TUpdateInfo;
    begin
      try
        if TfrmUpdate.ChecarAtualizacao(Info) then
        begin
          TThread.Queue(nil,
            procedure
            begin
              FLatestUpdateInfo := Info;
              btnTopUpdate.Caption := 'Atualizar p/ v' + Info.LatestVersion;
              btnTopUpdate.Visible := False;
              if Assigned(skTopUpdate) then
              begin
                skTopUpdate.Caption := '🚀 Nova Versão: v' + Info.LatestVersion;
                skTopUpdate.Visible := True;
              end;
              LogMessage(Format('🔔 Nova atualização do sistema disponível: v%s! Clique no botão superior para atualizar.', [Info.LatestVersion]));
            end);
        end;
      except
      end;
    end).Start;
end;

procedure TfrmMain.btnSalvarConfigClick(Sender: TObject);
var
  CfgFB: TFirebirdConfig;
  CfgCtl: TControlIDDefaultConfig;
begin
  CfgFB.Server := Trim(edtCfgServer.Text);
  CfgFB.Port := StrToIntDef(edtCfgPorta.Text, 3060);
  CfgFB.Database := Trim(edtCfgDatabase.Text);
  CfgFB.User := Trim(edtCfgUser.Text);
  CfgFB.Password := Trim(edtCfgPass.Text);
  CfgFB.VendorLib := Trim(edtCfgVendor.Text);
  CfgFB.Charset := 'WIN1252';

  CfgCtl := AppConfig.ControlID;
  CfgCtl.IntervaloColetaSegundos := StrToIntDef(edtIntervalo.Text, 60);
  CfgCtl.AutoIniciarColeta := chkAutoIniciar.Checked;

  AppConfig.Firebird := CfgFB;
  AppConfig.ControlID := CfgCtl;
  AppConfig.Save;

  LogMessage('💾 Configurações do sistema salvas com sucesso no arquivo Config.ini.');
  ShowMessage('Configurações salvas com sucesso!');
end;

procedure TfrmMain.btnTestarConexaoFBClick(Sender: TObject);
var
  Err: string;
begin
  btnSalvarConfigClick(Sender);
  Screen.Cursor := crHourGlass;
  try
    if dmDados.TestarConexao(Err) then
    begin
      AtualizarStatusMsg('Banco Firebird conectado com sucesso');
      LogMessage('🔌 Teste de conexão: Banco de dados Firebird conectado com sucesso!');
      ShowMessage('Conexão com o banco de dados Firebird realizada com sucesso!');
    end
    else
    begin
      AtualizarStatusMsg('Falha de conexão com o banco Firebird');
      LogMessage('❌ Falha no teste de conexão com o Firebird: ' + FormatarErroAmigavel(Err), True);
      ShowMessage('Falha ao conectar no banco Firebird:'#13#10 + Err);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnCarregarEmpBancoClick(Sender: TObject);
var
  Razao, Cnpj, Endereco, Cei, CpfResp: string;
begin
  Screen.Cursor := crHourGlass;
  try
    if dmDados.GetEmpresaPrincipal(Razao, Cnpj, Endereco, Cei, CpfResp) then
    begin
      edtEmpRazaoSocial.Text := Razao;
      edtEmpCpfCnpj.Text := Cnpj;
      edtEmpEndereco.Text := Endereco;
      edtEmpCEI.Text := Cei;
      edtEmpCpfResp.Text := CpfResp;

      if Length(OnlyDigits(Cnpj)) = 11 then
        cmbEmpTipoDoc.ItemIndex := 1
      else
        cmbEmpTipoDoc.ItemIndex := 0;

      AtualizarEmpregadorRodape(Razao, Cnpj);
      if Sender <> nil then
      begin
        LogMessage(Format('🏢 Dados do empregador [%s] carregados do banco de dados.', [Razao]));
        ShowMessage('Dados do empregador carregados do banco com sucesso!');
      end;
    end
    else
    begin
      if Sender <> nil then
        ShowMessage('Nenhum dado de empresa encontrado no banco de dados.');
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnSalvarEmpBancoClick(Sender: TObject);
var
  Razao, Cnpj, Endereco: string;
begin
  Razao := Trim(edtEmpRazaoSocial.Text);
  Cnpj := Trim(edtEmpCpfCnpj.Text);
  Endereco := Trim(edtEmpEndereco.Text);

  if Razao = '' then
  begin
    ShowMessage('Informe a Razão Social / Nome do empregador.');
    edtEmpRazaoSocial.SetFocus;
    Exit;
  end;

  if Cnpj = '' then
  begin
    ShowMessage('Informe o CNPJ / CPF do empregador.');
    edtEmpCpfCnpj.SetFocus;
    Exit;
  end;

  if Endereco = '' then
  begin
    ShowMessage('Informe o endereço do local de prestação do serviço.');
    edtEmpEndereco.SetFocus;
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    if dmDados.SalvarEmpresaPrincipal(Razao, Cnpj, Endereco) then
    begin
      AtualizarEmpregadorRodape(Razao, Cnpj);
      LogMessage(Format('💾 Dados do empregador [%s] atualizados no banco de dados com sucesso.', [Razao]));
      ShowMessage('Dados do empregador salvos no banco com sucesso!');
    end
    else
      ShowMessage('Não foi possível salvar os dados do empregador no banco de dados.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnEnviarEmpRelogioClick(Sender: TObject);
var
  RelId: Integer;
  Company: TControlIDCompany;
  CnpjLimpo, CpfRespLimpo: string;
begin
  RelId := 0;
  if cmbEmpRelogioDestino.ItemIndex >= 0 then
    RelId := Integer(NativeInt(cmbEmpRelogioDestino.Items.Objects[cmbEmpRelogioDestino.ItemIndex]));
  if RelId <= 0 then
    RelId := ObterRelogioAtivoId;

  if RelId <= 0 then
  begin
    ShowMessage('Selecione um relógio de destino para enviar os dados do empregador.');
    Exit;
  end;

  Company.Name := Trim(edtEmpRazaoSocial.Text);
  if Company.Name = '' then
  begin
    ShowMessage('Informe a Razão Social do empregador.');
    edtEmpRazaoSocial.SetFocus;
    Exit;
  end;

  CnpjLimpo := OnlyDigits(Trim(edtEmpCpfCnpj.Text));
  if CnpjLimpo = '' then
  begin
    ShowMessage('Informe o CNPJ/CPF do empregador.');
    edtEmpCpfCnpj.SetFocus;
    Exit;
  end;

  Company.DocType := cmbEmpTipoDoc.ItemIndex + 1; // 1 = CNPJ, 2 = CPF
  Company.CpfCnpj := CnpjLimpo;
  Company.Address := Trim(edtEmpEndereco.Text);
  Company.Cei := OnlyDigits(Trim(edtEmpCEI.Text));
  CpfRespLimpo := OnlyDigits(Trim(edtEmpCpfResp.Text));
  Company.CpfResp := CpfRespLimpo;

  // Validação essencial exigida pelo firmware Control iD iDClass:
  // Se for CNPJ (DocType = 1), o CPF do responsável não pode ser 0 ou vazio!
  if (Company.DocType = 1) and (Length(CpfRespLimpo) <> 11) then
  begin
    ShowMessage('Atenção: A legislação e o relógio Control iD exigem um CPF do Responsável válido (11 dígitos) quando o empregador é pessoa jurídica (CNPJ).'#13#10#13#10 +
                'Por favor, preencha o campo "CPF do Responsável" antes de enviar ao relógio.');
    edtEmpCpfResp.SetFocus;
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    if FPontoService.EnviarEmpregador(RelId, Company) then
    begin
      ShowMessage(Format('Dados do empregador [%s] gravados no relógio com sucesso!'#13#10 +
                         'Equipamento atualizado em conformidade com a Portaria 671 MTE.', [Company.Name]));
    end
    else
      ShowMessage('Não foi possível gravar os dados do empregador no relógio.'#13#10'Verifique o log de atividades.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnLerEmpRelogioClick(Sender: TObject);
var
  RelId: Integer;
  Company: TControlIDCompany;
begin
  RelId := 0;
  if cmbEmpRelogioDestino.ItemIndex >= 0 then
    RelId := Integer(NativeInt(cmbEmpRelogioDestino.Items.Objects[cmbEmpRelogioDestino.ItemIndex]));
  if RelId <= 0 then
    RelId := ObterRelogioAtivoId;

  if RelId <= 0 then
  begin
    ShowMessage('Selecione um relógio para leitura dos dados.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    if FPontoService.ObterEmpregador(RelId, Company) then
    begin
      edtEmpRazaoSocial.Text := Company.Name;
      edtEmpCpfCnpj.Text := Company.CpfCnpj;
      edtEmpEndereco.Text := Company.Address;
      edtEmpCEI.Text := Company.Cei;
      edtEmpCpfResp.Text := Company.CpfResp;

      if Company.DocType = 2 then
        cmbEmpTipoDoc.ItemIndex := 1
      else
        cmbEmpTipoDoc.ItemIndex := 0;

      ShowMessage(Format('Dados do empregador lidos do relógio com sucesso!'#13#10 +
                         'Razão: %s'#13#10 +
                         'Doc: %s', [Company.Name, Company.CpfCnpj]));
    end
    else
      ShowMessage('Não foi possível ler os dados do empregador do relógio.'#13#10'Verifique o log de atividades.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.pgcMainChange(Sender: TObject);
begin
  if pgcMain.ActivePage = tabDashboard then
    AtualizarDashboard
  else if pgcMain.ActivePage = tabRelogios then
    CarregarRelogios
  else if pgcMain.ActivePage = tabColaboradores then
  begin
    CarregarComboHorariosColab;
    CarregarColaboradores;
  end
  else if pgcMain.ActivePage = tabMarcacoes then
    CarregarMarcacoes
  else if pgcMain.ActivePage = tabHorarios then
    CarregarHorarios
  else if pgcMain.ActivePage = tabEspelho then
  begin
    CarregarComboColaboradoresEspelho;
    if (grdEspelho.RowCount <= 2) and (cmbEspelhoColab.Items.Count > 0) then
      btnCalcularEspelhoClick(nil);
  end;
end;

// =============================================================================
// HORÁRIOS & JORNADAS DE TRABALHO
// =============================================================================

procedure TfrmMain.CarregarHorarios;
var
  Qry: TFDQuery;
  OldDs: TDataSet;
begin
  OldDs := FdsHorarios.DataSet;
  Qry := dmDados.GetHorarios(False);
  FdsHorarios.DataSet := Qry;
  if Assigned(OldDs) then
    OldDs.Free;

  ConfigurarGridHorarios;

  if not Qry.IsEmpty then
  begin
    if (FSelectedHorarioId > 0) and Qry.Locate('HOR_ID', FSelectedHorarioId, []) then
      PreencherFormHorario(Qry)
    else
    begin
      Qry.First;
      PreencherFormHorario(Qry);
    end;
  end
  else
    LimparFormHorario;
end;

procedure TfrmMain.ConfigurarGridHorarios;
var
  Col: TColumn;
begin
  dbgHorarios.Columns.Clear;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_ID';
  Col.Title.Caption := 'ID';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 45;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_DESCRICAO';
  Col.Title.Caption := 'Descrição Completa da Jornada';
  Col.Title.Alignment := taLeftJustify;
  Col.Alignment := taLeftJustify;
  Col.Width := 460;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_ENTRADA_1';
  Col.Title.Caption := '1ª Entrada';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 90;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_SAIDA_1';
  Col.Title.Caption := '1ª Saída';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 90;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_ENTRADA_2';
  Col.Title.Caption := '2ª Entrada';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 90;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_SAIDA_2';
  Col.Title.Caption := '2ª Saída';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 90;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_CARGA_DIARIA_MIN';
  Col.Title.Caption := 'Carga Diária';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 130;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_TOLERANCIA_MIN';
  Col.Title.Caption := 'Tolerância CLT';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 105;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_COMPENSA_SABADO';
  Col.Title.Caption := 'Compensa Sábado';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 130;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_TRABALHA_SABADO';
  Col.Title.Caption := 'Trabalha Sábado';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 130;

  Col := dbgHorarios.Columns.Add;
  Col.FieldName := 'HOR_ATIVO';
  Col.Title.Caption := 'Status';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 85;
end;

procedure TfrmMain.LimparFormHorario;
begin
  FSelectedHorarioId := 0;
  edtHorDescricao.Text := 'Novo Horário Comercial';
  edtHorEntrada1.Text := '08:00';
  edtHorSaida1.Text := '12:00';
  edtHorEntrada2.Text := '13:12';
  edtHorSaida2.Text := '18:00';
  edtHorTolerancia.Text := '10';
  edtHorCarga.Text := '528';
  chkHorCompensaSab.Checked := True;
  chkHorTrabalhaSab.Checked := False;
  edtHorSabEntrada1.Text := '08:00';
  edtHorSabSaida1.Text := '12:00';
  chkHorAtivo.Checked := True;
  if edtHorDescricao.CanFocus then
    edtHorDescricao.SetFocus;
end;

procedure TfrmMain.PreencherFormHorario(AQry: TDataSet);
begin
  if (AQry = nil) or AQry.IsEmpty then
  begin
    LimparFormHorario;
    Exit;
  end;

  FSelectedHorarioId := AQry.FieldByName('HOR_ID').AsInteger;
  edtHorDescricao.Text := AQry.FieldByName('HOR_DESCRICAO').AsString;

  if AQry.FindField('HOR_ENTRADA_1') <> nil then
    edtHorEntrada1.Text := Copy(AQry.FieldByName('HOR_ENTRADA_1').AsString, 1, 5)
  else
    edtHorEntrada1.Text := '08:00';

  if AQry.FindField('HOR_SAIDA_1') <> nil then
    edtHorSaida1.Text := Copy(AQry.FieldByName('HOR_SAIDA_1').AsString, 1, 5)
  else
    edtHorSaida1.Text := '12:00';

  if AQry.FindField('HOR_ENTRADA_2') <> nil then
    edtHorEntrada2.Text := Copy(AQry.FieldByName('HOR_ENTRADA_2').AsString, 1, 5)
  else
    edtHorEntrada2.Text := '13:12';

  if AQry.FindField('HOR_SAIDA_2') <> nil then
    edtHorSaida2.Text := Copy(AQry.FieldByName('HOR_SAIDA_2').AsString, 1, 5)
  else
    edtHorSaida2.Text := '18:00';

  if AQry.FindField('HOR_TOLERANCIA_MIN') <> nil then
    edtHorTolerancia.Text := IntToStr(AQry.FieldByName('HOR_TOLERANCIA_MIN').AsInteger)
  else
    edtHorTolerancia.Text := '10';

  if AQry.FindField('HOR_CARGA_DIARIA_MIN') <> nil then
    edtHorCarga.Text := IntToStr(AQry.FieldByName('HOR_CARGA_DIARIA_MIN').AsInteger)
  else
    edtHorCarga.Text := '528';

  if AQry.FindField('HOR_COMPENSA_SABADO') <> nil then
    chkHorCompensaSab.Checked := SameText(AQry.FieldByName('HOR_COMPENSA_SABADO').AsString, 'S')
  else
    chkHorCompensaSab.Checked := True;

  if AQry.FindField('HOR_TRABALHA_SABADO') <> nil then
    chkHorTrabalhaSab.Checked := SameText(AQry.FieldByName('HOR_TRABALHA_SABADO').AsString, 'S')
  else
    chkHorTrabalhaSab.Checked := False;

  if AQry.FindField('HOR_SAB_ENTRADA_1') <> nil then
    edtHorSabEntrada1.Text := Copy(AQry.FieldByName('HOR_SAB_ENTRADA_1').AsString, 1, 5)
  else
    edtHorSabEntrada1.Text := '08:00';

  if AQry.FindField('HOR_SAB_SAIDA_1') <> nil then
    edtHorSabSaida1.Text := Copy(AQry.FieldByName('HOR_SAB_SAIDA_1').AsString, 1, 5)
  else
    edtHorSabSaida1.Text := '12:00';

  if AQry.FindField('HOR_ATIVO') <> nil then
    chkHorAtivo.Checked := SameText(AQry.FieldByName('HOR_ATIVO').AsString, 'S')
  else
    chkHorAtivo.Checked := True;
end;

procedure TfrmMain.btnNovoHorarioClick(Sender: TObject);
begin
  LimparFormHorario;
end;

procedure TfrmMain.btnAtualizarHorariosClick(Sender: TObject);
begin
  CarregarHorarios;
  CarregarComboHorariosColab;
  LogMessage('🔄 Lista de jornadas de trabalho atualizada.');
end;

procedure TfrmMain.dbgHorariosCellClick(Column: TColumn);
begin
  if (FdsHorarios.DataSet <> nil) and (not FdsHorarios.DataSet.IsEmpty) then
    PreencherFormHorario(FdsHorarios.DataSet);
end;

procedure TfrmMain.btnSalvarHorarioClick(Sender: TObject);
var
  Desc, E1, S1, E2, S2, SE1, SS1: string;
  Tol, Carga: Integer;
  CompSab, TrabSab, Ativo: Boolean;
  NovoId: Integer;
begin
  Desc := Trim(edtHorDescricao.Text);
  if Desc = '' then
  begin
    ShowMessage('Informe a descrição da jornada de trabalho.');
    edtHorDescricao.SetFocus;
    Exit;
  end;

  E1 := Trim(edtHorEntrada1.Text);
  S1 := Trim(edtHorSaida1.Text);
  E2 := Trim(edtHorEntrada2.Text);
  S2 := Trim(edtHorSaida2.Text);
  Tol := StrToIntDef(Trim(edtHorTolerancia.Text), 10);
  Carga := StrToIntDef(Trim(edtHorCarga.Text), 528);
  CompSab := chkHorCompensaSab.Checked;
  TrabSab := chkHorTrabalhaSab.Checked;
  SE1 := Trim(edtHorSabEntrada1.Text);
  SS1 := Trim(edtHorSabSaida1.Text);
  Ativo := chkHorAtivo.Checked;

  Screen.Cursor := crHourGlass;
  try
    NovoId := dmDados.SalvarHorario(FSelectedHorarioId, Desc, E1, S1, E2, S2, Tol, Carga, CompSab, TrabSab, SE1, SS1, Ativo);
    FSelectedHorarioId := NovoId;
    LogMessage(Format('💾 Jornada [%s] (ID %d) salva com sucesso.', [Desc, NovoId]));
    CarregarHorarios;
    CarregarComboHorariosColab;
    ShowMessage('Jornada de trabalho salva com sucesso!');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnSalvarEnviarHorarioClick(Sender: TObject);
var
  Desc, E1, S1, E2, S2, SE1, SS1: string;
  Tol, Carga: Integer;
  CompSab, TrabSab, Ativo: Boolean;
  NovoId: Integer;
  RelId: Integer;
  SincronizouRelogio: Boolean;
begin
  Desc := Trim(edtHorDescricao.Text);
  if Desc = '' then
  begin
    ShowMessage('Informe a descrição da jornada de trabalho.');
    if edtHorDescricao.CanFocus then edtHorDescricao.SetFocus;
    Exit;
  end;

  E1 := Trim(edtHorEntrada1.Text);
  S1 := Trim(edtHorSaida1.Text);
  E2 := Trim(edtHorEntrada2.Text);
  S2 := Trim(edtHorSaida2.Text);
  Tol := StrToIntDef(Trim(edtHorTolerancia.Text), 10);
  Carga := StrToIntDef(Trim(edtHorCarga.Text), 528);
  CompSab := chkHorCompensaSab.Checked;
  TrabSab := chkHorTrabalhaSab.Checked;
  SE1 := Trim(edtHorSabEntrada1.Text);
  SS1 := Trim(edtHorSabSaida1.Text);
  Ativo := chkHorAtivo.Checked;

  Screen.Cursor := crHourGlass;
  try
    // 1. Salvar no banco Firebird local
    NovoId := dmDados.SalvarHorario(FSelectedHorarioId, Desc, E1, S1, E2, S2, Tol, Carga, CompSab, TrabSab, SE1, SS1, Ativo);
    FSelectedHorarioId := NovoId;
    LogMessage(Format('💾 Jornada [%s] (ID %d) salva com sucesso no banco de dados.', [Desc, NovoId]));
    CarregarHorarios;
    CarregarComboHorariosColab;

    // 2. Sincronizar com o Relógio de Ponto Ativo
    RelId := ObterRelogioAtivoId;
    SincronizouRelogio := False;
    if RelId > 0 then
      SincronizouRelogio := FPontoService.SincronizarJornadaRelogio(RelId, NovoId, Desc, E1, S1, E2, S2);

    if SincronizouRelogio then
      ShowMessage(Format('Jornada [%s] salva no banco e sincronizada no relógio de ponto com sucesso!', [Desc]))
    else
      ShowMessage(Format('Jornada [%s] salva com sucesso no sistema local!'#13#10 +
                         'Nota: Nenhum relógio ativo online no momento para envio direto.', [Desc]));
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnExcluirHorarioClick(Sender: TObject);
var
  Erro: string;
begin
  if FSelectedHorarioId <= 0 then
  begin
    ShowMessage('Selecione uma jornada para excluir.');
    Exit;
  end;

  if MessageDlg(Format('Deseja realmente excluir a jornada selecionada (ID %d)?', [FSelectedHorarioId]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    if dmDados.ExcluirHorario(FSelectedHorarioId, Erro) then
    begin
      if Erro <> '' then
        ShowMessage(Erro)
      else
        ShowMessage('Jornada excluída com sucesso!');
      FSelectedHorarioId := 0;
      CarregarHorarios;
      CarregarComboHorariosColab;
    end
    else
      ShowMessage('Erro: ' + Erro);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.CarregarComboHorariosColab;
var
  Qry: TFDQuery;
  PrevHorId, Idx, I: Integer;
begin
  PrevHorId := 0;
  if cmbColabHorario.ItemIndex >= 0 then
    PrevHorId := Integer(NativeInt(cmbColabHorario.Items.Objects[cmbColabHorario.ItemIndex]));

  cmbColabHorario.Items.Clear;
  Qry := dmDados.GetHorarios(True);
  try
    while not Qry.Eof do
    begin
      cmbColabHorario.Items.AddObject(
        Format('%s (%d min/dia)', [Qry.FieldByName('HOR_DESCRICAO').AsString, Qry.FieldByName('HOR_CARGA_DIARIA_MIN').AsInteger]),
        TObject(NativeInt(Qry.FieldByName('HOR_ID').AsInteger))
      );
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;

  Idx := 0;
  if (PrevHorId > 0) and (cmbColabHorario.Items.Count > 0) then
  begin
    for I := 0 to cmbColabHorario.Items.Count - 1 do
    begin
      if Integer(NativeInt(cmbColabHorario.Items.Objects[I])) = PrevHorId then
      begin
        Idx := I;
        Break;
      end;
    end;
  end;

  if cmbColabHorario.Items.Count > 0 then
    cmbColabHorario.ItemIndex := Idx;
end;

procedure TfrmMain.CarregarComboColaboradoresEspelho;
var
  Qry: TFDQuery;
  PrevColabId, Idx, I: Integer;
begin
  PrevColabId := 0;
  if cmbEspelhoColab.ItemIndex >= 0 then
    PrevColabId := Integer(NativeInt(cmbEspelhoColab.Items.Objects[cmbEspelhoColab.ItemIndex]));

  cmbEspelhoColab.Items.Clear;
  Qry := dmDados.GetColaboradores(True);
  try
    while not Qry.Eof do
    begin
      cmbEspelhoColab.Items.AddObject(
        Format('%s (CPF: %s)', [Qry.FieldByName('PES_RSOCIAL_NOME').AsString, Qry.FieldByName('PES_CNPJ_CPF').AsString]),
        TObject(NativeInt(Qry.FieldByName('PES_ID').AsInteger))
      );
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;

  Idx := 0;
  if (PrevColabId > 0) and (cmbEspelhoColab.Items.Count > 0) then
  begin
    for I := 0 to cmbEspelhoColab.Items.Count - 1 do
    begin
      if Integer(NativeInt(cmbEspelhoColab.Items.Objects[I])) = PrevColabId then
      begin
        Idx := I;
        Break;
      end;
    end;
  end;

  if cmbEspelhoColab.Items.Count > 0 then
    cmbEspelhoColab.ItemIndex := Idx;
end;

// =============================================================================
// ESPELHO DE PONTO (APURAÇÃO & PORTARIA 671)
// =============================================================================

procedure TfrmMain.PreencherGridEspelho(AEspelho: TEspelhoPonto);
var
  I: Integer;
begin
  if AEspelho = nil then
    Exit;

  grdEspelho.RowCount := Max(2, Length(AEspelho.Dias) + 1);

  for I := 0 to High(AEspelho.Dias) do
  begin
    grdEspelho.Cells[0, I + 1] := FormatDateTime('dd/mm/yyyy', AEspelho.Dias[I].Data);
    grdEspelho.Cells[1, I + 1] := AEspelho.Dias[I].DiaSemana;
    grdEspelho.Cells[2, I + 1] := AEspelho.Dias[I].Entrada1;
    grdEspelho.Cells[3, I + 1] := AEspelho.Dias[I].Saida1;
    grdEspelho.Cells[4, I + 1] := AEspelho.Dias[I].Entrada2;
    grdEspelho.Cells[5, I + 1] := AEspelho.Dias[I].Saida2;
    grdEspelho.Cells[6, I + 1] := AEspelho.Dias[I].BatidasExtras;
    grdEspelho.Cells[7, I + 1] := AEspelho.Dias[I].CargaPrevistaStr;
    grdEspelho.Cells[8, I + 1] := AEspelho.Dias[I].TrabalhadoStr;
    grdEspelho.Cells[9, I + 1] := AEspelho.Dias[I].ExtraStr;
    grdEspelho.Cells[10, I + 1] := AEspelho.Dias[I].FaltaStr;
    grdEspelho.Cells[11, I + 1] := AEspelho.Dias[I].SaldoStr;
    grdEspelho.Cells[12, I + 1] := AEspelho.Dias[I].Ocorrencia;
  end;

  lblCardEsp1Val.Caption := AEspelho.Resumo.TotalPrevistoStr;
  lblCardEsp2Val.Caption := AEspelho.Resumo.TotalTrabalhadoStr;
  lblCardEsp3Val.Caption := '+' + AEspelho.Resumo.TotalExtrasStr;
  lblCardEsp4Val.Caption := '-' + AEspelho.Resumo.TotalFaltasStr;
  lblCardEsp5Val.Caption := AEspelho.Resumo.SaldoTotalStr;

  if AEspelho.Resumo.SaldoTotalMin >= 0 then
    lblCardEsp5Val.Font.Color := $002E7D32
  else
    lblCardEsp5Val.Font.Color := $00C53030;
end;

procedure TfrmMain.btnCalcularEspelhoClick(Sender: TObject);
var
  PessoaId: Integer;
  DtIni, DtFim: TDateTime;
begin
  if cmbEspelhoColab.ItemIndex < 0 then
  begin
    ShowMessage('Selecione um colaborador para apurar o ponto.');
    Exit;
  end;

  PessoaId := Integer(NativeInt(cmbEspelhoColab.Items.Objects[cmbEspelhoColab.ItemIndex]));
  DtIni := dtpEspelhoIni.Date;
  DtFim := dtpEspelhoFim.Date;

  if DtIni > DtFim then
  begin
    ShowMessage('A data inicial do período não pode ser maior que a data final.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    if Assigned(FUltimoEspelho) then
    begin
      FUltimoEspelho.Free;
      FUltimoEspelho := nil;
    end;

    FUltimoEspelho := TPontoCalculoService.CalcularEspelho(PessoaId, DtIni, DtFim);
    PreencherGridEspelho(FUltimoEspelho);
    LogMessage(Format('📋 Espelho de Ponto apurado para [%s] no período de %s a %s. Total trabalhado: %s, Extras: +%s, Faltas: -%s, Saldo: %s.',
      [FUltimoEspelho.Resumo.ColaboradorNome,
       FormatDateTime('dd/mm/yyyy', DtIni),
       FormatDateTime('dd/mm/yyyy', DtFim),
       FUltimoEspelho.Resumo.TotalTrabalhadoStr,
       FUltimoEspelho.Resumo.TotalExtrasStr,
       FUltimoEspelho.Resumo.TotalFaltasStr,
       FUltimoEspelho.Resumo.SaldoTotalStr]));
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnLancarJustificativaClick(Sender: TObject);
var
  PessoaId: Integer;
  Valores: array of string;
  DataJus: TDateTime;
  TipoJus, MotivoJus: string;
  AbonoMin: Integer;
begin
  if cmbEspelhoColab.ItemIndex < 0 then
  begin
    ShowMessage('Selecione um colaborador antes de lançar uma ocorrência.');
    Exit;
  end;

  PessoaId := Integer(NativeInt(cmbEspelhoColab.Items.Objects[cmbEspelhoColab.ItemIndex]));

  SetLength(Valores, 4);
  Valores[0] := FormatDateTime('dd/mm/yyyy', Date);
  Valores[1] := 'Atestado Médico';
  Valores[2] := 'Atestado médico de consulta';
  Valores[3] := '0';

  if InputQuery('Lançar Ocorrência / Justificativa (Portaria 671)',
       ['Data da Ocorrência (DD/MM/AAAA):',
        'Tipo (Atestado Médico, Folga, Feriado, Declaração):',
        'Motivo / Justificativa detalhada:',
        'Minutos a Abonar (0 para o dia integral):'],
       Valores) then
  begin
    if not TryStrToDate(Valores[0], DataJus) then
    begin
      ShowMessage('Data informada é inválida.');
      Exit;
    end;

    TipoJus := Trim(Valores[1]);
    MotivoJus := Trim(Valores[2]);
    AbonoMin := StrToIntDef(Valores[3], 0);

    if TipoJus = '' then
      TipoJus := 'Atestado Médico';

    if dmDados.SalvarJustificativa(PessoaId, DataJus, TipoJus, MotivoJus, AbonoMin) then
    begin
      LogMessage(Format('📝 Justificativa registrada para o colaborador (ID %d) no dia %s: %s (%s).',
        [PessoaId, FormatDateTime('dd/mm/yyyy', DataJus), TipoJus, MotivoJus]));
      ShowMessage('Justificativa lançada com sucesso! Recalculando espelho...');
      btnCalcularEspelhoClick(nil);
    end
    else
      ShowMessage('Erro ao registrar justificativa no banco de dados.');
  end;
end;

procedure TfrmMain.btnCorrigirBatidaEspelhoClick(Sender: TObject);
var
  Idx, ColabId: Integer;
  Prompts, Values: array of string;
  DataStr, HoraStr, TipoStr, MotivoStr: string;
  DataBat, HoraBat, DataHoraBat: TDateTime;
  NovoId: Integer;
begin
  Idx := cmbEspelhoColab.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Selecione primeiro o colaborador no Espelho de Ponto.');
    Exit;
  end;

  ColabId := Integer(NativeInt(cmbEspelhoColab.Items.Objects[Idx]));
  if ColabId <= 0 then
  begin
    ShowMessage('Colaborador selecionado inválido.');
    Exit;
  end;

  SetLength(Prompts, 4);
  SetLength(Values, 4);

  Prompts[0] := 'Data da Batida (DD/MM/AAAA):';
  Values[0] := FormatDateTime('dd/mm/yyyy', dtpEspelhoIni.Date);

  Prompts[1] := 'Hora da Batida (HH:MM:SS):';
  Values[1] := '08:00:00';

  Prompts[2] := 'Tipo de Batida (E = Entrada, S = Saída):';
  Values[2] := 'E';

  Prompts[3] := 'Motivo da Inclusão/Correção (Portaria 671):';
  Values[3] := 'Esquecimento de registro';

  if not InputQuery(Format('Corrigir / Incluir Batida - %s', [cmbEspelhoColab.Text]), Prompts, Values) then
    Exit;

  DataStr := Trim(Values[0]);
  HoraStr := Trim(Values[1]);
  TipoStr := UpperCase(Trim(Values[2]));
  MotivoStr := Trim(Values[3]);

  if not TryStrToDate(DataStr, DataBat) then
  begin
    ShowMessage('Data informada é inválida.');
    Exit;
  end;

  if not TryStrToTime(HoraStr, HoraBat) then
  begin
    ShowMessage('Hora informada é inválida.');
    Exit;
  end;

  if (TipoStr <> 'E') and (TipoStr <> 'S') then
  begin
    ShowMessage('Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
    Exit;
  end;

  DataHoraBat := Trunc(DataBat) + Frac(HoraBat);

  Screen.Cursor := crHourGlass;
  try
    NovoId := dmDados.InserirMarcacaoManual(ColabId, ObterRelogioAtivoId, DataHoraBat, TipoStr);
    if NovoId > 0 then
    begin
      LogMessage(Format('✏️ Batida inserida/corrigida no espelho ID %d para %s (%s) - %s',
        [NovoId, FormatDateTime('dd/mm/yyyy hh:nn:ss', DataHoraBat), TipoStr, cmbEspelhoColab.Text]));
      btnCalcularEspelhoClick(nil);
      ShowMessage('Batida gravada e Espelho de Ponto recalculado com sucesso!');
    end
    else
      ShowMessage('Erro ao registrar batida no banco de dados.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnExportarEspelhoHTMLClick(Sender: TObject);
var
  Html: string;
  Razao, Cnpj, Endereco, Cei, CpfResp: string;
  ArquivoTemp: string;
  Stream: TStreamWriter;
begin
  if FUltimoEspelho = nil then
  begin
    ShowMessage('Por favor, clique em "Apurar Ponto" antes de exportar ou visualizar o espelho.');
    Exit;
  end;

  Razao := 'Empresa';
  Cnpj := '';
  dmDados.GetEmpresaPrincipal(Razao, Cnpj, Endereco, Cei, CpfResp);

  Html := FUltimoEspelho.GerarRelatorioHTML(Razao, Cnpj);
  ArquivoTemp := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'Espelho_Ponto_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.html';

  Stream := TStreamWriter.Create(ArquivoTemp, False, TEncoding.UTF8);
  try
    Stream.Write(Html);
  finally
    Stream.Free;
  end;

  ShellExecute(0, 'open', PChar(ArquivoTemp), nil, nil, SW_SHOWNORMAL);
  LogMessage(Format('📄 Espelho de Ponto gerado e aberto no navegador: %s', [ArquivoTemp]));
end;

procedure TfrmMain.grdEspelhoDrawCell(Sender: TObject; ACol, ARow: Longint;
  Rect: TRect; State: TGridDrawState);
var
  Texto: string;
  TxtRect: TRect;
begin
  if (ARow = 0) then
  begin
    grdEspelho.Canvas.Brush.Color := $009A572B; // #2B579A Azul Corporativo
    grdEspelho.Canvas.Font.Color := clWhite;
    grdEspelho.Canvas.Font.Style := [fsBold];
    grdEspelho.Canvas.FillRect(Rect);
    Texto := grdEspelho.Cells[ACol, ARow];
    TxtRect := Rect;
    TxtRect.Top := TxtRect.Top + 4;
    DrawText(grdEspelho.Canvas.Handle, PChar(Texto), -1, TxtRect, DT_CENTER or DT_SINGLELINE);
    Exit;
  end;

  if not (gdSelected in State) then
  begin
    if (ACol = 1) and ((grdEspelho.Cells[1, ARow] = 'Dom') or (grdEspelho.Cells[1, ARow] = 'Sáb') or (grdEspelho.Cells[1, ARow] = 'Sab')) then
      grdEspelho.Canvas.Brush.Color := $00F5F6F8
    else if (ARow mod 2 = 0) then
      grdEspelho.Canvas.Brush.Color := $00FAFAFA
    else
      grdEspelho.Canvas.Brush.Color := clWhite;

    grdEspelho.Canvas.Font.Color := clBlack;
    grdEspelho.Canvas.Font.Style := [];

    if (ACol = 9) and (grdEspelho.Cells[9, ARow] <> '00:00') and (grdEspelho.Cells[9, ARow] <> '') then
    begin
      grdEspelho.Canvas.Font.Color := $002E7D32;
      grdEspelho.Canvas.Font.Style := [fsBold];
    end
    else if (ACol = 10) and (grdEspelho.Cells[10, ARow] <> '00:00') and (grdEspelho.Cells[10, ARow] <> '') then
    begin
      grdEspelho.Canvas.Font.Color := $003030C5;
      grdEspelho.Canvas.Font.Style := [fsBold];
    end
    else if (ACol = 11) then
    begin
      if Pos('+', grdEspelho.Cells[11, ARow]) > 0 then
      begin
        grdEspelho.Canvas.Font.Color := $002E7D32;
        grdEspelho.Canvas.Font.Style := [fsBold];
      end
      else if Pos('-', grdEspelho.Cells[11, ARow]) > 0 then
      begin
        grdEspelho.Canvas.Font.Color := $003030C5;
        grdEspelho.Canvas.Font.Style := [fsBold];
      end;
    end
    else if (ACol = 12) and (Pos('Falta', grdEspelho.Cells[12, ARow]) > 0) then
    begin
      grdEspelho.Canvas.Font.Color := $003030C5;
      grdEspelho.Canvas.Font.Style := [fsBold];
    end
    else if (ACol = 12) and ((Pos('Ímpar', grdEspelho.Cells[12, ARow]) > 0) or (Pos('Impar', grdEspelho.Cells[12, ARow]) > 0)) then
    begin
      grdEspelho.Canvas.Font.Color := $000677D9;
      grdEspelho.Canvas.Font.Style := [fsBold];
    end;
  end;

  grdEspelho.Canvas.FillRect(Rect);
  Texto := grdEspelho.Cells[ACol, ARow];
  TxtRect := Rect;
  TxtRect.Left := TxtRect.Left + 4;
  TxtRect.Right := TxtRect.Right - 4;
  TxtRect.Top := TxtRect.Top + 4;

  if (ACol in [0..11]) then
    DrawText(grdEspelho.Canvas.Handle, PChar(Texto), -1, TxtRect, DT_CENTER or DT_SINGLELINE)
  else
    DrawText(grdEspelho.Canvas.Handle, PChar(Texto), -1, TxtRect, DT_LEFT or DT_SINGLELINE);
end;

// ======================= Visual, Emojis e Grids =======================

procedure SetControlRounded(AControl: TWinControl; ARadius: Integer);
var
  Rgn: HRGN;
begin
  if (AControl <> nil) and (AControl.Width > 0) and (AControl.Height > 0) then
  begin
    AControl.HandleNeeded;
    if AControl.HandleAllocated then
    begin
      Rgn := CreateRoundRectRgn(0, 0, AControl.Width + 1, AControl.Height + 1, ARadius, ARadius);
      SetWindowRgn(AControl.Handle, Rgn, True);
    end;
  end;
end;

procedure TfrmMain.CriarBotoesSkia;
  function CriarBtn(AOriginal: TButton; const ACaption: string; AKind: TSkButtonKind; ARadius: Single = 10; AFontSize: Single = 11; AEmojiSize: Single = 16): TSkModernButton;
  begin
    Result := TSkModernButton.Create(Self);
    Result.Parent := AOriginal.Parent;
    Result.SetBounds(AOriginal.Left, AOriginal.Top, AOriginal.Width, AOriginal.Height);
    Result.Anchors := AOriginal.Anchors;
    Result.Caption := ACaption;
    Result.Kind := AKind;
    Result.Radius := ARadius;
    Result.FontSize := AFontSize;
    Result.EmojiSize := AEmojiSize;
    Result.OnClick := AOriginal.OnClick;
    AOriginal.Visible := False;
  end;
begin
  // Ações de Topo - Grandes, imponentes, espaçados e com emojis vibrantes destacados
  btnQuickTest.SetBounds(10, 21, 155, 42);
  btnQuickSyncTime.SetBounds(175, 21, 165, 42);
  btnQuickCollect.SetBounds(350, 21, 175, 42);
  btnQuickAuto.SetBounds(535, 21, 135, 42);

  skQuickTest := CriarBtn(btnQuickTest, '⚡ Testar Conexão', sbkPrimary, 12, 11, 17);
  skQuickSyncTime := CriarBtn(btnQuickSyncTime, '🕒 Sincronizar Hora', sbkTeal, 12, 11, 17);
  skQuickCollect := CriarBtn(btnQuickCollect, '📥 Coletar Marcações', sbkSuccess, 12, 11, 17);
  if tmrAutoColeta.Enabled then
    skQuickAuto := CriarBtn(btnQuickAuto, '🔄 Auto: ON', sbkSuccess, 12, 11, 17)
  else
    skQuickAuto := CriarBtn(btnQuickAuto, '🔄 Auto: OFF', sbkDark, 12, 11, 17);

  // Ações de Topo Esquerda - Configurações e Atualizações
  btnTopConfig.SetBounds(320, 21, 145, 42);
  skTopConfig := CriarBtn(btnTopConfig, '⚙️ Configurações', sbkDark, 12, 11, 17);

  btnTopUpdate.SetBounds(480, 21, 220, 42);
  skTopUpdate := CriarBtn(btnTopUpdate, '🚀 Atualização!', sbkWarning, 12, 11, 17);
  skTopUpdate.Visible := False;

  btnConfigVoltar.SetBounds(450, 470, 180, 40);
  skConfigVoltar := CriarBtn(btnConfigVoltar, '← Voltar ao Sistema', sbkPrimary, 10, 10.5, 15);

  // Log do Dashboard
  btnClearLog.Anchors := [akTop, akRight];
  btnSaveLog.Anchors := [akTop, akRight];
  btnClearLog.SetBounds(pnlLogHeader.ClientWidth - 305, 5, 140, 35);
  btnSaveLog.SetBounds(pnlLogHeader.ClientWidth - 155, 5, 145, 35);
  skClearLog := CriarBtn(btnClearLog, '🧹 Limpar Log', sbkDark, 8, 10.5, 15);
  skSaveLog := CriarBtn(btnSaveLog, '💾 Salvar Log', sbkSuccess, 8, 10.5, 15);
  skClearLog.Anchors := [akTop, akRight];
  skSaveLog.Anchors := [akTop, akRight];

  // Aba Relógios
  btnNovoRelogio.SetBounds(10, 6, 155, 38);
  btnAtualizarRelogios.SetBounds(175, 6, 130, 38);
  skNovoRelogio := CriarBtn(btnNovoRelogio, '➕ Novo Relógio', sbkSuccess, 8, 11, 16);
  skAtualizarRelogios := CriarBtn(btnAtualizarRelogios, '🔄 Atualizar', sbkPrimary, 8, 11, 16);

  btnSalvarRelogio.SetBounds(0, 4, 130, 36);
  btnExcluirRelogio.SetBounds(142, 4, 125, 36);
  btnTestarEsteRelogio.SetBounds(279, 4, 140, 36);
  btnSincHoraEste.SetBounds(0, 45, 185, 36);
  btnColetarEste.SetBounds(195, 45, 195, 36);

  skSalvarRelogio := CriarBtn(btnSalvarRelogio, '💾 Salvar', sbkSuccess, 8, 10.5, 16);
  skExcluirRelogio := CriarBtn(btnExcluirRelogio, '🗑️ Excluir', sbkDanger, 8, 10.5, 16);
  skTestarEsteRelogio := CriarBtn(btnTestarEsteRelogio, '⚡ Testar', sbkPrimary, 8, 10.5, 16);
  skSincHoraEste := CriarBtn(btnSincHoraEste, '🕒 Sincronizar Hora', sbkTeal, 8, 10.5, 16);
  skColetarEste := CriarBtn(btnColetarEste, '📥 Coletar Marcações', sbkSuccess, 8, 10.5, 16);

  // Aba Colaboradores - Barra superior da grid
  btnAtualizarColab.SetBounds(225, 8, 110, 38);
  btnEnviarTodosPendentes.SetBounds(345, 8, 165, 38);
  btnImportarDoRelogio.SetBounds(520, 8, 135, 38);
  btnLimparTodosRelogio.SetBounds(665, 8, 155, 38);
  btnEnviarColabRelogio.Visible := False;
  btnRemoverColabRelogio.Visible := False;

  skAtualizarColab := CriarBtn(btnAtualizarColab, '🔄 Atualizar', sbkPrimary, 8, 10.5, 16);
  skEnviarTodosPendentes := CriarBtn(btnEnviarTodosPendentes, '🚀 Enviar Pendentes', sbkWarning, 8, 10.5, 16);
  skImportarDoRelogio := CriarBtn(btnImportarDoRelogio, '📥 No Relógio', sbkPurple, 8, 10.5, 16);
  skLimparTodosRelogio := CriarBtn(btnLimparTodosRelogio, '⚠️ Limpar Relógio', sbkDanger, 8, 10.5, 16);

  // Aba Colaboradores - Formulário de Edição e Ações
  btnSalvarColab.SetBounds(0, 4, 95, 36);
  btnSalvarEnviarColab.SetBounds(105, 4, 215, 36);
  btnNovoColab.SetBounds(330, 4, 95, 36);
  btnRemoverColabForm.SetBounds(0, 46, 210, 36);
  btnExcluirColabBanco.SetBounds(220, 46, 205, 36);

  skSalvarColab := CriarBtn(btnSalvarColab, '💾 Salvar', sbkPrimary, 8, 10.5, 16);
  skSalvarEnviarColab := CriarBtn(btnSalvarEnviarColab, '📤 Salvar e Enviar ao Ponto', sbkSuccess, 8, 10.5, 16);
  skNovoColab := CriarBtn(btnNovoColab, '➕ Novo', sbkDark, 8, 10.5, 16);
  skRemoverColabForm := CriarBtn(btnRemoverColabForm, '❌ Remover do Relógio', sbkDanger, 8, 10.5, 16);
  skExcluirColabBanco := CriarBtn(btnExcluirColabBanco, '🗑️ Excluir do Banco', sbkDanger, 8, 10.5, 16);

  // Aba Marcações
  btnFiltrarMarcacoes.SetBounds(495, 18, 115, 40);
  btnEditarMarcacao.SetBounds(618, 18, 145, 40);
  btnNovaMarcacao.SetBounds(770, 18, 140, 40);
  btnExportarAFD.SetBounds(918, 18, 155, 40);
  btnExcluirMarcacao.SetBounds(1080, 18, 135, 40);
  lblTotalMarcacoesGrid.Anchors := [akTop, akRight];
  lblTotalMarcacoesGrid.Left := pnlMarcacoesFiltro.ClientWidth - 170;
  lblTotalMarcacoesGrid.Top := 30;
  skFiltrarMarcacoes := CriarBtn(btnFiltrarMarcacoes, '🔍 Filtrar', sbkPrimary, 8, 10.5, 15);
  skEditarMarcacao := CriarBtn(btnEditarMarcacao, '✏️ Corrigir Batida', sbkWarning, 8, 10.5, 15);
  skNovaMarcacao := CriarBtn(btnNovaMarcacao, '➕ Incluir Batida', sbkSuccess, 8, 10.5, 15);
  skExportarAFD := CriarBtn(btnExportarAFD, '📄 Exportar Registros', sbkPurple, 8, 10.5, 15);
  skExcluirMarcacao := CriarBtn(btnExcluirMarcacao, '🗑️ Excluir Batida', sbkDanger, 8, 10.5, 15);

  // Aba Configurações & Empregador
  btnSalvarConfig.SetBounds(30, 465, 225, 44);
  btnTestarConexaoFB.SetBounds(265, 465, 215, 44);
  skSalvarConfig := CriarBtn(btnSalvarConfig, '💾 Salvar Configurações', sbkSuccess, 10, 11, 17);
  skTestarConexaoFB := CriarBtn(btnTestarConexaoFB, '🔌 Testar Firebird', sbkPrimary, 10, 11, 17);

  btnCarregarEmpBanco.SetBounds(20, 295, 215, 38);
  btnSalvarEmpBanco.SetBounds(255, 295, 215, 38);
  btnEnviarEmpRelogio.SetBounds(20, 345, 215, 40);
  btnLerEmpRelogio.SetBounds(255, 345, 215, 40);
  skCarregarEmpBanco := CriarBtn(btnCarregarEmpBanco, '📥 Carregar do Banco', sbkPrimary, 8, 10.5, 16);
  skSalvarEmpBanco := CriarBtn(btnSalvarEmpBanco, '💾 Salvar no Banco', sbkSuccess, 8, 10.5, 16);
  skEnviarEmpRelogio := CriarBtn(btnEnviarEmpRelogio, '🏢 Enviar ao Relógio', sbkWarning, 8, 10.5, 16);
  skLerEmpRelogio := CriarBtn(btnLerEmpRelogio, '📖 Ler do Relógio', sbkPurple, 8, 10.5, 16);

  // Aba Horários & Jornadas
  btnNovoHorario.SetBounds(12, 6, 145, 34);
  btnAtualizarHorarios.SetBounds(165, 6, 120, 34);
  skNovoHorario := CriarBtn(btnNovoHorario, '➕ Novo Horário', sbkSuccess, 8, 10.5, 15);
  skAtualizarHorarios := CriarBtn(btnAtualizarHorarios, '🔄 Atualizar', sbkPrimary, 8, 10.5, 15);

  btnSalvarHorario.SetBounds(0, 4, 110, 36);
  btnSalvarEnviarHorario.SetBounds(118, 4, 205, 36);
  btnNovoHorarioForm.SetBounds(330, 4, 100, 36);
  btnExcluirHorario.SetBounds(0, 45, 140, 36);
  skSalvarHorario := CriarBtn(btnSalvarHorario, '💾 Salvar', sbkPrimary, 8, 10.5, 15);
  skSalvarEnviarHorario := CriarBtn(btnSalvarEnviarHorario, '📤 Salvar e Atualizar Ponto', sbkSuccess, 8, 10.5, 15);
  skNovoHorarioForm := CriarBtn(btnNovoHorarioForm, '✨ Novo', sbkDark, 8, 10.5, 15);
  skExcluirHorario := CriarBtn(btnExcluirHorario, '🗑️ Excluir', sbkDanger, 8, 10.5, 15);

  // Aba Espelho de Ponto
  btnCalcularEspelho.SetBounds(518, 18, 145, 36);
  btnLancarJustificativa.SetBounds(672, 18, 180, 36);
  btnExportarEspelhoHTML.SetBounds(860, 18, 200, 36);
  btnCorrigirBatidaEspelho.SetBounds(1070, 18, 210, 36);
  skCalcularEspelho := CriarBtn(btnCalcularEspelho, '⚙️ Apurar Ponto', sbkPrimary, 8, 10.5, 16);
  skLancarJustificativa := CriarBtn(btnLancarJustificativa, '📝 Lançar Ocorrência', sbkPurple, 8, 10.5, 16);
  skExportarEspelhoHTML := CriarBtn(btnExportarEspelhoHTML, '🖨️ Visualizar / Imprimir', sbkSuccess, 8, 10.5, 16);
  skCorrigirBatidaEspelho := CriarBtn(btnCorrigirBatidaEspelho, '✏️ Corrigir / Incluir Batida', sbkWarning, 8, 10.5, 16);
end;

procedure TfrmMain.ArredondarControles;
var
  I: Integer;
  Btn: TButton;
begin
  for I := 0 to ComponentCount - 1 do
  begin
    if Components[I] is TButton then
    begin
      Btn := TButton(Components[I]);
      Btn.Cursor := crHandPoint;
      SetControlRounded(Btn, 8);
    end;
  end;

  SetControlRounded(pnlCard1, 10);
  SetControlRounded(pnlCard2, 10);
  SetControlRounded(pnlCard3, 10);
  SetControlRounded(pnlCard4, 10);
  SetControlRounded(pnlCardEsp1, 10);
  SetControlRounded(pnlCardEsp2, 10);
  SetControlRounded(pnlCardEsp3, 10);
  SetControlRounded(pnlCardEsp4, 10);
  SetControlRounded(pnlCardEsp5, 10);
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  ArredondarControles;
end;

procedure TfrmMain.ConfigurarGridRelogios;
var
  Col: TColumn;
begin
  dbgRelogios.Columns.Clear;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_ID';
  Col.Title.Caption := 'ID';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 45;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_NOME';
  Col.Title.Caption := 'Nome do Equipamento';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 180;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_IP';
  Col.Title.Caption := 'Endereço IP';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 115;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_PORTA';
  Col.Title.Caption := 'Porta';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 50;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_USAR_SSL';
  Col.Title.Caption := 'HTTPS';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 65;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_MODELO';
  Col.Title.Caption := 'Modelo';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 100;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_SERIAL';
  Col.Title.Caption := 'Nº de Série';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 145;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_VERSAO_FW';
  Col.Title.Caption := 'Firmware';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 75;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_ATIVO';
  Col.Title.Caption := 'Ativo';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 65;

  Col := dbgRelogios.Columns.Add;
  Col.FieldName := 'PRE_ULTIMA_COLETA';
  Col.Title.Caption := 'Última Coleta';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 135;
end;

procedure TfrmMain.ConfigurarGridColaboradores;
var
  Col: TColumn;
begin
  dbgColaboradores.Columns.Clear;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'PES_ID';
  Col.Title.Caption := 'ID';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 50;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'PES_RSOCIAL_NOME';
  Col.Title.Caption := 'Nome do Colaborador';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 250;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'PES_CNPJ_CPF';
  Col.Title.Caption := 'CPF';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 115;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'COL_PIS';
  Col.Title.Caption := 'PIS / PASEP';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 115;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'COL_CARTAO_PONTO';
  Col.Title.Caption := 'Crachá / Matrícula';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 115;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'COL_FUNCAO';
  Col.Title.Caption := 'Função / Cargo';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 140;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'COL_SINCRONIZADO_RELOGIO';
  Col.Title.Caption := 'Sincronizado?';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 120;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'COL_ULTIMA_SINCRONIZACAO';
  Col.Title.Caption := 'Último Envio';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 135;

  Col := dbgColaboradores.Columns.Add;
  Col.FieldName := 'PES_STATUS';
  Col.Title.Caption := 'Status';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 75;
end;

procedure TfrmMain.ConfigurarGridMarcacoes;
var
  Col: TColumn;
begin
  dbgMarcacoes.Columns.Clear;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_ID';
  Col.Title.Caption := 'ID';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 50;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_NSR';
  Col.Title.Caption := 'NSR';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 70;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_DATA_HORA';
  Col.Title.Caption := 'Data e Hora';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 145;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PESSOA_NOME';
  Col.Title.Caption := 'Nome do Colaborador';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 340;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_CPF';
  Col.Title.Caption := 'CPF';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 120;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_PIS';
  Col.Title.Caption := 'PIS';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 120;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_TIPO_BATIDA';
  Col.Title.Caption := 'Tipo Batida';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 100;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'RELOGIO_NOME';
  Col.Title.Caption := 'Equipamento';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 220;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_ORIGEM';
  Col.Title.Caption := 'Origem';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 95;

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_EXPORTADO';
  Col.Title.Caption := 'Exportado';
  Col.Title.Alignment := taCenter;
  Col.Alignment := taCenter;
  Col.Width := 95;
end;

procedure TfrmMain.dbgGridDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  Grid: TDBGrid;
  Fld: TField;
  Txt: string;
  DrawRect, BadgeRect: TRect;
  BgColor, TxtColor, BadgeBg, BadgeBorder, BadgeTxtColor: TColor;
  IsBadge: Boolean;
  Mins: Integer;
begin
  Grid := Sender as TDBGrid;
  Fld := Column.Field;
  if not Assigned(Fld) then
  begin
    Grid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
    Exit;
  end;

  // 1. Cor de Fundo Zebra e Seleção
  if gdSelected in State then
  begin
    BgColor := $00EBF3F8; // Azul suave de seleção
    TxtColor := $002B2B2B;
  end
  else
  begin
    if (Grid.DataSource <> nil) and (Grid.DataSource.DataSet <> nil) and
       (Grid.DataSource.DataSet.RecNo mod 2 = 0) then
      BgColor := $00F9FBFB // Zebra suave
    else
      BgColor := clWhite;
    TxtColor := $00333333;
  end;

  Grid.Canvas.Brush.Color := BgColor;
  Grid.Canvas.FillRect(Rect);
  Grid.Canvas.Font.Color := TxtColor;
  Grid.Canvas.Font.Name := 'Segoe UI';
  Grid.Canvas.Font.Size := 9;

  IsBadge := False;
  BadgeBg := clWhite;
  BadgeBorder := clSilver;
  BadgeTxtColor := clBlack;
  Txt := Fld.DisplayText;

  // 2. Formatações Especiais e Badges
  if (Column.FieldName = 'COL_SINCRONIZADO_RELOGIO') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'S') then
    begin
      Txt := '✓ Sim';
      BadgeBg := $00E6F4EA;      // Verde suave
      BadgeBorder := $00CEEAD6;
      BadgeTxtColor := $00137333;
    end
    else
    begin
      Txt := '⏳ Pendente';
      BadgeBg := $00FEF7E0;      // Amarelo / Âmbar suave
      BadgeBorder := $00FEEFC3;
      BadgeTxtColor := $00B06000;
    end;
  end
  else if (Column.FieldName = 'PES_STATUS') or (Column.FieldName = 'PRE_ATIVO') or (Column.FieldName = 'HOR_ATIVO') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'S') or SameText(Fld.AsString, 'A') then
    begin
      Txt := 'Ativo';
      BadgeBg := $00E6F4EA;
      BadgeBorder := $00CEEAD6;
      BadgeTxtColor := $00137333;
    end
    else
    begin
      Txt := 'Inativo';
      BadgeBg := $00FCE8E6;      // Vermelho suave
      BadgeBorder := $00FAD2CF;
      BadgeTxtColor := $00C5221F;
    end;
  end
  else if (Column.FieldName = 'HOR_COMPENSA_SABADO') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'S') then
    begin
      Txt := '✓ Sim (Folga)';
      BadgeBg := $00E6F4EA;
      BadgeBorder := $00CEEAD6;
      BadgeTxtColor := $00137333;
    end
    else
    begin
      Txt := '✕ Não';
      BadgeBg := $00F1F3F4;
      BadgeBorder := $00DADCE0;
      BadgeTxtColor := $005F6368;
    end;
  end
  else if (Column.FieldName = 'HOR_TRABALHA_SABADO') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'S') then
    begin
      Txt := '✓ Sim';
      BadgeBg := $00FEF7E0;
      BadgeBorder := $00FEEFC3;
      BadgeTxtColor := $00B06000;
    end
    else
    begin
      Txt := '✕ Não';
      BadgeBg := $00F1F3F4;
      BadgeBorder := $00DADCE0;
      BadgeTxtColor := $005F6368;
    end;
  end
  else if (Column.FieldName = 'HOR_CARGA_DIARIA_MIN') then
  begin
    if not Fld.IsNull then
    begin
      Mins := Fld.AsInteger;
      Txt := Format('%dh%02d (%d min)', [Mins div 60, Mins mod 60, Mins]);
    end;
  end
  else if (Column.FieldName = 'HOR_TOLERANCIA_MIN') then
  begin
    if not Fld.IsNull then
      Txt := Format('%d min', [Fld.AsInteger]);
  end
  else if (Column.FieldName = 'HOR_ENTRADA_1') or (Column.FieldName = 'HOR_SAIDA_1') or
          (Column.FieldName = 'HOR_ENTRADA_2') or (Column.FieldName = 'HOR_SAIDA_2') or
          (Column.FieldName = 'HOR_SAB_ENTRADA_1') or (Column.FieldName = 'HOR_SAB_SAIDA_1') or
          (Column.FieldName = 'HOR_SABADO_ENTRADA') or (Column.FieldName = 'HOR_SABADO_SAIDA') then
  begin
    if not Fld.IsNull then
    begin
      if Fld.DataType in [ftTime, ftDateTime, ftTimeStamp] then
        Txt := FormatDateTime('hh:nn', Fld.AsDateTime)
      else if Length(Trim(Fld.AsString)) >= 5 then
        Txt := Copy(Trim(Fld.AsString), 1, 5);
    end;
  end
  else if (Column.FieldName = 'PRE_USAR_SSL') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'S') then
    begin
      Txt := 'HTTPS';
      BadgeBg := $00E8F0FE;      // Azul suave
      BadgeBorder := $00D2E3FC;
      BadgeTxtColor := $001A73E8;
    end
    else
    begin
      Txt := 'HTTP';
      BadgeBg := $00F1F3F4;
      BadgeBorder := $00DADCE0;
      BadgeTxtColor := $005F6368;
    end;
  end
  else if (Column.FieldName = 'PMA_TIPO_BATIDA') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'E') or SameText(Fld.AsString, 'ENTRADA') then
    begin
      Txt := 'Entrada';
      BadgeBg := $00E6F4EA;
      BadgeBorder := $00CEEAD6;
      BadgeTxtColor := $00137333;
    end
    else if SameText(Fld.AsString, 'S') or SameText(Fld.AsString, 'SAIDA') or SameText(Fld.AsString, 'SAÍDA') then
    begin
      Txt := 'Saída';
      BadgeBg := $00E8F0FE;
      BadgeBorder := $00D2E3FC;
      BadgeTxtColor := $001A73E8;
    end
    else
    begin
      Txt := 'Registro';
      BadgeBg := $00F1F3F4;
      BadgeBorder := $00DADCE0;
      BadgeTxtColor := $005F6368;
    end;
  end
  else if (Column.FieldName = 'PMA_ORIGEM') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'M') then
    begin
      Txt := '✏️ Manual';
      BadgeBg := $00FEF7E0;
      BadgeBorder := $00FEEFC3;
      BadgeTxtColor := $00B06000;
    end
    else
    begin
      Txt := 'Relógio';
      BadgeBg := $00F1F3F4;
      BadgeBorder := $00DADCE0;
      BadgeTxtColor := $005F6368;
    end;
  end
  else if (Column.FieldName = 'PMA_EXPORTADO') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'S') then
    begin
      Txt := '✓ Sim';
      BadgeBg := $00E6F4EA;
      BadgeBorder := $00CEEAD6;
      BadgeTxtColor := $00137333;
    end
    else
    begin
      Txt := 'Pendente';
      BadgeBg := $00F1F3F4;
      BadgeBorder := $00DADCE0;
      BadgeTxtColor := $005F6368;
    end;
  end
  else if (Column.FieldName = 'PES_CNPJ_CPF') or (Column.FieldName = 'PMA_CPF') then
  begin
    Txt := Trim(Fld.AsString);
    if Length(Txt) = 11 then
      Txt := Copy(Txt, 1, 3) + '.' + Copy(Txt, 4, 3) + '.' + Copy(Txt, 7, 3) + '-' + Copy(Txt, 10, 2);
  end
  else if (Fld.DataType in [ftDateTime, ftTimeStamp]) and (not Fld.IsNull) then
  begin
    Txt := FormatDateTime('dd/mm/yyyy hh:nn:ss', Fld.AsDateTime);
  end;

  // 3. Renderização
  if IsBadge then
  begin
    BadgeRect := Rect;
    InflateRect(BadgeRect, -3, -2);
    Grid.Canvas.Brush.Color := BadgeBg;
    Grid.Canvas.Pen.Color := BadgeBorder;
    Grid.Canvas.RoundRect(BadgeRect.Left, BadgeRect.Top, BadgeRect.Right, BadgeRect.Bottom, 6, 6);

    Grid.Canvas.Font.Color := BadgeTxtColor;
    Grid.Canvas.Font.Style := [fsBold];
    DrawText(Grid.Canvas.Handle, PChar(Txt), Length(Txt), BadgeRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end
  else
  begin
    DrawRect := Rect;
    InflateRect(DrawRect, -5, 0);

    if Column.Alignment = taCenter then
      DrawText(Grid.Canvas.Handle, PChar(Txt), Length(Txt), DrawRect,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE)
    else if Column.Alignment = taRightJustify then
      DrawText(Grid.Canvas.Handle, PChar(Txt), Length(Txt), DrawRect,
        DT_RIGHT or DT_VCENTER or DT_SINGLELINE)
    else
      DrawText(Grid.Canvas.Handle, PChar(Txt), Length(Txt), DrawRect,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;
end;

end.
