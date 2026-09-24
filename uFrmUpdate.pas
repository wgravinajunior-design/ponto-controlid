unit uFrmUpdate;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  System.Generics.Collections,
  System.JSON, System.Net.HttpClient, System.Net.HttpClientComponent,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.ComCtrls,
  uConfig, uSkiaButtons;

type
  TfrmUpdate = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubTitle: TLabel;
    pnlContent: TPanel;
    lblVersaoAtual: TLabel;
    lblVersaoNova: TLabel;
    lblNotas: TLabel;
    memNotas: TMemo;
    pbDownload: TProgressBar;
    lblProgresso: TLabel;
    lblPorcentagem: TLabel;
    pnlBottom: TPanel;
    btnBaixar: TButton;
    btnCancelar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnBaixarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FUpdateInfo: TUpdateInfo;
    FSkBaixar: TSkModernButton;
    FSkCancelar: TSkModernButton;
    FDownloading: Boolean;
    FCancelRequested: Boolean;
    procedure SetUpdateInfo(const Value: TUpdateInfo);
    procedure IniciarDownload;
    procedure ConcluirAtualizacao(const ANovoExePath: string);
    function CriarBtn(AOriginal: TButton; const ACaption: string; AKind: TSkButtonKind): TSkModernButton;
    procedure HttpReceiveData(const Sender: TObject; AContentLength: Int64; AReadCount: Int64; var AAbort: Boolean);
  public
    class function ChecarAtualizacao(out AInfo: TUpdateInfo): Boolean; static;
    class function CompararVersoes(const V1, V2: string): Integer; static;
    class procedure ExecutarAtualizacao(AOwner: TComponent; const AInfo: TUpdateInfo); static;
    property UpdateInfo: TUpdateInfo read FUpdateInfo write SetUpdateInfo;
  end;

var
  frmUpdate: TfrmUpdate;

implementation

{$R *.dfm}

{ Utilitários de Versão e Rede }

function LimparVersao(const AVersao: string): string;
var
  S: string;
begin
  S := Trim(AVersao);
  if (Length(S) > 0) and ((S[1] = 'v') or (S[1] = 'V')) then
    S := Copy(S, 2, Length(S) - 1);
  Result := Trim(S);
end;

class function TfrmUpdate.CompararVersoes(const V1, V2: string): Integer;
var
  Parts1, Parts2: TArray<string>;
  P1, P2, MaxParts, I, N1, N2: Integer;
begin
  Parts1 := LimparVersao(V1).Split(['.']);
  Parts2 := LimparVersao(V2).Split(['.']);

  P1 := Length(Parts1);
  P2 := Length(Parts2);
  if P1 > P2 then MaxParts := P1 else MaxParts := P2;

  for I := 0 to MaxParts - 1 do
  begin
    if I < P1 then N1 := StrToIntDef(Parts1[I], 0) else N1 := 0;
    if I < P2 then N2 := StrToIntDef(Parts2[I], 0) else N2 := 0;

    if N1 > N2 then
      Exit(1)
    else if N1 < N2 then
      Exit(-1);
  end;
  Result := 0;
end;

function FormatarBytes(const ABytes: Int64): string;
begin
  if ABytes >= 1048576 then
    Result := Format('%.1f MB', [ABytes / 1048576.0])
  else if ABytes >= 1024 then
    Result := Format('%.0f KB', [ABytes / 1024.0])
  else
    Result := Format('%d B', [ABytes]);
end;

class function TfrmUpdate.ChecarAtualizacao(out AInfo: TUpdateInfo): Boolean;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
  URL, JsonStr, TagStr, AssetName, DownloadUrl: string;
  JSONVal, AssetObj: TJSONValue;
  RootObj: TJSONObject;
  AssetsArr: TJSONArray;
  I: Integer;
  AssetSize: Int64;
begin
  Result := False;
  AInfo.HasUpdate := False;
  AInfo.LatestVersion := '';
  AInfo.ReleaseName := '';
  AInfo.ReleaseNotes := '';
  AInfo.DownloadUrl := '';
  AInfo.AssetFileName := '';
  AInfo.AssetSize := 0;

  URL := Format('https://api.github.com/repos/%s/%s/releases/latest', [GITHUB_OWNER, GITHUB_REPO]);
  Client := THTTPClient.Create;
  try
    Client.CustomHeaders['User-Agent'] := 'PontoControlID-Updater';
    Client.CustomHeaders['Accept'] := 'application/vnd.github.v3+json';
    Client.HandleRedirects := True;
    Client.ConnectionTimeout := 5000;
    Client.ResponseTimeout := 8000;

    try
      Resp := Client.Get(URL);
      if Resp.StatusCode = 200 then
      begin
        JsonStr := Resp.ContentAsString(TEncoding.UTF8);
        JSONVal := TJSONObject.ParseJSONValue(JsonStr);
        if Assigned(JSONVal) and (JSONVal is TJSONObject) then
        begin
          try
            RootObj := JSONVal as TJSONObject;
            TagStr := RootObj.GetValue<string>('tag_name', '');
            AInfo.LatestVersion := LimparVersao(TagStr);
            AInfo.ReleaseName := RootObj.GetValue<string>('name', TagStr);
            AInfo.ReleaseNotes := RootObj.GetValue<string>('body', '');
            AInfo.PublishedAt := RootObj.GetValue<string>('published_at', '');

            // Localizar executável nos assets
            AssetsArr := RootObj.GetValue<TJSONArray>('assets');
            if Assigned(AssetsArr) then
            begin
              for I := 0 to AssetsArr.Count - 1 do
              begin
                AssetObj := AssetsArr.Items[I];
                if AssetObj is TJSONObject then
                begin
                  AssetName := (AssetObj as TJSONObject).GetValue<string>('name', '');
                  DownloadUrl := (AssetObj as TJSONObject).GetValue<string>('browser_download_url', '');
                  AssetSize := (AssetObj as TJSONObject).GetValue<Int64>('size', 0);

                  if SameText(ExtractFileExt(AssetName), '.exe') or (AInfo.DownloadUrl = '') then
                  begin
                    AInfo.AssetFileName := AssetName;
                    AInfo.DownloadUrl := DownloadUrl;
                    AInfo.AssetSize := AssetSize;
                    if SameText(ExtractFileExt(AssetName), '.exe') then
                      Break;
                  end;
                end;
              end;
            end;

            // Se encontrou release válida e versão é superior
            if (AInfo.LatestVersion <> '') and (AInfo.DownloadUrl <> '') then
            begin
              if CompararVersoes(AInfo.LatestVersion, APP_VERSION) > 0 then
              begin
                AInfo.HasUpdate := True;
                Result := True;
              end;
            end;
          finally
            JSONVal.Free;
          end;
        end;
      end;
    except
      Result := False;
    end;
  finally
    Client.Free;
  end;
end;

class procedure TfrmUpdate.ExecutarAtualizacao(AOwner: TComponent; const AInfo: TUpdateInfo);
var
  Frm: TfrmUpdate;
begin
  Frm := TfrmUpdate.Create(AOwner);
  try
    Frm.UpdateInfo := AInfo;
    Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

{ TfrmUpdate }

function TfrmUpdate.CriarBtn(AOriginal: TButton; const ACaption: string; AKind: TSkButtonKind): TSkModernButton;
begin
  Result := TSkModernButton.Create(Self);
  Result.Parent := AOriginal.Parent;
  Result.SetBounds(AOriginal.Left, AOriginal.Top, AOriginal.Width, AOriginal.Height);
  Result.Anchors := AOriginal.Anchors;
  Result.Caption := ACaption;
  Result.Kind := AKind;
  Result.Radius := 8;
  Result.FontSize := 11;
  Result.EmojiSize := 16;
  Result.OnClick := AOriginal.OnClick;
  AOriginal.Visible := False;
end;

procedure TfrmUpdate.FormCreate(Sender: TObject);
begin
  FDownloading := False;
  FCancelRequested := False;
  pbDownload.Position := 0;

  // Botões Skia com visual moderno
  FSkBaixar := CriarBtn(btnBaixar, '🚀 Baixar e Atualizar', sbkSuccess);
  FSkCancelar := CriarBtn(btnCancelar, 'Fechar', sbkDark);
end;

procedure TfrmUpdate.FormDestroy(Sender: TObject);
begin
  FCancelRequested := True;
end;

procedure TfrmUpdate.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FDownloading then
  begin
    if MessageDlg('O download da atualização está em andamento. Deseja cancelar?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      FCancelRequested := True;
      Action := caFree;
    end
    else
      Action := caNone;
  end;
end;

procedure TfrmUpdate.SetUpdateInfo(const Value: TUpdateInfo);
begin
  FUpdateInfo := Value;
  lblVersaoAtual.Caption := 'Versão Atual: v' + APP_VERSION;
  lblVersaoNova.Caption := 'Nova Versão: v' + FUpdateInfo.LatestVersion;

  if Trim(FUpdateInfo.ReleaseNotes) <> '' then
    memNotas.Text := FUpdateInfo.ReleaseNotes
  else
    memNotas.Text := 'Melhorias de desempenho, correções e novas funcionalidades disponíveis.';

  if FUpdateInfo.AssetSize > 0 then
    lblProgresso.Caption := Format('Arquivo: %s (%s) pronto para download.',
                                   [FUpdateInfo.AssetFileName, FormatarBytes(FUpdateInfo.AssetSize)])
  else
    lblProgresso.Caption := 'Pronto para iniciar download da atualização.';
end;

procedure TfrmUpdate.btnBaixarClick(Sender: TObject);
begin
  if FDownloading then Exit;
  IniciarDownload;
end;

procedure TfrmUpdate.btnCancelarClick(Sender: TObject);
begin
  if FDownloading then
  begin
    FCancelRequested := True;
    lblProgresso.Caption := 'Cancelando download...';
  end
  else
    Close;
end;

procedure TfrmUpdate.HttpReceiveData(const Sender: TObject; AContentLength: Int64; AReadCount: Int64; var AAbort: Boolean);
var
  Pct: Integer;
  TxtProgresso, TxtPct: string;
begin
  if FCancelRequested then
  begin
    AAbort := True;
    Exit;
  end;

  if AContentLength > 0 then
    Pct := Trunc((AReadCount / AContentLength) * 100)
  else
    Pct := 0;

  TxtProgresso := Format('Baixando: %s de %s', [FormatarBytes(AReadCount), FormatarBytes(AContentLength)]);
  TxtPct := Format('%d%%', [Pct]);

  TThread.Queue(nil,
    procedure
    begin
      pbDownload.Position := Pct;
      lblProgresso.Caption := TxtProgresso;
      lblPorcentagem.Caption := TxtPct;
    end);
end;

procedure TfrmUpdate.IniciarDownload;
var
  TargetUrl, DestPath: string;
begin
  FDownloading := True;
  FCancelRequested := False;
  btnBaixar.Enabled := False;
  if Assigned(FSkBaixar) then FSkBaixar.Enabled := False;
  btnCancelar.Caption := 'Cancelar';
  if Assigned(FSkCancelar) then FSkCancelar.Caption := 'Cancelar';

  TargetUrl := FUpdateInfo.DownloadUrl;
  DestPath := ExtractFilePath(ParamStr(0)) + 'PontoControlID_new.exe';

  TThread.CreateAnonymousThread(
    procedure
    var
      Client: THTTPClient;
      FileStream: TFileStream;
      Resp: IHTTPResponse;
      Success: Boolean;
      ErrMessage: string;
    begin
      Success := False;
      ErrMessage := '';
      Client := THTTPClient.Create;
      try
        Client.CustomHeaders['User-Agent'] := 'PontoControlID-Updater';
        Client.HandleRedirects := True;
        Client.ConnectionTimeout := 8000;
        Client.ResponseTimeout := 30000;
        Client.OnReceiveData := HttpReceiveData;

        try
          if FileExists(DestPath) then
            DeleteFile(DestPath);

          FileStream := TFileStream.Create(DestPath, fmCreate);
          try
            Resp := Client.Get(TargetUrl, FileStream);
            if (Resp.StatusCode = 200) and (not FCancelRequested) then
              Success := True
            else
              ErrMessage := Format('HTTP %d - %s', [Resp.StatusCode, Resp.StatusText]);
          finally
            FileStream.Free;
          end;
        except
          on E: Exception do
          begin
            Success := False;
            ErrMessage := E.Message;
          end;
        end;
      finally
        Client.Free;
      end;

      TThread.Queue(nil,
        procedure
        begin
          FDownloading := False;
          if Success then
          begin
            pbDownload.Position := 100;
            lblPorcentagem.Caption := '100%';
            lblProgresso.Caption := '✅ Download concluído! Reiniciando o sistema...';
            ConcluirAtualizacao(DestPath);
          end
          else
          begin
            btnBaixar.Enabled := True;
            if Assigned(FSkBaixar) then FSkBaixar.Enabled := True;
            btnCancelar.Caption := 'Fechar';
            if Assigned(FSkCancelar) then FSkCancelar.Caption := 'Fechar';

            if FCancelRequested then
              lblProgresso.Caption := 'Download cancelado pelo usuário.'
            else
              lblProgresso.Caption := '❌ Erro no download: ' + ErrMessage;

            if FileExists(DestPath) then
              DeleteFile(DestPath);
          end;
        end);
    end).Start;
end;

procedure TfrmUpdate.ConcluirAtualizacao(const ANovoExePath: string);
var
  BatPath, AppExePath, BatContent: string;
  BatFile: TStringList;
  AppPID: Cardinal;
begin
  AppExePath := ParamStr(0);
  BatPath := ExtractFilePath(AppExePath) + 'update_restart.bat';
  AppPID := GetCurrentProcessId;

  BatContent :=
    '@echo off' + sLineBreak +
    'timeout /t 1 /nobreak > nul' + sLineBreak +
    ':loop' + sLineBreak +
    Format('taskkill /F /PID %d > nul 2>&1', [AppPID]) + sLineBreak +
    Format('del "%s" > nul 2>&1', [AppExePath]) + sLineBreak +
    Format('if exist "%s" (', [AppExePath]) + sLineBreak +
    '    timeout /t 1 /nobreak > nul' + sLineBreak +
    '    goto loop' + sLineBreak +
    ')' + sLineBreak +
    Format('move /y "%s" "%s" > nul', [ANovoExePath, AppExePath]) + sLineBreak +
    Format('start "" "%s"', [AppExePath]) + sLineBreak +
    'del "%~f0"' + sLineBreak;

  BatFile := TStringList.Create;
  try
    BatFile.Text := BatContent;
    BatFile.SaveToFile(BatPath, TEncoding.ASCII);
  finally
    BatFile.Free;
  end;

  ShellExecute(0, 'open', PChar(BatPath), nil, nil, SW_HIDE);
  Application.Terminate;
end;

end.
