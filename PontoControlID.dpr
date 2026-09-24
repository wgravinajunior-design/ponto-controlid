program PontoControlID;

uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Skia,
  Vcl.Forms,
  uConfig in 'uConfig.pas',
  uControlIDClient in 'uControlIDClient.pas',
  uDataModule in 'uDataModule.pas' {dmDados: TDataModule},
  uPontoCalculoService in 'uPontoCalculoService.pas',
  uPontoService in 'uPontoService.pas',
  uSkiaButtons in 'uSkiaButtons.pas',
  uFrmUpdate in 'uFrmUpdate.pas' {frmUpdate},
  uFrmMain in 'uFrmMain.pas' {frmMain};

{$R *.res}

begin
  try
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.Title := 'Integrador Ponto Control iD';
    Application.CreateForm(TdmDados, dmDados);
    Application.CreateForm(TfrmMain, frmMain);
    Application.Run;
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
