program PontoControlID;

uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Skia,
  Vcl.Forms,
  uBuildInfo in 'uBuildInfo.pas',
  uConfig in 'uConfig.pas',
  uControlIDClient in 'uControlIDClient.pas',
  uDataModule in 'uDataModule.pas' {dmDados: TDataModule},
  uPontoCalculoService in 'uPontoCalculoService.pas',
  uPontoService in 'uPontoService.pas',
  uSkiaButtons in 'uSkiaButtons.pas',
  uBiometriaHamster in 'uBiometriaHamster.pas',
  uRelatorioPonto in 'uRelatorioPonto.pas',
  uFrmTerminalPonto in 'uFrmTerminalPonto.pas',
  uFrmLogin in 'uFrmLogin.pas',
  uFrmUpdate in 'uFrmUpdate.pas' {frmUpdate},
  uFrmMain in 'uFrmMain.pas' {frmMain};

{$R *.res}

var
  UsuarioNome: string;
  UsuarioAdmin: Boolean;

// Log do terminal quando ele roda sem a tela principal (usuário não administrador)
procedure LogTerminal(const AMsg: string; AIsError: Boolean = False);
begin
  try
    TFile.AppendAllText(TPath.Combine(ExtractFilePath(ParamStr(0)), 'terminal.log'),
      FormatDateTime('dd/mm/yyyy hh:nn:ss', Now) + '  ' + AMsg + sLineBreak, TEncoding.UTF8);
  except
  end;
end;

begin
  try
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.Title := 'Integrador Ponto Control iD';
    if FileExists(ExtractFilePath(ParamStr(0)) + 'PontoControlID_Icon.ico') then
    begin
      try
        Application.Icon.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'PontoControlID_Icon.ico');
      except
      end;
    end;
    Application.CreateForm(TdmDados, dmDados);

    if not ExecutarLogin(UsuarioNome, UsuarioAdmin) then
      Exit;

    if UsuarioAdmin then
    begin
      Application.CreateForm(TfrmMain, frmMain);
      frmMain.Caption := frmMain.Caption + '  -  Usuário: ' + UsuarioNome;
      Application.Run;
    end
    else
      ExecutarTerminalPontoExclusivo(LogTerminal);
  except
    on E: Exception do
    begin
      TFile.WriteAllText(
        TPath.Combine(ExtractFilePath(ParamStr(0)), 'startup_error.log'),
        E.ClassName + ': ' + E.Message
      );
      raise;
    end;
  end;
end.
