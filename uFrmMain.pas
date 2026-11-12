unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes, System.Types, System.IOUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.Clipbrd, Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  uConfig, uControlIDClient, uDataModule, uPontoService, uPontoCalculoService, uSkiaButtons,
  uFrmUpdate, uBiometriaHamster, uFrmTerminalPonto, uRelatorioPonto, uRegiao,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet;

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
    pgcConfig: TPageControl;
    tabCfgParametros: TTabSheet;
    btnConfigVoltar: TButton;
    btnIrParaVersoes: TButton;
    tabCfgVersoes: TTabSheet;
    pnlVersaoHeader: TPanel;
    lblVersaoTitulo: TLabel;
    lblPesquisarVersao: TLabel;
    edtPesquisarVersao: TEdit;
    pnlVersaoFooter: TPanel;
    btnVersaoAtualizar: TButton;
    btnVersaoSair: TButton;
    pnlVersaoBody: TPanel;
    pnlVersaoEsq: TPanel;
    grpVersoes: TGroupBox;
    dbgVersoes: TDBGrid;
    pnlVersaoContador: TPanel;
    lblVersaoContador: TLabel;
    pnlVersaoLegenda: TPanel;
    pbLegenda: TPaintBox;
    splVersao: TSplitter;
    pnlVersaoDir: TPanel;
    grpScript: TGroupBox;
    mmoScript: TMemo;
    splScriptProg: TSplitter;
    grpProgresso: TGroupBox;
    mmoProgresso: TMemo;
    splProgErros: TSplitter;
    grpErros: TGroupBox;
    mmoErros: TMemo;
    mtVersoes: TFDMemTable;
    dsVersoes: TDataSource;
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
    chkAutoAtualizar: TCheckBox;
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
    lblHorSexSaida2: TLabel;
    edtHorSexSaida2: TEdit;
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
    btnIncluirBatidaEspelho: TButton;
    btnSaldoAnterior: TButton;
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
    procedure btnIncluirBatidaEspelhoClick(Sender: TObject);
    procedure btnSaldoAnteriorClick(Sender: TObject);
    procedure btnAfastamentosClick(Sender: TObject);
    procedure btnFeriadosClick(Sender: TObject);
    procedure btnResumoGeralClick(Sender: TObject);
    procedure btnMesAnteriorClick(Sender: TObject);
    procedure btnMesSeguinteClick(Sender: TObject);
    procedure NavegarMesEspelho(ADelta: Integer);
    procedure HorEscalaChange(Sender: TObject);
    procedure HorModelosClick(Sender: TObject);
    procedure chkVerDesconsideradasClick(Sender: TObject);
    procedure grdEspelhoDblClick(Sender: TObject);
    procedure grdEspelhoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

    // Controle de Versão (Log de Atualização)
    procedure btnIrParaVersoesClick(Sender: TObject);
    procedure btnVersaoAtualizarClick(Sender: TObject);
    procedure btnVersaoSairClick(Sender: TObject);
    procedure edtPesquisarVersaoChange(Sender: TObject);
    procedure dbgVersoesDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure mtVersoesAfterScroll(DataSet: TDataSet);
    procedure pbLegendaPaint(Sender: TObject);
    procedure CarregarControleVersao;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
    FLblEspelhoDetalhe: TLabel;
    chkVerDesconsideradas: TCheckBox;
    FPnlHorDias: TPanel;                          // grade semanal do cadastro de jornada
    FPnlHorRegras: TPanel;                        // regras: escala, intervalo, virada do dia, banco de horas
    FCmbEscala: TComboBox;
    FEdtEscalaInicio, FEdtCicloTrab, FEdtCicloFolga, FEdtIntervalo, FEdtVirada: TEdit;
    FChkBanco: TCheckBox;
    FBtnAfastamentos, FBtnFeriados, FBtnResumoGeral, FBtnMesAnt, FBtnMesProx: TButton;
    FHorEdt: array[1..7, 0..3] of TEdit;          // dia (1 = segunda) x (entrada, saída almoço, volta, saída)
    FHorCargaLbl: array[1..7] of TLabel;
    FPreviousTab: TTabSheet;
    FLatestUpdateInfo: TUpdateInfo;
    FTmrChecarAtualizacao: TTimer;
    FChecandoAtualizacao: Boolean;
    FTelaAtualizacaoAberta: Boolean;
    FUltimaAtualizacaoOferecida: string;

    // Configuração do relógio / leitor (aba criada em tempo de execução)
    tabCfgRelogio: TTabSheet;
    grpCfgRelogio: TGroupBox;
    cmbCfgTipoRelogio: TComboBox;
    lblCfgTipoInfo: TLabel;
    grpCfgHamster: TGroupBox;
    cmbCfgNivelSeguranca: TComboBox;
    edtCfgIntervaloBatida: TEdit;
    chkCfgAbrirTerminal: TCheckBox;
    skCfgTestarLeitor: TSkModernButton;
    skCfgSalvarRelogio: TSkModernButton;
    lblCfgHamsterReq: TLabel;
    skCfgInstalarHamster: TSkModernButton;

    // Biometria no cadastro do colaborador
    grpBiometria: TGroupBox;
    lblBioStatus: TLabel;
    lblBioData: TLabel;
    skCadastrarBio: TSkModernButton;
    skTestarBio: TSkModernButton;
    skRemoverBio: TSkModernButton;
    FColabBioCadastrada: Boolean;

    // Relatório padrão de Entradas e Saídas
    skRelatorioES: TSkModernButton;

    procedure CriarControlesIntegracao;
    procedure AplicarModoRelogio;
    procedure AtualizarInfoBiometria(AQry: TDataSet);
    procedure AtualizarTextoTipoRelogio;
    procedure cmbCfgTipoRelogioChange(Sender: TObject);
    procedure skCfgTestarLeitorClick(Sender: TObject);
    procedure skCfgInstalarHamsterClick(Sender: TObject);
    function RequisitosHamsterOk: Boolean;
    procedure AtualizarStatusRequisitosHamster;
    function ExecutarInstaladorComoAdmin(const AArquivo, AParametros: string): Boolean;
    procedure skCadastrarBioClick(Sender: TObject);
    procedure skTestarBioClick(Sender: TObject);
    procedure skRemoverBioClick(Sender: TObject);
    procedure skRelatorioESClick(Sender: TObject);
    procedure AbrirTerminalBiometrico;
    procedure TerminalBatidaRegistrada;
    function LeitorLivreParaUso: Boolean;

    procedure ChecarAtualizacaoSistemaAsync;
    procedure TmrChecarAtualizacaoTimer(Sender: TObject);
    procedure AbrirTelaAtualizacao(AAutomatico: Boolean);
    procedure ExibirVersaoBuild;
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
    function ValidarEntradaBatida(const AData, AHora, ATipo: string; out ADataHora: TDateTime;
      out ATipoOk: string): Boolean;
    procedure ApurarEspelho(ASilencioso: Boolean);
    procedure AjustarColunasEspelho;
    procedure ConstruirGradeHorario;
    function NovoQuadroLista(const ATitulo, ASub: string; ACor: TColor; const ACols: array of string;
      const ALargs: array of Integer; out ALst: TListView): TForm;
    procedure AtualizarCargaDiaHorario(D: Integer);
    procedure HorDiaChange(Sender: TObject);
    procedure HorDiaExit(Sender: TObject);
    procedure HorCopiarSegundaClick(Sender: TObject);
    procedure DefinirDiaHorario(D: Integer; const E1, S1, E2, S2: string);
    procedure LimparDiaHorario(D: Integer);
    function SalvarJornadaDoForm(out ANovoId: Integer; out ADesc, AE1, AS1, AE2, AS2: string): Boolean;
    procedure EspelhoFiltroChange(Sender: TObject);
    function PessoaEspelhoId: Integer;
    function DiaEspelhoSelecionado(out ADia: TDateTime): Boolean;
    function IncluirBatidaEspelho(ADia: TDateTime): Boolean;
    function CorrigirBatidaExistente(AId: Integer; ADataHora: TDateTime; const ATipo: string): Boolean;
    procedure AbrirTelaDiaEspelho(ADia: TDateTime);
    function DialogoCampos(const ATitulo, ASubtitulo: string; const APrompts: array of string;
      var AValores: array of string; ACor: TColor = $00633A1E): Boolean;
    procedure LvDiaCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      var DefaultDraw: Boolean);
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
    skIncluirBatidaEspelho: TSkModernButton;
    skSaldoAnterior: TSkModernButton;
    skAfastamentos, skFeriados, skResumoGeral, skMesAnt, skMesProx: TSkModernButton;
    skExportarEspelhoHTML: TSkModernButton;
    skIrParaVersoes: TSkModernButton;
    skVersaoAtualizar: TSkModernButton;
    skVersaoSair: TSkModernButton;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

function SeTexto(ACond: Boolean; const ASim, ANao: string): string;
begin
  if ACond then
    Result := ASim
  else
    Result := ANao;
end;

// Horas com sinal em HH:MM ("+12:30", "-05:15", "8:00") -> minutos
function ParseSaldoHoras(const S: string; out AMin: Integer): Boolean;
var
  T: string;
  Neg: Boolean;
  P, H, M: Integer;
begin
  Result := False;
  AMin := 0;
  T := Trim(S);
  if T = '' then
    Exit;
  Neg := False;
  if (T[1] = '+') or (T[1] = '-') then
  begin
    Neg := T[1] = '-';
    T := Trim(Copy(T, 2, MaxInt));
  end;
  P := Pos(':', T);
  if P < 2 then
    Exit;
  if (not TryStrToInt(Copy(T, 1, P - 1), H)) or (not TryStrToInt(Copy(T, P + 1, 2), M)) then
    Exit;
  if (H < 0) or (M < 0) or (M > 59) then
    Exit;
  AMin := H * 60 + M;
  if Neg then
    AMin := -AMin;
  Result := True;
end;

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
  TPontoCalculoService.LogErro := procedure(AMsg: string)
    begin
      LogMessage('⚠️ ' + AMsg, True);
    end;
  FLblEspelhoDetalhe := nil;
  chkVerDesconsideradas := nil;

  dtpIni.Date := StartOfTheMonth(Date);
  dtpFim.Date := Date;

  dtpEspelhoIni.Date := StartOfTheMonth(Date);
  dtpEspelhoFim.Date := EndOfTheMonth(Date);
  // Seletores de data no padrão dd/mm/aaaa (calendário em português)
  PadronizarSeletoresDeData(Self);
  // Trocar colaborador ou período refaz a apuração sozinho
  cmbEspelhoColab.OnChange := EspelhoFiltroChange;
  dtpEspelhoIni.OnChange := EspelhoFiltroChange;
  dtpEspelhoFim.OnChange := EspelhoFiltroChange;

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
  grdEspelho.Cells[10, 0] := 'Noturno';
  grdEspelho.Cells[11, 0] := 'Interv. Suprimido';
  grdEspelho.Cells[12, 0] := 'Faltas e Atrasos';
  grdEspelho.Cells[13, 0] := 'Saldo Diário';
  grdEspelho.Cells[14, 0] := 'Ocorrência / Justificativa Legal';

  grdEspelho.Font.Name := 'Segoe UI';
  grdEspelho.Font.Size := 9;
  grdEspelho.DefaultRowHeight := 27;
  grdEspelho.RowHeights[0] := 34;
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
  grdEspelho.ColWidths[10] := 80;
  grdEspelho.ColWidths[11] := 110;
  grdEspelho.ColWidths[12] := 110;
  grdEspelho.ColWidths[13] := 95;
  grdEspelho.ColWidths[14] := 450;

  CriarBotoesSkia;
  CriarControlesIntegracao;
  LimparFormColaborador;
  ConstruirGradeHorario;
  LimparFormHorario;
  ConfigurarGridRelogios;
  ConfigurarGridColaboradores;
  ConfigurarGridMarcacoes;
  ConfigurarGridHorarios;

  CarregarConfigNaTela;
  AplicarModoRelogio;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  Err: string;
begin
  WindowState := wsMaximized;
  ShowWindow(Handle, SW_MAXIMIZE);
  ArredondarControles;
  ExibirVersaoBuild;

  // Auto-update via GitHub: verifica ao abrir (mesmo sem banco) e periodicamente
  if not Assigned(FTmrChecarAtualizacao) then
  begin
    FTmrChecarAtualizacao := TTimer.Create(Self);
    FTmrChecarAtualizacao.Interval := AppConfig.Atualizacao.IntervaloVerificacaoMin * 60 * 1000;
    FTmrChecarAtualizacao.OnTimer := TmrChecarAtualizacaoTimer;
    FTmrChecarAtualizacao.Enabled := True;
  end;
  ChecarAtualizacaoSistemaAsync;
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
    CarregarControleVersao;

    KeyPreview := True;
    OnKeyDown := FormKeyDown;

    if FindCmdLineSwitch('tab_colab') then
      pgcMain.ActivePage := tabColaboradores
    else if FindCmdLineSwitch('tab_marc') then
      pgcMain.ActivePage := tabMarcacoes
    else if FindCmdLineSwitch('tab_cfg') then
    begin
      pgcMain.ActivePage := tabConfig;
      pgcConfig.ActivePage := tabCfgParametros;
    end
    else if FindCmdLineSwitch('tab_versao') then
    begin
      pgcMain.ActivePage := tabConfig;
      pgcConfig.ActivePage := tabCfgVersoes;
    end
    else if FindCmdLineSwitch('tab_hor') then
      pgcMain.ActivePage := tabHorarios
    else if FindCmdLineSwitch('tab_esp') then
      pgcMain.ActivePage := tabEspelho
    else if FindCmdLineSwitch('tab_rel') and not ModoHamsterDX then
      pgcMain.ActivePage := tabRelogios;

    if ModoHamsterDX then
    begin
      AtualizarStatusColeta('👆 Leitor Biométrico Hamster DX', True);
      if AppConfig.Relogio.AbrirTerminalAoIniciar then
        AbrirTerminalBiometrico;
    end
    else if AppConfig.ControlID.AutoIniciarColeta then
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
  chkAutoAtualizar.Checked := AppConfig.Atualizacao.AutoAtualizar;

  if Assigned(cmbCfgTipoRelogio) then
  begin
    cmbCfgTipoRelogio.ItemIndex := Ord(AppConfig.Relogio.Tipo);
    cmbCfgNivelSeguranca.ItemIndex := AppConfig.Relogio.NivelSeguranca - 1;
    edtCfgIntervaloBatida.Text := IntToStr(AppConfig.Relogio.IntervaloMinimoBatidaMin);
    chkCfgAbrirTerminal.Checked := AppConfig.Relogio.AbrirTerminalAoIniciar;
    AtualizarTextoTipoRelogio;
    AtualizarStatusRequisitosHamster;
  end;
end;

procedure TfrmMain.AtualizarDashboard;
var
  TotalRel, TotalMarc, TotalColab: Integer;
begin
  if ModoHamsterDX then
  begin
    if dmDados.GetTotalBiometrias(TotalRel) then
      lblCard1Val.Caption := IntToStr(TotalRel);
  end
  else if dmDados.GetTotalRelogiosAtivos(TotalRel) then
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
  Qry := dmDados.GetMarcacoes(dtpIni.Date, dtpFim.Date, RelId, 0,
    not (Assigned(chkVerDesconsideradas) and chkVerDesconsideradas.Checked));
  FdsMarcacoes.DataSet := Qry;
  if Assigned(OldDs) then
    OldDs.Free;

  ConfigurarGridMarcacoes;
  lblTotalMarcacoesGrid.Caption := Format('Total: %d marcações', [Qry.RecordCount]);

  // Batida nova (coleta, importação, ajuste): refaz o espelho se ele está na tela. Em outra aba não custa
  // nada agora: ao abrir a aba do Espelho a apuração é refeita (pgcMainChange).
  if Assigned(FUltimoEspelho) and (pgcMain.ActivePage = tabEspelho) then
    ApurarEspelho(True);
end;

procedure TfrmMain.chkVerDesconsideradasClick(Sender: TObject);
begin
  CarregarMarcacoes;
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
  if ModoHamsterDX then
  begin
    skCfgTestarLeitorClick(Sender);
    Exit;
  end;

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
  if ModoHamsterDX then
  begin
    AbrirTerminalBiometrico;
    Exit;
  end;

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
  if ModoHamsterDX then
    Exit;
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
  AtualizarInfoBiometria(nil);
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

  AtualizarInfoBiometria(AQry);
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
  Valores: array of string;
begin
  if (not Assigned(FdsMarcacoes.DataSet)) or FdsMarcacoes.DataSet.IsEmpty then
  begin
    ShowMessage('Selecione uma marcação na grade para desconsiderar ou restaurar.');
    Exit;
  end;

  MarcId := FdsMarcacoes.DataSet.FieldByName('PMA_ID').AsInteger;
  Colab := FdsMarcacoes.DataSet.FieldByName('PESSOA_NOME').AsString;
  DataHoraStr := FormatDateTime('dd/mm/yyyy hh:nn:ss', FdsMarcacoes.DataSet.FieldByName('PMA_DATA_HORA').AsDateTime);

  // Portaria 671: a batida nunca é apagada. Ela fica desconsiderada, com o motivo, e pode ser restaurada.
  if FdsMarcacoes.DataSet.FieldByName('PMA_DESCONSIDERADA').AsString = 'S' then
  begin
    if MessageDlg(Format('Voltar a considerar a batida #%d de %s (%s)?', [MarcId, Colab, DataHoraStr]),
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    if dmDados.RestaurarMarcacao(MarcId) then
    begin
      LogMessage(Format('↩️ Batida #%d (%s - %s) voltou a ser considerada.', [MarcId, Colab, DataHoraStr]));
      CarregarMarcacoes;
      AtualizarDashboard;
    end
    else
      ShowMessage('Não foi possível restaurar a batida selecionada.');
    Exit;
  end;

  SetLength(Valores, 1);
  Valores[0] := 'Batida em duplicidade';
  if not DialogoCampos('Desconsiderar batida', Format('Batida #%d  •  %s  •  %s', [MarcId, Colab, DataHoraStr]),
       ['Motivo (obrigatório pela Portaria 671 - a batida original fica guardada):'], Valores, $003030C5) then
    Exit;
  if Length(Trim(Valores[0])) < 5 then
  begin
    ShowMessage('Informe o motivo com pelo menos 5 caracteres.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    if dmDados.DesconsiderarMarcacao(MarcId, Valores[0]) then
    begin
      LogMessage(Format('🚫 Batida #%d (%s - %s) desconsiderada. Motivo: %s', [MarcId, Colab, DataHoraStr, Trim(Valores[0])]));
      CarregarMarcacoes;
      AtualizarDashboard;
    end
    else
    begin
      LogMessage(Format('❌ Falha ao desconsiderar batida #%d: %s', [MarcId, FormatarErroAmigavel(dmDados.LastError)]), True);
      ShowMessage('Não foi possível desconsiderar a batida selecionada (a base pode não ter a estrutura da Portaria 671).');
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// Valida data, hora e tipo digitados nos diálogos de batida (uma só regra para todas as telas)
function TfrmMain.ValidarEntradaBatida(const AData, AHora, ATipo: string; out ADataHora: TDateTime;
  out ATipoOk: string): Boolean;
var
  D, H: TDateTime;
begin
  Result := False;
  ADataHora := 0;
  ATipoOk := UpperCase(Trim(ATipo));
  if not TryStrToDate(Trim(AData), D) then
  begin
    ShowMessage('Data informada é inválida. Utilize o formato DD/MM/AAAA.');
    Exit;
  end;
  if not TryStrToTime(Trim(AHora), H) then
  begin
    ShowMessage('Hora informada é inválida. Utilize o formato HH:MM:SS.');
    Exit;
  end;
  if (ATipoOk <> 'E') and (ATipoOk <> 'S') then
  begin
    ShowMessage('Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
    Exit;
  end;
  ADataHora := Trunc(D) + Frac(H);
  Result := True;
end;

procedure TfrmMain.btnEditarMarcacaoClick(Sender: TObject);
var
  PmaId: Integer;
  DataHoraAtual: TDateTime;
  TipoAtual, NomeColab: string;
  Prompts, Values: array of string;
  NovoTipoStr, NovoMotivoStr: string;
  NovaDataHora: TDateTime;
  NovoId: Integer;
  Qry: TDataSet;
begin
  Qry := FdsMarcacoes.DataSet;
  if (Qry = nil) or Qry.IsEmpty then
  begin
    ShowMessage('Selecione uma marcação de ponto na lista para corrigir.');
    Exit;
  end;
  if Qry.FieldByName('PMA_DESCONSIDERADA').AsString = 'S' then
  begin
    ShowMessage('Esta batida já está desconsiderada. Inclua uma nova batida ou restaure esta.');
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

  if not DialogoCampos('Corrigir batida', Format('Batida #%d  •  %s', [PmaId, NomeColab]),
       Prompts, Values, $000677D9) then
    Exit;

  NovoMotivoStr := Trim(Values[3]);
  if not ValidarEntradaBatida(Values[0], Values[1], Values[2], NovaDataHora, NovoTipoStr) then
    Exit;
  if Length(NovoMotivoStr) < 5 then
  begin
    ShowMessage('Informe o motivo da correção (mínimo 5 caracteres).');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    // Portaria 671: a original fica desconsiderada e uma nova batida é gravada com o motivo
    NovoId := dmDados.CorrigirMarcacao(PmaId, NovaDataHora, NovoTipoStr, NovoMotivoStr);
    if NovoId > 0 then
    begin
      LogMessage(Format('✏️ Batida #%d corrigida pela #%d em %s (%s) - Colaborador: %s [Motivo: %s]',
        [PmaId, NovoId, FormatDateTime('dd/mm/yyyy hh:nn:ss', NovaDataHora), NovoTipoStr, NomeColab, NovoMotivoStr]));
      CarregarMarcacoes;
      ShowMessage('Correção registrada! A batida original foi preservada como desconsiderada (Portaria 671).');
    end
    else
      ShowMessage('Não foi possível corrigir a marcação de ponto no banco de dados.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnNovaMarcacaoClick(Sender: TObject);
var
  Prompts, Values: array of string;
  ColabBusca, NovoTipoStr, NovoMotivoStr: string;
  NovaDataHora: TDateTime;
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

  if not DialogoCampos('Incluir batida manual', 'Informe o colaborador, o horário e o motivo (Portaria 671)',
       Prompts, Values, $00137333) then
    Exit;

  ColabBusca := Trim(Values[0]);
  NovoMotivoStr := Trim(Values[4]);

  if ColabBusca = '' then
  begin
    ShowMessage('Informe o CPF ou código do colaborador.');
    Exit;
  end;
  if not ValidarEntradaBatida(Values[1], Values[2], Values[3], NovaDataHora, NovoTipoStr) then
    Exit;
  if Length(NovoMotivoStr) < 5 then
  begin
    ShowMessage('Informe o motivo da inclusão (mínimo 5 caracteres).');
    Exit;
  end;

  // Localizar Pessoa (mesmas colunas do restante do sistema: PES_ID e PES_RSOCIAL_NOME)
  PessoaId := 0;
  NomeColab := '';
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := dmDados.FDConnection;
    Qry.SQL.Text :=
      'SELECT FIRST 1 PES_ID, PES_RSOCIAL_NOME FROM TB_PESSOA ' +
      'WHERE PES_ID = :COD OR PES_CNPJ_CPF = :CPF OR PES_CNPJ_CPF = :DIG';
    Qry.ParamByName('COD').AsInteger := StrToIntDef(ColabBusca, 0);
    Qry.ParamByName('CPF').AsString := ColabBusca;
    Qry.ParamByName('DIG').AsString := OnlyDigits(ColabBusca);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      PessoaId := Qry.FieldByName('PES_ID').AsInteger;
      NomeColab := Qry.FieldByName('PES_RSOCIAL_NOME').AsString;
    end;
  finally
    Qry.Free;
  end;

  if PessoaId <= 0 then
  begin
    ShowMessage('Colaborador não localizado com o identificador informado: ' + ColabBusca);
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    NovoId := dmDados.InserirMarcacaoManual(PessoaId, ObterRelogioAtivoId, NovaDataHora, NovoTipoStr, NovoMotivoStr);
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
    if Assigned(pgcConfig) then
    begin
      if pgcConfig.ActivePage = nil then
        pgcConfig.ActivePage := tabCfgParametros;
    end;
    CarregarControleVersao;
  end;
end;

procedure TfrmMain.btnConfigVoltarClick(Sender: TObject);
begin
  if FPreviousTab <> nil then
    pgcMain.ActivePage := FPreviousTab
  else
    pgcMain.ActivePage := tabDashboard;
end;

procedure TfrmMain.btnIrParaVersoesClick(Sender: TObject);
begin
  if Assigned(pgcConfig) and Assigned(tabCfgVersoes) then
  begin
    pgcConfig.ActivePage := tabCfgVersoes;
    CarregarControleVersao;
  end;
end;

procedure TfrmMain.btnVersaoSairClick(Sender: TObject);
begin
  if FPreviousTab <> nil then
    pgcMain.ActivePage := FPreviousTab
  else
    pgcMain.ActivePage := tabDashboard;
end;

procedure TfrmMain.btnVersaoAtualizarClick(Sender: TObject);
var
  LogMig: string;
begin
  Screen.Cursor := crHourGlass;
  try
    dmDados.VerificarEAtualizarEstruturaBanco(LogMig);
    CarregarControleVersao;
    ShowMessage('Base de dados verificada e sincronizada com sucesso!'#13#10#13#10 + LogMig);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.edtPesquisarVersaoChange(Sender: TObject);
var
  Termo: string;
begin
  if not Assigned(mtVersoes) or not mtVersoes.Active then
    Exit;

  Termo := Trim(edtPesquisarVersao.Text);
  if Termo = '' then
    mtVersoes.Filtered := False
  else
  begin
    mtVersoes.Filter := Format(
      '(VERSAO LIKE ''%%%s%%'') OR (ACAO LIKE ''%%%s%%'') OR (DESCRICAO LIKE ''%%%s%%'') OR (SCRIPT LIKE ''%%%s%%'')',
      [Termo, Termo, Termo, Termo]);
    mtVersoes.Filtered := True;
  end;
  lblVersaoContador.Caption := Format('  %d registros', [mtVersoes.RecordCount]);
  mtVersoesAfterScroll(mtVersoes);
end;

procedure TfrmMain.dbgVersoesDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  StatusVal: string;
  CenterX, CenterY, Radius: Integer;
  BrushColor, PenColor: TColor;
begin
  if not Assigned(mtVersoes) or not mtVersoes.Active then
    Exit;

  if Column.FieldName = 'STATUS' then
  begin
    dbgVersoes.Canvas.FillRect(Rect);
    StatusVal := mtVersoes.FieldByName('STATUS').AsString;

    // Cores fiéis à imagem:
    // Verde = Desatualizado, Azul = Atualizado, Vermelho = Atualizado com erros
    if StatusVal = 'D' then
    begin
      BrushColor := $002EC971; // Verde esmeralda
      PenColor := $001B8A4C;
    end
    else if StatusVal = 'E' then
    begin
      BrushColor := $003333E7; // Vermelho rubi
      PenColor := $002222A8;
    end
    else
    begin
      BrushColor := $00D45C1A; // Azul Royal / Cobalto
      PenColor := $00943A08;
    end;

    CenterX := (Rect.Left + Rect.Right) div 2;
    CenterY := (Rect.Top + Rect.Bottom) div 2;
    Radius := 7;

    dbgVersoes.Canvas.Brush.Color := BrushColor;
    dbgVersoes.Canvas.Pen.Color := PenColor;
    dbgVersoes.Canvas.Ellipse(CenterX - Radius, CenterY - Radius, CenterX + Radius, CenterY + Radius);

    // Efeito de reflexo de luz / esfera 3D idêntico à imagem
    dbgVersoes.Canvas.Brush.Color := clWhite;
    dbgVersoes.Canvas.Pen.Color := clWhite;
    dbgVersoes.Canvas.Ellipse(CenterX - Radius + 2, CenterY - Radius + 2, CenterX - Radius + 5, CenterY - Radius + 5);
  end
  else
  begin
    dbgVersoes.DefaultDrawColumnCell(Rect, DataCol, Column, State);
  end;
end;

procedure TfrmMain.mtVersoesAfterScroll(DataSet: TDataSet);
begin
  if Assigned(mmoScript) and Assigned(mmoProgresso) and Assigned(mmoErros) then
  begin
    if Assigned(mtVersoes) and mtVersoes.Active and not mtVersoes.IsEmpty then
    begin
      mmoScript.Text := mtVersoes.FieldByName('SCRIPT').AsString;
      mmoProgresso.Text := mtVersoes.FieldByName('PROGRESSO').AsString;
      mmoErros.Text := mtVersoes.FieldByName('ERROS').AsString;
    end
    else
    begin
      mmoScript.Clear;
      mmoProgresso.Clear;
      mmoErros.Clear;
    end;
  end;
end;

procedure TfrmMain.pbLegendaPaint(Sender: TObject);
var
  C: TCanvas;
  X, Y, R: Integer;
begin
  if not Assigned(pbLegenda) then
    Exit;

  C := pbLegenda.Canvas;
  C.Brush.Color := clWhite;
  C.FillRect(pbLegenda.ClientRect);
  C.Font.Name := 'Segoe UI';
  C.Font.Size := 9;
  C.Font.Color := clWindowText;

  R := 6;
  Y := pbLegenda.Height div 2;

  // 1. Desatualizado (Verde)
  X := 16;
  C.Brush.Style := bsSolid;
  C.Brush.Color := $002EC971; // Verde
  C.Pen.Color := $001B8A4C;
  C.Ellipse(X - R, Y - R, X + R, Y + R);
  C.Brush.Color := clWhite;
  C.Pen.Color := clWhite;
  C.Ellipse(X - R + 2, Y - R + 2, X - R + 5, Y - R + 5);
  C.Brush.Style := bsClear;
  C.TextOut(X + R + 6, Y - (C.TextHeight('D') div 2), 'Desatualizado');

  // 2. Atualizado (Azul)
  X := 130;
  C.Brush.Style := bsSolid;
  C.Brush.Color := $00D45C1A; // Azul
  C.Pen.Color := $00943A08;
  C.Ellipse(X - R, Y - R, X + R, Y + R);
  C.Brush.Color := clWhite;
  C.Pen.Color := clWhite;
  C.Ellipse(X - R + 2, Y - R + 2, X - R + 5, Y - R + 5);
  C.Brush.Style := bsClear;
  C.TextOut(X + R + 6, Y - (C.TextHeight('A') div 2), 'Atualizado');

  // 3. Atualizado com erros (Vermelho)
  X := 230;
  C.Brush.Style := bsSolid;
  C.Brush.Color := $003333E7; // Vermelho
  C.Pen.Color := $002222A8;
  C.Ellipse(X - R, Y - R, X + R, Y + R);
  C.Brush.Color := clWhite;
  C.Pen.Color := clWhite;
  C.Ellipse(X - R + 2, Y - R + 2, X - R + 5, Y - R + 5);
  C.Brush.Style := bsClear;
  C.TextOut(X + R + 6, Y - (C.TextHeight('A') div 2), 'Atualizado com erros');
end;

procedure TfrmMain.CarregarControleVersao;
var
  Versoes: TBdVersaoArray;
  I: Integer;
begin
  if not Assigned(mtVersoes) then
    Exit;

  mtVersoes.DisableControls;
  try
    if not mtVersoes.Active then
    begin
      mtVersoes.FieldDefs.Clear;
      mtVersoes.FieldDefs.Add('STATUS', ftString, 1);
      mtVersoes.FieldDefs.Add('CODIGO', ftInteger);
      mtVersoes.FieldDefs.Add('VERSAO', ftString, 20);
      mtVersoes.FieldDefs.Add('DATA_HORA', ftString, 25);
      mtVersoes.FieldDefs.Add('ACAO', ftString, 40);
      mtVersoes.FieldDefs.Add('DESCRICAO', ftString, 250);
      mtVersoes.FieldDefs.Add('SCRIPT', ftMemo);
      mtVersoes.FieldDefs.Add('PROGRESSO', ftMemo);
      mtVersoes.FieldDefs.Add('ERROS', ftMemo);
      mtVersoes.CreateDataSet;
    end
    else
      mtVersoes.EmptyDataSet;

    Versoes := dmDados.ObterHistoricoVersoes;
    for I := 0 to High(Versoes) do
    begin
      mtVersoes.Append;
      mtVersoes.FieldByName('STATUS').AsString := Versoes[I].Status;
      mtVersoes.FieldByName('CODIGO').AsInteger := Versoes[I].Numero;
      mtVersoes.FieldByName('VERSAO').AsString := Versoes[I].Sistema;
      mtVersoes.FieldByName('DATA_HORA').AsString := FormatDateTime('dd/mm/yyyy hh:nn:ss', Versoes[I].DataHora);
      mtVersoes.FieldByName('ACAO').AsString := Versoes[I].Acao;
      mtVersoes.FieldByName('DESCRICAO').AsString := Versoes[I].Descricao;
      mtVersoes.FieldByName('SCRIPT').AsString := Versoes[I].Script;
      mtVersoes.FieldByName('PROGRESSO').AsString := Versoes[I].Progresso;
      mtVersoes.FieldByName('ERROS').AsString := Versoes[I].Erros;
      mtVersoes.Post;
    end;

    mtVersoes.First;
  finally
    mtVersoes.EnableControls;
  end;

  if Assigned(lblVersaoContador) then
    lblVersaoContador.Caption := Format('  %d registros', [mtVersoes.RecordCount]);
  mtVersoesAfterScroll(mtVersoes);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (pgcMain.ActivePage = tabConfig) and Assigned(pgcConfig) and (pgcConfig.ActivePage = tabCfgVersoes) then
  begin
    if Key = VK_F4 then
    begin
      Key := 0;
      btnVersaoAtualizarClick(nil);
    end
    else if Key = VK_ESCAPE then
    begin
      Key := 0;
      btnVersaoSairClick(nil);
    end;
  end;
end;

procedure TfrmMain.btnTopUpdateClick(Sender: TObject);
begin
  AbrirTelaAtualizacao(False);
end;

procedure TfrmMain.ExibirVersaoBuild;
begin
  // Cabeçalho: título e, logo abaixo, a versão + build
  lblTitle.Top := 14;
  lblHeaderVersion.Left := lblTitle.Left + 2;
  lblHeaderVersion.Top := lblTitle.Top + lblTitle.Height + 4;
  lblHeaderVersion.Caption := VersaoCompleta;
  if APP_BUILD_DATE <> '' then
  begin
    lblHeaderVersion.Hint := 'Compilado em ' + APP_BUILD_DATE;
    lblHeaderVersion.ShowHint := True;
  end;

  // Rodapé: versão + build, reposicionando os itens seguintes
  lblFootVersion.Caption := '🏷️ ' + VersaoCompleta;
  lblFootVersion.Hint := lblHeaderVersion.Hint;
  lblFootVersion.ShowHint := lblHeaderVersion.ShowHint;
  lblFootSep1.Left := lblFootVersion.Left + lblFootVersion.Width + 10;
  lblFootColeta.Left := lblFootSep1.Left + lblFootSep1.Width + 10;
end;

procedure TfrmMain.TmrChecarAtualizacaoTimer(Sender: TObject);
begin
  ChecarAtualizacaoSistemaAsync;
end;

procedure TfrmMain.AbrirTelaAtualizacao(AAutomatico: Boolean);
begin
  if FTelaAtualizacaoAberta or (not FLatestUpdateInfo.HasUpdate) then Exit;
  FTelaAtualizacaoAberta := True;
  try
    FUltimaAtualizacaoOferecida := Format('%s.%d', [FLatestUpdateInfo.LatestVersion, FLatestUpdateInfo.LatestBuild]);
    TfrmUpdate.ExecutarAtualizacao(Self, FLatestUpdateInfo, AAutomatico);
  finally
    FTelaAtualizacaoAberta := False;
  end;
end;

procedure TfrmMain.ChecarAtualizacaoSistemaAsync;
begin
  if FChecandoAtualizacao then Exit;
  FChecandoAtualizacao := True;
  TThread.CreateAnonymousThread(
    procedure
    var
      Info: TUpdateInfo;
      Encontrou: Boolean;
    begin
      Encontrou := False;
      try
        Encontrou := TfrmUpdate.ChecarAtualizacao(Info);
      except
      end;

      TThread.Queue(nil,
        procedure
        var
          VersaoNova: string;
        begin
          FChecandoAtualizacao := False;
          if not Encontrou then Exit;

          FLatestUpdateInfo := Info;
          if Info.LatestBuild > 0 then
            VersaoNova := Format('v%s (Build %d)', [Info.LatestVersion, Info.LatestBuild])
          else
            VersaoNova := 'v' + Info.LatestVersion;

          btnTopUpdate.Caption := 'Atualizar p/ ' + VersaoNova;
          btnTopUpdate.Visible := False;
          if Assigned(skTopUpdate) then
          begin
            skTopUpdate.Caption := '🚀 Nova Versão: v' + Info.LatestVersion;
            skTopUpdate.Visible := True;
          end;

          // Modo automático: oferece a atualização uma única vez por versão/build,
          // com contagem regressiva que o usuário pode adiar.
          if AppConfig.Atualizacao.AutoAtualizar and (not FTelaAtualizacaoAberta) and
             (FUltimaAtualizacaoOferecida <> Format('%s.%d', [Info.LatestVersion, Info.LatestBuild])) then
          begin
            LogMessage(Format('🔔 Nova atualização %s encontrada no GitHub. Iniciando atualização automática...', [VersaoNova]));
            AbrirTelaAtualizacao(True);
          end
          else
            LogMessage(Format('🔔 Nova atualização do sistema disponível: %s! Clique no botão superior para atualizar.', [VersaoNova]));
        end);
    end).Start;
end;

procedure TfrmMain.btnSalvarConfigClick(Sender: TObject);
var
  CfgFB: TFirebirdConfig;
  CfgCtl: TControlIDDefaultConfig;
  CfgAtu: TAtualizacaoConfig;
  CfgRel: TRelogioConfig;
  TipoAnterior: TTipoRelogio;
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

  CfgAtu := AppConfig.Atualizacao;
  CfgAtu.AutoAtualizar := chkAutoAtualizar.Checked;

  AppConfig.Firebird := CfgFB;
  AppConfig.ControlID := CfgCtl;
  AppConfig.Atualizacao := CfgAtu;

  TipoAnterior := AppConfig.Relogio.Tipo;
  CfgRel := AppConfig.Relogio;
  if cmbCfgTipoRelogio.ItemIndex = Ord(trHamsterDX) then
    CfgRel.Tipo := trHamsterDX
  else
    CfgRel.Tipo := trControlID;
  CfgRel.NivelSeguranca := cmbCfgNivelSeguranca.ItemIndex + 1;
  CfgRel.IntervaloMinimoBatidaMin := StrToIntDef(Trim(edtCfgIntervaloBatida.Text), 2);
  if CfgRel.IntervaloMinimoBatidaMin < 0 then
    CfgRel.IntervaloMinimoBatidaMin := 0;
  CfgRel.AbrirTerminalAoIniciar := chkCfgAbrirTerminal.Checked;
  AppConfig.Relogio := CfgRel;

  AppConfig.Save;

  if TipoAnterior <> CfgRel.Tipo then
  begin
    LogMessage('🔀 Integração de ponto alterada para: ' + TipoRelogioDescricao(CfgRel.Tipo));
    AplicarModoRelogio;
    if dmDados.IsConectado then
    begin
      CarregarColaboradores;
      AtualizarDashboard;
    end;
  end;

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
    // Sempre refaz a apuração ao abrir a aba: o espelho nunca fica com valores de antes de uma correção
    if cmbEspelhoColab.Items.Count > 0 then
      ApurarEspelho(True);
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

// ======================= Jornada dia a dia (segunda a domingo) =======================

const
  NomesDiasHor: array[1..7] of string = ('Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo');

// "8", "800", "8:0", "08:00" -> "08:00"; texto vazio continua vazio; o que não der para entender fica como está
function NormalizaHoraTxt(const S: string): string;
var
  D: string;
  I, P, H, M: Integer;
begin
  Result := Trim(S);
  if Result = '' then
    Exit;
  P := Pos(':', Result);
  if P > 0 then
  begin
    if TryStrToInt(Copy(Result, 1, P - 1), H) and TryStrToInt(Copy(Result, P + 1, 2), M) and
       (H >= 0) and (H <= 23) and (M >= 0) and (M <= 59) then
      Result := Format('%.2d:%.2d', [H, M]);
    Exit;
  end;
  D := '';
  for I := 1 to Length(Result) do
    if CharInSet(Result[I], ['0'..'9']) then
      D := D + Result[I];
  case Length(D) of
    1, 2: begin H := StrToInt(D); M := 0; end;
    3: begin H := StrToInt(Copy(D, 1, 1)); M := StrToInt(Copy(D, 2, 2)); end;
    4: begin H := StrToInt(Copy(D, 1, 2)); M := StrToInt(Copy(D, 3, 2)); end;
  else
    Exit;
  end;
  if (H <= 23) and (M <= 59) then
    Result := Format('%.2d:%.2d', [H, M]);
end;

function HoraTxtValida(const S: string): Boolean;
var
  H, M: Integer;
begin
  Result := (Length(S) = 5) and (S[3] = ':') and TryStrToInt(Copy(S, 1, 2), H) and TryStrToInt(Copy(S, 4, 2), M) and
    (H >= 0) and (H <= 23) and (M >= 0) and (M <= 59);
end;

// Minutos entre dois horários HH:MM (passando da meia-noite soma 24h)
function MinutosEntreHoras(const A, B: string): Integer;
begin
  if (not HoraTxtValida(A)) or (not HoraTxtValida(B)) then
    Exit(0);
  Result := TPontoCalculoService.HoraParaMinutos(B) - TPontoCalculoService.HoraParaMinutos(A);
  if Result < 0 then
    Inc(Result, 1440);
end;

// Cria a grade semanal no lugar dos campos gerais do cadastro de jornada
procedure TfrmMain.ConstruirGradeHorario;
const
  Titulos: array[0..4] of string = ('Dia', 'Entrada', 'Saída almoço', 'Volta almoço', 'Saída');
var
  D, K, X: Integer;
  Lb: TLabel;
  Ed: TEdit;
  Btn: TButton;
  Antigos: array of TControl;
  C: TControl;
begin
  // campos gerais antigos: agora tudo vem da grade, dia a dia
  Antigos := [lblHorEntrada1, lblHorSaida1, lblHorEntrada2, lblHorSaida2, edtHorEntrada1, edtHorSaida1,
    edtHorEntrada2, edtHorSaida2, lblHorCarga, edtHorCarga, chkHorCompensaSab, chkHorTrabalhaSab,
    lblHorSabEntrada1, lblHorSabSaida1, edtHorSabEntrada1, edtHorSabSaida1, lblHorSexSaida2, edtHorSexSaida2];
  for C in Antigos do
    C.Visible := False;

  FPnlHorDias := TPanel.Create(Self);
  FPnlHorDias.Parent := pnlHorarioForm;
  FPnlHorDias.SetBounds(20, 86, 440, 208);
  FPnlHorDias.BevelOuter := bvNone;
  FPnlHorDias.ParentBackground := False;
  FPnlHorDias.Color := $00F5F5F5;

  // cabeçalho
  for K := 0 to 4 do
  begin
    Lb := TLabel.Create(FPnlHorDias);
    Lb.Parent := FPnlHorDias;
    Lb.Font.Style := [fsBold];
    Lb.Font.Size := 8;
    Lb.Font.Color := $00555555;
    Lb.Caption := Titulos[K];
    if K = 0 then
      Lb.SetBounds(0, 2, 62, 15)
    else
      Lb.SetBounds(64 + (K - 1) * 72, 2, 70, 15);
  end;
  Lb := TLabel.Create(FPnlHorDias);
  Lb.Parent := FPnlHorDias;
  Lb.Font.Style := [fsBold];
  Lb.Font.Size := 8;
  Lb.Font.Color := $00555555;
  Lb.Caption := 'Carga';
  Lb.SetBounds(360, 2, 70, 15);

  for D := 1 to 7 do
  begin
    Lb := TLabel.Create(FPnlHorDias);
    Lb.Parent := FPnlHorDias;
    Lb.SetBounds(0, 24 + (D - 1) * 26 + 4, 62, 15);
    Lb.Font.Style := [fsBold];
    Lb.Caption := NomesDiasHor[D];
    for K := 0 to 3 do
    begin
      X := 64 + K * 72;
      Ed := TEdit.Create(FPnlHorDias);
      Ed.Parent := FPnlHorDias;
      Ed.SetBounds(X, 24 + (D - 1) * 26, 68, 23);
      Ed.MaxLength := 5;
      Ed.Alignment := taCenter;
      Ed.TextHint := '--:--';
      Ed.Tag := D * 10 + K;
      Ed.OnChange := HorDiaChange;
      Ed.OnExit := HorDiaExit;
      FHorEdt[D, K] := Ed;
    end;
    FHorCargaLbl[D] := TLabel.Create(FPnlHorDias);
    FHorCargaLbl[D].Parent := FPnlHorDias;
    FHorCargaLbl[D].SetBounds(360, 24 + (D - 1) * 26 + 4, 76, 15);
    FHorCargaLbl[D].Caption := 'Folga';
  end;

  Btn := TButton.Create(Self);
  Btn.Parent := pnlHorarioForm;
  Btn.SetBounds(250, 314, 210, 30);
  Btn.Caption := 'Copiar segunda para terça a sexta';
  Btn.OnClick := HorCopiarSegundaClick;

  Lb := TLabel.Create(Self);
  Lb.Parent := pnlHorarioForm;
  Lb.SetBounds(250, 40, 210, 15);
  Lb.Font.Color := $00555555;
  Lb.Font.Style := [fsItalic];
  Lb.Caption := 'Dia em branco = não trabalha';

  Btn := TButton.Create(Self);
  Btn.Parent := pnlHorarioForm;
  Btn.SetBounds(250, 6, 210, 28);
  Btn.Caption := 'Modelos: 5x2, 6x1, 12x36...';
  Btn.OnClick := HorModelosClick;

  // demais campos sobem para baixo da grade
  lblHorTolerancia.SetBounds(20, 300, 180, 15);
  lblHorTolerancia.Caption := 'Tolerância CLT (minutos)';
  edtHorTolerancia.SetBounds(20, 318, 100, 23);
  chkHorAtivo.SetBounds(135, 320, 110, 19);

  // Regras da jornada: escala, intervalo, virada do dia e banco de horas
  FPnlHorRegras := TPanel.Create(Self);
  FPnlHorRegras.Parent := pnlHorarioForm;
  FPnlHorRegras.SetBounds(20, 354, 440, 100);
  FPnlHorRegras.BevelOuter := bvNone;
  FPnlHorRegras.ParentBackground := False;
  FPnlHorRegras.Color := $00F5F5F5;

  FCmbEscala := TComboBox.Create(Self);
  FCmbEscala.Parent := FPnlHorRegras;
  FCmbEscala.Style := csDropDownList;
  FCmbEscala.SetBounds(0, 16, 190, 23);
  FCmbEscala.Items.Add('Semanal (dia a dia)');
  FCmbEscala.Items.Add('12x36 (usa o 1º dia preenchido)');
  FCmbEscala.Items.Add('Ciclo, ex.: 6x1 (1º dia preenchido)');
  FCmbEscala.ItemIndex := 0;
  FCmbEscala.OnChange := HorEscalaChange;

  FEdtEscalaInicio := TEdit.Create(Self);
  FEdtEscalaInicio.Parent := FPnlHorRegras;
  FEdtEscalaInicio.SetBounds(200, 16, 110, 23);
  FEdtEscalaInicio.TextHint := 'DD/MM/AAAA';

  FEdtCicloTrab := TEdit.Create(Self);
  FEdtCicloTrab.Parent := FPnlHorRegras;
  FEdtCicloTrab.SetBounds(320, 16, 50, 23);
  FEdtCicloTrab.Alignment := taCenter;
  FEdtCicloFolga := TEdit.Create(Self);
  FEdtCicloFolga.Parent := FPnlHorRegras;
  FEdtCicloFolga.SetBounds(380, 16, 50, 23);
  FEdtCicloFolga.Alignment := taCenter;

  FEdtIntervalo := TEdit.Create(Self);
  FEdtIntervalo.Parent := FPnlHorRegras;
  FEdtIntervalo.SetBounds(0, 68, 110, 23);
  FEdtIntervalo.Alignment := taCenter;
  FEdtVirada := TEdit.Create(Self);
  FEdtVirada.Parent := FPnlHorRegras;
  FEdtVirada.SetBounds(200, 68, 110, 23);
  FEdtVirada.Alignment := taCenter;
  FEdtVirada.TextHint := '00:00';
  FEdtVirada.OnExit := HorDiaExit;
  FEdtVirada.Tag := 0;

  FChkBanco := TCheckBox.Create(Self);
  FChkBanco.Parent := FPnlHorRegras;
  FChkBanco.SetBounds(320, 70, 120, 19);
  FChkBanco.Caption := 'Banco de horas';

  Lb := TLabel.Create(Self); Lb.Parent := FPnlHorRegras; Lb.SetBounds(0, 0, 190, 15); Lb.Caption := 'Tipo de escala';
  Lb := TLabel.Create(Self); Lb.Parent := FPnlHorRegras; Lb.SetBounds(200, 0, 110, 15); Lb.Caption := '1º dia trabalhado';
  Lb := TLabel.Create(Self); Lb.Parent := FPnlHorRegras; Lb.SetBounds(320, 0, 50, 15); Lb.Caption := 'Trabalha';
  Lb := TLabel.Create(Self); Lb.Parent := FPnlHorRegras; Lb.SetBounds(380, 0, 50, 15); Lb.Caption := 'Folga';
  Lb := TLabel.Create(Self); Lb.Parent := FPnlHorRegras; Lb.SetBounds(0, 52, 190, 15); Lb.Caption := 'Intervalo mínimo (minutos)';
  Lb := TLabel.Create(Self); Lb.Parent := FPnlHorRegras; Lb.SetBounds(200, 52, 110, 15); Lb.Caption := 'Virada do dia';
  HorEscalaChange(nil);

  pnlHorarioBtns.Top := 462;
end;

procedure TfrmMain.AtualizarCargaDiaHorario(D: Integer);
var
  K: Integer;
  Vazio: Boolean;
  V: array[0..3] of string;
  Carga: Integer;
begin
  if (D < 1) or (D > 7) or (FHorEdt[D, 0] = nil) or (FHorCargaLbl[D] = nil) then
    Exit;
  Vazio := True;
  for K := 0 to 3 do
  begin
    V[K] := Trim(FHorEdt[D, K].Text);
    if V[K] <> '' then
      Vazio := False;
  end;
  if Vazio then
  begin
    FHorCargaLbl[D].Caption := 'Folga';
    FHorCargaLbl[D].Font.Color := $00999999;
    Exit;
  end;
  if (V[1] <> '') or (V[2] <> '') then
    Carga := MinutosEntreHoras(V[0], V[1]) + MinutosEntreHoras(V[2], V[3])
  else
    Carga := MinutosEntreHoras(V[0], V[3]);
  FHorCargaLbl[D].Caption := TPontoCalculoService.MinutosParaHora(Carga);
  FHorCargaLbl[D].Font.Color := $00333333;
end;

// Modelos prontos de escala: preenchem a grade e as regras (depois dá para ajustar dia a dia)
procedure TfrmMain.HorModelosClick(Sender: TObject);
const
  M5X2_44 = '5x2 - 44h semanais (8h48 por dia, sábado compensado)';
  M5X2_40 = '5x2 - 40h semanais (8h por dia)';
  M6X1_44 = '6x1 - 44h semanais (7h20 por dia)';
  M12X36 = '12x36 - 07:00 às 19:00';
var
  V: array of string;
  D: Integer;
  Nome: string;
begin
  SetLength(V, 1);
  V[0] := M5X2_44;
  if not DialogoCampos('Modelo de escala', 'Preenche a grade e as regras; você pode ajustar depois',
       ['Modelo|' + M5X2_44 + '|' + M5X2_40 + '|' + M6X1_44 + '|' + M12X36], V, $00633A1E) then
    Exit;
  Nome := V[0];
  if Nome = M5X2_44 then
  begin
    // 5x2: trabalha de segunda a sexta; sábado é dia útil não trabalhado (compensado) e domingo é o DSR
    for D := 1 to 5 do DefinirDiaHorario(D, '08:00', '12:00', '13:12', '18:00');
    LimparDiaHorario(6); LimparDiaHorario(7);
    FCmbEscala.ItemIndex := 0;
  end
  else if Nome = M5X2_40 then
  begin
    for D := 1 to 5 do DefinirDiaHorario(D, '08:00', '12:00', '13:00', '17:00');
    LimparDiaHorario(6); LimparDiaHorario(7);
    FCmbEscala.ItemIndex := 0;
  end
  else if Nome = M6X1_44 then
  begin
    for D := 1 to 6 do DefinirDiaHorario(D, '07:00', '11:00', '12:00', '15:20');
    LimparDiaHorario(7);
    FCmbEscala.ItemIndex := 0;
  end
  else if Nome = M12X36 then
  begin
    DefinirDiaHorario(1, '07:00', '12:00', '13:00', '19:00');
    for D := 2 to 7 do LimparDiaHorario(D);
    FCmbEscala.ItemIndex := 1;
    if Trim(FEdtEscalaInicio.Text) = '' then
      FEdtEscalaInicio.Text := FormatDateTime('dd/mm/yyyy', Date);
    ShowMessage('Ajuste a data do primeiro dia trabalhado da escala 12x36.');
  end
  else
    Exit;
  FEdtIntervalo.Text := '60';
  HorEscalaChange(nil);
  if (Trim(edtHorDescricao.Text) = '') or (Pos('Novo Horário', edtHorDescricao.Text) = 1) then
    edtHorDescricao.Text := Copy(Nome, 1, Pos(' (', Nome + ' (') - 1);
end;

// Escala semanal: só a grade; 12x36 e ciclo precisam do primeiro dia trabalhado; o ciclo também de trabalha/folga
procedure TfrmMain.HorEscalaChange(Sender: TObject);
begin
  FEdtEscalaInicio.Enabled := FCmbEscala.ItemIndex > 0;
  FEdtCicloTrab.Enabled := FCmbEscala.ItemIndex = 2;
  FEdtCicloFolga.Enabled := FCmbEscala.ItemIndex = 2;
end;

procedure TfrmMain.HorDiaChange(Sender: TObject);
begin
  AtualizarCargaDiaHorario(TComponent(Sender).Tag div 10);
end;

procedure TfrmMain.HorDiaExit(Sender: TObject);
begin
  TEdit(Sender).Text := NormalizaHoraTxt(TEdit(Sender).Text);
end;

procedure TfrmMain.HorCopiarSegundaClick(Sender: TObject);
var
  D, K: Integer;
begin
  for D := 2 to 5 do
    for K := 0 to 3 do
      FHorEdt[D, K].Text := FHorEdt[1, K].Text;
end;

// Horários no formato gravado (1ª entrada, 1ª saída, 2ª entrada, 2ª saída) -> campos da tela
// (Entrada, Saída almoço, Volta almoço, Saída). Sem 2º período = sem almoço.
procedure TfrmMain.DefinirDiaHorario(D: Integer; const E1, S1, E2, S2: string);
var
  SemAlmoco: Boolean;
begin
  SemAlmoco := (Trim(E2) = '') and (Trim(S2) = '');
  FHorEdt[D, 0].Text := Copy(Trim(E1), 1, 5);
  if SemAlmoco then
  begin
    FHorEdt[D, 1].Text := '';
    FHorEdt[D, 2].Text := '';
    FHorEdt[D, 3].Text := Copy(Trim(S1), 1, 5);
  end
  else
  begin
    FHorEdt[D, 1].Text := Copy(Trim(S1), 1, 5);
    FHorEdt[D, 2].Text := Copy(Trim(E2), 1, 5);
    FHorEdt[D, 3].Text := Copy(Trim(S2), 1, 5);
  end;
end;

procedure TfrmMain.LimparDiaHorario(D: Integer);
begin
  DefinirDiaHorario(D, '', '', '', '');
end;

procedure TfrmMain.LimparFormHorario;
var
  D: Integer;
begin
  FSelectedHorarioId := 0;
  edtHorDescricao.Text := 'Novo Horário Comercial';
  edtHorTolerancia.Text := '10';
  chkHorAtivo.Checked := True;
  FCmbEscala.ItemIndex := 0;
  FEdtEscalaInicio.Text := '';
  FEdtCicloTrab.Text := '6';
  FEdtCicloFolga.Text := '1';
  FEdtIntervalo.Text := '60';
  FEdtVirada.Text := '00:00';
  FChkBanco.Checked := False;
  HorEscalaChange(nil);
  // padrão: segunda a sexta 08:00-12:00 / 13:12-18:00; sábado e domingo em branco (não trabalha)
  for D := 1 to 5 do
    DefinirDiaHorario(D, '08:00', '12:00', '13:12', '18:00');
  LimparDiaHorario(6);
  LimparDiaHorario(7);
  if edtHorDescricao.CanFocus then
    edtHorDescricao.SetFocus;
end;

procedure TfrmMain.PreencherFormHorario(AQry: TDataSet);
var
  D, DiaSem: Integer;
  E1, S1, E2, S2, SE1, SS1, XS2: string;
  TrabSab: Boolean;
  Dias: TFDQuery;
  Achou: Boolean;

  function Txt(const ACampo, APadrao: string): string;
  begin
    if AQry.FindField(ACampo) <> nil then
      Result := Copy(AQry.FieldByName(ACampo).AsString, 1, 5)
    else
      Result := APadrao;
  end;

begin
  if (AQry = nil) or AQry.IsEmpty then
  begin
    LimparFormHorario;
    Exit;
  end;

  FSelectedHorarioId := AQry.FieldByName('HOR_ID').AsInteger;
  edtHorDescricao.Text := AQry.FieldByName('HOR_DESCRICAO').AsString;
  if AQry.FindField('HOR_TOLERANCIA_MIN') <> nil then
    edtHorTolerancia.Text := IntToStr(AQry.FieldByName('HOR_TOLERANCIA_MIN').AsInteger)
  else
    edtHorTolerancia.Text := '10';
  if AQry.FindField('HOR_ATIVO') <> nil then
    chkHorAtivo.Checked := SameText(AQry.FieldByName('HOR_ATIVO').AsString, 'S')
  else
    chkHorAtivo.Checked := True;

  // cadastros antigos (sem jornada por dia): monta a semana a partir dos campos gerais
  E1 := Txt('HOR_ENTRADA_1', '08:00');
  S1 := Txt('HOR_SAIDA_1', '12:00');
  E2 := Txt('HOR_ENTRADA_2', '13:12');
  S2 := Txt('HOR_SAIDA_2', '18:00');
  SE1 := Txt('HOR_SAB_ENTRADA_1', '08:00');
  SS1 := Txt('HOR_SAB_SAIDA_1', '12:00');
  XS2 := Txt('HOR_SEX_SAIDA_2', '');
  TrabSab := (AQry.FindField('HOR_TRABALHA_SABADO') <> nil) and
    SameText(AQry.FieldByName('HOR_TRABALHA_SABADO').AsString, 'S');
  for D := 1 to 5 do
    DefinirDiaHorario(D, E1, S1, E2, S2);
  if XS2 <> '' then
    DefinirDiaHorario(5, E1, S1, E2, XS2);
  if TrabSab then
    DefinirDiaHorario(6, SE1, SS1, '', '')
  else
    LimparDiaHorario(6);
  LimparDiaHorario(7);

  // regras da jornada (escala, virada do dia, intervalo, banco de horas)
  FCmbEscala.ItemIndex := 0;
  FEdtEscalaInicio.Text := '';
  FEdtCicloTrab.Text := '6';
  FEdtCicloFolga.Text := '1';
  FEdtIntervalo.Text := '60';
  FEdtVirada.Text := '00:00';
  FChkBanco.Checked := False;
  try
    Dias := dmDados.GetRegrasHorario(FSelectedHorarioId);
    try
      if not Dias.IsEmpty then
      begin
        if SameText(Dias.FieldByName('HOR_TIPO_ESCALA').AsString, '12X36') then FCmbEscala.ItemIndex := 1
        else if SameText(Dias.FieldByName('HOR_TIPO_ESCALA').AsString, 'CICLO') then FCmbEscala.ItemIndex := 2;
        if not Dias.FieldByName('HOR_ESCALA_INICIO').IsNull then
          FEdtEscalaInicio.Text := FormatDateTime('dd/mm/yyyy', Dias.FieldByName('HOR_ESCALA_INICIO').AsDateTime);
        if Dias.FieldByName('HOR_CICLO_TRABALHO').AsInteger > 0 then
          FEdtCicloTrab.Text := IntToStr(Dias.FieldByName('HOR_CICLO_TRABALHO').AsInteger);
        if Dias.FieldByName('HOR_CICLO_FOLGA').AsInteger > 0 then
          FEdtCicloFolga.Text := IntToStr(Dias.FieldByName('HOR_CICLO_FOLGA').AsInteger);
        if Dias.FieldByName('HOR_INTERVALO_MIN').AsInteger > 0 then
          FEdtIntervalo.Text := IntToStr(Dias.FieldByName('HOR_INTERVALO_MIN').AsInteger);
        if Trim(Dias.FieldByName('HOR_VIRADA_DIA').AsString) <> '' then
          FEdtVirada.Text := Trim(Dias.FieldByName('HOR_VIRADA_DIA').AsString);
        FChkBanco.Checked := Dias.FieldByName('HOR_BANCO_HORAS').AsString = 'S';
      end;
    finally
      Dias.Free;
    end;
  except
    // base sem as colunas das regras: mantém os padrões
  end;
  HorEscalaChange(nil);

  // jornada dia a dia gravada (dia sem horários = folga)
  Achou := False;
  try
    Dias := dmDados.GetHorarioDias(FSelectedHorarioId);
    try
      while not Dias.Eof do
      begin
        DiaSem := Dias.FieldByName('HDI_DIA_SEMANA').AsInteger;
        if (DiaSem >= 1) and (DiaSem <= 7) then
        begin
          Achou := True;
          if Dias.FieldByName('HDI_FOLGA').AsString = 'S' then
            LimparDiaHorario(DiaSem)
          else
            DefinirDiaHorario(DiaSem, Dias.FieldByName('HDI_ENTRADA_1').AsString, Dias.FieldByName('HDI_SAIDA_1').AsString,
              Dias.FieldByName('HDI_ENTRADA_2').AsString, Dias.FieldByName('HDI_SAIDA_2').AsString);
        end;
        Dias.Next;
      end;
    finally
      Dias.Free;
    end;
  except
    // base sem a tabela de jornada por dia: segue com os campos gerais
  end;
  if not Achou then
    for D := 1 to 7 do
      AtualizarCargaDiaHorario(D);
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

// Valida a grade semanal e grava a jornada (campos gerais + dia a dia). Os campos gerais
// (envio ao relógio e compatibilidade) seguem o primeiro dia trabalhado da semana.
function TfrmMain.SalvarJornadaDoForm(out ANovoId: Integer; out ADesc, AE1, AS1, AE2, AS2: string): Boolean;
var
  D, K, Primeiro, Carga, Tol: Integer;
  V: array[0..3] of string;
  G: array[0..3] of string;
  Dados: TArray<string>;
  Cargas: TArray<Integer>;
  Folgas: TArray<Boolean>;
  Vazio, TrabSab: Boolean;
  SE1, SS1: string;
  RegEscala, RegVirada: string;
  RegInicio: TDateTime;
  RegIntervalo, RegCicloT, RegCicloF, SomaSem, MaiorDia: Integer;
begin
  Result := False;
  ANovoId := FSelectedHorarioId;
  ADesc := Trim(edtHorDescricao.Text);
  if ADesc = '' then
  begin
    ShowMessage('Informe a descrição da jornada de trabalho.');
    if edtHorDescricao.CanFocus then
      edtHorDescricao.SetFocus;
    Exit;
  end;

  SetLength(Dados, 28);
  SetLength(Cargas, 7);
  SetLength(Folgas, 7);
  Primeiro := 0;
  for D := 1 to 7 do
  begin
    Vazio := True;
    for K := 0 to 3 do
    begin
      V[K] := NormalizaHoraTxt(FHorEdt[D, K].Text);
      FHorEdt[D, K].Text := V[K];
      if V[K] <> '' then
        Vazio := False;
    end;
    if Vazio then
    begin
      Folgas[D - 1] := True;   // tudo em branco: o dia não é trabalhado
      Continue;
    end;
    for K := 0 to 3 do
      if (V[K] <> '') and (not HoraTxtValida(V[K])) then
      begin
        ShowMessage(Format('Horário inválido em %s. Utilize o formato HH:MM.', [NomesDiasHor[D]]));
        Exit;
      end;
    if (V[0] = '') or (V[3] = '') then
    begin
      ShowMessage(Format('Informe a entrada e a saída de %s (ou deixe o dia inteiro em branco para folga).', [NomesDiasHor[D]]));
      Exit;
    end;
    if (V[1] = '') <> (V[2] = '') then
    begin
      ShowMessage(Format('Informe a saída e a volta do almoço de %s (ou deixe as duas em branco).', [NomesDiasHor[D]]));
      Exit;
    end;
    if V[1] <> '' then
    begin
      G[0] := V[0]; G[1] := V[1]; G[2] := V[2]; G[3] := V[3];
      Cargas[D - 1] := MinutosEntreHoras(G[0], G[1]) + MinutosEntreHoras(G[2], G[3]);
    end
    else
    begin
      G[0] := V[0]; G[1] := V[3]; G[2] := ''; G[3] := '';
      Cargas[D - 1] := MinutosEntreHoras(G[0], G[1]);
    end;
    for K := 0 to 3 do
      Dados[(D - 1) * 4 + K] := G[K];
    Folgas[D - 1] := False;
    if Primeiro = 0 then
      Primeiro := D;
  end;

  if Primeiro = 0 then
  begin
    ShowMessage('Informe ao menos um dia de trabalho na semana.');
    Exit;
  end;

  // Limites constitucionais/CLT para a escala semanal: 44h na semana (CF art. 7º XIII) e 10h no dia (art. 59)
  if FCmbEscala.ItemIndex = 0 then
  begin
    SomaSem := 0;
    MaiorDia := 0;
    for D := 1 to 7 do
    begin
      Inc(SomaSem, Cargas[D - 1]);
      if Cargas[D - 1] > MaiorDia then
        MaiorDia := Cargas[D - 1];
    end;
    if (SomaSem > 2640) and (MessageDlg(Format('A soma da semana é %s, acima do limite de 44h (CF, art. 7º, XIII).'#13#10 +
         'Deseja salvar mesmo assim?', [TPontoCalculoService.MinutosParaHora(SomaSem)]), mtWarning, [mbYes, mbNo], 0) <> mrYes) then
      Exit;
    if (MaiorDia > 600) and (MessageDlg(Format('Há um dia com %s de jornada, acima de 10h (CLT, art. 59).'#13#10 +
         'Deseja salvar mesmo assim?', [TPontoCalculoService.MinutosParaHora(MaiorDia)]), mtWarning, [mbYes, mbNo], 0) <> mrYes) then
      Exit;
  end;

  AE1 := Dados[(Primeiro - 1) * 4];
  AS1 := Dados[(Primeiro - 1) * 4 + 1];
  AE2 := Dados[(Primeiro - 1) * 4 + 2];
  AS2 := Dados[(Primeiro - 1) * 4 + 3];
  Carga := Cargas[Primeiro - 1];
  TrabSab := not Folgas[5];
  SE1 := '';
  SS1 := '';
  if TrabSab then
  begin
    SE1 := Dados[20];
    if Dados[23] <> '' then SS1 := Dados[23] else SS1 := Dados[21];
  end;
  Tol := StrToIntDef(Trim(edtHorTolerancia.Text), 10);

  // Regras da jornada
  RegEscala := 'SEMANAL';
  RegInicio := 0;
  RegCicloT := 0;
  RegCicloF := 0;
  if FCmbEscala.ItemIndex = 1 then RegEscala := '12X36'
  else if FCmbEscala.ItemIndex = 2 then RegEscala := 'CICLO';
  if RegEscala <> 'SEMANAL' then
  begin
    if not TryStrToDate(Trim(FEdtEscalaInicio.Text), RegInicio) then
    begin
      ShowMessage('Informe a data do primeiro dia trabalhado da escala (DD/MM/AAAA).');
      Exit;
    end;
    if RegEscala = 'CICLO' then
    begin
      RegCicloT := StrToIntDef(Trim(FEdtCicloTrab.Text), 0);
      RegCicloF := StrToIntDef(Trim(FEdtCicloFolga.Text), 0);
      if (RegCicloT <= 0) or (RegCicloF <= 0) then
      begin
        ShowMessage('Informe quantos dias a escala trabalha e quantos folga (ex.: 6 e 1).');
        Exit;
      end;
    end;
  end;
  RegVirada := NormalizaHoraTxt(FEdtVirada.Text);
  if (RegVirada <> '') and (not HoraTxtValida(RegVirada)) then
  begin
    ShowMessage('Horário da virada do dia inválido. Utilize HH:MM (ex.: 00:00 ou 05:00).');
    Exit;
  end;
  if RegVirada = '' then
    RegVirada := '00:00';
  RegIntervalo := StrToIntDef(Trim(FEdtIntervalo.Text), 60);
  if RegIntervalo < 0 then
    RegIntervalo := 60;

  // Horário geral e dias da semana são gravados juntos: se um falhar, nada é alterado
  // cria as tabelas que faltarem antes de abrir a transação (DDL não deve ficar dentro dela)
  if not dmDados.TabelaExiste('TB_PONTO_HORARIO_DIA') then
    dmDados.GarantirEstruturaComplementar;
  dmDados.FDConnection.StartTransaction;
  try
    ANovoId := dmDados.SalvarHorario(FSelectedHorarioId, ADesc, AE1, AS1, AE2, AS2, Tol, Carga,
      not TrabSab, TrabSab, SE1, SS1, chkHorAtivo.Checked, '');
    if (ANovoId <= 0) or (not dmDados.SalvarHorarioDias(ANovoId, Dados, Cargas, Folgas)) or
       (not dmDados.SalvarRegrasHorario(ANovoId, RegEscala, RegInicio, RegVirada, RegIntervalo, FChkBanco.Checked,
          RegCicloT, RegCicloF)) then
    begin
      dmDados.FDConnection.Rollback;
      ANovoId := FSelectedHorarioId;
      ShowMessage('Não foi possível salvar a jornada (nada foi alterado): ' + dmDados.LastError);
      Exit;
    end;
    dmDados.FDConnection.Commit;
    FSelectedHorarioId := ANovoId;
  except
    on E: Exception do
    begin
      if dmDados.FDConnection.InTransaction then
        dmDados.FDConnection.Rollback;
      ANovoId := FSelectedHorarioId;
      ShowMessage('Erro ao salvar a jornada (nada foi alterado): ' + E.Message);
      Exit;
    end;
  end;
  Result := True;
end;

procedure TfrmMain.btnSalvarHorarioClick(Sender: TObject);
var
  Desc, E1, S1, E2, S2: string;
  NovoId: Integer;
begin
  Screen.Cursor := crHourGlass;
  try
    if not SalvarJornadaDoForm(NovoId, Desc, E1, S1, E2, S2) then
      Exit;
    LogMessage(Format('💾 Jornada [%s] (ID %d) salva com sucesso.', [Desc, NovoId]));
    CarregarHorarios;
    CarregarComboHorariosColab;
    if Assigned(FUltimoEspelho) then
      ApurarEspelho(True);
    ShowMessage('Jornada de trabalho salva com sucesso!');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnSalvarEnviarHorarioClick(Sender: TObject);
var
  Desc, E1, S1, E2, S2: string;
  NovoId: Integer;
  RelId: Integer;
  SincronizouRelogio: Boolean;
begin
  Screen.Cursor := crHourGlass;
  try
    // 1. Salvar no banco Firebird local
    if not SalvarJornadaDoForm(NovoId, Desc, E1, S1, E2, S2) then
      Exit;
    LogMessage(Format('💾 Jornada [%s] (ID %d) salva com sucesso no banco de dados.', [Desc, NovoId]));
    CarregarHorarios;
    CarregarComboHorariosColab;
    if Assigned(FUltimoEspelho) then
      ApurarEspelho(True);

    // 2. Sincronizar com o Relógio de Ponto Ativo (usa o primeiro dia trabalhado da semana)
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
  I, C: Integer;
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
    if AEspelho.Dias[I].NoturnoMin > 0 then
      grdEspelho.Cells[10, I + 1] := TPontoCalculoService.MinutosParaHora(AEspelho.Dias[I].NoturnoMin)
    else
      grdEspelho.Cells[10, I + 1] := '';
    if AEspelho.Dias[I].IntervaloSuprimidoMin > 0 then
      grdEspelho.Cells[11, I + 1] := TPontoCalculoService.MinutosParaHora(AEspelho.Dias[I].IntervaloSuprimidoMin)
    else
      grdEspelho.Cells[11, I + 1] := '';
    grdEspelho.Cells[12, I + 1] := AEspelho.Dias[I].FaltaStr;
    grdEspelho.Cells[13, I + 1] := AEspelho.Dias[I].SaldoStr;
    grdEspelho.Cells[14, I + 1] := AEspelho.Dias[I].Ocorrencia;

    // Dias depois de hoje aparecem na grade, mas sem informações
    if AEspelho.Dias[I].Data > Date then
      for C := 2 to 14 do
        grdEspelho.Cells[C, I + 1] := '';
  end;

  AjustarColunasEspelho;

  with AEspelho.Resumo do
  begin
    lblCardEsp1Val.Caption := TotalPrevistoStr;
    lblCardEsp2Val.Caption := TotalTrabalhadoStr;
    lblCardEsp3Title.Caption := 'Extras 50% / 100%';
    lblCardEsp3Val.Caption := '+' + TPontoCalculoService.MinutosParaHora(TotalExtras50Min + TotalExtrasFaixa2Min) +
      ' / +' + TPontoCalculoService.MinutosParaHora(TotalExtras100Min);
    lblCardEsp4Title.Caption := 'Atrasos (faltas: ' + TPontoCalculoService.MinutosParaHora(TotalFaltasMin) + ')';
    lblCardEsp4Val.Caption := '-' + TPontoCalculoService.MinutosParaHora(TotalAtrasosMin);
    if UsaBancoHoras then
      lblCardEsp5Title.Caption := 'Banco de horas'
    else
      lblCardEsp5Title.Caption := 'Saldo do Período';
    lblCardEsp5Val.Caption := SaldoTotalStr;
    if SaldoTotalMin >= 0 then
      lblCardEsp5Val.Font.Color := $002E7D32
    else
      lblCardEsp5Val.Font.Color := $00C53030;

    // Linha de detalhes (mesmas informações do resumo do GoUp Ponto)
    if FLblEspelhoDetalhe = nil then
    begin
      FLblEspelhoDetalhe := TLabel.Create(Self);
      FLblEspelhoDetalhe.Parent := pnlEspelhoResumo;
      FLblEspelhoDetalhe.SetBounds(15, 66, 1050, 18);
      FLblEspelhoDetalhe.Anchors := [akLeft, akTop, akRight];
      FLblEspelhoDetalhe.Font.Color := $00555555;
      FLblEspelhoDetalhe.Font.Size := 9;
      pnlEspelhoResumo.Height := 92;
    end;
    FLblEspelhoDetalhe.Caption := Format(
      'Jornada: %s  •  Dias úteis: %d  •  Trabalhados: %d  •  Faltas: %d  •  DSR descontados: %d  •  ' +
      'Feriados: %d (descontados: %d)  •  Noturno: %s  •  Interv. suprimido: %s  •  Interjornada: %s' +
      '%s%s',
      [JornadaDescricao, TotalDiasUteis, TotalDiasTrabalhados, TotalFaltas, DsrDescontados,
       TotalFeriados, FeriadosDescontados, TPontoCalculoService.MinutosParaHora(TotalNoturnoMin),
       TPontoCalculoService.MinutosParaHora(TotalIntervaloSuprimidoMin),
       TPontoCalculoService.MinutosParaHora(TotalInterjornadaMin),
       SeTexto(DiasExtraAcima2h > 0, Format('  •  Dias com extra acima de 2h: %d', [DiasExtraAcima2h]), ''),
       SeTexto(SaldoAnteriorMin <> 0, '  •  Saldo anterior: ' +
         TPontoCalculoService.MinutosParaHora(SaldoAnteriorMin, True), '') +
       SeTexto(CreditoHorasMin <> 0, '  •  Crédito lançado: ' +
         TPontoCalculoService.MinutosParaHora(CreditoHorasMin, True), '') +
       SeTexto(ReflexoDsrExtrasMin > 0, '  •  Reflexo das extras no DSR: ' +
         TPontoCalculoService.MinutosParaHora(ReflexoDsrExtrasMin), '')]);
  end;
end;

procedure TfrmMain.btnCalcularEspelhoClick(Sender: TObject);
begin
  ApurarEspelho(False);
end;

// Ajusta a largura de cada coluna do espelho ao maior conteúdo (cabeçalho ou células); a sobra vai para a
// coluna de ocorrência. Se faltar espaço, a grade rola na horizontal em vez de cortar o texto.
procedure TfrmMain.AjustarColunasEspelho;
const
  MARGEM = 18;
  MINIMO: array[0..14] of Integer = (84, 60, 62, 62, 62, 62, 70, 72, 76, 72, 62, 72, 72, 76, 160);
var
  C, R, W, Largura, Soma: Integer;
begin
  grdEspelho.Canvas.Font.Name := 'Segoe UI';
  grdEspelho.Canvas.Font.Size := 9;
  Soma := 0;
  for C := 0 to grdEspelho.ColCount - 1 do
  begin
    grdEspelho.Canvas.Font.Style := [fsBold];
    Largura := grdEspelho.Canvas.TextWidth(grdEspelho.Cells[C, 0]) + MARGEM + 6;
    for R := 1 to grdEspelho.RowCount - 1 do
    begin
      W := grdEspelho.Canvas.TextWidth(grdEspelho.Cells[C, R]) + MARGEM;
      if W > Largura then
        Largura := W;
    end;
    if (C <= High(MINIMO)) and (Largura < MINIMO[C]) then
      Largura := MINIMO[C];
    grdEspelho.ColWidths[C] := Largura;
    Inc(Soma, Largura + grdEspelho.GridLineWidth);
  end;
  // sobra de largura vai para a última coluna (ocorrência)
  W := grdEspelho.ClientWidth - Soma;
  if W > 0 then
    grdEspelho.ColWidths[grdEspelho.ColCount - 1] := grdEspelho.ColWidths[grdEspelho.ColCount - 1] + W;
  grdEspelho.ScrollBars := ssBoth;
end;

// Trocou colaborador ou período: refaz a apuração sem janelas nem log
procedure TfrmMain.EspelhoFiltroChange(Sender: TObject);
begin
  ApurarEspelho(True);
end;

// Apura o espelho. No modo silencioso (troca de filtro, batida nova) não mostra avisos nem registra no log.
procedure TfrmMain.ApurarEspelho(ASilencioso: Boolean);
var
  PessoaId: Integer;
  DtIni, DtFim: TDateTime;
begin
  if cmbEspelhoColab.ItemIndex < 0 then
  begin
    if not ASilencioso then
      ShowMessage('Selecione um colaborador para apurar o ponto.');
    Exit;
  end;

  PessoaId := Integer(NativeInt(cmbEspelhoColab.Items.Objects[cmbEspelhoColab.ItemIndex]));
  DtIni := dtpEspelhoIni.Date;
  DtFim := dtpEspelhoFim.Date;

  if DtIni > DtFim then
  begin
    if not ASilencioso then
      ShowMessage('A data inicial do período não pode ser maior que a data final.');
    Exit;
  end;

  if not dmDados.IsConectado then
    Exit;

  if not ASilencioso then
    Screen.Cursor := crHourGlass;
  try
    if Assigned(FUltimoEspelho) then
    begin
      FUltimoEspelho.Free;
      FUltimoEspelho := nil;
    end;

    try
      FUltimoEspelho := TPontoCalculoService.CalcularEspelho(PessoaId, DtIni, DtFim);
      PreencherGridEspelho(FUltimoEspelho);
    except
      on E: Exception do
      begin
        LogMessage('❌ Falha ao apurar o espelho de ponto: ' + E.Message, True);
        if not ASilencioso then
          raise;
        Exit;
      end;
    end;
    if not ASilencioso then
      LogMessage(Format('📋 Espelho de Ponto apurado para [%s] no período de %s a %s. Total trabalhado: %s, Extras: +%s, Faltas: -%s, Saldo: %s.',
        [FUltimoEspelho.Resumo.ColaboradorNome,
         FormatDateTime('dd/mm/yyyy', DtIni),
         FormatDateTime('dd/mm/yyyy', DtFim),
         FUltimoEspelho.Resumo.TotalTrabalhadoStr,
         FUltimoEspelho.Resumo.TotalExtrasStr,
         FUltimoEspelho.Resumo.TotalFaltasStr,
         FUltimoEspelho.Resumo.SaldoTotalStr]));
  finally
    if not ASilencioso then
      Screen.Cursor := crDefault;
  end;
end;

// Ocorrência / justificativa: tipos previstos na CLT (art. 473 e Lei 605/49) e vários dias de uma vez
procedure TfrmMain.btnLancarJustificativaClick(Sender: TObject);
var
  PessoaId, I, Dias, AbonoMin, Gravadas: Integer;
  Valores: array of string;
  DataJus, DiaSel: TDateTime;
  TipoJus, MotivoJus: string;
begin
  if cmbEspelhoColab.ItemIndex < 0 then
  begin
    ShowMessage('Selecione um colaborador antes de lançar uma ocorrência.');
    Exit;
  end;

  PessoaId := Integer(NativeInt(cmbEspelhoColab.Items.Objects[cmbEspelhoColab.ItemIndex]));
  if not DiaEspelhoSelecionado(DiaSel) then
    DiaSel := Date;

  SetLength(Valores, 5);
  Valores[0] := FormatDateTime('dd/mm/yyyy', DiaSel);
  Valores[1] := 'Atestado médico';
  Valores[2] := '1';
  Valores[3] := '';
  Valores[4] := '0';

  if DialogoCampos('Lançar ocorrência / justificativa',
       cmbEspelhoColab.Text + '  •  CLT art. 473: luto 2 dias, casamento 3, nascimento 5, doação de sangue 1/ano',
       ['Data inicial (DD/MM/AAAA):',
        'Tipo|Atestado médico|Luto (2 dias)|Casamento (3 dias)|Nascimento de filho (5 dias)|Doação de sangue|' +
        'Alistamento eleitoral|Vestibular / prova|Comparecimento em juízo|Acompanhar filho ao médico|' +
        'Serviço militar|Folga / compensação|Declaração de comparecimento|Outra ocorrência',
        'Dias consecutivos (1 = só esta data):',
        'Motivo / justificativa detalhada:',
        'Minutos a abonar por dia (0 = o dia integral):'],
       Valores, $00A8449A) then
  begin
    if not TryStrToDate(Trim(Valores[0]), DataJus) then
    begin
      ShowMessage('Data informada é inválida. Utilize o formato DD/MM/AAAA.');
      Exit;
    end;
    Dias := StrToIntDef(Trim(Valores[2]), 1);
    if (Dias < 1) or (Dias > 60) then
    begin
      ShowMessage('Informe de 1 a 60 dias consecutivos. Para períodos longos use "Afastamentos".');
      Exit;
    end;
    TipoJus := Trim(Valores[1]);
    if TipoJus = '' then
      TipoJus := 'Atestado médico';
    MotivoJus := Trim(Valores[3]);
    AbonoMin := StrToIntDef(Trim(Valores[4]), 0);

    Gravadas := 0;
    for I := 0 to Dias - 1 do
      if dmDados.SalvarJustificativa(PessoaId, DataJus + I, TipoJus, MotivoJus, AbonoMin) then
        Inc(Gravadas);
    if Gravadas = Dias then
    begin
      LogMessage(Format('📝 Ocorrência registrada para %s a partir de %s (%d dia(s)): %s %s.',
        [cmbEspelhoColab.Text, FormatDateTime('dd/mm/yyyy', DataJus), Dias, TipoJus, MotivoJus]));
      ApurarEspelho(False);
    end
    else
      ShowMessage(Format('Só foi possível registrar %d de %d dia(s). Confira o banco de dados.', [Gravadas, Dias]));
  end;
end;

function TfrmMain.PessoaEspelhoId: Integer;
begin
  Result := 0;
  if cmbEspelhoColab.ItemIndex >= 0 then
    Result := Integer(NativeInt(cmbEspelhoColab.Items.Objects[cmbEspelhoColab.ItemIndex]));
end;

// Dia da linha selecionada na grade do espelho (a primeira linha só vale se o espelho foi apurado)
function TfrmMain.DiaEspelhoSelecionado(out ADia: TDateTime): Boolean;
var
  Lista: TArray<TDiaEspelho>;
begin
  Result := False;
  ADia := 0;
  if FUltimoEspelho = nil then
    Exit;
  Lista := FUltimoEspelho.Dias;
  if (grdEspelho.Row >= 1) and (grdEspelho.Row - 1 <= High(Lista)) then
  begin
    ADia := Lista[grdEspelho.Row - 1].Data;
    Result := True;
  end;
end;

procedure TfrmMain.btnCorrigirBatidaEspelhoClick(Sender: TObject);
var
  Dia: TDateTime;
begin
  if PessoaEspelhoId <= 0 then
  begin
    ShowMessage('Selecione primeiro o colaborador no Espelho de Ponto.');
    Exit;
  end;
  if not DiaEspelhoSelecionado(Dia) then
  begin
    ShowMessage('Clique em "Recalcular" e selecione o dia na grade (ou dê duplo clique nele) para corrigir as batidas.');
    Exit;
  end;
  AbrirTelaDiaEspelho(Dia);
end;

procedure TfrmMain.grdEspelhoDblClick(Sender: TObject);
var
  Dia: TDateTime;
  Cel: TGridCoord;
  P: TPoint;
begin
  // Só vale o duplo clique em uma linha de dados (não no cabeçalho)
  P := grdEspelho.ScreenToClient(Mouse.CursorPos);
  Cel := grdEspelho.MouseCoord(P.X, P.Y);
  if (Cel.Y < 1) or (PessoaEspelhoId <= 0) then
    Exit;
  if DiaEspelhoSelecionado(Dia) and (Dia <= Date) then
    AbrirTelaDiaEspelho(Dia);
end;

// F8: salta para a próxima pendência (marcação ímpar ou falta) a partir da linha atual
procedure TfrmMain.grdEspelhoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  I, Ini: Integer;
  Txt: string;
begin
  if Key <> VK_F8 then
    Exit;
  Key := 0;
  Ini := grdEspelho.Row + 1;
  for I := 0 to grdEspelho.RowCount - 2 do
  begin
    Txt := grdEspelho.Cells[14, ((Ini - 1 + I) mod (grdEspelho.RowCount - 1)) + 1];
    if (Pos('Impar', Txt) > 0) or (Pos('Ímpar', Txt) > 0) or (Pos('Falta', Txt) > 0) then
    begin
      grdEspelho.Row := ((Ini - 1 + I) mod (grdEspelho.RowCount - 1)) + 1;
      Exit;
    end;
  end;
  ShowMessage('Nenhuma pendência (marcação ímpar ou falta) encontrada no período.');
end;

// Saldo anterior: horas (positivas ou negativas) que o colaborador já tinha, por exemplo vindas de outro sistema.
// Entram no saldo do espelho e continuam somando nos meses seguintes.
procedure TfrmMain.btnSaldoAnteriorClick(Sender: TObject);
var
  Frm: TForm;
  Pnl: TPanel;
  Lb: TLabel;
  Lst: TListView;
  Col: TListColumn;
  Item: TListItem;
  Qry: TFDQuery;
  Ids: TStringList;
  Valores: array of string;
  PessoaId, Minutos, Sel: Integer;
  Data: TDateTime;
  Alterou, Continua: Boolean;
  Res: TModalResult;
  Tipo: string;

  function NovoBotao(const ACaption: string; ALeft, ALargura: Integer; AModal: TModalResult): TButton;
  begin
    Result := TButton.Create(Frm);
    Result.Parent := Frm;
    Result.SetBounds(ALeft, 330, ALargura, 34);
    Result.Caption := ACaption;
    Result.ModalResult := AModal;
  end;

begin
  PessoaId := PessoaEspelhoId;
  if PessoaId <= 0 then
  begin
    ShowMessage('Selecione primeiro o colaborador no Espelho de Ponto.');
    Exit;
  end;
  Alterou := False;
  Continua := True;
  Ids := TStringList.Create;
  try
    while Continua do
    begin
      if Alterou then
        ApurarEspelho(True);
      Ids.Clear;
      Frm := TForm.Create(Self);
      try
        Frm.Caption := 'Saldo anterior';
        Frm.BorderStyle := bsDialog;
        Frm.Position := poOwnerFormCenter;
        Frm.Font.Name := 'Segoe UI';
        Frm.Font.Size := 9;
        Frm.Color := $00FAF8F6;
        Frm.ClientWidth := 640;
        Frm.ClientHeight := 384;

        Pnl := TPanel.Create(Frm);
        Pnl.Parent := Frm;
        Pnl.SetBounds(0, 0, 640, 68);
        Pnl.BevelOuter := bvNone;
        Pnl.ParentBackground := False;
        Pnl.Color := $00A06A1B;
        Lb := TLabel.Create(Pnl);
        Lb.Parent := Pnl;
        Lb.SetBounds(20, 10, 600, 26);
        Lb.AutoSize := False;
        Lb.Font.Size := 14;
        Lb.Font.Style := [fsBold];
        Lb.Font.Color := clWhite;
        Lb.Caption := 'Saldo anterior de horas';
        Lb := TLabel.Create(Pnl);
        Lb.Parent := Pnl;
        Lb.SetBounds(20, 38, 600, 20);
        Lb.AutoSize := False;
        Lb.Font.Color := $00F2F2F2;
        Lb.Caption := cmbEspelhoColab.Text + '  •  entra no saldo e continua somando nos meses seguintes';

        Lst := TListView.Create(Frm);
        Lst.Parent := Frm;
        Lst.SetBounds(12, 80, 616, 236);
        Lst.ViewStyle := vsReport;
        Lst.ReadOnly := True;
        Lst.RowSelect := True;
        Lst.GridLines := True;
        Lst.HideSelection := False;
        Lst.Font.Size := 10;
        Col := Lst.Columns.Add; Col.Caption := 'Data'; Col.Width := 100;
        Col := Lst.Columns.Add; Col.Caption := 'Horas'; Col.Width := 90;
        Col := Lst.Columns.Add; Col.Caption := 'Tipo'; Col.Width := 120;
        Col := Lst.Columns.Add; Col.Caption := 'Descrição / origem'; Col.Width := 280;

        Qry := dmDados.GetLancamentosBancoHoras(PessoaId);
        try
          while not Qry.Eof do
          begin
            Tipo := Trim(Qry.FieldByName('BH_TIPO').AsString);
            if Tipo = 'S' then Tipo := 'Saldo anterior'
            else if Tipo = 'P' then Tipo := 'Pagamento em folha'
            else if Tipo = 'F' then Tipo := 'Folga compensada'
            else if Tipo = 'A' then Tipo := 'Ajuste';
            Item := Lst.Items.Add;
            Item.Caption := FormatDateTime('dd/mm/yyyy', Qry.FieldByName('BH_DATA').AsDateTime);
            Item.SubItems.Add(TPontoCalculoService.MinutosParaHora(Qry.FieldByName('BH_MINUTOS').AsInteger, True));
            Item.SubItems.Add(Tipo);
            Item.SubItems.Add(Qry.FieldByName('BH_DESCRICAO').AsString);
            Ids.Add(IntToStr(Qry.FieldByName('BH_ID').AsInteger));
            Qry.Next;
          end;
        finally
          Qry.Free;
        end;
        if Lst.Items.Count > 0 then
          Lst.ItemIndex := 0;

        NovoBotao('➕ Adicionar saldo', 12, 160, mrOk);
        NovoBotao('🗑️ Excluir lançamento', 180, 170, mrIgnore);
        NovoBotao('Fechar', 516, 112, mrCancel);

        Sel := Lst.ItemIndex;
        Res := Frm.ShowModal;
        if Res = mrCancel then
          Continua := False
        else if Res = mrIgnore then
        begin
          if (Sel < 0) or (Sel >= Ids.Count) then
            ShowMessage('Selecione um lançamento na lista.')
          else if MessageDlg('Excluir este lançamento? O saldo do colaborador será recalculado.',
                    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
          begin
            if dmDados.ExcluirLancamentoBancoHoras(StrToInt(Ids[Sel])) then
            begin
              LogMessage(Format('🗑️ Lançamento de saldo #%s excluído - %s.', [Ids[Sel], cmbEspelhoColab.Text]));
              Alterou := True;
            end;
          end;
        end
        else if Res = mrOk then
        begin
          SetLength(Valores, 3);
          Valores[0] := FormatDateTime('dd/mm/yyyy', dtpEspelhoIni.Date);
          Valores[1] := '+00:00';
          Valores[2] := 'Saldo de outro sistema';
          if DialogoCampos('Adicionar saldo anterior', cmbEspelhoColab.Text,
               ['Data de referência (DD/MM/AAAA):',
                'Saldo em horas (use - para negativo, ex.: -05:30 ou +12:00):',
                'Descrição / origem:'], Valores, $00A06A1B) then
          begin
            if not TryStrToDate(Trim(Valores[0]), Data) then
              ShowMessage('Data informada é inválida. Utilize o formato DD/MM/AAAA.')
            else if (not ParseSaldoHoras(Valores[1], Minutos)) or (Minutos = 0) then
              ShowMessage('Informe o saldo em horas no formato HH:MM, com + ou -. Exemplo: -05:30')
            else if dmDados.LancarBancoHoras(PessoaId, Data, Minutos, 'S', Trim(Valores[2])) > 0 then
            begin
              LogMessage(Format('🏦 Saldo anterior lançado para %s em %s: %s.',
                [cmbEspelhoColab.Text, FormatDateTime('dd/mm/yyyy', Data),
                 TPontoCalculoService.MinutosParaHora(Minutos, True)]));
              Alterou := True;
            end
            else
              ShowMessage('Não foi possível gravar o saldo: ' + dmDados.LastError);
          end;
        end;
      finally
        Frm.Free;
      end;
    end;
  finally
    Ids.Free;
  end;
  if Alterou then
    ApurarEspelho(False);
end;

// Quadro padrão das telas de lista (afastamentos, feriados): faixa colorida e lista em colunas
function TfrmMain.NovoQuadroLista(const ATitulo, ASub: string; ACor: TColor; const ACols: array of string;
  const ALargs: array of Integer; out ALst: TListView): TForm;
var
  Pnl: TPanel;
  Lb: TLabel;
  Col: TListColumn;
  I: Integer;
begin
  Result := TForm.Create(Self);
  Result.Caption := ATitulo;
  Result.BorderStyle := bsDialog;
  Result.Position := poOwnerFormCenter;
  Result.Font.Name := 'Segoe UI';
  Result.Font.Size := 9;
  Result.Color := $00FAF8F6;
  Result.ClientWidth := 700;
  Result.ClientHeight := 424;

  Pnl := TPanel.Create(Result);
  Pnl.Parent := Result;
  Pnl.SetBounds(0, 0, 700, 68);
  Pnl.BevelOuter := bvNone;
  Pnl.ParentBackground := False;
  Pnl.Color := ACor;
  Lb := TLabel.Create(Pnl);
  Lb.Parent := Pnl;
  Lb.SetBounds(20, 10, 660, 26);
  Lb.AutoSize := False;
  Lb.Font.Size := 14;
  Lb.Font.Style := [fsBold];
  Lb.Font.Color := clWhite;
  Lb.Caption := ATitulo;
  Lb := TLabel.Create(Pnl);
  Lb.Parent := Pnl;
  Lb.SetBounds(20, 38, 660, 20);
  Lb.AutoSize := False;
  Lb.Font.Color := $00F2F2F2;
  Lb.Caption := ASub;

  ALst := TListView.Create(Result);
  ALst.Parent := Result;
  ALst.SetBounds(12, 80, 676, 288);
  ALst.ViewStyle := vsReport;
  ALst.ReadOnly := True;
  ALst.RowSelect := True;
  ALst.GridLines := True;
  ALst.HideSelection := False;
  ALst.Font.Size := 10;
  for I := 0 to High(ACols) do
  begin
    Col := ALst.Columns.Add;
    Col.Caption := ACols[I];
    Col.Width := ALargs[I];
  end;
end;

function BotaoDoQuadro(AForm: TForm; const ACaption: string; ALeft, ALargura: Integer; AModal: TModalResult): TButton;
begin
  Result := TButton.Create(AForm);
  Result.Parent := AForm;
  Result.SetBounds(ALeft, 378, ALargura, 34);
  Result.Caption := ACaption;
  Result.ModalResult := AModal;
end;

// Afastamentos: férias, licenças, INSS... No período não há jornada prevista, falta nem desconto de DSR
procedure TfrmMain.btnAfastamentosClick(Sender: TObject);
var
  Frm: TForm;
  Lst: TListView;
  Qry: TFDQuery;
  Item: TListItem;
  Ids: TStringList;
  Valores: array of string;
  PessoaId, Sel: Integer;
  Alterou, Continua: Boolean;
  Res: TModalResult;
  Ini, Fim: TDateTime;
begin
  PessoaId := PessoaEspelhoId;
  if PessoaId <= 0 then
  begin
    ShowMessage('Selecione primeiro o colaborador no Espelho de Ponto.');
    Exit;
  end;
  Alterou := False;
  Continua := True;
  Ids := TStringList.Create;
  try
    while Continua do
    begin
      if Alterou then
        ApurarEspelho(True);
      Ids.Clear;
      Frm := NovoQuadroLista('Afastamentos', cmbEspelhoColab.Text + '  •  férias, licenças e INSS: não geram falta nem desconto',
        $0088571B, ['Início', 'Fim', 'Tipo', 'Motivo / observação'], [95, 95, 190, 280], Lst);
      try
        Qry := dmDados.GetAfastamentos(PessoaId);
        try
          while not Qry.Eof do
          begin
            Item := Lst.Items.Add;
            Item.Caption := FormatDateTime('dd/mm/yyyy', Qry.FieldByName('AFA_INICIO').AsDateTime);
            Item.SubItems.Add(FormatDateTime('dd/mm/yyyy', Qry.FieldByName('AFA_FIM').AsDateTime));
            Item.SubItems.Add(Qry.FieldByName('AFA_TIPO').AsString);
            Item.SubItems.Add(Qry.FieldByName('AFA_MOTIVO').AsString);
            Ids.Add(IntToStr(Qry.FieldByName('AFA_ID').AsInteger));
            Qry.Next;
          end;
        finally
          Qry.Free;
        end;
        if Lst.Items.Count > 0 then
          Lst.ItemIndex := 0;
        BotaoDoQuadro(Frm, '➕ Novo afastamento', 12, 170, mrOk);
        BotaoDoQuadro(Frm, '🗑️ Excluir', 190, 120, mrIgnore);
        BotaoDoQuadro(Frm, 'Fechar', 576, 112, mrCancel);

        Sel := Lst.ItemIndex;
        Res := Frm.ShowModal;
        if Res = mrCancel then
          Continua := False
        else if Res = mrIgnore then
        begin
          if (Sel < 0) or (Sel >= Ids.Count) then
            ShowMessage('Selecione um afastamento na lista.')
          else if MessageDlg('Excluir este afastamento? Os dias voltam a ter jornada prevista.',
                    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
            if dmDados.ExcluirAfastamento(StrToInt(Ids[Sel])) then
            begin
              LogMessage(Format('🗑️ Afastamento #%s excluído - %s.', [Ids[Sel], cmbEspelhoColab.Text]));
              Alterou := True;
            end;
        end
        else if Res = mrOk then
        begin
          SetLength(Valores, 4);
          Valores[0] := 'Férias';
          Valores[1] := FormatDateTime('dd/mm/yyyy', dtpEspelhoIni.Date);
          Valores[2] := FormatDateTime('dd/mm/yyyy', dtpEspelhoIni.Date);
          Valores[3] := '';
          if DialogoCampos('Novo afastamento', cmbEspelhoColab.Text,
               ['Tipo|Férias|Licença-maternidade|Licença-paternidade|Auxílio-doença (INSS)|Acidente de trabalho|' +
                'Licença não remunerada|Suspensão|Serviço militar|Outro afastamento',
                'Início (DD/MM/AAAA):', 'Fim (DD/MM/AAAA):', 'Motivo / observação:'], Valores, $0088571B) then
          begin
            if Trim(Valores[0]) = '' then
              ShowMessage('Informe o tipo do afastamento.')
            else if (not TryStrToDate(Trim(Valores[1]), Ini)) or (not TryStrToDate(Trim(Valores[2]), Fim)) then
              ShowMessage('Data inválida. Utilize o formato DD/MM/AAAA.')
            else if Fim < Ini then
              ShowMessage('O fim do afastamento não pode ser antes do início.')
            else if dmDados.LancarAfastamento(PessoaId, Ini, Fim, Valores[0], Valores[3]) > 0 then
            begin
              LogMessage(Format('🏖️ Afastamento lançado para %s: %s de %s a %s.',
                [cmbEspelhoColab.Text, Valores[0], FormatDateTime('dd/mm/yyyy', Ini), FormatDateTime('dd/mm/yyyy', Fim)]));
              Alterou := True;
            end
            else
              ShowMessage('Não foi possível gravar o afastamento: ' + dmDados.LastError);
          end;
        end;
      finally
        Frm.Free;
      end;
    end;
  finally
    Ids.Free;
  end;
  if Alterou then
    ApurarEspelho(False);
end;

// Feriados: nacionais, estaduais e municipais. Feriado nacional removido fica "desativado" (não volta sozinho).
procedure TfrmMain.btnFeriadosClick(Sender: TObject);
var
  Frm: TForm;
  Lst: TListView;
  Qry: TFDQuery;
  Item: TListItem;
  Ids, Datas, Descs, Abrs, Recs: TStringList;
  Valores: array of string;
  Sel, Id: Integer;
  Alterou, Continua: Boolean;
  Res: TModalResult;
  Data: TDateTime;
  Abr, Rec: string;

  function PedirDados(const ATitulo: string): Boolean;
  begin
    Result := DialogoCampos(ATitulo, 'Feriados estaduais e municipais valem para todos os colaboradores',
      ['Data (DD/MM/AAAA):', 'Descrição:', 'Abrangência|Nacional|Estadual|Municipal', 'Repete todo ano|Sim|Não'],
      Valores, $00137333);
  end;

  function ValidarDados: Boolean;
  begin
    Result := False;
    if not TryStrToDate(Trim(Valores[0]), Data) then
      ShowMessage('Data inválida. Utilize o formato DD/MM/AAAA.')
    else if Trim(Valores[1]) = '' then
      ShowMessage('Informe a descrição do feriado.')
    else
      Result := True;
  end;

begin
  Alterou := False;
  Continua := True;
  Ids := TStringList.Create;
  Datas := TStringList.Create;
  Descs := TStringList.Create;
  Abrs := TStringList.Create;
  Recs := TStringList.Create;
  try
    while Continua do
    begin
      if Alterou then
        ApurarEspelho(True);
      Ids.Clear; Datas.Clear; Descs.Clear; Abrs.Clear; Recs.Clear;
      Frm := NovoQuadroLista('Feriados', 'Os feriados nacionais fixos já vêm cadastrados; inclua os estaduais e municipais',
        $00137333, ['Data', 'Descrição', 'Abrangência', 'Repete'], [90, 300, 140, 120], Lst);
      try
        Qry := dmDados.GetFeriados;
        try
          while not Qry.Eof do
          begin
            Abr := UpperCase(Qry.FieldByName('FER_ABRANGENCIA').AsString);
            Item := Lst.Items.Add;
            if Qry.FieldByName('FER_RECORRENTE').AsString = 'N' then
              Item.Caption := FormatDateTime('dd/mm/yyyy', Qry.FieldByName('FER_DATA').AsDateTime)
            else
              Item.Caption := FormatDateTime('dd/mm', Qry.FieldByName('FER_DATA').AsDateTime);
            Item.SubItems.Add(Qry.FieldByName('FER_DESCRICAO').AsString);
            if Abr = 'EXCLUIDO' then Item.SubItems.Add('Desativado')
            else if Abr = 'ESTADUAL' then Item.SubItems.Add('Estadual')
            else if Abr = 'MUNICIPAL' then Item.SubItems.Add('Municipal')
            else Item.SubItems.Add('Nacional');
            Item.SubItems.Add(SeTexto(Qry.FieldByName('FER_RECORRENTE').AsString = 'N', 'Só nesta data', 'Todo ano'));
            Ids.Add(IntToStr(Qry.FieldByName('FER_ID').AsInteger));
            Datas.Add(FormatDateTime('dd/mm/yyyy', Qry.FieldByName('FER_DATA').AsDateTime));
            Descs.Add(Qry.FieldByName('FER_DESCRICAO').AsString);
            Abrs.Add(Abr);
            Recs.Add(Qry.FieldByName('FER_RECORRENTE').AsString);
            Qry.Next;
          end;
        finally
          Qry.Free;
        end;
        if Lst.Items.Count > 0 then
          Lst.ItemIndex := 0;
        BotaoDoQuadro(Frm, '➕ Adicionar', 12, 112, mrOk);
        BotaoDoQuadro(Frm, '✏️ Editar', 130, 100, mrRetry);
        BotaoDoQuadro(Frm, '🗑️ Remover', 236, 112, mrIgnore);
        BotaoDoQuadro(Frm, '↩️ Reativar', 354, 112, mrYes);
        BotaoDoQuadro(Frm, 'Fechar', 576, 112, mrCancel);

        Sel := Lst.ItemIndex;
        Res := Frm.ShowModal;
        SetLength(Valores, 4);
        if Res = mrCancel then
          Continua := False
        else if Res = mrOk then
        begin
          Valores[0] := FormatDateTime('dd/mm/yyyy', Date);
          Valores[1] := '';
          Valores[2] := 'Municipal';
          Valores[3] := 'Sim';
          if PedirDados('Adicionar feriado') and ValidarDados then
          begin
            Abr := UpperCase(Valores[2]);
            if dmDados.SalvarFeriado(0, Data, Valores[1], SameText(Valores[3], 'Sim'), Abr) > 0 then
            begin
              LogMessage(Format('📅 Feriado cadastrado: %s em %s (%s).', [Valores[1], FormatDateTime('dd/mm/yyyy', Data), Abr]));
              Alterou := True;
            end
            else
              ShowMessage('Não foi possível gravar o feriado: ' + dmDados.LastError);
          end;
        end
        else if (Sel < 0) or (Sel >= Ids.Count) then
          ShowMessage('Selecione um feriado na lista.')
        else
        begin
          Id := StrToInt(Ids[Sel]);
          if Res = mrRetry then
          begin
            Valores[0] := Datas[Sel];
            Valores[1] := Descs[Sel];
            if Abrs[Sel] = 'ESTADUAL' then Valores[2] := 'Estadual'
            else if Abrs[Sel] = 'MUNICIPAL' then Valores[2] := 'Municipal'
            else Valores[2] := 'Nacional';
            Valores[3] := SeTexto(Recs[Sel] = 'N', 'Não', 'Sim');
            if PedirDados('Editar feriado') and ValidarDados then
            begin
              Abr := UpperCase(Valores[2]);
              if dmDados.SalvarFeriado(Id, Data, Valores[1], SameText(Valores[3], 'Sim'), Abr) > 0 then
                Alterou := True
              else
                ShowMessage('Não foi possível gravar o feriado: ' + dmDados.LastError);
            end;
          end
          else if Res = mrIgnore then
          begin
            Rec := SeTexto(Abrs[Sel] = 'NACIONAL', 'Este feriado nacional será desativado (não conta mais no cálculo). ' +
              'Você pode reativá-lo depois.', 'Remover este feriado?');
            if MessageDlg(Descs[Sel] + ' (' + Datas[Sel] + ')'#13#10 + Rec, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
              if dmDados.RemoverFeriado(Id) then
              begin
                LogMessage(Format('🗑️ Feriado removido/desativado: %s (%s).', [Descs[Sel], Datas[Sel]]));
                Alterou := True;
              end;
          end
          else if Res = mrYes then
          begin
            if Abrs[Sel] <> 'EXCLUIDO' then
              ShowMessage('Este feriado já está ativo.')
            else if dmDados.ReativarFeriado(Id) then
              Alterou := True;
          end;
        end;
      finally
        Frm.Free;
      end;
    end;
  finally
    Ids.Free; Datas.Free; Descs.Free; Abrs.Free; Recs.Free;
  end;
  if Alterou then
    ApurarEspelho(False);
end;

// Navegação rápida: ajusta o período para o mês inteiro anterior/seguinte e refaz a apuração
procedure TfrmMain.NavegarMesEspelho(ADelta: Integer);
var
  Base: TDateTime;
begin
  Base := IncMonth(StartOfTheMonth(dtpEspelhoIni.Date), ADelta);
  dtpEspelhoIni.Date := Base;
  dtpEspelhoFim.Date := EndOfTheMonth(Base);
  ApurarEspelho(True);
end;

procedure TfrmMain.btnMesAnteriorClick(Sender: TObject);
begin
  NavegarMesEspelho(-1);
end;

procedure TfrmMain.btnMesSeguinteClick(Sender: TObject);
begin
  NavegarMesEspelho(1);
end;

// Resumo de todos os colaboradores no período (base para a folha): horas, extras 50%/100%, noturno, faltas e DSR
procedure TfrmMain.btnResumoGeralClick(Sender: TObject);
var
  SB: TStringBuilder;
  I: Integer;
  Esp: TEspelhoPonto;
  R: TResumoEspelho;
  Razao, Cnpj, Endereco, Cei, CpfResp, Arquivo: string;
  Total: TResumoEspelho;
  Stream: TStreamWriter;
  Qtd: Integer;

  function H(AMin: Integer; ASinal: Boolean = False): string;
  begin
    Result := TPontoCalculoService.MinutosParaHora(AMin, ASinal);
  end;

  function Linha(const ANome: string; const AR: TResumoEspelho; ATotal: Boolean): string;
  begin
    Result := '<tr' + SeTexto(ATotal, ' class="total"', '') + '><td style="text-align:left">' + ANome + '</td>' +
      '<td>' + H(AR.TotalPrevistoMin) + '</td><td>' + H(AR.TotalTrabalhadoMin) + '</td>' +
      '<td>' + H(AR.TotalExtras50Min + AR.TotalExtrasFaixa2Min) + '</td><td>' + H(AR.TotalExtras100Min) + '</td>' +
      '<td>' + H(AR.ReflexoDsrExtrasMin) + '</td><td>' + H(AR.NoturnoPagoMin) + '</td><td>' + H(AR.TotalAtrasosMin) + '</td><td>' + IntToStr(AR.TotalFaltas) + '</td>' +
      '<td>' + IntToStr(AR.DsrDescontados + AR.FeriadosDescontados) + '</td><td>' + H(AR.TotalAbonadoMin) + '</td>' +
      '<td>' + H(AR.TotalIntervaloSuprimidoMin) + '</td><td><b>' + H(AR.SaldoTotalMin, True) + '</b></td></tr>';
  end;

begin
  if cmbEspelhoColab.Items.Count = 0 then
  begin
    ShowMessage('Não há colaboradores cadastrados.');
    Exit;
  end;
  if dtpEspelhoIni.Date > dtpEspelhoFim.Date then
  begin
    ShowMessage('A data inicial do período não pode ser maior que a data final.');
    Exit;
  end;

  Total := Default(TResumoEspelho);
  SB := TStringBuilder.Create;
  Screen.Cursor := crHourGlass;
  try
    Razao := 'Empresa';
    Cnpj := '';
    dmDados.GetEmpresaPrincipal(Razao, Cnpj, Endereco, Cei, CpfResp);
    SB.AppendLine('<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8"><title>Resumo geral do ponto</title><style>');
    SB.AppendLine('body{font-family:Segoe UI,Arial,sans-serif;font-size:12px;color:#222;margin:20px}');
    SB.AppendLine('h2{margin:0 0 4px 0;color:#1e395b} p{margin:2px 0;color:#555;font-size:11px}');
    SB.AppendLine('table{width:100%;border-collapse:collapse;margin-top:12px}');
    SB.AppendLine('th{background:#2b579a;color:#fff;padding:6px 4px;font-size:11px}');
    SB.AppendLine('td{border:1px solid #e1e4e8;padding:5px 4px;text-align:center;font-size:11px}');
    SB.AppendLine('tr:nth-child(even){background:#fafafa} .total td{background:#eef2f7;font-weight:bold}');
    SB.AppendLine('@media print{button{display:none} body{margin:8mm}}</style></head><body>');
    SB.AppendLine('<div style="text-align:right"><button onclick="window.print()" style="padding:8px 16px;background:#2b579a;color:#fff;border:none;border-radius:4px;cursor:pointer;font-weight:bold">Imprimir</button></div>');
    SB.AppendLine('<h2>RESUMO GERAL DO PONTO</h2>');
    SB.AppendLine('<p><b>Empregador:</b> ' + Razao + ' &nbsp;|&nbsp; <b>CNPJ:</b> ' + Cnpj + '</p>');
    SB.AppendLine('<p><b>Período:</b> ' + FormatDateTime('dd/mm/yyyy', dtpEspelhoIni.Date) + ' a ' +
      FormatDateTime('dd/mm/yyyy', dtpEspelhoFim.Date) + '</p>');
    SB.AppendLine('<table><thead><tr><th>Colaborador</th><th>Previsto</th><th>Realizado</th><th>Extras 50%</th>' +
      '<th>Extras 100%</th><th>Reflexo DSR s/ extras</th><th>Noturno (hora reduzida)</th><th>Atrasos</th><th>Faltas (dias)</th>' +
      '<th>DSR/feriado descontado</th><th>Abonado</th><th>Interv. suprimido</th><th>Saldo</th></tr></thead><tbody>');
    Qtd := 0;
    for I := 0 to cmbEspelhoColab.Items.Count - 1 do
    begin
      Esp := TPontoCalculoService.CalcularEspelho(Integer(NativeInt(cmbEspelhoColab.Items.Objects[I])),
        dtpEspelhoIni.Date, dtpEspelhoFim.Date);
      try
        R := Esp.Resumo;
        if R.ColaboradorNome = '' then
          Continue;
        Inc(Qtd);
        SB.AppendLine(Linha(R.ColaboradorNome, R, False));
        Inc(Total.TotalPrevistoMin, R.TotalPrevistoMin);
        Inc(Total.TotalTrabalhadoMin, R.TotalTrabalhadoMin);
        Inc(Total.TotalExtras50Min, R.TotalExtras50Min + R.TotalExtrasFaixa2Min);
        Inc(Total.TotalExtras100Min, R.TotalExtras100Min);
        Inc(Total.NoturnoPagoMin, R.NoturnoPagoMin);
        Inc(Total.ReflexoDsrExtrasMin, R.ReflexoDsrExtrasMin);
        Inc(Total.TotalAtrasosMin, R.TotalAtrasosMin);
        Inc(Total.TotalFaltas, R.TotalFaltas);
        Inc(Total.DsrDescontados, R.DsrDescontados + R.FeriadosDescontados);
        Inc(Total.TotalAbonadoMin, R.TotalAbonadoMin);
        Inc(Total.TotalIntervaloSuprimidoMin, R.TotalIntervaloSuprimidoMin);
        Inc(Total.SaldoTotalMin, R.SaldoTotalMin);
      finally
        Esp.Free;
      end;
    end;
    // o total usa os campos de extras já somados (50% + faixa 2) e descontos juntos
    Total.TotalExtrasFaixa2Min := 0;
    Total.FeriadosDescontados := 0;
    SB.AppendLine(Linha('TOTAL (' + IntToStr(Qtd) + ' colaboradores)', Total, True));
    SB.AppendLine('</tbody></table>');
    SB.AppendLine('<p style="margin-top:10px">Noturno em hora reduzida (art. 73 §1º CLT: 52min30s = 1h). ' +
      'Extras em domingos, feriados e folgas da escala: 100%. DSR e feriado perdidos por falta injustificada na semana (Lei 605/49, art. 6º).</p>');
    SB.AppendLine('</body></html>');

    Arquivo := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'Resumo_Geral_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.html';
    Stream := TStreamWriter.Create(Arquivo, False, TEncoding.UTF8);
    try
      Stream.Write(SB.ToString);
    finally
      Stream.Free;
    end;
  finally
    Screen.Cursor := crDefault;
    SB.Free;
  end;
  ShellExecute(0, 'open', PChar(Arquivo), nil, nil, SW_SHOWNORMAL);
  LogMessage('📊 Resumo geral do ponto gerado: ' + Arquivo);
end;

procedure TfrmMain.btnIncluirBatidaEspelhoClick(Sender: TObject);
var
  Dia: TDateTime;
begin
  if not DiaEspelhoSelecionado(Dia) then
    Dia := Date;
  if IncluirBatidaEspelho(Dia) then
    btnCalcularEspelhoClick(nil);
end;

// Corrige uma batida existente (Portaria 671: a original fica desconsiderada e uma nova é gravada)
function TfrmMain.CorrigirBatidaExistente(AId: Integer; ADataHora: TDateTime; const ATipo: string): Boolean;
var
  Prompts, Values: array of string;
  TipoStr, MotivoStr: string;
  NovaDataHora: TDateTime;
  NovoId: Integer;
begin
  Result := False;
  SetLength(Prompts, 4);
  SetLength(Values, 4);
  Prompts[0] := 'Data da Batida (DD/MM/AAAA):';
  Values[0] := FormatDateTime('dd/mm/yyyy', ADataHora);
  Prompts[1] := 'Hora da Batida (HH:MM:SS):';
  Values[1] := FormatDateTime('hh:nn:ss', ADataHora);
  Prompts[2] := 'Tipo de Batida (E = Entrada, S = Saída):';
  Values[2] := SeTexto((ATipo = 'E') or (ATipo = 'S'), ATipo, 'E');
  Prompts[3] := 'Motivo da Correção (Portaria 671 MTE):';
  Values[3] := 'Esquecimento de registro';

  if not DialogoCampos('Corrigir batida', Format('Batida #%d  •  %s', [AId, cmbEspelhoColab.Text]),
       Prompts, Values, $000677D9) then
    Exit;

  MotivoStr := Trim(Values[3]);
  if not ValidarEntradaBatida(Values[0], Values[1], Values[2], NovaDataHora, TipoStr) then
    Exit;
  if Length(MotivoStr) < 5 then
  begin
    ShowMessage('Informe o motivo da correção (mínimo 5 caracteres).');
    Exit;
  end;

  NovoId := dmDados.CorrigirMarcacao(AId, NovaDataHora, TipoStr, MotivoStr);
  if NovoId > 0 then
  begin
    LogMessage(Format('✏️ Batida #%d corrigida pela #%d em %s (%s) - %s [Motivo: %s]',
      [AId, NovoId, FormatDateTime('dd/mm/yyyy hh:nn:ss', NovaDataHora), TipoStr, cmbEspelhoColab.Text, MotivoStr]));
    Result := True;
  end
  else
    ShowMessage('Não foi possível corrigir a batida.');
end;

// Diálogo de preenchimento no padrão visual do sistema: faixa colorida com título, um campo por linha
// (o "Tipo de Batida" vira lista E/S) e botões de confirmar/cancelar. Substitui o InputQuery.
function TfrmMain.DialogoCampos(const ATitulo, ASubtitulo: string; const APrompts: array of string;
  var AValores: array of string; ACor: TColor): Boolean;
var
  Frm: TForm;
  Pnl: TPanel;
  Lb: TLabel;
  Ed: TEdit;
  Cb: TComboBox;
  Ctrls: array of TWinControl;
  BtnOk, BtnCancel: TButton;
  I, Y, P: Integer;
  Itens, Rotulo: string;
begin
  Result := False;
  Frm := TForm.Create(Self);
  try
    Frm.BorderStyle := bsDialog;
    Frm.Position := poOwnerFormCenter;
    Frm.Font.Name := 'Segoe UI';
    Frm.Font.Size := 9;
    Frm.Color := $00FAF8F6;
    Frm.Caption := ATitulo;
    Frm.ClientWidth := 540;

    Pnl := TPanel.Create(Frm);
    Pnl.Parent := Frm;
    Pnl.SetBounds(0, 0, 540, 68);
    Pnl.BevelOuter := bvNone;
    Pnl.ParentBackground := False;
    Pnl.Color := ACor;

    Lb := TLabel.Create(Pnl);
    Lb.Parent := Pnl;
    Lb.SetBounds(20, 10, 500, 26);
    Lb.AutoSize := False;
    Lb.Font.Size := 14;
    Lb.Font.Style := [fsBold];
    Lb.Font.Color := clWhite;
    Lb.Caption := ATitulo;

    Lb := TLabel.Create(Pnl);
    Lb.Parent := Pnl;
    Lb.SetBounds(20, 38, 500, 20);
    Lb.AutoSize := False;
    Lb.Font.Color := $00F2F2F2;
    Lb.Caption := ASubtitulo;

    SetLength(Ctrls, Length(APrompts));
    Y := 84;
    for I := 0 to High(APrompts) do
    begin
      Lb := TLabel.Create(Frm);
      Lb.Parent := Frm;
      Lb.SetBounds(22, Y, 496, 16);
      Lb.AutoSize := False;
      Lb.Font.Color := $00555555;
      // "Rótulo|opção 1|opção 2": campo com lista de opções (também aceita texto livre)
      Itens := '';
      Rotulo := APrompts[I];
      P := Pos('|', Rotulo);
      if P > 0 then
      begin
        Itens := Copy(Rotulo, P + 1, MaxInt);
        Rotulo := Copy(Rotulo, 1, P - 1);
      end;
      Lb.Caption := Rotulo;

      if Itens <> '' then
      begin
        Cb := TComboBox.Create(Frm);
        Cb.Parent := Frm;
        Cb.Style := csDropDown;
        Cb.Tag := 1;                       // 1 = aceita texto livre
        Cb.Font.Size := 10;
        Cb.SetBounds(22, Y + 19, 496, 28);
        Cb.Items.StrictDelimiter := True;
        Cb.Items.Delimiter := '|';
        Cb.Items.DelimitedText := Itens;
        if Trim(AValores[I]) <> '' then
          Cb.Text := AValores[I]
        else if Cb.Items.Count > 0 then
          Cb.ItemIndex := 0;
        Ctrls[I] := Cb;
      end
      else if Pos('Tipo de Batida', APrompts[I]) = 1 then
      begin
        Cb := TComboBox.Create(Frm);
        Cb.Parent := Frm;
        Cb.Style := csDropDownList;
        Cb.Font.Size := 10;
        Cb.SetBounds(22, Y + 19, 496, 28);
        Cb.Items.Add('E');
        Cb.Items.Add('S');
        if UpperCase(Trim(AValores[I])) = 'S' then
          Cb.ItemIndex := 1
        else
          Cb.ItemIndex := 0;
        Ctrls[I] := Cb;
      end
      else
      begin
        Ed := TEdit.Create(Frm);
        Ed.Parent := Frm;
        Ed.Font.Size := 10;
        Ed.SetBounds(22, Y + 19, 496, 27);
        Ed.Text := AValores[I];
        Ctrls[I] := Ed;
      end;
      Inc(Y, 58);
    end;

    BtnOk := TButton.Create(Frm);
    BtnOk.Parent := Frm;
    BtnOk.SetBounds(298, Y + 6, 108, 34);
    BtnOk.Caption := '✔ Confirmar';
    BtnOk.Font.Style := [fsBold];
    BtnOk.Default := True;
    BtnOk.ModalResult := mrOk;

    BtnCancel := TButton.Create(Frm);
    BtnCancel.Parent := Frm;
    BtnCancel.SetBounds(414, Y + 6, 104, 34);
    BtnCancel.Caption := 'Cancelar';
    BtnCancel.Cancel := True;
    BtnCancel.ModalResult := mrCancel;

    Frm.ClientHeight := Y + 6 + 34 + 18;

    if Frm.ShowModal = mrOk then
    begin
      for I := 0 to High(APrompts) do
        if (Ctrls[I] is TComboBox) and (Ctrls[I].Tag = 1) then
          AValores[I] := Trim(TComboBox(Ctrls[I]).Text)
        else if Ctrls[I] is TComboBox then
          AValores[I] := TComboBox(Ctrls[I]).Items[TComboBox(Ctrls[I]).ItemIndex]
        else
          AValores[I] := TEdit(Ctrls[I]).Text;
      Result := True;
    end;
  finally
    Frm.Free;
  end;
end;

// Batida desconsiderada (Portaria 671): cinza e riscada na lista da tela do dia
procedure TfrmMain.LvDiaCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  if Item.Data <> nil then
  begin
    Sender.Canvas.Font.Color := clGray;
    Sender.Canvas.Font.Style := [fsStrikeOut];
  end
  else
    Sender.Canvas.Font.Style := [];
end;

// Tela de alteração do dia: lista as batidas, corrige, desconsidera/restaura e inclui
procedure TfrmMain.AbrirTelaDiaEspelho(ADia: TDateTime);
var
  Frm: TForm;
  Lst: TListView;
  Pnl: TPanel;
  LblTit, LblInfo: TLabel;
  Col: TListColumn;
  Item: TListItem;
  DiaInfo: TDiaEspelho;
  TemInfo: Boolean;
  I: Integer;
  Origem, Situacao: string;
  ChkSemExtra, ChkFeriado: TCheckBox;
  SemExtra0, Feriado0: Boolean;
  Ids, Flags, Tipos: TStringList;
  Qry: TFDQuery;
  Alterou, Continua: Boolean;
  PessoaId, Sel, Id: Integer;
  Res: TModalResult;
  Desc: Boolean;
  Dh: TDateTime;
  Motivo: string;
  Valores: array of string;

  function NovoBotao(const ACaption: string; ALeft: Integer; AModal: TModalResult): TButton;
  begin
    Result := TButton.Create(Frm);
    Result.Parent := Frm;
    Result.SetBounds(ALeft, 338, 112, 34);
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := 9;
    Result.Caption := ACaption;
    Result.ModalResult := AModal;
  end;

begin
  PessoaId := PessoaEspelhoId;
  if PessoaId <= 0 then
    Exit;
  Alterou := False;
  Continua := True;
  Ids := TStringList.Create;
  Flags := TStringList.Create;
  Tipos := TStringList.Create;
  try
    while Continua do
    begin
      // Depois de qualquer alteração o espelho (e o saldo) é recalculado antes de reabrir a tela do dia
      if Alterou then
        ApurarEspelho(True);
      Ids.Clear;
      Flags.Clear;
      Tipos.Clear;

      // Resumo do dia, vindo do espelho já recalculado
      TemInfo := False;
      if FUltimoEspelho <> nil then
        for I := 0 to High(FUltimoEspelho.Dias) do
          if Trunc(FUltimoEspelho.Dias[I].Data) = Trunc(ADia) then
          begin
            DiaInfo := FUltimoEspelho.Dias[I];
            TemInfo := True;
            Break;
          end;

      Frm := TForm.Create(Self);
      try
        Frm.Caption := 'Batidas do dia';
        Frm.BorderStyle := bsDialog;
        Frm.Position := poOwnerFormCenter;
        Frm.Font.Name := 'Segoe UI';
        Frm.Font.Size := 9;
        Frm.Color := $00F7F3F0;
        Frm.ClientWidth := 640;
        Frm.ClientHeight := 392;

        Pnl := TPanel.Create(Frm);
        Pnl.Parent := Frm;
        Pnl.SetBounds(0, 0, 640, 66);
        Pnl.BevelOuter := bvNone;
        Pnl.ParentBackground := False;
        Pnl.Color := $00633A1E;

        LblTit := TLabel.Create(Pnl);
        LblTit.Parent := Pnl;
        LblTit.SetBounds(16, 8, 608, 24);
        LblTit.AutoSize := False;
        LblTit.Font.Name := 'Segoe UI';
        LblTit.Font.Size := 13;
        LblTit.Font.Style := [fsBold];
        LblTit.Font.Color := clWhite;
        LblTit.Caption := FormatDateTime('dddd, dd/mm/yyyy', ADia) + '  •  ' + cmbEspelhoColab.Text;

        LblInfo := TLabel.Create(Pnl);
        LblInfo.Parent := Pnl;
        LblInfo.SetBounds(16, 36, 608, 20);
        LblInfo.AutoSize := False;
        LblInfo.Font.Name := 'Segoe UI';
        LblInfo.Font.Size := 9;
        LblInfo.Font.Color := $00F0D9C4;
        if TemInfo then
          LblInfo.Caption := Format('Previsto %s   •   Realizado %s   •   Saldo do dia %s%s',
            [DiaInfo.CargaPrevistaStr, DiaInfo.TrabalhadoStr, DiaInfo.SaldoStr,
             SeTexto(DiaInfo.Ocorrencia <> '', '   •   ' + DiaInfo.Ocorrencia, '')])
        else
          LblInfo.Caption := 'Dia sem apuração';

        Lst := TListView.Create(Frm);
        Lst.Parent := Frm;
        Lst.SetBounds(12, 78, 616, 190);
        Lst.ViewStyle := vsReport;
        Lst.ReadOnly := True;
        Lst.RowSelect := True;
        Lst.GridLines := True;
        Lst.HideSelection := False;
        Lst.Font.Name := 'Segoe UI';
        Lst.Font.Size := 10;
        Lst.OnCustomDrawItem := LvDiaCustomDrawItem;
        Col := Lst.Columns.Add; Col.Caption := 'Hora'; Col.Width := 100;
        Col := Lst.Columns.Add; Col.Caption := 'Tipo'; Col.Width := 60;
        Col := Lst.Columns.Add; Col.Caption := 'Origem'; Col.Width := 100;
        Col := Lst.Columns.Add; Col.Caption := 'Situação / Motivo'; Col.Width := 330;

        Qry := dmDados.GetMarcacoes(ADia, ADia, 0, PessoaId, False);
        try
          // a consulta vem em ordem decrescente: insere no início para exibir em ordem cronológica
          while not Qry.Eof do
          begin
            Desc := Qry.FieldByName('PMA_DESCONSIDERADA').AsString = 'S';
            Origem := UpperCase(Trim(Qry.FieldByName('PMA_ORIGEM').AsString));
            if Origem = 'M' then Origem := 'Manual'
            else if Origem = 'C' then Origem := 'Relógio'
            else if Origem = 'B' then Origem := 'Biometria';
            Situacao := SeTexto(Desc, 'Desconsiderada: ' + Qry.FieldByName('PMA_MOTIVO_DESCONSIDERACAO').AsString, 'Válida');
            Item := Lst.Items.Insert(0);
            Item.Caption := FormatDateTime('hh:nn:ss', Qry.FieldByName('PMA_DATA_HORA').AsDateTime);
            Item.SubItems.Add(Trim(Qry.FieldByName('PMA_TIPO_BATIDA').AsString));
            Item.SubItems.Add(Origem);
            Item.SubItems.Add(Situacao);
            if Desc then
              Item.Data := Pointer(1);
            Ids.Insert(0, IntToStr(Qry.FieldByName('PMA_ID').AsInteger));
            Flags.Insert(0, SeTexto(Desc, 'S', 'N'));
            Tipos.Insert(0, Trim(Qry.FieldByName('PMA_TIPO_BATIDA').AsString));
            Qry.Next;
          end;
        finally
          Qry.Free;
        end;
        if Lst.Items.Count > 0 then
          Lst.ItemIndex := 0
        else
        begin
          Item := Lst.Items.Add;
          Item.Caption := 'Nenhuma batida neste dia. Use "Incluir".';
        end;

        // Ajustes do dia: valem para este colaborador nesta data
        dmDados.LerAjusteDia(PessoaId, ADia, SemExtra0, Feriado0);
        ChkSemExtra := TCheckBox.Create(Frm);
        ChkSemExtra.Parent := Frm;
        ChkSemExtra.SetBounds(14, 274, 612, 20);
        ChkSemExtra.Caption := 'Não contar hora extra neste dia (o que passar do horário não entra no saldo)';
        ChkSemExtra.Checked := SemExtra0;
        ChkFeriado := TCheckBox.Create(Frm);
        ChkFeriado.Parent := Frm;
        ChkFeriado.SetBounds(14, 298, 612, 20);
        ChkFeriado.Caption := 'Este dia é feriado (zera previsto e faltas; horas trabalhadas contam 100%)';
        ChkFeriado.Checked := Feriado0;

        NovoBotao('✏️ Corrigir', 12, mrOk);
        NovoBotao('🚫 Desconsiderar / Restaurar', 132, mrIgnore).Width := 200;
        NovoBotao('➕ Incluir', 340, mrRetry);
        NovoBotao('Fechar', 516, mrCancel);

        Sel := -1;
        Res := Frm.ShowModal;
        // Opções do dia: grava se mudou, em qualquer botão que tenha fechado a tela
        if (ChkSemExtra.Checked <> SemExtra0) or (ChkFeriado.Checked <> Feriado0) then
        begin
          if dmDados.SalvarAjusteDia(PessoaId, ADia, ChkSemExtra.Checked, ChkFeriado.Checked) then
          begin
            LogMessage(Format('🗓️ Ajuste do dia %s - %s: sem hora extra = %s; feriado = %s.',
              [FormatDateTime('dd/mm/yyyy', ADia), cmbEspelhoColab.Text,
               SeTexto(ChkSemExtra.Checked, 'sim', 'não'), SeTexto(ChkFeriado.Checked, 'sim', 'não')]));
            Alterou := True;
          end
          else
            ShowMessage('Não foi possível salvar o ajuste do dia: ' + dmDados.LastError);
        end;
        case Res of
          mrOk, mrIgnore:
            begin
              Sel := Lst.ItemIndex;
              if (Sel < 0) or (Sel >= Ids.Count) then
              begin
                ShowMessage('Selecione uma batida na lista.');
                Sel := -1;
              end;
            end;
          mrRetry: ;
        else
          Continua := False;
        end;
        // o formulário só fecha depois de ler a seleção; as ações abaixo usam os valores já copiados
        if Continua then
        begin
          if Sel >= 0 then
          begin
            Id := StrToInt(Ids[Sel]);
            Desc := Flags[Sel] = 'S';
            if Res = mrOk then
            begin
              if Desc then
                ShowMessage('Esta batida já está desconsiderada. Inclua uma nova batida.')
              else
              begin
                Qry := dmDados.GetMarcacoes(ADia, ADia, 0, PessoaId, True);
                try
                  Dh := ADia;
                  while not Qry.Eof do
                  begin
                    if Qry.FieldByName('PMA_ID').AsInteger = Id then
                      Dh := Qry.FieldByName('PMA_DATA_HORA').AsDateTime;
                    Qry.Next;
                  end;
                finally
                  Qry.Free;
                end;
                if CorrigirBatidaExistente(Id, Dh, Tipos[Sel]) then
                  Alterou := True;
              end;
            end
            else if Desc then
            begin
              if MessageDlg(Format('Voltar a considerar a batida #%d?', [Id]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
                if dmDados.RestaurarMarcacao(Id) then
                begin
                  LogMessage(Format('↩️ Batida #%d voltou a ser considerada - %s.', [Id, cmbEspelhoColab.Text]));
                  Alterou := True;
                end;
            end
            else
            begin
              SetLength(Valores, 1);
              Valores[0] := 'Batida em duplicidade';
              if DialogoCampos('Desconsiderar batida', Format('Batida #%d  •  %s', [Id, cmbEspelhoColab.Text]),
                   ['Motivo (obrigatório pela Portaria 671 - a batida original fica guardada):'], Valores, $003030C5) then
              begin
                Motivo := Trim(Valores[0]);
                if Length(Motivo) < 5 then
                  ShowMessage('Informe o motivo com pelo menos 5 caracteres.')
                else if dmDados.DesconsiderarMarcacao(Id, Motivo) then
                begin
                  LogMessage(Format('🚫 Batida #%d desconsiderada - %s. Motivo: %s', [Id, cmbEspelhoColab.Text, Motivo]));
                  Alterou := True;
                end;
              end;
            end;
          end
          else if Res = mrRetry then
            if IncluirBatidaEspelho(ADia) then
              Alterou := True;
        end;
      finally
        Frm.Free;
      end;
    end;
  finally
    Ids.Free;
    Flags.Free;
    Tipos.Free;
  end;

  if Alterou then
    btnCalcularEspelhoClick(nil);
end;

// Inclusão de batida manual; a data sugerida é a do dia selecionado
function TfrmMain.IncluirBatidaEspelho(ADia: TDateTime): Boolean;
var
  Idx, ColabId: Integer;
  Prompts, Values: array of string;
  TipoStr, MotivoStr: string;
  DataHoraBat: TDateTime;
  NovoId: Integer;
begin
  Result := False;
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
  Values[0] := FormatDateTime('dd/mm/yyyy', ADia);

  Prompts[1] := 'Hora da Batida (HH:MM:SS):';
  Values[1] := '08:00:00';

  Prompts[2] := 'Tipo de Batida (E = Entrada, S = Saída):';
  Values[2] := 'E';

  Prompts[3] := 'Motivo da Inclusão/Correção (Portaria 671):';
  Values[3] := 'Esquecimento de registro';

  if not DialogoCampos('Incluir batida', cmbEspelhoColab.Text, Prompts, Values, $00137333) then
    Exit;

  MotivoStr := Trim(Values[3]);
  if not ValidarEntradaBatida(Values[0], Values[1], Values[2], DataHoraBat, TipoStr) then
    Exit;
  if Length(MotivoStr) < 5 then
  begin
    ShowMessage('Informe o motivo da inclusão (mínimo 5 caracteres).');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    NovoId := dmDados.InserirMarcacaoManual(ColabId, ObterRelogioAtivoId, DataHoraBat, TipoStr, MotivoStr);
    if NovoId > 0 then
    begin
      LogMessage(Format('➕ Batida incluída no espelho ID %d para %s (%s) - %s',
        [NovoId, FormatDateTime('dd/mm/yyyy hh:nn:ss', DataHoraBat), TipoStr, cmbEspelhoColab.Text]));
      Result := True;
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
    ShowMessage('Por favor, clique em "Recalcular" antes de exportar ou visualizar o espelho.');
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
  Lista: TArray<TDiaEspelho>;
  Dia: TDiaEspelho;
  TemDia, Hoje: Boolean;
  Fundo, CorTxt: TColor;
  Estilo: TFontStyles;
  Flags: Cardinal;
begin
  // Desenho 100% próprio (DefaultDrawing = False): pincel sólido para apagar a célula antes do texto
  grdEspelho.Canvas.Brush.Style := bsSolid;
  SetBkMode(grdEspelho.Canvas.Handle, TRANSPARENT);
  grdEspelho.Canvas.Font.Name := 'Segoe UI';
  grdEspelho.Canvas.Font.Size := 9;
  Texto := grdEspelho.Cells[ACol, ARow];

  if (ARow = 0) then
  begin
    grdEspelho.Canvas.Brush.Color := $00633A1E; // azul-marinho
    grdEspelho.Canvas.Font.Color := clWhite;
    grdEspelho.Canvas.Font.Style := [fsBold];
    grdEspelho.Canvas.FillRect(Rect);
    TxtRect := Rect;
    InflateRect(TxtRect, -4, 0);
    DrawText(grdEspelho.Canvas.Handle, PChar(Texto), -1, TxtRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
    Exit;
  end;

  // Dia desta linha (para colorir pelo tipo: feriado, folga, falta, marcação ímpar...)
  TemDia := False;
  Hoje := False;
  if FUltimoEspelho <> nil then
  begin
    Lista := FUltimoEspelho.Dias;
    if (ARow - 1 >= 0) and (ARow - 1 <= High(Lista)) then
    begin
      Dia := Lista[ARow - 1];
      TemDia := True;
      Hoje := Trunc(Dia.Data) = Trunc(Date);
    end;
  end;

  if ARow mod 2 = 0 then
    Fundo := $00FBFBFB
  else
    Fundo := clWhite;
  CorTxt := $00333333;
  Estilo := [];

  if TemDia then
  begin
    if Dia.DsrDescontado then
      Fundo := $00ECECFE            // vermelho claro: DSR/feriado perdido
    else if Dia.FaltaDiaInteiro then
      Fundo := $00E2E2FE            // vermelho: falta
    else if Dia.TipoDia = tdFeriado then
      Fundo := $00FFF3E8            // azul claro: feriado
    else if Dia.TipoDia in [tdDomingoDSR, tdSabadoCompensado, tdFolga] then
    begin
      Fundo := $00F6F4F3;           // cinza: folga / DSR
      CorTxt := $00808080;
    end
    else if Dia.Impar then
      Fundo := $00D6F6FF            // amarelo: marcação ímpar
    else if Hoje then
      Fundo := $00E6FBFF;           // hoje
  end;

  // Cor do texto por coluna
  if (ACol >= 2) and (ACol <= 5) and (Texto = '00:00') then
  begin
    CorTxt := $000677D9;            // batida à meia-noite: costuma ser lançamento errado
    Estilo := [fsBold];
  end
  else if ((ACol = 7) or (ACol = 8) or (ACol = 9) or (ACol = 12)) and (Texto = '00:00') then
    CorTxt := $00BDBDBD             // zero fica discreto
  else if ACol = 9 then
  begin
    if Texto <> '' then begin CorTxt := $002E7D32; Estilo := [fsBold]; end;
  end
  else if ACol = 10 then
  begin
    if Texto <> '' then begin CorTxt := $00B03A7B; Estilo := [fsBold]; end;   // roxo: noturno
  end
  else if ACol = 11 then
  begin
    if Texto <> '' then begin CorTxt := $000677D9; Estilo := [fsBold]; end;   // laranja: intervalo
  end
  else if ACol = 12 then
  begin
    if Texto <> '' then begin CorTxt := $003030C5; Estilo := [fsBold]; end;
  end
  else if ACol = 13 then
  begin
    if Pos('+', Texto) > 0 then
    begin
      CorTxt := $002E7D32;
      Estilo := [fsBold];
    end
    else if Pos('-', Texto) > 0 then
    begin
      CorTxt := $003030C5;
      Estilo := [fsBold];
    end
    else if Texto = '00:00' then
      CorTxt := $00BDBDBD;
  end
  else if ACol = 14 then
  begin
    if (Pos('Falta', Texto) > 0) or (Pos('descontado', Texto) > 0) then
    begin
      CorTxt := $003030C5;
      Estilo := [fsBold];
    end
    else if (Pos('Ímpar', Texto) > 0) or (Pos('Impar', Texto) > 0) or (Pos('Interjornada', Texto) > 0) or
            (Pos('Extra acima', Texto) > 0) or (Pos('Intervalo de', Texto) > 0) then
    begin
      CorTxt := $000677D9;
      Estilo := [fsBold];
    end
    else if Pos('Feriado', Texto) > 0 then
    begin
      CorTxt := $00D84E1D;          // azul
      Estilo := [fsBold];
    end;
  end
  else if (ACol = 0) and Hoje then
    Estilo := [fsBold];

  if gdSelected in State then
  begin
    Fundo := $00FAE8D6;             // azul claro de seleção
    Estilo := Estilo + [fsBold];
  end;

  grdEspelho.Canvas.Brush.Color := Fundo;
  grdEspelho.Canvas.FillRect(Rect);
  // linha divisória suave
  grdEspelho.Canvas.Pen.Color := $00EAEAEA;
  grdEspelho.Canvas.MoveTo(Rect.Left, Rect.Bottom - 1);
  grdEspelho.Canvas.LineTo(Rect.Right, Rect.Bottom - 1);

  grdEspelho.Canvas.Font.Color := CorTxt;
  grdEspelho.Canvas.Font.Style := Estilo;
  TxtRect := Rect;
  InflateRect(TxtRect, -5, 0);
  if ACol >= 14 then
    Flags := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS
  else
    Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE;
  DrawText(grdEspelho.Canvas.Handle, PChar(Texto), -1, TxtRect, Flags);
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

  // Log do Dashboard
  btnClearLog.Anchors := [akTop, akRight];
  btnSaveLog.Anchors := [akTop, akRight];
  btnClearLog.SetBounds(pnlLogHeader.ClientWidth - 305, 5, 140, 35);
  btnSaveLog.SetBounds(pnlLogHeader.ClientWidth - 155, 5, 145, 35);
  skClearLog := CriarBtn(btnClearLog, '🧹 Limpar Log', sbkDark, 8, 11, 15);
  skSaveLog := CriarBtn(btnSaveLog, '💾 Salvar Log', sbkSuccess, 8, 11, 15);
  skClearLog.Anchors := [akTop, akRight];
  skSaveLog.Anchors := [akTop, akRight];

  // Aba Relógios
  btnNovoRelogio.SetBounds(10, 6, 155, 38);
  btnAtualizarRelogios.SetBounds(175, 6, 130, 38);
  skNovoRelogio := CriarBtn(btnNovoRelogio, '➕ Novo Relógio', sbkSuccess, 8, 11, 16);
  skAtualizarRelogios := CriarBtn(btnAtualizarRelogios, '🔄 Atualizar', sbkPrimary, 8, 11, 16);

  btnSalvarRelogio.SetBounds(0, 4, 130, 36);
  btnExcluirRelogio.SetBounds(140, 4, 125, 36);
  btnTestarEsteRelogio.SetBounds(275, 4, 140, 36);
  btnSincHoraEste.SetBounds(0, 46, 185, 36);
  btnColetarEste.SetBounds(195, 46, 220, 36);

  skSalvarRelogio := CriarBtn(btnSalvarRelogio, '💾 Salvar', sbkSuccess, 8, 11, 16);
  skExcluirRelogio := CriarBtn(btnExcluirRelogio, '🗑️ Excluir', sbkDanger, 8, 11, 16);
  skTestarEsteRelogio := CriarBtn(btnTestarEsteRelogio, '⚡ Testar', sbkPrimary, 8, 11, 16);
  skSincHoraEste := CriarBtn(btnSincHoraEste, '🕒 Sincronizar Hora', sbkTeal, 8, 11, 16);
  skColetarEste := CriarBtn(btnColetarEste, '📥 Coletar Marcações', sbkSuccess, 8, 11, 16);

  // Aba Colaboradores - Barra superior da grid
  btnAtualizarColab.SetBounds(225, 8, 110, 38);
  btnEnviarTodosPendentes.SetBounds(345, 8, 165, 38);
  btnImportarDoRelogio.SetBounds(520, 8, 135, 38);
  btnLimparTodosRelogio.SetBounds(665, 8, 155, 38);
  btnEnviarColabRelogio.Visible := False;
  btnRemoverColabRelogio.Visible := False;

  skAtualizarColab := CriarBtn(btnAtualizarColab, '🔄 Atualizar', sbkPrimary, 8, 11, 16);
  skEnviarTodosPendentes := CriarBtn(btnEnviarTodosPendentes, '🚀 Enviar Pendentes', sbkWarning, 8, 11, 16);
  skImportarDoRelogio := CriarBtn(btnImportarDoRelogio, '📥 No Relógio', sbkPurple, 8, 11, 16);
  skLimparTodosRelogio := CriarBtn(btnLimparTodosRelogio, '⚠️ Limpar Relógio', sbkDanger, 8, 11, 16);

  // Aba Colaboradores - Formulário de Edição e Ações
  btnSalvarColab.SetBounds(0, 4, 95, 36);
  btnSalvarEnviarColab.SetBounds(105, 4, 215, 36);
  btnNovoColab.SetBounds(330, 4, 95, 36);
  btnRemoverColabForm.SetBounds(0, 46, 205, 36);
  btnExcluirColabBanco.SetBounds(215, 46, 210, 36);

  skSalvarColab := CriarBtn(btnSalvarColab, '💾 Salvar', sbkPrimary, 8, 11, 16);
  skSalvarEnviarColab := CriarBtn(btnSalvarEnviarColab, '📤 Salvar e Enviar ao Ponto', sbkSuccess, 8, 11, 16);
  skNovoColab := CriarBtn(btnNovoColab, '➕ Novo', sbkDark, 8, 11, 16);
  skRemoverColabForm := CriarBtn(btnRemoverColabForm, '❌ Remover do Relógio', sbkDanger, 8, 11, 16);
  skExcluirColabBanco := CriarBtn(btnExcluirColabBanco, '🗑️ Excluir do Banco', sbkDanger, 8, 11, 16);

  // Aba Marcações
  btnFiltrarMarcacoes.SetBounds(490, 16, 110, 38);
  btnEditarMarcacao.SetBounds(608, 16, 125, 38);
  btnNovaMarcacao.SetBounds(739, 16, 125, 38);
  btnExportarAFD.SetBounds(870, 16, 130, 38);
  btnExcluirMarcacao.SetBounds(1006, 16, 193, 38);   // termina antes do Relatório E/S (1205)
  lblTotalMarcacoesGrid.Anchors := [akTop, akRight];
  lblTotalMarcacoesGrid.Left := pnlMarcacoesFiltro.ClientWidth - 170;
  lblTotalMarcacoesGrid.Top := 26;
  skFiltrarMarcacoes := CriarBtn(btnFiltrarMarcacoes, '🔍 Filtrar', sbkPrimary, 8, 11, 16);
  skEditarMarcacao := CriarBtn(btnEditarMarcacao, '✏️ Corrigir Batida', sbkWarning, 8, 11, 16);
  skNovaMarcacao := CriarBtn(btnNovaMarcacao, '➕ Incluir Batida', sbkSuccess, 8, 11, 16);
  skExportarAFD := CriarBtn(btnExportarAFD, '📄 Exportar AFD', sbkPurple, 8, 11, 16);
  skExcluirMarcacao := CriarBtn(btnExcluirMarcacao, '🚫 Desconsiderar/Restaurar', sbkDanger, 8, 10, 15);

  // Portaria 671: batidas desconsideradas ficam guardadas; por padrão só as válidas aparecem
  pnlMarcacoesFiltro.Height := 90;
  chkVerDesconsideradas := TCheckBox.Create(Self);
  chkVerDesconsideradas.Parent := pnlMarcacoesFiltro;
  chkVerDesconsideradas.SetBounds(12, 66, 260, 20);
  chkVerDesconsideradas.Caption := 'Mostrar batidas desconsideradas';
  chkVerDesconsideradas.OnClick := chkVerDesconsideradasClick;

  // Aba Configurações (Geral e Conexão) - 4 botões perfeitamente alinhados e espaçados
  btnSalvarConfig.SetBounds(30, 465, 210, 44);
  btnTestarConexaoFB.SetBounds(255, 465, 185, 44);
  btnIrParaVersoes.SetBounds(455, 465, 230, 44);
  btnConfigVoltar.SetBounds(700, 465, 185, 44);

  skSalvarConfig := CriarBtn(btnSalvarConfig, '💾 Salvar Configurações', sbkSuccess, 10, 11, 17);
  skTestarConexaoFB := CriarBtn(btnTestarConexaoFB, '🔌 Testar Firebird', sbkPrimary, 10, 11, 17);
  skIrParaVersoes := CriarBtn(btnIrParaVersoes, '📋 Controle de Versão (Log)', sbkDark, 10, 11, 17);
  skConfigVoltar := CriarBtn(btnConfigVoltar, '⬅️ Voltar ao Sistema', sbkPurple, 10, 11, 17);

  // Dados do Empregador
  btnCarregarEmpBanco.SetBounds(20, 295, 215, 40);
  btnSalvarEmpBanco.SetBounds(255, 295, 215, 40);
  btnEnviarEmpRelogio.SetBounds(20, 345, 215, 40);
  btnLerEmpRelogio.SetBounds(255, 345, 215, 40);
  skCarregarEmpBanco := CriarBtn(btnCarregarEmpBanco, '📥 Carregar do Banco', sbkPrimary, 8, 11, 16);
  skSalvarEmpBanco := CriarBtn(btnSalvarEmpBanco, '💾 Salvar no Banco', sbkSuccess, 8, 11, 16);
  skEnviarEmpRelogio := CriarBtn(btnEnviarEmpRelogio, '🏢 Enviar ao Relógio', sbkWarning, 8, 11, 16);
  skLerEmpRelogio := CriarBtn(btnLerEmpRelogio, '📖 Ler do Relógio', sbkPurple, 8, 11, 16);

  // Aba Controle de Versão (Rodapé)
  btnVersaoAtualizar.SetBounds(16, 8, 165, 38);
  btnVersaoSair.SetBounds(pnlVersaoFooter.ClientWidth - 145, 8, 125, 38);
  btnVersaoSair.Anchors := [akTop, akRight];
  skVersaoAtualizar := CriarBtn(btnVersaoAtualizar, '🔄 Atualizar [F4]', sbkPrimary, 8, 11, 16);
  skVersaoSair := CriarBtn(btnVersaoSair, '🚪 Sair [ESC]', sbkDark, 8, 11, 16);
  skVersaoSair.Anchors := [akTop, akRight];

  // Aba Horários & Jornadas
  btnNovoHorario.SetBounds(12, 6, 145, 34);
  btnAtualizarHorarios.SetBounds(165, 6, 120, 34);
  skNovoHorario := CriarBtn(btnNovoHorario, '➕ Novo Horário', sbkSuccess, 8, 11, 15);
  skAtualizarHorarios := CriarBtn(btnAtualizarHorarios, '🔄 Atualizar', sbkPrimary, 8, 11, 15);

  btnSalvarHorario.SetBounds(0, 4, 110, 36);
  btnSalvarEnviarHorario.SetBounds(118, 4, 205, 36);
  btnNovoHorarioForm.SetBounds(330, 4, 100, 36);
  btnExcluirHorario.SetBounds(0, 45, 140, 36);
  skSalvarHorario := CriarBtn(btnSalvarHorario, '💾 Salvar', sbkPrimary, 8, 11, 15);
  skSalvarEnviarHorario := CriarBtn(btnSalvarEnviarHorario, '📤 Salvar e Atualizar Ponto', sbkSuccess, 8, 11, 15);
  skNovoHorarioForm := CriarBtn(btnNovoHorarioForm, '✨ Novo', sbkDark, 8, 11, 15);
  skExcluirHorario := CriarBtn(btnExcluirHorario, '🗑️ Excluir', sbkDanger, 8, 11, 15);

  // Aba Espelho de Ponto
  btnCalcularEspelho.SetBounds(515, 16, 125, 38);
  btnLancarJustificativa.SetBounds(648, 16, 170, 38);
  btnExportarEspelhoHTML.SetBounds(826, 16, 185, 38);
  // Linha 1: colaborador, período, recalcular, ocorrência e impressão. Linha 2: batidas, saldo, afastamentos, feriados e resumo.
  pnlEspelhoTop.Height := 112;
  btnCorrigirBatidaEspelho.SetBounds(12, 62, 120, 38);
  btnIncluirBatidaEspelho.SetBounds(140, 62, 120, 38);
  btnSaldoAnterior.SetBounds(268, 62, 160, 38);
  FBtnAfastamentos := TButton.Create(Self);
  FBtnAfastamentos.Parent := pnlEspelhoTop;
  FBtnAfastamentos.SetBounds(436, 62, 160, 38);
  FBtnAfastamentos.OnClick := btnAfastamentosClick;
  FBtnFeriados := TButton.Create(Self);
  FBtnFeriados.Parent := pnlEspelhoTop;
  FBtnFeriados.SetBounds(604, 62, 130, 38);
  FBtnFeriados.OnClick := btnFeriadosClick;
  FBtnResumoGeral := TButton.Create(Self);
  FBtnResumoGeral.Parent := pnlEspelhoTop;
  FBtnResumoGeral.SetBounds(742, 62, 170, 38);
  FBtnResumoGeral.OnClick := btnResumoGeralClick;
  FBtnMesAnt := TButton.Create(Self);
  FBtnMesAnt.Parent := pnlEspelhoTop;
  FBtnMesAnt.SetBounds(920, 62, 140, 38);
  FBtnMesAnt.OnClick := btnMesAnteriorClick;
  FBtnMesProx := TButton.Create(Self);
  FBtnMesProx.Parent := pnlEspelhoTop;
  FBtnMesProx.SetBounds(1068, 62, 140, 38);
  FBtnMesProx.OnClick := btnMesSeguinteClick;
  skCalcularEspelho := CriarBtn(btnCalcularEspelho, '🔄 Recalcular', sbkPrimary, 8, 11, 16);
  skLancarJustificativa := CriarBtn(btnLancarJustificativa, '📝 Lançar Ocorrência', sbkPurple, 8, 11, 16);
  skExportarEspelhoHTML := CriarBtn(btnExportarEspelhoHTML, '🖨️ Imprimir / Relatório', sbkSuccess, 8, 11, 16);
  skCorrigirBatidaEspelho := CriarBtn(btnCorrigirBatidaEspelho, '✏️ Corrigir', sbkWarning, 8, 11, 16);
  skIncluirBatidaEspelho := CriarBtn(btnIncluirBatidaEspelho, '➕ Incluir', sbkSuccess, 8, 11, 16);
  skSaldoAnterior := CriarBtn(btnSaldoAnterior, '🏦 Saldo anterior', sbkTeal, 8, 11, 16);
  skAfastamentos := CriarBtn(FBtnAfastamentos, '🏖️ Afastamentos', sbkPurple, 8, 11, 16);
  skFeriados := CriarBtn(FBtnFeriados, '📅 Feriados', sbkPrimary, 8, 11, 16);
  skResumoGeral := CriarBtn(FBtnResumoGeral, '📊 Resumo geral', sbkSuccess, 8, 11, 16);
  skMesAnt := CriarBtn(FBtnMesAnt, '◀ Mês anterior', sbkDark, 8, 11, 16);
  skMesProx := CriarBtn(FBtnMesProx, 'Mês seguinte ▶', sbkDark, 8, 11, 16);
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
  if Assigned(FUltimoEspelho) and (pgcMain.ActivePage = tabEspelho) then
    AjustarColunasEspelho;

  // Evita que o total de marcações fique por cima do botão de relatório em telas estreitas
  if Assigned(skRelatorioES) then
  begin
    if lblTotalMarcacoesGrid.Left < skRelatorioES.Left + skRelatorioES.Width + 10 then
      lblTotalMarcacoesGrid.Top := 1
    else
      lblTotalMarcacoesGrid.Top := 26;
  end;
end;

// =============================================================================
// INTEGRAÇÕES DE RELÓGIO (Control iD / Leitor Biométrico Hamster DX)
// =============================================================================

procedure TfrmMain.CriarControlesIntegracao;

  function NovoLabel(AParent: TWinControl; X, Y: Integer; const ACaption: string): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(X, Y, 300, 15);
    Result.Font.Style := [];
    Result.Caption := ACaption;
  end;

  function NovoBtn(AParent: TWinControl; X, Y, W, H: Integer; const ACaption: string;
    AKind: TSkButtonKind; AOnClick: TNotifyEvent): TSkModernButton;
  begin
    Result := TSkModernButton.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(X, Y, W, H);
    Result.Caption := ACaption;
    Result.Kind := AKind;
    Result.Radius := 8;
    Result.FontSize := 11;
    Result.EmojiSize := 16;
    Result.OnClick := AOnClick;
  end;

  function NovoGrupo(AParent: TWinControl; X, Y, W, H: Integer; const ACaption: string): TGroupBox;
  begin
    Result := TGroupBox.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(X, Y, W, H);
    Result.Caption := ACaption;
    Result.Font.Name := 'Segoe UI';
    Result.Font.Height := -12;
    Result.Font.Style := [fsBold];
  end;

var
  I: Integer;
  Lbl: TLabel;
begin
  // ===== Configurações > Relógio de Ponto =====
  tabCfgRelogio := TTabSheet.Create(Self);
  tabCfgRelogio.PageControl := pgcConfig;
  tabCfgRelogio.Caption := '  Relógio de Ponto  ';
  tabCfgRelogio.PageIndex := 1;

  grpCfgRelogio := NovoGrupo(tabCfgRelogio, 30, 20, 600, 160, ' Integração de Relógio de Ponto ');
  NovoLabel(grpCfgRelogio, 20, 32, 'Relógio / leitor utilizado nesta instalação:');
  cmbCfgTipoRelogio := TComboBox.Create(Self);
  cmbCfgTipoRelogio.Parent := grpCfgRelogio;
  cmbCfgTipoRelogio.Style := csDropDownList;
  cmbCfgTipoRelogio.Font.Style := [];
  cmbCfgTipoRelogio.SetBounds(20, 52, 560, 23);
  cmbCfgTipoRelogio.Items.Add(TipoRelogioDescricao(trControlID));
  cmbCfgTipoRelogio.Items.Add(TipoRelogioDescricao(trHamsterDX));
  cmbCfgTipoRelogio.ItemIndex := 0;
  cmbCfgTipoRelogio.OnChange := cmbCfgTipoRelogioChange;

  lblCfgTipoInfo := NovoLabel(grpCfgRelogio, 20, 86, '');
  lblCfgTipoInfo.AutoSize := False;
  lblCfgTipoInfo.WordWrap := True;
  lblCfgTipoInfo.SetBounds(20, 86, 560, 64);
  lblCfgTipoInfo.Font.Color := clGray;

  grpCfgHamster := NovoGrupo(tabCfgRelogio, 30, 195, 600, 260, ' Leitor Biométrico Hamster DX (Nitgen) ');
  NovoLabel(grpCfgHamster, 20, 32, 'Nível de segurança da identificação:');
  cmbCfgNivelSeguranca := TComboBox.Create(Self);
  cmbCfgNivelSeguranca.Parent := grpCfgHamster;
  cmbCfgNivelSeguranca.Style := csDropDownList;
  cmbCfgNivelSeguranca.Font.Style := [];
  cmbCfgNivelSeguranca.SetBounds(20, 52, 260, 23);
  for I := 1 to 9 do
  begin
    case I of
      1: cmbCfgNivelSeguranca.Items.Add('1 - Mais tolerante');
      5: cmbCfgNivelSeguranca.Items.Add('5 - Padrão (recomendado)');
      9: cmbCfgNivelSeguranca.Items.Add('9 - Mais rigoroso');
    else
      cmbCfgNivelSeguranca.Items.Add(IntToStr(I));
    end;
  end;
  cmbCfgNivelSeguranca.ItemIndex := 4;

  NovoLabel(grpCfgHamster, 300, 32, 'Intervalo mínimo entre batidas (minutos):');
  edtCfgIntervaloBatida := TEdit.Create(Self);
  edtCfgIntervaloBatida.Parent := grpCfgHamster;
  edtCfgIntervaloBatida.Font.Style := [];
  edtCfgIntervaloBatida.NumbersOnly := True;
  edtCfgIntervaloBatida.SetBounds(300, 52, 120, 23);

  chkCfgAbrirTerminal := TCheckBox.Create(Self);
  chkCfgAbrirTerminal.Parent := grpCfgHamster;
  chkCfgAbrirTerminal.Font.Style := [];
  chkCfgAbrirTerminal.SetBounds(20, 90, 560, 19);
  chkCfgAbrirTerminal.Caption := 'Abrir o Terminal de Ponto automaticamente ao iniciar o sistema';

  lblCfgHamsterReq := NovoLabel(grpCfgHamster, 20, 128, '');
  lblCfgHamsterReq.AutoSize := False;
  lblCfgHamsterReq.SetBounds(20, 128, 370, 20);
  lblCfgHamsterReq.Font.Style := [fsBold];
  skCfgInstalarHamster := NovoBtn(grpCfgHamster, 400, 118, 180, 36, '🛠️ Instalar Driver e SDK',
    sbkWarning, skCfgInstalarHamsterClick);
  skCfgInstalarHamster.Visible := False;

  Lbl := NovoLabel(grpCfgHamster, 20, 168, '');
  Lbl.AutoSize := False;
  Lbl.WordWrap := True;
  Lbl.SetBounds(20, 168, 560, 80);
  Lbl.Font.Color := clGray;
  Lbl.Caption :=
    'Requisitos: driver do Hamster DX e SDK Nitgen eNBSP (NBioBSP) instalados neste computador. ' +
    'O leitor é usado somente para leitura: cadastre a digital de cada colaborador na aba Colaboradores ' +
    'e registre Entrada/Saída pelo botão "Terminal de Ponto". O intervalo mínimo evita batidas duplicadas ' +
    'quando o colaborador encosta o dedo duas vezes seguidas.';

  skCfgSalvarRelogio := NovoBtn(tabCfgRelogio, 30, 475, 210, 44, '💾 Salvar Configurações', sbkSuccess, btnSalvarConfigClick);
  skCfgSalvarRelogio.Radius := 10;
  skCfgSalvarRelogio.EmojiSize := 17;
  skCfgTestarLeitor := NovoBtn(tabCfgRelogio, 255, 475, 210, 44, '⚡ Testar Leitor Hamster', sbkPrimary, skCfgTestarLeitorClick);
  skCfgTestarLeitor.Radius := 10;
  skCfgTestarLeitor.EmojiSize := 17;

  // ===== Colaboradores > Biometria (mesma posição do grupo de sincronização Control iD) =====
  grpBiometria := TGroupBox.Create(Self);
  grpBiometria.Parent := grpInfoSinc.Parent;
  grpBiometria.BoundsRect := grpInfoSinc.BoundsRect;
  grpBiometria.Caption := ' Biometria (Leitor Hamster DX) ';
  grpBiometria.Visible := False;

  lblBioStatus := NovoLabel(grpBiometria, 15, 22, '');
  lblBioStatus.Font.Style := [fsBold];
  lblBioData := NovoLabel(grpBiometria, 15, 44, '');
  lblBioData.AutoSize := False;
  lblBioData.Width := grpBiometria.ClientWidth - 30;
  lblBioData.Font.Color := clGray;

  skCadastrarBio := NovoBtn(grpBiometria, 15, 72, 150, 38, '👆 Cadastrar Digital', sbkSuccess, skCadastrarBioClick);
  skTestarBio := NovoBtn(grpBiometria, 173, 72, 125, 38, '🧪 Testar', sbkPrimary, skTestarBioClick);
  skRemoverBio := NovoBtn(grpBiometria, 306, 72, 124, 38, '🗑️ Remover', sbkDanger, skRemoverBioClick);

  // ===== Marcações > Relatório padrão de Entradas e Saídas =====
  skRelatorioES := NovoBtn(pnlMarcacoesFiltro, 1205, 16, 160, 38, '📋 Relatório E/S', sbkTeal, skRelatorioESClick);
  skRelatorioES.Hint := 'Relatório de Entradas e Saídas de todos os colaboradores no período filtrado';
  skRelatorioES.ShowHint := True;
end;

procedure TfrmMain.AtualizarTextoTipoRelogio;
begin
  if not Assigned(lblCfgTipoInfo) then
    Exit;
  if cmbCfgTipoRelogio.ItemIndex = Ord(trHamsterDX) then
    lblCfgTipoInfo.Caption :=
      'Leitor biométrico USB conectado a este computador, usado apenas para marcar Entrada e Saída. ' +
      'Cada colaborador precisa ter a digital cadastrada (aba Colaboradores). As batidas são gravadas ' +
      'direto no banco e aparecem em Marcações, Espelho de Ponto e no Relatório de Entradas e Saídas.'
  else
    lblCfgTipoInfo.Caption :=
      'Relógios Control iD (iDClass, iDFace, iDAccess...) conectados na rede. As marcações são ' +
      'coletadas pela API do equipamento e os colaboradores/jornadas são enviados ao relógio.';
end;

procedure TfrmMain.cmbCfgTipoRelogioChange(Sender: TObject);
begin
  AtualizarTextoTipoRelogio;
  AtualizarStatusRequisitosHamster;

  // Ao escolher o Hamster DX, verifica na hora se driver e SDK estão neste computador
  if (cmbCfgTipoRelogio.ItemIndex = Ord(trHamsterDX)) and not RequisitosHamsterOk then
  begin
    if MessageDlg('O leitor Hamster DX precisa do driver e do SDK Nitgen eNBSP instalados ' +
      'neste computador, e algum deles não foi encontrado.'#13#10#13#10 +
      lblCfgHamsterReq.Caption + #13#10#13#10 +
      'Deseja instalar agora?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      skCfgInstalarHamsterClick(nil);
  end;
end;

function TfrmMain.RequisitosHamsterOk: Boolean;
begin
  Result := THamsterDX.DriverInstalado and THamsterDX.SdkInstalado;
end;

procedure TfrmMain.AtualizarStatusRequisitosHamster;
const
  STATUS: array[Boolean] of string = ('❌ não instalado', '✅ instalado');
var
  Driver, Sdk: Boolean;
begin
  if not Assigned(lblCfgHamsterReq) then
    Exit;
  Driver := THamsterDX.DriverInstalado;
  Sdk := THamsterDX.SdkInstalado;
  lblCfgHamsterReq.Caption := 'Driver: ' + STATUS[Driver] + '     SDK eNBSP: ' + STATUS[Sdk];
  if Driver and Sdk then
    lblCfgHamsterReq.Font.Color := clGreen
  else
    lblCfgHamsterReq.Font.Color := clMaroon;
  skCfgInstalarHamster.Visible := not (Driver and Sdk);
end;

function TfrmMain.ExecutarInstaladorComoAdmin(const AArquivo, AParametros: string): Boolean;
var
  Info: TShellExecuteInfo;
begin
  // Instaladores de driver/SDK exigem administrador: abre com UAC e aguarda terminar
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_NOCLOSEPROCESS;
  Info.Wnd := Handle;
  Info.lpVerb := 'runas';
  Info.lpFile := PChar(AArquivo);
  Info.lpParameters := PChar(AParametros);
  Info.lpDirectory := PChar(ExtractFileDir(AArquivo));
  Info.nShow := SW_SHOWNORMAL;
  Result := ShellExecuteEx(@Info);
  if not Result then
  begin
    LogMessage('⚠️ Instalador não executado (' + SysErrorMessage(GetLastError) + '): ' + AArquivo, True);
    Exit;
  end;
  if Info.hProcess = 0 then
    Exit;
  try
    Screen.Cursor := crHourGlass;
    while MsgWaitForMultipleObjects(1, Info.hProcess, False, INFINITE, QS_ALLINPUT) = WAIT_OBJECT_0 + 1 do
      Application.ProcessMessages;
  finally
    Screen.Cursor := crDefault;
    CloseHandle(Info.hProcess);
  end;
end;

procedure TfrmMain.skCfgInstalarHamsterClick(Sender: TObject);
var
  Extras: TArray<string>;
  Dlg: TFileOpenDialog;
  InstDriver, InstSdk, Iss, Params, Serial: string;
  PrecisaDriver, PrecisaSdk: Boolean;
begin
  PrecisaDriver := not THamsterDX.DriverInstalado;
  PrecisaSdk := not THamsterDX.SdkInstalado;
  if not (PrecisaDriver or PrecisaSdk) then
  begin
    AtualizarStatusRequisitosHamster;
    MessageDlg('Driver e SDK do Hamster DX já estão instalados neste computador.', mtInformation, [mbOK], 0);
    Exit;
  end;

  // Pacote embarcado (Instaladores\driver + Instaladores\sdk): instala sem download nem serial
  Iss := ExtractFilePath(Application.ExeName) + 'Instaladores\instalar_hamster.bat';
  if not FileExists(Iss) then
  begin
    // Pacote não veio com o sistema: baixa da última release no GitHub
    LogMessage('⬇️ Baixando pacote de instaladores do Hamster DX (GitHub)...');
    Screen.Cursor := crHourGlass;
    try
      if not TfrmUpdate.BaixarPacoteInstaladores(ExtractFilePath(Application.ExeName), Serial) then
        LogMessage('⚠️ Não foi possível baixar os instaladores: ' + Serial, True);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
  if FileExists(Iss) then
  begin
    LogMessage('🛠️ Instalando driver e SDK do Hamster DX pelo pacote embarcado: ' + Iss);
    ExecutarInstaladorComoAdmin(GetEnvironmentVariable('ComSpec'), '/c "' + Iss + '"');
    AtualizarStatusRequisitosHamster;
    if RequisitosHamsterOk then
    begin
      LogMessage('✅ Driver e SDK do Hamster DX instalados.');
      MessageDlg('Driver e SDK do Hamster DX instalados.'#13#10#13#10 +
        'Desconecte e reconecte o leitor na USB e clique em "Testar Leitor Hamster".', mtInformation, [mbOK], 0);
      Exit;
    end;
    LogMessage('⚠️ Pacote embarcado não concluiu a instalação: ' + lblCfgHamsterReq.Caption, True);
  end;

  Extras := [];
  Screen.Cursor := crHourGlass;
  try
    if PrecisaDriver then
      InstDriver := THamsterDX.LocalizarInstaladorDriver(Extras);
    if PrecisaSdk then
      InstSdk := THamsterDX.LocalizarInstaladorSdk(Extras);
  finally
    Screen.Cursor := crDefault;
  end;

  // Não achou nas pastas padrão: pede a pasta onde estão os instaladores
  if (PrecisaDriver and (InstDriver = '')) or (PrecisaSdk and (InstSdk = '')) then
  begin
    MessageDlg('Não encontrei os instaladores na pasta "Instaladores" do sistema, na Área de Trabalho ' +
      'nem em Downloads.'#13#10#13#10 +
      'Selecione a pasta onde estão o driver (UBio_Hamster_X_Driver_Setup) e/ou o ' +
      'eNBSP SDK (eNBSP_SDK_v4.85 descompactado).', mtInformation, [mbOK], 0);
    Dlg := TFileOpenDialog.Create(Self);
    try
      Dlg.Title := 'Pasta com os instaladores do Hamster DX';
      Dlg.Options := [fdoPickFolders, fdoPathMustExist];
      if not Dlg.Execute then
        Exit;
      Extras := [Dlg.FileName];
    finally
      Dlg.Free;
    end;
    Screen.Cursor := crHourGlass;
    try
      if PrecisaDriver and (InstDriver = '') then
        InstDriver := THamsterDX.LocalizarInstaladorDriver(Extras);
      if PrecisaSdk and (InstSdk = '') then
        InstSdk := THamsterDX.LocalizarInstaladorSdk(Extras);
    finally
      Screen.Cursor := crDefault;
    end;
  end;

  if PrecisaDriver then
  begin
    if InstDriver = '' then
      MessageDlg('Instalador do driver (UBio_Hamster_X_Driver_Setup) não encontrado.', mtWarning, [mbOK], 0)
    else
    begin
      LogMessage('🛠️ Instalando driver do Hamster DX: ' + InstDriver);
      // Instalação silenciosa se o pacote trouxer o arquivo de respostas do InstallShield
      Iss := TPath.Combine(ExtractFileDir(InstDriver), 'install_UBio_Hamster_X_Driver.iss');
      if FileExists(Iss) then
        Params := '-s -f1"' + Iss + '"'
      else
        Params := '';
      ExecutarInstaladorComoAdmin(InstDriver, Params);
    end;
  end;

  if PrecisaSdk then
  begin
    if InstSdk = '' then
      MessageDlg('Instalador do SDK Nitgen eNBSP (Master CD\for 32bit\setup.exe) não encontrado.',
        mtWarning, [mbOK], 0)
    else
    begin
      Serial := THamsterDX.LerSerialSdk(InstSdk);
      if Serial <> '' then
      begin
        Clipboard.AsText := Serial;
        MessageDlg('O instalador do SDK Nitgen eNBSP vai abrir agora.'#13#10#13#10 +
          'Quando ele pedir o número de série, cole (Ctrl+V) o serial abaixo, que já foi copiado:'#13#10#13#10 +
          Serial + #13#10#13#10 +
          'Siga as telas com as opções padrão até concluir.', mtInformation, [mbOK], 0);
      end
      else
        MessageDlg('O instalador do SDK Nitgen eNBSP vai abrir agora. Informe o número de série do ' +
          'seu pacote quando solicitado e siga as telas com as opções padrão.', mtInformation, [mbOK], 0);
      LogMessage('🛠️ Instalando SDK Nitgen eNBSP: ' + InstSdk);
      ExecutarInstaladorComoAdmin(InstSdk, '');
    end;
  end;

  AtualizarStatusRequisitosHamster;
  if RequisitosHamsterOk then
  begin
    LogMessage('✅ Driver e SDK do Hamster DX instalados.');
    MessageDlg('Driver e SDK do Hamster DX instalados.'#13#10#13#10 +
      'Conecte o leitor na USB e clique em "Testar Leitor Hamster".', mtInformation, [mbOK], 0);
  end
  else
    MessageDlg('A instalação não foi concluída.'#13#10#13#10 + lblCfgHamsterReq.Caption,
      mtWarning, [mbOK], 0);
end;

procedure TfrmMain.AplicarModoRelogio;
var
  Hamster: Boolean;
begin
  Hamster := ModoHamsterDX;

  // Relógios Control iD não se aplicam ao leitor USB
  tabRelogios.TabVisible := not Hamster;
  if Hamster and (pgcMain.ActivePage = tabRelogios) then
    pgcMain.ActivePage := tabDashboard;

  // Ações rápidas do topo
  skQuickSyncTime.Visible := not Hamster;
  skQuickAuto.Visible := not Hamster;
  if Hamster then
  begin
    if tmrAutoColeta.Enabled then
    begin
      tmrAutoColeta.Enabled := False;
      skQuickAuto.Caption := '🔄 Auto: OFF';
      skQuickAuto.Kind := sbkDark;
      btnQuickAuto.Caption := 'Auto: OFF';
    end;
    skQuickTest.Caption := '⚡ Testar Leitor';
    skQuickCollect.Caption := '👆 Terminal de Ponto';
    skQuickCollect.Left := skQuickSyncTime.Left;
    lblCard1Title.Caption := 'Digitais Cadastradas';
    lblCard4Title.Caption := 'Última Batida';
    AtualizarStatusColeta('👆 Leitor Biométrico Hamster DX', True);
  end
  else
  begin
    skQuickTest.Caption := '⚡ Testar Conexão';
    skQuickCollect.Caption := '📥 Coletar Marcações';
    skQuickCollect.Left := btnQuickCollect.Left;
    lblCard1Title.Caption := 'Relógios Cadastrados';
    lblCard4Title.Caption := 'Última Coleta';
    if not tmrAutoColeta.Enabled then
      AtualizarStatusColeta('🔄 Coleta: Desativada', False);
  end;

  // Colaboradores: envio ao relógio x cadastro de digital
  skEnviarTodosPendentes.Visible := not Hamster;
  skImportarDoRelogio.Visible := not Hamster;
  skLimparTodosRelogio.Visible := not Hamster;
  skSalvarEnviarColab.Visible := not Hamster;
  skRemoverColabForm.Visible := not Hamster;
  grpInfoSinc.Visible := not Hamster;
  grpBiometria.Visible := Hamster;
  if Hamster then
  begin
    skSalvarColab.SetBounds(0, 4, 210, 36);
    skNovoColab.SetBounds(220, 4, 205, 36);
    skExcluirColabBanco.SetBounds(0, 46, 210, 36);
  end
  else
  begin
    skSalvarColab.SetBounds(0, 4, 95, 36);
    skNovoColab.SetBounds(330, 4, 95, 36);
    skExcluirColabBanco.SetBounds(215, 46, 210, 36);
  end;
  ConfigurarGridColaboradores;

  // Horários: envio da jornada ao relógio
  skSalvarEnviarHorario.Visible := not Hamster;
  if Hamster then
    skNovoHorarioForm.SetBounds(118, 4, 120, 36)
  else
    skNovoHorarioForm.SetBounds(330, 4, 100, 36);

  // Empregador: envio/leitura no relógio
  skEnviarEmpRelogio.Visible := not Hamster;
  skLerEmpRelogio.Visible := not Hamster;
  lblEmpRelogioDestino.Visible := not Hamster;
  cmbEmpRelogioDestino.Visible := not Hamster;
end;

procedure TfrmMain.AtualizarInfoBiometria(AQry: TDataSet);
var
  Fld: TField;
begin
  if not Assigned(lblBioStatus) then
    Exit;

  FColabBioCadastrada := False;
  if (AQry <> nil) and (not AQry.IsEmpty) then
  begin
    Fld := AQry.FindField('COL_BIOMETRIA_CADASTRADA');
    FColabBioCadastrada := (Fld <> nil) and SameText(Fld.AsString, 'S');
  end;

  if FColabBioCadastrada then
  begin
    lblBioStatus.Caption := '✅ Digital cadastrada';
    lblBioStatus.Font.Color := $001A8C2B;
    Fld := AQry.FindField('COL_BIOMETRIA_DATA');
    if (Fld <> nil) and not Fld.IsNull then
      lblBioData.Caption := 'Cadastrada em ' + FormatDateTime('dd/mm/yyyy hh:nn', Fld.AsDateTime)
    else
      lblBioData.Caption := '';
    skCadastrarBio.Caption := '👆 Recadastrar';
  end
  else
  begin
    lblBioStatus.Caption := '⏳ Nenhuma digital cadastrada';
    lblBioStatus.Font.Color := $00247BA0;
    if FSelectedColabId > 0 then
      lblBioData.Caption := 'Clique em "Cadastrar Digital" e siga as instruções do leitor.'
    else
      lblBioData.Caption := 'Salve o colaborador para poder cadastrar a digital.';
    skCadastrarBio.Caption := '👆 Cadastrar Digital';
  end;
  skTestarBio.Enabled := FColabBioCadastrada;
  skRemoverBio.Enabled := FColabBioCadastrada;
end;

function TfrmMain.LeitorLivreParaUso: Boolean;
begin
  Result := False;
  if TerminalPontoAberto then
  begin
    MessageDlg('O Terminal de Ponto está aberto e usando o leitor Hamster DX.'#13#10 +
      'Feche o terminal para cadastrar ou testar digitais.', mtInformation, [mbOK], 0);
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    Result := AguardarLeitorLivre;
  finally
    Screen.Cursor := crDefault;
  end;
  if not Result then
    MessageDlg('O leitor Hamster DX ainda está sendo liberado. Tente novamente em alguns segundos.',
      mtWarning, [mbOK], 0);
end;

procedure TfrmMain.skCfgTestarLeitorClick(Sender: TObject);
var
  Leitor: THamsterDX;
  Template: string;
  Ok: Boolean;
begin
  if not LeitorLivreParaUso then
    Exit;

  if not RequisitosHamsterOk then
  begin
    AtualizarStatusRequisitosHamster;
    LogMessage('⚠️ Driver/SDK do Hamster DX incompleto nesta máquina: ' + lblCfgHamsterReq.Caption, True);
    if MessageDlg('Driver ou SDK do leitor não encontrado.'#13#10#13#10 +
      lblCfgHamsterReq.Caption + #13#10#13#10 +
      'Deseja instalar agora?', mtWarning, [mbYes, mbNo], 0) = mrYes then
      skCfgInstalarHamsterClick(nil);
    if not RequisitosHamsterOk then
      Exit;
  end;

  Leitor := THamsterDX.Create;
  try
    Screen.Cursor := crHourGlass;
    try
      Ok := Leitor.Abrir;
    finally
      Screen.Cursor := crDefault;
    end;

    if not Ok then
    begin
      LogMessage('⚠️ ' + Leitor.UltimoErro, True);
      MessageDlg(Leitor.UltimoErro + #13#10#13#10 +
        'Verifique se o leitor está conectado na USB e se o driver está instalado.', mtError, [mbOK], 0);
      Exit;
    end;

    LogMessage('✅ Leitor biométrico Hamster DX conectado e pronto.');
    if MessageDlg('Leitor Hamster DX conectado e pronto!'#13#10#13#10 +
      'Deseja fazer uma leitura de teste agora?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if Leitor.Capturar(Template, True) then
        MessageDlg('Leitura realizada com sucesso. O leitor está funcionando corretamente.', mtInformation, [mbOK], 0)
      else
        MessageDlg('Leitura não concluída.'#13#10 + Leitor.UltimoErro, mtWarning, [mbOK], 0);
    end;
  finally
    Leitor.Free;
  end;
end;

procedure TfrmMain.skCadastrarBioClick(Sender: TObject);
var
  Leitor: THamsterDX;
  Template, Nome: string;
  Outras, Todas: TDigitaisCadastradas;
  Digital, Dono: TDigitalCadastrada;
  Duplicada: Boolean;
begin
  if FSelectedColabId <= 0 then
  begin
    ShowMessage('Salve o colaborador antes de cadastrar a biometria.');
    Exit;
  end;
  Nome := Trim(edtColabNome.Text);

  if FColabBioCadastrada and (MessageDlg(Format('"%s" já possui digital cadastrada. Deseja substituir?', [Nome]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
    Exit;

  if not LeitorLivreParaUso then
    Exit;

  Leitor := THamsterDX.Create;
  try
    // O assistente do SDK pede várias leituras do(s) dedo(s)
    if not Leitor.Cadastrar(Template) then
    begin
      if Leitor.UltimoErro <> '' then
      begin
        LogMessage('⚠️ ' + Leitor.UltimoErro, True);
        MessageDlg('Não foi possível cadastrar a digital.'#13#10 + Leitor.UltimoErro, mtWarning, [mbOK], 0);
      end;
      Exit;
    end;

    // A mesma digital não deve pertencer a dois colaboradores
    Duplicada := False;
    try
      Todas := dmDados.GetDigitaisCadastradas;
      SetLength(Outras, 0);
      for Digital in Todas do
        if Digital.PessoaId <> FSelectedColabId then
          Outras := Outras + [Digital];
      if Length(Outras) > 0 then
      begin
        Leitor.CarregarDigitais(Outras);
        Duplicada := Leitor.Identificar(Template, AppConfig.Relogio.NivelSeguranca, Dono);
      end;
    except
      Duplicada := False;
    end;

    if Duplicada and (MessageDlg(Format('Atenção: esta digital parece já estar cadastrada para "%s".'#13#10 +
      'Deseja gravar mesmo assim para "%s"?', [Dono.Nome, Nome]), mtWarning, [mbYes, mbNo], 0) <> mrYes) then
      Exit;

    if dmDados.SalvarBiometriaColaborador(FSelectedColabId, Template) then
    begin
      LogMessage(Format('👆 Digital cadastrada para o colaborador %s (ID %d).', [Nome, FSelectedColabId]));
      CarregarColaboradores;
      AtualizarDashboard;
      MessageDlg('Digital cadastrada com sucesso!', mtInformation, [mbOK], 0);
    end
    else
    begin
      LogMessage('⚠️ ' + dmDados.LastError, True);
      MessageDlg(dmDados.LastError, mtError, [mbOK], 0);
    end;
  finally
    Leitor.Free;
  end;
end;

procedure TfrmMain.skTestarBioClick(Sender: TObject);
var
  Leitor: THamsterDX;
  Armazenado, Capturado: string;
begin
  if FSelectedColabId <= 0 then
    Exit;
  Armazenado := dmDados.GetBiometriaColaborador(FSelectedColabId);
  if Armazenado = '' then
  begin
    ShowMessage('Este colaborador ainda não possui digital cadastrada.');
    Exit;
  end;

  if not LeitorLivreParaUso then
    Exit;

  Leitor := THamsterDX.Create;
  try
    if not Leitor.Capturar(Capturado, True) then
    begin
      if Leitor.UltimoErro <> '' then
        MessageDlg('Leitura não concluída.'#13#10 + Leitor.UltimoErro, mtWarning, [mbOK], 0);
      Exit;
    end;

    if Leitor.Comparar(Capturado, Armazenado) then
      MessageDlg(Format('✅ A digital confere com o cadastro de "%s".', [Trim(edtColabNome.Text)]),
        mtInformation, [mbOK], 0)
    else
      MessageDlg(Format('❌ A digital NÃO confere com o cadastro de "%s".'#13#10 +
        'Tente novamente ou recadastre a digital.', [Trim(edtColabNome.Text)]), mtWarning, [mbOK], 0);
  finally
    Leitor.Free;
  end;
end;

procedure TfrmMain.skRemoverBioClick(Sender: TObject);
begin
  if FSelectedColabId <= 0 then
    Exit;
  if MessageDlg(Format('Remover a digital cadastrada de "%s"?'#13#10 +
    'O colaborador não conseguirá mais registrar o ponto no leitor até cadastrar novamente.',
    [Trim(edtColabNome.Text)]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  if dmDados.RemoverBiometriaColaborador(FSelectedColabId) then
  begin
    LogMessage(Format('🗑️ Digital removida do colaborador %s (ID %d).', [Trim(edtColabNome.Text), FSelectedColabId]));
    CarregarColaboradores;
    AtualizarDashboard;
  end
  else
    ShowMessage('Não foi possível remover a digital do colaborador.');
end;

procedure TfrmMain.AbrirTerminalBiometrico;
begin
  if not dmDados.IsConectado then
  begin
    ShowMessage('Conecte ao banco de dados antes de abrir o Terminal de Ponto.');
    Exit;
  end;
  AbrirTerminalPonto(LogMessage, TerminalBatidaRegistrada);
end;

procedure TfrmMain.TerminalBatidaRegistrada;
begin
  lblCard4Val.Caption := FormatDateTime('hh:nn:ss', Now);
  AtualizarDashboard;
  if pgcMain.ActivePage = tabMarcacoes then
    CarregarMarcacoes;
end;

procedure TfrmMain.skRelatorioESClick(Sender: TObject);
var
  Html, ArquivoTemp: string;
  Razao, Cnpj, Endereco, Cei, CpfResp: string;
  Stream: TStreamWriter;
begin
  if dtpFim.Date < dtpIni.Date then
  begin
    ShowMessage('A data final deve ser maior ou igual à data inicial.');
    Exit;
  end;

  Razao := 'Empresa';
  Cnpj := '';
  dmDados.GetEmpresaPrincipal(Razao, Cnpj, Endereco, Cei, CpfResp);

  Screen.Cursor := crHourGlass;
  try
    Html := TRelatorioPonto.GerarEntradasSaidasHTML(dtpIni.Date, dtpFim.Date, 0, Razao, Cnpj);
  finally
    Screen.Cursor := crDefault;
  end;

  ArquivoTemp := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'Relatorio_Entradas_Saidas_' +
    FormatDateTime('yyyymmdd_hhnnss', Now) + '.html';
  Stream := TStreamWriter.Create(ArquivoTemp, False, TEncoding.UTF8);
  try
    Stream.Write(Html);
  finally
    Stream.Free;
  end;

  ShellExecute(0, 'open', PChar(ArquivoTemp), nil, nil, SW_SHOWNORMAL);
  LogMessage(Format('📋 Relatório de Entradas e Saídas (%s a %s) gerado: %s',
    [FormatDateTime('dd/mm/yyyy', dtpIni.Date), FormatDateTime('dd/mm/yyyy', dtpFim.Date), ArquivoTemp]));
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

  if ModoHamsterDX then
  begin
    Col := dbgColaboradores.Columns.Add;
    Col.FieldName := 'COL_BIOMETRIA_CADASTRADA';
    Col.Title.Caption := 'Biometria';
    Col.Title.Alignment := taCenter;
    Col.Alignment := taCenter;
    Col.Width := 120;

    Col := dbgColaboradores.Columns.Add;
    Col.FieldName := 'COL_BIOMETRIA_DATA';
    Col.Title.Caption := 'Cadastrada em';
    Col.Title.Alignment := taCenter;
    Col.Alignment := taCenter;
    Col.Width := 135;
  end
  else
  begin
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
  end;

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

  Col := dbgMarcacoes.Columns.Add;
  Col.FieldName := 'PMA_MOTIVO_DESCONSIDERACAO';
  Col.Title.Caption := 'Motivo (desconsiderada)';
  Col.Title.Alignment := taLeftJustify;
  Col.Width := 240;
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

  // Batida desconsiderada (Portaria 671): cinza e riscada, mas continua visível e restaurável
  if (Grid = dbgMarcacoes) and (Grid.DataSource <> nil) and (Grid.DataSource.DataSet <> nil) and
     (Grid.DataSource.DataSet.FindField('PMA_DESCONSIDERADA') <> nil) and
     (Grid.DataSource.DataSet.FieldByName('PMA_DESCONSIDERADA').AsString = 'S') then
  begin
    Grid.Canvas.Font.Color := clGray;
    Grid.Canvas.Font.Style := [fsStrikeOut];
  end;

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
  else if (Column.FieldName = 'COL_BIOMETRIA_CADASTRADA') then
  begin
    IsBadge := True;
    if SameText(Fld.AsString, 'S') then
    begin
      Txt := '👆 Cadastrada';
      BadgeBg := $00E6F4EA;
      BadgeBorder := $00CEEAD6;
      BadgeTxtColor := $00137333;
    end
    else
    begin
      Txt := '⏳ Sem digital';
      BadgeBg := $00FEF7E0;
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
    else if SameText(Fld.AsString, 'B') then
    begin
      Txt := '👆 Biometria';
      BadgeBg := $00E6F4EA;
      BadgeBorder := $00CEEAD6;
      BadgeTxtColor := $00137333;
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
