unit uFrmTerminalPonto;

{
  Terminal de Ponto Biométrico (Nitgen Hamster DX).

  Tela de leitura contínua: o colaborador encosta o dedo no leitor, a digital é
  identificada contra os templates cadastrados e a batida é gravada em
  TB_PONTO_MARCACAO (Entrada/Saída alternadas no dia).

  A captura roda em uma thread própria (o SDK bloqueia até ler a digital ou
  expirar o tempo), e a gravação no banco acontece na thread principal.
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX, System.SysUtils, System.Classes,
  System.DateUtils, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, uConfig, uBiometriaHamster, uDataModule, uPontoService, uSkiaButtons;

type
  TLeituraDigitalThread = class(TThread)
  private
    FDigitais: TDigitaisCadastradas;
    FNivelSeguranca: Integer;
    FOnStatus: TProc<string, Boolean>;
    FOnIdentificado: TProc<TDigitalCadastrada, TDateTime>;
    FOnNaoIdentificado: TProc;
    // Dados repassados à thread principal via Synchronize
    FMsgStatus: string;
    FMsgErro: Boolean;
    FDigital: TDigitalCadastrada;
    FMomento: TDateTime;
    procedure NotificarStatus(const AMsg: string; AErro: Boolean);
    procedure DoStatus;
    procedure DoIdentificado;
    procedure DoNaoIdentificado;
  protected
    procedure Execute; override;
  public
    constructor Create(const ADigitais: TDigitaisCadastradas; ANivelSeguranca: Integer);
    property OnStatus: TProc<string, Boolean> write FOnStatus;
    property OnIdentificado: TProc<TDigitalCadastrada, TDateTime> write FOnIdentificado;
    property OnNaoIdentificado: TProc write FOnNaoIdentificado;
  end;

  TfrmTerminalPonto = class(TForm)
  private
    FLog: TLogCallback;
    FOnBatidaRegistrada: TProc;
    FThread: TLeituraDigitalThread;
    FTotalDigitais: Integer;

    pnlTopo: TPanel;
    lblTitulo: TLabel;
    lblInfo: TLabel;
    lblHora: TLabel;
    lblData: TLabel;
    pnlResultado: TPanel;
    lblStatus: TLabel;
    lblNome: TLabel;
    lblDetalhe: TLabel;
    lblUltimasTitulo: TLabel;
    lstUltimas: TListBox;
    pnlRodape: TPanel;
    skRecarregar: TSkModernButton;
    skFechar: TSkModernButton;
    tmrRelogio: TTimer;
    tmrVoltar: TTimer;
    pnlCorrecao: TPanel;
    lblCorrecao: TLabel;
    skTipo: array[1..4] of TSkModernButton;

    // Batida recém-registrada que ainda pode ter o tipo corrigido (F1..F4)
    FCorrAtiva: Boolean;
    FCorrPessoaId: Integer;
    FCorrMomento: TDateTime;
    FCorrNome: string;

    procedure MontarTela;
    procedure CorrigirTipo(AOpcao: Integer);
    procedure skTipoClick(Sender: TObject);
    procedure IniciarLeitura;
    procedure PararLeitura;
    procedure MostrarAguardando;
    procedure MostrarResultado(ACor: TColor; const AStatus, ANome, ADetalhe: string);
    procedure ThreadStatus(AMsg: string; AErro: Boolean);
    procedure ThreadIdentificado(ADigital: TDigitalCadastrada; AMomento: TDateTime);
    procedure ThreadNaoIdentificado;
    procedure ThreadTerminou(Sender: TObject);
    procedure tmrRelogioTimer(Sender: TObject);
    procedure tmrVoltarTimer(Sender: TObject);
    procedure skRecarregarClick(Sender: TObject);
    procedure skFecharClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateTerminal(AOwner: TComponent; ALog: TLogCallback; AOnBatidaRegistrada: TProc);
    destructor Destroy; override;
  end;

// Abre (ou traz à frente) o terminal de ponto biométrico
procedure AbrirTerminalPonto(ALog: TLogCallback; AOnBatidaRegistrada: TProc);
// Usuário sem perfil administrador: o terminal é a única tela do sistema (modal, sem frmMain)
procedure ExecutarTerminalPontoExclusivo(ALog: TLogCallback);
function TerminalPontoAberto: Boolean;
// Aguarda a thread de leitura liberar o leitor (ao fechar o terminal a captura em andamento
// só termina quando expira o tempo de leitura do SDK)
function AguardarLeitorLivre(ATimeoutMs: Cardinal = 15000): Boolean;

implementation

procedure TfrmTerminalPonto.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // Botão próprio na barra de tarefas: com a janela minimizada, o Alt+Tab consegue restaurá-la
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;

const
  COR_FUNDO     = $002A221C;
  COR_PAINEL    = $00463A30;
  COR_AGUARDA   = $00705A48;
  COR_ENTRADA   = $00409A2E;
  COR_SAIDA     = $001C7CE0;
  COR_REPETIDA  = $00A07850;
  COR_ERRO      = $003030C8;

var
  GTerminal: TfrmTerminalPonto = nil;
  GLeiturasAtivas: Integer = 0;

procedure AbrirTerminalPonto(ALog: TLogCallback; AOnBatidaRegistrada: TProc);
begin
  if GTerminal = nil then
  begin
    if not AguardarLeitorLivre then
    begin
      MessageDlg('O leitor Hamster DX ainda está ocupado com a leitura anterior. Tente novamente em alguns segundos.',
        mtWarning, [mbOK], 0);
      Exit;
    end;
    GTerminal := TfrmTerminalPonto.CreateTerminal(Application, ALog, AOnBatidaRegistrada);
  end;
  GTerminal.Show;
  if GTerminal.WindowState = wsMinimized then
    GTerminal.WindowState := wsNormal;
  GTerminal.BringToFront;
end;

procedure ExecutarTerminalPontoExclusivo(ALog: TLogCallback);
begin
  GTerminal := TfrmTerminalPonto.CreateTerminal(Application, ALog, nil);
  GTerminal.ShowModal; // FormClose usa caFree: o form se libera ao fechar
  AguardarLeitorLivre;
end;

function TerminalPontoAberto: Boolean;
begin
  Result := GTerminal <> nil;
end;

function AguardarLeitorLivre(ATimeoutMs: Cardinal): Boolean;
var
  Inicio: Cardinal;
begin
  Inicio := GetTickCount;
  while (GLeiturasAtivas > 0) and (GetTickCount - Inicio < ATimeoutMs) do
  begin
    Application.ProcessMessages;
    Sleep(50);
  end;
  Result := GLeiturasAtivas = 0;
end;

{ TLeituraDigitalThread }

constructor TLeituraDigitalThread.Create(const ADigitais: TDigitaisCadastradas; ANivelSeguranca: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FDigitais := Copy(ADigitais);
  FNivelSeguranca := ANivelSeguranca;
end;

procedure TLeituraDigitalThread.NotificarStatus(const AMsg: string; AErro: Boolean);
begin
  FMsgStatus := AMsg;
  FMsgErro := AErro;
  Synchronize(DoStatus);
end;

// Os métodos Do* rodam na thread principal. Terminated = terminal já fechado: não tocar no form.
procedure TLeituraDigitalThread.DoStatus;
begin
  if (not Terminated) and Assigned(FOnStatus) then
    FOnStatus(FMsgStatus, FMsgErro);
end;

procedure TLeituraDigitalThread.DoIdentificado;
begin
  if (not Terminated) and Assigned(FOnIdentificado) then
    FOnIdentificado(FDigital, FMomento);
end;

procedure TLeituraDigitalThread.DoNaoIdentificado;
begin
  if (not Terminated) and Assigned(FOnNaoIdentificado) then
    FOnNaoIdentificado();
end;

procedure TLeituraDigitalThread.Execute;
var
  Leitor: THamsterDX;
  Template: string;
  Inicio: Cardinal;
begin
  InterlockedIncrement(GLeiturasAtivas);
  try
    CoInitialize(nil);
    try
      Leitor := THamsterDX.Create;
      try
        if not Leitor.Abrir then
        begin
          NotificarStatus(Leitor.UltimoErro, True);
          Exit;
        end;
        Leitor.CarregarDigitais(FDigitais);
        NotificarStatus('', False);

        while not Terminated do
        begin
          Inicio := GetTickCount;
          if Leitor.Capturar(Template, False) then
          begin
            if Terminated then
              Break;
            FMomento := Now;
            if Leitor.Identificar(Template, FNivelSeguranca, FDigital) then
              Synchronize(DoIdentificado)
            else
              Synchronize(DoNaoIdentificado);
          end
          else if GetTickCount - Inicio < 1500 then
          begin
            // Falha imediata (não foi apenas o tempo de espera expirando): leitor desconectado ou com erro
            NotificarStatus(Leitor.UltimoErro, True);
            Leitor.Fechar;
            Sleep(2000);
            if (not Terminated) and Leitor.Abrir then
              NotificarStatus('', False);
          end;
        end;
      finally
        Leitor.Free;
      end;
    finally
      CoUninitialize;
    end;
  finally
    InterlockedDecrement(GLeiturasAtivas);
  end;
end;

{ TfrmTerminalPonto }

constructor TfrmTerminalPonto.CreateTerminal(AOwner: TComponent; ALog: TLogCallback; AOnBatidaRegistrada: TProc);
begin
  inherited CreateNew(AOwner);
  FLog := ALog;
  FOnBatidaRegistrada := AOnBatidaRegistrada;
  MontarTela;
  IniciarLeitura;
end;

destructor TfrmTerminalPonto.Destroy;
begin
  PararLeitura;
  if GTerminal = Self then
    GTerminal := nil;
  inherited;
end;

procedure TfrmTerminalPonto.MontarTela;

  function NovoLabel(AParent: TWinControl; AAlign: TAlign; AAltura, ATamanhoFonte: Integer;
    AEstilo: TFontStyles; ACor: TColor): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.Align := AAlign;
    Result.AutoSize := False;
    Result.Height := AAltura;
    Result.Alignment := taCenter;
    Result.Layout := tlCenter;
    Result.Font.Name := 'Segoe UI';
    Result.Font.Size := ATamanhoFonte;
    Result.Font.Style := AEstilo;
    Result.Font.Color := ACor;
    Result.Transparent := True;
    Result.WordWrap := True;
  end;

begin
  Caption := 'Terminal de Ponto Biométrico - Hamster DX';
  Width := 980;
  Height := 700;
  Position := poScreenCenter;
  Color := COR_FUNDO;
  Font.Name := 'Segoe UI';
  KeyPreview := True;
  OnClose := FormClose;
  OnKeyDown := FormKeyDown;
  if Application.MainForm <> nil then
    Icon := Application.MainForm.Icon;

  // Cabeçalho
  pnlTopo := TPanel.Create(Self);
  pnlTopo.Parent := Self;
  pnlTopo.Align := alTop;
  pnlTopo.Height := 70;
  pnlTopo.BevelOuter := bvNone;
  pnlTopo.ParentBackground := False;
  pnlTopo.Color := COR_PAINEL;

  lblTitulo := NovoLabel(pnlTopo, alTop, 38, 16, [fsBold], clWhite);
  lblTitulo.Caption := '👆  Registro de Ponto Biométrico';
  lblInfo := NovoLabel(pnlTopo, alClient, 30, 10, [], $00D8C8B8);

  // Relógio
  lblHora := NovoLabel(Self, alTop, 120, 64, [fsBold], clWhite);
  lblHora.Top := pnlTopo.Height;
  lblData := NovoLabel(Self, alTop, 36, 15, [], $00D8C8B8);
  lblData.Top := lblHora.Top + lblHora.Height;

  // Rodapé
  pnlRodape := TPanel.Create(Self);
  pnlRodape.Parent := Self;
  pnlRodape.Align := alBottom;
  pnlRodape.Height := 62;
  pnlRodape.BevelOuter := bvNone;
  pnlRodape.ParentBackground := False;
  pnlRodape.Color := COR_PAINEL;

  skRecarregar := TSkModernButton.Create(Self);
  skRecarregar.Parent := pnlRodape;
  skRecarregar.SetBounds(16, 11, 230, 40);
  skRecarregar.Caption := '🔄 Recarregar Digitais';
  skRecarregar.Kind := sbkPrimary;
  skRecarregar.Radius := 10;
  skRecarregar.FontSize := 11;
  skRecarregar.EmojiSize := 16;
  skRecarregar.OnClick := skRecarregarClick;

  skFechar := TSkModernButton.Create(Self);
  skFechar.Parent := pnlRodape;
  skFechar.Anchors := [akTop, akRight];
  skFechar.SetBounds(pnlRodape.ClientWidth - 196, 11, 180, 40);
  skFechar.Caption := '🚪 Fechar [ESC]';
  skFechar.Kind := sbkDark;
  skFechar.Radius := 10;
  skFechar.FontSize := 11;
  skFechar.EmojiSize := 16;
  skFechar.OnClick := skFecharClick;

  // Últimas batidas
  lstUltimas := TListBox.Create(Self);
  lstUltimas.Parent := Self;
  lstUltimas.Align := alBottom;
  lstUltimas.Height := 150;
  lstUltimas.BorderStyle := bsNone;
  lstUltimas.Color := COR_PAINEL;
  lstUltimas.Font.Name := 'Segoe UI';
  lstUltimas.Font.Size := 12;
  lstUltimas.Font.Color := clWhite;
  lstUltimas.ItemHeight := 24;
  lstUltimas.AlignWithMargins := True;
  lstUltimas.Margins.SetBounds(24, 0, 24, 12);

  lblUltimasTitulo := NovoLabel(Self, alBottom, 28, 11, [fsBold], $00D8C8B8);
  lblUltimasTitulo.Alignment := taLeftJustify;
  lblUltimasTitulo.AlignWithMargins := True;
  lblUltimasTitulo.Margins.SetBounds(24, 0, 24, 0);
  lblUltimasTitulo.Caption := 'Últimas batidas registradas neste terminal';

  // Resultado da leitura
  pnlResultado := TPanel.Create(Self);
  pnlResultado.Parent := Self;
  pnlResultado.Align := alClient;
  pnlResultado.AlignWithMargins := True;
  pnlResultado.Margins.SetBounds(24, 12, 24, 12);
  pnlResultado.BevelOuter := bvNone;
  pnlResultado.ParentBackground := False;
  pnlResultado.Color := COR_AGUARDA;

  lblStatus := NovoLabel(pnlResultado, alTop, 60, 22, [fsBold], clWhite);
  lblNome := NovoLabel(pnlResultado, alTop, 60, 26, [fsBold], clWhite);
  lblNome.Top := lblStatus.Height;
  // Correção rápida do tipo: aparece por alguns segundos após cada batida
  pnlCorrecao := TPanel.Create(Self);
  pnlCorrecao.Parent := pnlResultado;
  pnlCorrecao.Align := alBottom;
  pnlCorrecao.Height := 86;
  pnlCorrecao.BevelOuter := bvNone;
  pnlCorrecao.ParentBackground := True;
  pnlCorrecao.Visible := False;

  lblCorrecao := NovoLabel(pnlCorrecao, alTop, 28, 11, [], clWhite);
  lblCorrecao.Caption := 'Tipo errado? Toque na opção correta ou use as teclas F1 a F4:';

  for var K := 1 to 4 do
  begin
    skTipo[K] := TSkModernButton.Create(Self);
    skTipo[K].Parent := pnlCorrecao;
    skTipo[K].Tag := K;
    skTipo[K].SetBounds(20 + (K - 1) * 225, 34, 210, 42);
    skTipo[K].Kind := sbkDark;
    skTipo[K].Radius := 10;
    skTipo[K].FontSize := 11;
    skTipo[K].OnClick := skTipoClick;
  end;
  skTipo[1].Caption := 'F1  Entrada';
  skTipo[2].Caption := 'F2  Saída almoço';
  skTipo[3].Caption := 'F3  Volta almoço';
  skTipo[4].Caption := 'F4  Saída';

  lblDetalhe := NovoLabel(pnlResultado, alClient, 40, 16, [], clWhite);

  tmrRelogio := TTimer.Create(Self);
  tmrRelogio.Interval := 500;
  tmrRelogio.OnTimer := tmrRelogioTimer;
  tmrRelogioTimer(nil);

  tmrVoltar := TTimer.Create(Self);
  tmrVoltar.Enabled := False;
  tmrVoltar.Interval := 4000;
  tmrVoltar.OnTimer := tmrVoltarTimer;
end;

procedure TfrmTerminalPonto.IniciarLeitura;
var
  Digitais: TDigitaisCadastradas;
begin
  PararLeitura;

  try
    Digitais := dmDados.GetDigitaisCadastradas;
  except
    on E: Exception do
    begin
      MostrarResultado(COR_ERRO, '⚠️ Erro ao carregar as digitais', '', E.Message);
      Exit;
    end;
  end;

  FTotalDigitais := Length(Digitais);
  lblInfo.Caption := Format('%d colaborador(es) com biometria cadastrada', [FTotalDigitais]);

  if FTotalDigitais = 0 then
  begin
    MostrarResultado(COR_ERRO, '⚠️ Nenhuma digital cadastrada', '',
      'Cadastre a biometria dos colaboradores na aba Colaboradores e clique em "Recarregar Digitais".');
    Exit;
  end;

  if not AguardarLeitorLivre then
  begin
    MostrarResultado(COR_ERRO, '⚠️ Leitor ocupado', '', 'Aguarde alguns segundos e clique em "Recarregar Digitais".');
    Exit;
  end;

  lblStatus.Caption := 'Conectando ao leitor Hamster DX...';
  lblNome.Caption := '';
  lblDetalhe.Caption := '';

  FThread := TLeituraDigitalThread.Create(Digitais, AppConfig.Relogio.NivelSeguranca);
  FThread.OnStatus := ThreadStatus;
  FThread.OnIdentificado := ThreadIdentificado;
  FThread.OnNaoIdentificado := ThreadNaoIdentificado;
  FThread.OnTerminate := ThreadTerminou;
  FThread.Start;
end;

// A thread tem FreeOnTerminate: se ela termina sozinha (ex.: leitor não abriu), o objeto é liberado.
// Sem zerar FThread aqui, fechar o terminal chamaria Terminate num objeto já liberado
// ("Cannot terminate an externally created thread").
procedure TfrmTerminalPonto.ThreadTerminou(Sender: TObject);
begin
  if FThread = Sender then
    FThread := nil;
end;

procedure TfrmTerminalPonto.PararLeitura;
begin
  if FThread <> nil then
  begin
    // Desliga os avisos para a thread não tocar no form que está fechando
    FThread.OnTerminate := nil;
    FThread.OnStatus := nil;
    FThread.OnIdentificado := nil;
    FThread.OnNaoIdentificado := nil;
    // FreeOnTerminate: a thread encerra sozinha ao fim da captura em andamento
    FThread.Terminate;
    FThread := nil;
  end;
end;

procedure TfrmTerminalPonto.MostrarAguardando;
begin
  tmrVoltar.Enabled := False;
  tmrVoltar.Interval := 4000;
  FCorrAtiva := False;
  pnlCorrecao.Visible := False;
  pnlResultado.Color := COR_AGUARDA;
  lblStatus.Caption := '👆 Posicione o dedo no leitor';
  lblNome.Caption := '';
  lblDetalhe.Caption := 'Aguardando leitura da digital...';
end;

procedure TfrmTerminalPonto.MostrarResultado(ACor: TColor; const AStatus, ANome, ADetalhe: string);
begin
  pnlResultado.Color := ACor;
  lblStatus.Caption := AStatus;
  lblNome.Caption := ANome;
  lblDetalhe.Caption := ADetalhe;
end;

procedure TfrmTerminalPonto.ThreadStatus(AMsg: string; AErro: Boolean);
begin
  if AErro then
  begin
    tmrVoltar.Enabled := False;
    MostrarResultado(COR_ERRO, '⚠️ Problema no leitor Hamster DX', '', AMsg);
    if Assigned(FLog) then
      FLog('⚠️ Terminal biométrico: ' + AMsg, True);
  end
  else if not tmrVoltar.Enabled then
    MostrarAguardando;
end;

procedure TfrmTerminalPonto.ThreadIdentificado(ADigital: TDigitalCadastrada; AMomento: TDateTime);
var
  Tipo, TipoDesc: string;
  Ultima: TDateTime;
begin
  // Nova leitura encerra a correção da batida anterior
  FCorrAtiva := False;
  pnlCorrecao.Visible := False;
  tmrVoltar.Interval := 4000;
  case dmDados.RegistrarBatidaBiometrica(ADigital.PessoaId, AMomento,
    AppConfig.Relogio.IntervaloMinimoBatidaMin, Tipo, TipoDesc, Ultima) of
    rbRegistrada:
      begin
        if Tipo = 'E' then
          MostrarResultado(COR_ENTRADA, '✅ ' + TipoDesc + ' registrada', ADigital.Nome,
            FormatDateTime('dd/mm/yyyy "às" hh:nn:ss', AMomento))
        else
          MostrarResultado(COR_SAIDA, '✅ ' + TipoDesc + ' registrada', ADigital.Nome,
            FormatDateTime('dd/mm/yyyy "às" hh:nn:ss', AMomento));
        lstUltimas.Items.Insert(0, Format('%s   %-13s   %s',
          [FormatDateTime('hh:nn:ss', AMomento), TipoDesc, ADigital.Nome]));
        while lstUltimas.Items.Count > 50 do
          lstUltimas.Items.Delete(lstUltimas.Items.Count - 1);
        MessageBeep(MB_OK);
        if Assigned(FLog) then
          FLog(Format('👆 Batida biométrica: %s - %s às %s',
            [ADigital.Nome, TipoDesc, FormatDateTime('hh:nn:ss', AMomento)]));
        if Assigned(FOnBatidaRegistrada) then
          FOnBatidaRegistrada();

        // Abre a janela de correção do tipo por 7 segundos
        FCorrAtiva := True;
        FCorrPessoaId := ADigital.PessoaId;
        FCorrMomento := AMomento;
        FCorrNome := ADigital.Nome;
        pnlCorrecao.Visible := True;
        tmrVoltar.Interval := 7000;
      end;
    rbRepetida:
      begin
        MostrarResultado(COR_REPETIDA, 'ℹ️ Batida já registrada', ADigital.Nome,
          Format('Última batida (%s) às %s. Leituras repetidas em menos de 10 minutos são ignoradas.',
            [TipoDesc, FormatDateTime('hh:nn:ss', Ultima)]));
        MessageBeep(MB_ICONASTERISK);
      end;
  else
    MostrarResultado(COR_ERRO, '⚠️ Batida NÃO registrada', ADigital.Nome, dmDados.LastError);
    MessageBeep(MB_ICONHAND);
    if Assigned(FLog) then
      FLog('⚠️ Terminal biométrico: ' + dmDados.LastError, True);
  end;
  tmrVoltar.Enabled := False;
  tmrVoltar.Enabled := True;
end;

procedure TfrmTerminalPonto.ThreadNaoIdentificado;
begin
  FCorrAtiva := False;
  pnlCorrecao.Visible := False;
  tmrVoltar.Interval := 4000;
  MostrarResultado(COR_ERRO, '❌ Digital não reconhecida', '',
    'Tente novamente posicionando o dedo no centro do leitor.');
  MessageBeep(MB_ICONHAND);
  tmrVoltar.Enabled := False;
  tmrVoltar.Enabled := True;
end;

procedure TfrmTerminalPonto.tmrRelogioTimer(Sender: TObject);
begin
  lblHora.Caption := FormatDateTime('hh:nn:ss', Now);
  lblData.Caption := FormatDateTime('dddd, dd "de" mmmm "de" yyyy', Now);
end;

procedure TfrmTerminalPonto.tmrVoltarTimer(Sender: TObject);
begin
  if FThread <> nil then
    MostrarAguardando
  else
    tmrVoltar.Enabled := False;
end;

procedure TfrmTerminalPonto.skRecarregarClick(Sender: TObject);
begin
  IniciarLeitura;
end;

procedure TfrmTerminalPonto.skFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmTerminalPonto.CorrigirTipo(AOpcao: Integer);
const
  DESCRICOES: array[1..4] of string = ('ENTRADA', 'SAÍDA ALMOÇO', 'VOLTA ALMOÇO', 'SAÍDA');
var
  Tipo: string;
begin
  if not FCorrAtiva then
    Exit;
  if Odd(AOpcao) then Tipo := 'E' else Tipo := 'S';
  if dmDados.CorrigirTipoBatida(FCorrPessoaId, FCorrMomento, Tipo) then
  begin
    if Tipo = 'E' then
      MostrarResultado(COR_ENTRADA, '✅ ' + DESCRICOES[AOpcao] + ' registrada', FCorrNome,
        FormatDateTime('dd/mm/yyyy "às" hh:nn:ss', FCorrMomento) + '  (corrigido)')
    else
      MostrarResultado(COR_SAIDA, '✅ ' + DESCRICOES[AOpcao] + ' registrada', FCorrNome,
        FormatDateTime('dd/mm/yyyy "às" hh:nn:ss', FCorrMomento) + '  (corrigido)');
    if lstUltimas.Items.Count > 0 then
      lstUltimas.Items[0] := Format('%s   %-13s   %s',
        [FormatDateTime('hh:nn:ss', FCorrMomento), DESCRICOES[AOpcao], FCorrNome]);
    if Assigned(FLog) then
      FLog(Format('✏️ Tipo da batida corrigido pelo colaborador: %s - %s às %s',
        [FCorrNome, DESCRICOES[AOpcao], FormatDateTime('hh:nn:ss', FCorrMomento)]));
    if Assigned(FOnBatidaRegistrada) then
      FOnBatidaRegistrada();
  end
  else
    MostrarResultado(COR_ERRO, '⚠️ Não foi possível corrigir', FCorrNome, dmDados.LastError);
  FCorrAtiva := False;
  pnlCorrecao.Visible := False;
  tmrVoltar.Enabled := False;
  tmrVoltar.Interval := 4000;
  tmrVoltar.Enabled := True;
end;

procedure TfrmTerminalPonto.skTipoClick(Sender: TObject);
begin
  CorrigirTipo(TComponent(Sender).Tag);
end;

procedure TfrmTerminalPonto.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: Close;
    VK_F1..VK_F4:
      if FCorrAtiva then
      begin
        CorrigirTipo(Key - VK_F1 + 1);
        Key := 0;
      end;
  end;
end;

procedure TfrmTerminalPonto.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  PararLeitura;
  tmrRelogio.Enabled := False;
  tmrVoltar.Enabled := False;
  Action := caFree;
  GTerminal := nil;
end;

end.
