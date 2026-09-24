unit uPontoCalculoService;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math, System.Generics.Defaults, System.Generics.Collections,
  FireDAC.Comp.Client, Data.DB, uDataModule;

type
  TTipoDia = (tdUtil, tdSabadoCompensado, tdSabadoTrabalhado, tdDomingoDSR, tdFeriado, tdFolga);

  TDiaEspelho = record
    Data: TDateTime;
    DiaSemana: string;
    TipoDia: TTipoDia;
    Entrada1: string;
    Saida1: string;
    Entrada2: string;
    Saida2: string;
    BatidasExtras: string;
    CargaPrevistaMin: Integer;
    TrabalhadoMin: Integer;
    ExtraMin: Integer;
    FaltaMin: Integer;
    SaldoMin: Integer;
    Ocorrencia: string;
    Justificativa: string;
    function CargaPrevistaStr: string;
    function TrabalhadoStr: string;
    function ExtraStr: string;
    function FaltaStr: string;
    function SaldoStr: string;
  end;

  TResumoEspelho = record
    ColaboradorNome: string;
    ColaboradorCPF: string;
    ColaboradorPIS: string;
    ColaboradorMatricula: string;
    ColaboradorFuncao: string;
    JornadaDescricao: string;
    TotalDiasPeriodo: Integer;
    TotalDiasUteis: Integer;
    TotalDiasTrabalhados: Integer;
    TotalFaltas: Integer;
    TotalPrevistoMin: Integer;
    TotalTrabalhadoMin: Integer;
    TotalExtrasMin: Integer;
    TotalFaltasMin: Integer;
    SaldoTotalMin: Integer;
    function TotalPrevistoStr: string;
    function TotalTrabalhadoStr: string;
    function TotalExtrasStr: string;
    function TotalFaltasStr: string;
    function SaldoTotalStr: string;
  end;

  TEspelhoPonto = class
  private
    FDias: TArray<TDiaEspelho>;
    FResumo: TResumoEspelho;
  public
    property Dias: TArray<TDiaEspelho> read FDias write FDias;
    property Resumo: TResumoEspelho read FResumo write FResumo;
    function GerarRelatorioHTML(const ARazaoEmpresa, ACnpjEmpresa: string): string;
  end;

  TPontoCalculoService = class
  public
    class function MinutosParaHora(AMinutos: Integer; AExibirSinal: Boolean = False): string;
    class function HoraParaMinutos(const AHoraStr: string): Integer;
    class function CalcularEspelho(APessoaId: Integer; ADataIni, ADataFim: TDateTime): TEspelhoPonto;
  end;

implementation

{ Funcoes Utilitarias }

class function TPontoCalculoService.MinutosParaHora(AMinutos: Integer; AExibirSinal: Boolean): string;
var
  H, M: Integer;
  Sinal: string;
  AbsMin: Integer;
begin
  if AMinutos = 0 then
  begin
    Result := '00:00';
    Exit;
  end;

  if AMinutos < 0 then
    Sinal := '-'
  else if AExibirSinal and (AMinutos > 0) then
    Sinal := '+'
  else
    Sinal := '';

  AbsMin := Abs(AMinutos);
  H := AbsMin div 60;
  M := AbsMin mod 60;
  Result := Format('%s%.2d:%.2d', [Sinal, H, M]);
end;

class function TPontoCalculoService.HoraParaMinutos(const AHoraStr: string): Integer;
var
  P: Integer;
  H, M: Integer;
  S: string;
begin
  Result := 0;
  S := Trim(AHoraStr);
  if S = '' then
    Exit;

  P := Pos(':', S);
  if P > 0 then
  begin
    H := StrToIntDef(Copy(S, 1, P - 1), 0);
    M := StrToIntDef(Copy(S, P + 1, 2), 0);
    Result := (H * 60) + M;
  end;
end;

{ TDiaEspelho }

function TDiaEspelho.CargaPrevistaStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(CargaPrevistaMin);
end;

function TDiaEspelho.TrabalhadoStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(TrabalhadoMin);
end;

function TDiaEspelho.ExtraStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(ExtraMin);
end;

function TDiaEspelho.FaltaStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(FaltaMin);
end;

function TDiaEspelho.SaldoStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(SaldoMin, True);
end;

{ TResumoEspelho }

function TResumoEspelho.TotalPrevistoStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(TotalPrevistoMin);
end;

function TResumoEspelho.TotalTrabalhadoStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(TotalTrabalhadoMin);
end;

function TResumoEspelho.TotalExtrasStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(TotalExtrasMin);
end;

function TResumoEspelho.TotalFaltasStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(TotalFaltasMin);
end;

function TResumoEspelho.SaldoTotalStr: string;
begin
  Result := TPontoCalculoService.MinutosParaHora(SaldoTotalMin, True);
end;

{ TEspelhoPonto }

function TEspelhoPonto.GerarRelatorioHTML(const ARazaoEmpresa, ACnpjEmpresa: string): string;
var
  SB: TStringBuilder;
  I: Integer;
  CorLinha, CorSaldo: string;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('<!DOCTYPE html>');
    SB.AppendLine('<html lang="pt-BR">');
    SB.AppendLine('<head>');
    SB.AppendLine('  <meta charset="UTF-8">');
    SB.AppendLine('  <title>Espelho de Ponto Eletrônico - Portaria 671 MTE</title>');
    SB.AppendLine('  <style>');
    SB.AppendLine('    body { font-family: Segoe UI, Arial, sans-serif; font-size: 12px; color: #222; margin: 20px; }');
    SB.AppendLine('    .header { border-bottom: 2px solid #2b579a; padding-bottom: 8px; margin-bottom: 15px; }');
    SB.AppendLine('    .header h2 { margin: 0 0 4px 0; color: #1e395b; }');
    SB.AppendLine('    .header p { margin: 2px 0; font-size: 11px; color: #555; }');
    SB.AppendLine('    .info-box { background: #f4f6f9; border: 1px solid #d5dbe3; border-radius: 4px; padding: 10px; margin-bottom: 15px; }');
    SB.AppendLine('    .info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }');
    SB.AppendLine('    .info-item b { color: #333; }');
    SB.AppendLine('    table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }');
    SB.AppendLine('    th { background: #2b579a; color: #fff; padding: 6px 4px; text-align: center; font-size: 11px; }');
    SB.AppendLine('    td { border: 1px solid #e1e4e8; padding: 5px 4px; text-align: center; font-size: 11px; }');
    SB.AppendLine('    tr:nth-child(even) { background-color: #fcfcfc; }');
    SB.AppendLine('    .dsr { background-color: #f7f7f7 !important; color: #888; }');
    SB.AppendLine('    .falta { background-color: #fef0f0 !important; color: #c53030; font-weight: bold; }');
    SB.AppendLine('    .extra { color: #2e7d32; font-weight: bold; }');
    SB.AppendLine('    .impar { background-color: #fff9db !important; color: #d97706; font-weight: bold; }');
    SB.AppendLine('    .resumo-box { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; margin-bottom: 30px; }');
    SB.AppendLine('    .card { background: #fff; border: 1px solid #d0d7de; border-radius: 6px; padding: 10px; text-align: center; }');
    SB.AppendLine('    .card .val { font-size: 18px; font-weight: bold; margin-top: 4px; }');
    SB.AppendLine('    .val-pos { color: #2e7d32; }');
    SB.AppendLine('    .val-neg { color: #c53030; }');
    SB.AppendLine('    .signatures { display: grid; grid-template-columns: 1fr 1fr; gap: 60px; margin-top: 40px; text-align: center; }');
    SB.AppendLine('    .sign-line { border-top: 1px solid #333; padding-top: 5px; margin-top: 40px; }');
    SB.AppendLine('    @media print { button { display: none; } body { margin: 0; } }');
    SB.AppendLine('  </style>');
    SB.AppendLine('</head>');
    SB.AppendLine('<body>');

    SB.AppendLine('  <div style="text-align: right; margin-bottom: 10px;">');
    SB.AppendLine('    <button onclick="window.print()" style="padding: 8px 16px; background: #2b579a; color: #fff; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;">Imprimir Espelho de Ponto</button>');
    SB.AppendLine('  </div>');

    SB.AppendLine('  <div class="header">');
    SB.AppendLine('    <h2>ESPELHO DE PONTO ELETRÔNICO</h2>');
    SB.AppendLine(Format('    <p><b>Empregador:</b> %s &nbsp;&nbsp;|&nbsp;&nbsp; <b>CNPJ:</b> %s</p>', [ARazaoEmpresa, ACnpjEmpresa]));
    SB.AppendLine('    <p>Relatório gerado em conformidade com as diretrizes da Portaria MTE 671/2021.</p>');
    SB.AppendLine('  </div>');

    SB.AppendLine('  <div class="info-box">');
    SB.AppendLine('    <div class="info-grid">');
    SB.AppendLine(Format('      <div class="info-item"><b>Colaborador:</b> %s</div>', [FResumo.ColaboradorNome]));
    SB.AppendLine(Format('      <div class="info-item"><b>CPF:</b> %s</div>', [FResumo.ColaboradorCPF]));
    SB.AppendLine(Format('      <div class="info-item"><b>PIS:</b> %s</div>', [FResumo.ColaboradorPIS]));
    SB.AppendLine(Format('      <div class="info-item"><b>Matrícula:</b> %s</div>', [FResumo.ColaboradorMatricula]));
    SB.AppendLine(Format('      <div class="info-item"><b>Função/Cargo:</b> %s</div>', [FResumo.ColaboradorFuncao]));
    SB.AppendLine(Format('      <div class="info-item"><b>Jornada:</b> %s</div>', [FResumo.JornadaDescricao]));
    SB.AppendLine('    </div>');
    SB.AppendLine('  </div>');

    SB.AppendLine('  <table>');
    SB.AppendLine('    <thead>');
    SB.AppendLine('      <tr>');
    SB.AppendLine('        <th>Data</th>');
    SB.AppendLine('        <th>Dia</th>');
    SB.AppendLine('        <th>1ª Ent</th>');
    SB.AppendLine('        <th>1ª Saí</th>');
    SB.AppendLine('        <th>2ª Ent</th>');
    SB.AppendLine('        <th>2ª Saí</th>');
    SB.AppendLine('        <th>Outras</th>');
    SB.AppendLine('        <th>Previsto</th>');
    SB.AppendLine('        <th>Realizado</th>');
    SB.AppendLine('        <th>Extras</th>');
    SB.AppendLine('        <th>Faltas</th>');
    SB.AppendLine('        <th>Saldo</th>');
    SB.AppendLine('        <th>Ocorrência / Justificativa</th>');
    SB.AppendLine('      </tr>');
    SB.AppendLine('    </thead>');
    SB.AppendLine('    <tbody>');

    for I := 0 to High(FDias) do
    begin
      CorLinha := '';
      if FDias[I].TipoDia in [tdDomingoDSR, tdSabadoCompensado] then
        CorLinha := ' class="dsr"'
      else if Pos('Ímpar', FDias[I].Ocorrencia) > 0 then
        CorLinha := ' class="impar"'
      else if (FDias[I].FaltaMin > 0) and (FDias[I].TrabalhadoMin = 0) then
        CorLinha := ' class="falta"';

      CorSaldo := '';
      if FDias[I].SaldoMin > 0 then
        CorSaldo := ' class="extra"'
      else if FDias[I].SaldoMin < 0 then
        CorSaldo := ' style="color: #c53030; font-weight: bold;"';

      SB.AppendLine(Format('      <tr%s>', [CorLinha]));
      SB.AppendLine(Format('        <td>%s</td>', [FormatDateTime('dd/mm/yyyy', FDias[I].Data)]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].DiaSemana]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].Entrada1]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].Saida1]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].Entrada2]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].Saida2]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].BatidasExtras]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].CargaPrevistaStr]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].TrabalhadoStr]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].ExtraStr]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].FaltaStr]));
      SB.AppendLine(Format('        <td%s>%s</td>', [CorSaldo, FDias[I].SaldoStr]));
      SB.AppendLine(Format('        <td>%s</td>', [FDias[I].Ocorrencia]));
      SB.AppendLine('      </tr>');
    end;

    SB.AppendLine('    </tbody>');
    SB.AppendLine('  </table>');

    SB.AppendLine('  <div class="resumo-box">');
    SB.AppendLine(Format('    <div class="card"><div>Previsto Total</div><div class="val">%s</div></div>', [FResumo.TotalPrevistoStr]));
    SB.AppendLine(Format('    <div class="card"><div>Realizado Total</div><div class="val">%s</div></div>', [FResumo.TotalTrabalhadoStr]));
    SB.AppendLine(Format('    <div class="card"><div>Horas Extras</div><div class="val val-pos">+%s</div></div>', [FResumo.TotalExtrasStr]));
    SB.AppendLine(Format('    <div class="card"><div>Faltas / Atrasos</div><div class="val val-neg">-%s</div></div>', [FResumo.TotalFaltasStr]));

    if FResumo.SaldoTotalMin >= 0 then
      SB.AppendLine(Format('    <div class="card"><div>Saldo do Período</div><div class="val val-pos">%s</div></div>', [FResumo.SaldoTotalStr]))
    else
      SB.AppendLine(Format('    <div class="card"><div>Saldo do Período</div><div class="val val-neg">%s</div></div>', [FResumo.SaldoTotalStr]));

    SB.AppendLine('  </div>');

    SB.AppendLine('  <div class="signatures">');
    SB.AppendLine('    <div><div class="sign-line">Assinatura do Colaborador</div></div>');
    SB.AppendLine('    <div><div class="sign-line">Assinatura do Gestor / RH</div></div>');
    SB.AppendLine('  </div>');

    SB.AppendLine('</body>');
    SB.AppendLine('</html>');

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

{ TPontoCalculoService - Motor de Apuracao }

class function TPontoCalculoService.CalcularEspelho(APessoaId: Integer; ADataIni, ADataFim: TDateTime): TEspelhoPonto;
var
  Espelho: TEspelhoPonto;
  QryPessoa, QryHorario, QryMarcacoes, QryJus: TFDQuery;
  HorId, ToleranciaMin, CargaDiariaMin: Integer;
  CompensaSabado, TrabalhaSabado: Boolean;
  SabCargaMin: Integer;
  DataCur: TDateTime;
  DiaItem: TDiaEspelho;
  HorarioDesc: string;
  BatidasDia: TArray<TDateTime>;
  TotalDias, TotalUteis, TotalTrab, TotalFalt: Integer;
  TotPrev, TotTrab, TotExt, TotFalt: Integer;
  I, NumBatidas, Pares: Integer;
  DuracaoPar: Integer;
  Diff, AbonoMin: Integer;
  TemJus: Boolean;
  JusTipo, JusMotivo: string;
begin
  Espelho := TEspelhoPonto.Create;
  Result := Espelho;

  if (APessoaId <= 0) or (ADataIni > ADataFim) then
    Exit;

  // 1. Obter dados da Pessoa / Colaborador
  QryPessoa := dmDados.GetPessoaPorId(APessoaId);
  try
    if QryPessoa.IsEmpty then
      Exit;

    Espelho.FResumo.ColaboradorNome := QryPessoa.FieldByName('PES_RSOCIAL_NOME').AsString;
    Espelho.FResumo.ColaboradorCPF := QryPessoa.FieldByName('COL_CPF').AsString;
    if Espelho.FResumo.ColaboradorCPF = '' then
      Espelho.FResumo.ColaboradorCPF := QryPessoa.FieldByName('PES_CNPJ_CPF').AsString;
    Espelho.FResumo.ColaboradorPIS := QryPessoa.FieldByName('COL_PIS').AsString;
    Espelho.FResumo.ColaboradorMatricula := QryPessoa.FieldByName('COL_CARTAO_PONTO').AsString;
    Espelho.FResumo.ColaboradorFuncao := QryPessoa.FieldByName('COL_FUNCAO').AsString;

    HorId := QryPessoa.FieldByName('COL_HORARIO').AsInteger;
    if HorId <= 0 then
      HorId := 1; // Padrao Comercial
  finally
    QryPessoa.Free;
  end;

  // 2. Obter Jornada de Trabalho
  ToleranciaMin := 10;
  CargaDiariaMin := 528; // 8h48
  CompensaSabado := True;
  TrabalhaSabado := False;
  SabCargaMin := 240;
  HorarioDesc := 'Comercial 44h (Padrao)';

  QryHorario := dmDados.GetHorarioPorId(HorId);
  try
    if not QryHorario.IsEmpty then
    begin
      HorarioDesc := QryHorario.FieldByName('HOR_DESCRICAO').AsString;
      ToleranciaMin := QryHorario.FieldByName('HOR_TOLERANCIA_MIN').AsInteger;
      if ToleranciaMin <= 0 then ToleranciaMin := 10;
      CargaDiariaMin := QryHorario.FieldByName('HOR_CARGA_DIARIA_MIN').AsInteger;
      if CargaDiariaMin <= 0 then CargaDiariaMin := 528;
      CompensaSabado := (QryHorario.FieldByName('HOR_COMPENSA_SABADO').AsString = 'S');
      TrabalhaSabado := (QryHorario.FieldByName('HOR_TRABALHA_SABADO').AsString = 'S');
    end;
  finally
    QryHorario.Free;
  end;
  Espelho.FResumo.JornadaDescricao := HorarioDesc;

  // 3. Obter Marcacoes no Periodo
  QryMarcacoes := dmDados.GetMarcacoes(ADataIni, ADataFim, 0, APessoaId);

  // 4. Obter Justificativas no Periodo
  QryJus := dmDados.GetJustificativasPeriodo(APessoaId, ADataIni, ADataFim);

  TotalDias := 0;
  TotalUteis := 0;
  TotalTrab := 0;
  TotalFalt := 0;
  TotPrev := 0;
  TotTrab := 0;
  TotExt := 0;
  TotFalt := 0;

  try
    DataCur := Trunc(ADataIni);
    while DataCur <= Trunc(ADataFim) do
    begin
      Inc(TotalDias);
      FillChar(DiaItem, SizeOf(DiaItem), 0);
      DiaItem.Data := DataCur;

      // Definir dia da semana e carga prevista
      case DayOfWeek(DataCur) of
        1: // Domingo
        begin
          DiaItem.DiaSemana := 'Dom';
          DiaItem.TipoDia := tdDomingoDSR;
          DiaItem.CargaPrevistaMin := 0;
          DiaItem.Ocorrencia := 'DSR / Folga';
        end;
        7: // Sabado
        begin
          DiaItem.DiaSemana := 'Sab';
          if TrabalhaSabado then
          begin
            DiaItem.TipoDia := tdSabadoTrabalhado;
            DiaItem.CargaPrevistaMin := SabCargaMin;
            Inc(TotalUteis);
          end
          else
          begin
            DiaItem.TipoDia := tdSabadoCompensado;
            DiaItem.CargaPrevistaMin := 0;
            DiaItem.Ocorrencia := 'Sabado Compensado';
          end;
        end;
      else
        // Segunda a Sexta
        begin
          case DayOfWeek(DataCur) of
            2: DiaItem.DiaSemana := 'Seg';
            3: DiaItem.DiaSemana := 'Ter';
            4: DiaItem.DiaSemana := 'Qua';
            5: DiaItem.DiaSemana := 'Qui';
            6: DiaItem.DiaSemana := 'Sex';
          end;
          DiaItem.TipoDia := tdUtil;
          DiaItem.CargaPrevistaMin := CargaDiariaMin;
          Inc(TotalUteis);
        end;
      end;

      // Filtrar batidas do dia
      SetLength(BatidasDia, 0);
      if QryMarcacoes.Active and (not QryMarcacoes.IsEmpty) then
      begin
        QryMarcacoes.First;
        while not QryMarcacoes.Eof do
        begin
          if Trunc(QryMarcacoes.FieldByName('PMA_DATA_HORA').AsDateTime) = DataCur then
          begin
            SetLength(BatidasDia, Length(BatidasDia) + 1);
            BatidasDia[High(BatidasDia)] := QryMarcacoes.FieldByName('PMA_DATA_HORA').AsDateTime;
          end;
          QryMarcacoes.Next;
        end;
      end;

      // Ordenar batidas do dia
      if Length(BatidasDia) > 1 then
      begin
        TArray.Sort<TDateTime>(BatidasDia, TComparer<TDateTime>.Construct(
          function(const L, R: TDateTime): Integer
          begin
            Result := CompareDateTime(L, R);
          end));
      end;

      NumBatidas := Length(BatidasDia);
      if NumBatidas > 0 then
      begin
        DiaItem.Entrada1 := FormatDateTime('hh:nn', BatidasDia[0]);
        if NumBatidas >= 2 then
          DiaItem.Saida1 := FormatDateTime('hh:nn', BatidasDia[1]);
        if NumBatidas >= 3 then
          DiaItem.Entrada2 := FormatDateTime('hh:nn', BatidasDia[2]);
        if NumBatidas >= 4 then
          DiaItem.Saida2 := FormatDateTime('hh:nn', BatidasDia[3]);

        if NumBatidas > 4 then
        begin
          DiaItem.BatidasExtras := '';
          for I := 4 to NumBatidas - 1 do
          begin
            if DiaItem.BatidasExtras <> '' then
              DiaItem.BatidasExtras := DiaItem.BatidasExtras + ' ';
            DiaItem.BatidasExtras := DiaItem.BatidasExtras + FormatDateTime('hh:nn', BatidasDia[I]);
          end;
        end;

        // Calcular minutos trabalhados por pares
        DiaItem.TrabalhadoMin := 0;
        Pares := NumBatidas div 2;
        for I := 0 to Pares - 1 do
        begin
          DuracaoPar := MinutesBetween(BatidasDia[(I * 2) + 1], BatidasDia[I * 2]);
          DiaItem.TrabalhadoMin := DiaItem.TrabalhadoMin + DuracaoPar;
        end;

        if (NumBatidas mod 2) <> 0 then
        begin
          if DiaItem.Ocorrencia = '' then
            DiaItem.Ocorrencia := 'Marcacao Impar';
        end;

        Inc(TotalTrab);
      end;

      // Verificar justificativas
      TemJus := False;
      AbonoMin := 0;
      if QryJus.Active and (not QryJus.IsEmpty) then
      begin
        QryJus.First;
        while not QryJus.Eof do
        begin
          if Trunc(QryJus.FieldByName('JUS_DATA').AsDateTime) = DataCur then
          begin
            TemJus := True;
            JusTipo := QryJus.FieldByName('JUS_TIPO').AsString;
            JusMotivo := QryJus.FieldByName('JUS_MOTIVO').AsString;
            AbonoMin := QryJus.FieldByName('JUS_ABONO_MINUTOS').AsInteger;
            if AbonoMin <= 0 then
              AbonoMin := DiaItem.CargaPrevistaMin;

            DiaItem.Ocorrencia := JusTipo;
            if JusMotivo <> '' then
              DiaItem.Ocorrencia := DiaItem.Ocorrencia + ' (' + JusMotivo + ')';
            Break;
          end;
          QryJus.Next;
        end;
      end;

      // Calcular Horas Extras e Faltas
      Diff := (DiaItem.TrabalhadoMin + AbonoMin) - DiaItem.CargaPrevistaMin;
      if Diff > 0 then
      begin
        if Diff > ToleranciaMin then
          DiaItem.ExtraMin := Diff
        else
          DiaItem.ExtraMin := 0;
        DiaItem.FaltaMin := 0;
      end
      else if Diff < 0 then
      begin
        if Abs(Diff) > ToleranciaMin then
          DiaItem.FaltaMin := Abs(Diff)
        else
          DiaItem.FaltaMin := 0;
        DiaItem.ExtraMin := 0;
      end
      else
      begin
        DiaItem.ExtraMin := 0;
        DiaItem.FaltaMin := 0;
      end;

      // Caso dia util sem marcacao e sem justificativa -> Falta Total
      if (DiaItem.CargaPrevistaMin > 0) and (NumBatidas = 0) and (not TemJus) then
      begin
        DiaItem.FaltaMin := DiaItem.CargaPrevistaMin;
        DiaItem.Ocorrencia := 'Falta Nao Justificada';
        Inc(TotalFalt);
      end;

      // Saldo do dia
      DiaItem.SaldoMin := DiaItem.ExtraMin - DiaItem.FaltaMin;

      // Acumular Totais do Periodo
      TotPrev := TotPrev + DiaItem.CargaPrevistaMin;
      TotTrab := TotTrab + DiaItem.TrabalhadoMin;
      TotExt := TotExt + DiaItem.ExtraMin;
      TotFalt := TotFalt + DiaItem.FaltaMin;

      // Adicionar dia ao espelho
      SetLength(Espelho.FDias, Length(Espelho.FDias) + 1);
      Espelho.FDias[High(Espelho.FDias)] := DiaItem;

      DataCur := IncDay(DataCur, 1);
    end;
  finally
    QryMarcacoes.Free;
    QryJus.Free;
  end;

  // Atualizar Resumo Final
  Espelho.FResumo.TotalDiasPeriodo := TotalDias;
  Espelho.FResumo.TotalDiasUteis := TotalUteis;
  Espelho.FResumo.TotalDiasTrabalhados := TotalTrab;
  Espelho.FResumo.TotalFaltas := TotalFalt;
  Espelho.FResumo.TotalPrevistoMin := TotPrev;
  Espelho.FResumo.TotalTrabalhadoMin := TotTrab;
  Espelho.FResumo.TotalExtrasMin := TotExt;
  Espelho.FResumo.TotalFaltasMin := TotFalt;
  Espelho.FResumo.SaldoTotalMin := TotExt - TotFalt;
end;

end.
