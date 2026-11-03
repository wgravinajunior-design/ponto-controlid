unit uFrmLogin;

{
  Login do sistema (usuários de TB_USUARIO do ERP).

  USU_ADMINISTRADOR = 'S' abre o sistema completo; os demais usuários abrem
  somente o Terminal de Ponto (leitor biométrico).

  O botão "Servidor" permite apontar o banco para outra máquina da rede
  (IP/nome do servidor, porta e caminho do .FDB no servidor), gravando em Config.ini.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmLogin = class(TForm)
  private
    edtLogin: TEdit;
    edtSenha: TEdit;
    lblStatus: TLabel;
    pnlServidor: TPanel;
    edtServidor: TEdit;
    edtPorta: TEdit;
    edtBanco: TEdit;
    FUsuarioNome: string;
    FAdministrador: Boolean;
    procedure MontarTela;
    procedure MostrarServidor(AVisivel: Boolean);
    procedure CarregarServidor;
    function SalvarServidorEConectar: Boolean;
    procedure btnEntrarClick(Sender: TObject);
    procedure btnSairClick(Sender: TObject);
    procedure btnServidorClick(Sender: TObject);
    procedure btnTestarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  public
    constructor CreateLogin(AOwner: TComponent);
    property UsuarioNome: string read FUsuarioNome;
    property Administrador: Boolean read FAdministrador;
  end;

// Mostra o login. Retorna False se o usuário cancelou.
function ExecutarLogin(out ANome: string; out AAdmin: Boolean): Boolean;

implementation

uses
  uConfig, uDataModule;

const
  COR_FUNDO = $002A221C;
  ALTURA_LOGIN = 300;
  ALTURA_SERVIDOR = 200;

function ExecutarLogin(out ANome: string; out AAdmin: Boolean): Boolean;
var
  F: TfrmLogin;
begin
  F := TfrmLogin.CreateLogin(nil);
  try
    Result := F.ShowModal = mrOk;
    ANome := F.UsuarioNome;
    AAdmin := F.Administrador;
  finally
    F.Free;
  end;
end;

{ TfrmLogin }

constructor TfrmLogin.CreateLogin(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  MontarTela;
  CarregarServidor;
end;

procedure TfrmLogin.MontarTela;

  function NovoLabel(AParent: TWinControl; X, Y: Integer; const ATexto: string): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(X, Y, 300, 17);
    Result.Caption := ATexto;
    Result.Font.Color := clWhite;
  end;

  function NovoEdit(AParent: TWinControl; X, Y, W: Integer): TEdit;
  begin
    Result := TEdit.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(X, Y, W, 25);
  end;

  function NovoBotao(AParent: TWinControl; X, Y, W: Integer; const ATexto: string;
    AEvento: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(X, Y, W, 32);
    Result.Caption := ATexto;
    Result.OnClick := AEvento;
  end;

var
  Titulo: TLabel;
  BtnEntrar, BtnSair: TButton;
begin
  Caption := 'Controle de Ponto - Login';
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 380;
  ClientHeight := ALTURA_LOGIN;
  Color := COR_FUNDO;
  Font.Name := 'Segoe UI';
  Font.Size := 10;
  OnShow := FormShow;

  Titulo := NovoLabel(Self, 30, 20, 'Controle de Ponto');
  Titulo.Font.Size := 16;
  Titulo.Font.Style := [fsBold];
  Titulo.Height := 32;

  NovoLabel(Self, 30, 70, 'Usuário');
  edtLogin := NovoEdit(Self, 30, 90, 320);
  NovoLabel(Self, 30, 125, 'Senha');
  edtSenha := NovoEdit(Self, 30, 145, 320);
  edtSenha.PasswordChar := '•';

  lblStatus := NovoLabel(Self, 30, 180, '');
  lblStatus.Width := 320;
  lblStatus.Height := 34;
  lblStatus.WordWrap := True;
  lblStatus.Font.Color := $006B6BFF;

  BtnEntrar := NovoBotao(Self, 30, 220, 155, 'Entrar', btnEntrarClick);
  BtnEntrar.Default := True;
  BtnSair := NovoBotao(Self, 195, 220, 155, 'Sair', btnSairClick);
  BtnSair.Cancel := True;
  NovoBotao(Self, 30, 260, 320, '⚙  Servidor do banco de dados', btnServidorClick).Height := 28;

  pnlServidor := TPanel.Create(Self);
  pnlServidor.Parent := Self;
  pnlServidor.SetBounds(0, ALTURA_LOGIN, 380, ALTURA_SERVIDOR);
  pnlServidor.BevelOuter := bvNone;
  pnlServidor.ParentBackground := False;
  pnlServidor.Color := $00463A30;
  pnlServidor.Visible := False;

  NovoLabel(pnlServidor, 30, 10, 'Servidor (IP ou nome da máquina)');
  edtServidor := NovoEdit(pnlServidor, 30, 30, 220);
  NovoLabel(pnlServidor, 260, 10, 'Porta');
  edtPorta := NovoEdit(pnlServidor, 260, 30, 90);
  NovoLabel(pnlServidor, 30, 65, 'Caminho do banco NO SERVIDOR (ex.: C:\DADOS\DADOS.FDB)');
  edtBanco := NovoEdit(pnlServidor, 30, 85, 320);
  NovoBotao(pnlServidor, 30, 125, 320, 'Salvar e testar conexão', btnTestarClick);
end;

procedure TfrmLogin.FormShow(Sender: TObject);
var
  Erro: string;
begin
  if not dmDados.TestarConexao(Erro) then
  begin
    lblStatus.Caption := 'Sem conexão com o banco. Confira o servidor abaixo.';
    MostrarServidor(True);
    edtServidor.SetFocus;
  end
  else
    edtLogin.SetFocus;
end;

procedure TfrmLogin.CarregarServidor;
begin
  edtServidor.Text := AppConfig.Firebird.Server;
  edtPorta.Text := IntToStr(AppConfig.Firebird.Port);
  edtBanco.Text := AppConfig.Firebird.Database;
end;

procedure TfrmLogin.MostrarServidor(AVisivel: Boolean);
begin
  pnlServidor.Visible := AVisivel;
  if AVisivel then
    ClientHeight := ALTURA_LOGIN + ALTURA_SERVIDOR
  else
    ClientHeight := ALTURA_LOGIN;
end;

function TfrmLogin.SalvarServidorEConectar: Boolean;
var
  Cfg: TFirebirdConfig;
  Erro: string;
begin
  Cfg := AppConfig.Firebird;
  Cfg.Server := Trim(edtServidor.Text);
  Cfg.Port := StrToIntDef(Trim(edtPorta.Text), 3050);
  Cfg.Database := Trim(edtBanco.Text);
  AppConfig.Firebird := Cfg;
  AppConfig.Save;

  dmDados.Desconectar;
  Result := dmDados.TestarConexao(Erro);
  if Result then
    lblStatus.Caption := ''
  else
    lblStatus.Caption := 'Falha ao conectar: ' + Erro;
end;

procedure TfrmLogin.btnServidorClick(Sender: TObject);
begin
  MostrarServidor(not pnlServidor.Visible);
end;

procedure TfrmLogin.btnTestarClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    if SalvarServidorEConectar then
    begin
      MessageDlg('Conexão realizada com sucesso.', mtInformation, [mbOK], 0);
      MostrarServidor(False);
      edtLogin.SetFocus;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmLogin.btnEntrarClick(Sender: TObject);
var
  Nome: string;
  Admin: Boolean;
begin
  if Trim(edtLogin.Text) = '' then
  begin
    lblStatus.Caption := 'Informe o usuário.';
    edtLogin.SetFocus;
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    try
      if not dmDados.AutenticarUsuario(edtLogin.Text, edtSenha.Text, Nome, Admin) then
      begin
        lblStatus.Caption := 'Usuário ou senha inválidos.';
        edtSenha.Clear;
        edtSenha.SetFocus;
        Exit;
      end;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Sem conexão com o banco: ' + E.Message;
        MostrarServidor(True);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  FUsuarioNome := Nome;
  FAdministrador := Admin;
  ModalResult := mrOk;
end;

procedure TfrmLogin.btnSairClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
