unit uPontoCalculoService;

interface

uses
  System.SysUtils, System.StrUtils, System.Classes, System.DateUtils, System.Math, System.Generics.Defaults, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Stan.Param, Data.DB, uDataModule;

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
    SaldoTotalMin: Integer;    // saldo final: extras - faltas + créditos de horas lançados
    CreditoHorasMin: Integer;  // créditos/débitos manuais (TB_PONTO_BANCO_HORAS) considerados no saldo
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

    if FResumo.CreditoHorasMin <> 0 then
      SB.AppendLine(Format('    <div class="card"><div>Crédito de horas lançado</div><div class="val %s">%s</div></div>',
        [IfThen(FResumo.CreditoHorasMin >= 0, 'val-pos', 'val-neg'),
         TPontoCalculoService.MinutosParaHora(FResumo.CreditoHorasMin, True)]));

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
  CargaSextaMin: Integer;
  Filtradas: TArray<TDateTime>;
  Feriados: TStringList;
  FeriadoDesc: string;
  BancoHoras: Boolean;
  CreditoMin: Integer;
  // Jornada por dia da semana (TB_PONTO_HORARIO_DIA), índice 1 = segunda ... 7 = domingo
  DiaCfgExiste, DiaCfgFolga: array[1..7] of Boolean;
  DiaCfgCarga: array[1..7] of Integer;
  DiaIso: Integer;

  function MinCampo(AQry: TFDQuery; const ACampo: string): Integer;
  var
    F: TField;
  begin
    Result := -1;
    F := AQry.FindField(ACampo);
    if (F <> nil) and (not F.IsNull) then
      Result := Round(Frac(F.AsDateTime) * 1440);
  end;

  // 'HH:MM' gravado em texto -> minutos (-1 quando vazio)
  function HoraOuNada(const S: string): Integer;
  begin
    if Pos(':', Trim(S)) > 0 then
      Result := TPontoCalculoService.HoraParaMinutos(S)
    else
      Result := -1;
  end;

  // Carga em minutos a partir dos horários (Entrada/Saída almoço/Volta/Saída)
  function CargaPorHorarios(E1, S1, E2, S2: Integer): Integer;
  begin
    Result := 0;
    if (E1 >= 0) and (S1 > E1) then
      Inc(Result, S1 - E1);
    if (E2 >= 0) and (S2 > E2) then
      Inc(Result, S2 - E2);
  end;

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
  BancoHoras := False;
  CargaSextaMin := -1;

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
      if QryHorario.FindField('HOR_BANCO_HORAS') <> nil then
        BancoHoras := (QryHorario.FieldByName('HOR_BANCO_HORAS').AsString = 'S');

      // Carga diária derivada dos horários cadastrados (seg-qui) e da saída
      // diferenciada da sexta-feira. Ex.: 08-12/13-18 = 9h; sexta até 17h = 8h.
      var E1 := MinCampo(QryHorario, 'HOR_ENTRADA_1');
      var S1 := MinCampo(QryHorario, 'HOR_SAIDA_1');
      var E2 := MinCampo(QryHorario, 'HOR_ENTRADA_2');
      var S2 := MinCampo(QryHorario, 'HOR_SAIDA_2');
      var XS2 := MinCampo(QryHorario, 'HOR_SEX_SAIDA_2');
      if CargaPorHorarios(E1, S1, E2, S2) > 0 then
        CargaDiariaMin := CargaPorHorarios(E1, S1, E2, S2);
      if XS2 >= 0 then
      begin
        if S2 >= 0 then
          CargaSextaMin := CargaPorHorarios(E1, S1, E2, XS2)
        else
          CargaSextaMin := CargaPorHorarios(E1, XS2, -1, -1);
      end;
      if CargaPorHorarios(MinCampo(QryHorario, 'HOR_SAB_ENTRADA_1'),
        MinCampo(QryHorario, 'HOR_SAB_SAIDA_1'), -1, -1) > 0 then
        SabCargaMin := CargaPorHorarios(MinCampo(QryHorario, 'HOR_SAB_ENTRADA_1'),
          MinCampo(QryHorario, 'HOR_SAB_SAIDA_1'), -1, -1);
    end;
  finally
    QryHorario.Free;
  end;
  Espelho.FResumo.JornadaDescricao := HorarioDesc;

  // 2b. Jornada por dia da semana gravada no cadastro (mesma regra do GoUp Ponto):
  //     dia configurado usa a própria carga ou folga; sem grade, valem os horários gerais.
  for DiaIso := 1 to 7 do
  begin
    DiaCfgExiste[DiaIso] := False;
    DiaCfgFolga[DiaIso] := False;
    DiaCfgCarga[DiaIso] := 0;
  end;
  try
    var QryDia := TFDQuery.Create(nil);
    try
      QryDia.Connection := dmDados.FDConnection;
      QryDia.SQL.Text := 'SELECT HDI_DIA_SEMANA, HDI_ENTRADA_1, HDI_SAIDA_1, HDI_ENTRADA_2, HDI_SAIDA_2, ' +
        'HDI_CARGA_MIN, HDI_FOLGA FROM TB_PONTO_HORARIO_DIA WHERE HDI_HORARIO = :H';
      QryDia.ParamByName('H').AsInteger := HorId;
      QryDia.Open;
      while not QryDia.Eof do
      begin
        DiaIso := QryDia.FieldByName('HDI_DIA_SEMANA').AsInteger;
        if (DiaIso >= 1) and (DiaIso <= 7) then
        begin
          DiaCfgExiste[DiaIso] := True;
          DiaCfgFolga[DiaIso] := (QryDia.FieldByName('HDI_FOLGA').AsString = 'S');
          DiaCfgCarga[DiaIso] := QryDia.FieldByName('HDI_CARGA_MIN').AsInteger;
          if (not DiaCfgFolga[DiaIso]) and (DiaCfgCarga[DiaIso] <= 0) then
            DiaCfgCarga[DiaIso] := CargaPorHorarios(
              HoraOuNada(QryDia.FieldByName('HDI_ENTRADA_1').AsString),
              HoraOuNada(QryDia.FieldByName('HDI_SAIDA_1').AsString),
              HoraOuNada(QryDia.FieldByName('HDI_ENTRADA_2').AsString),
              HoraOuNada(QryDia.FieldByName('HDI_SAIDA_2').AsString));
        end;
        QryDia.Next;
      end;
    finally
      QryDia.Free;
    end;
  except
    // Base sem a tabela de jornada por dia: segue com os horários gerais
  end;

  // 2c. Créditos de horas lançados (saldo de sistema anterior, ajustes, pagamentos, folgas):
  //     os do período entram no saldo; com banco de horas, os anteriores formam o saldo acumulado.
  //     Créditos/débitos apurados no fechamento (C/D) não entram: são o próprio cálculo.
  CreditoMin := 0;
  try
    var QryBh := TFDQuery.Create(nil);
    try
      QryBh.Connection := dmDados.FDConnection;
      QryBh.SQL.Text := 'SELECT BH_DATA, BH_MINUTOS, BH_TIPO FROM TB_PONTO_BANCO_HORAS ' +
        'WHERE BH_PESSOA = :P AND BH_DATA <= :F';
      QryBh.ParamByName('P').AsInteger := APessoaId;
      QryBh.ParamByName('F').AsDate := Trunc(ADataFim);
      QryBh.Open;
      while not QryBh.Eof do
      begin
        if Trunc(QryBh.FieldByName('BH_DATA').AsDateTime) < Trunc(ADataIni) then
        begin
          if BancoHoras then
            Inc(CreditoMin, QryBh.FieldByName('BH_MINUTOS').AsInteger);
        end
        else if (QryBh.FieldByName('BH_TIPO').AsString <> 'C') and (QryBh.FieldByName('BH_TIPO').AsString <> 'D') then
          Inc(CreditoMin, QryBh.FieldByName('BH_MINUTOS').AsInteger);
        QryBh.Next;
      end;
    finally
      QryBh.Free;
    end;
  except
    // Base sem a tabela de banco de horas: sem créditos
  end;

  // 3. Obter Marcacoes no Periodo
  QryMarcacoes := dmDados.GetMarcacoes(ADataIni, ADataFim, 0, APessoaId, True);

  // 4. Obter Justificativas no Periodo
  QryJus := dmDados.GetJustificativasPeriodo(APessoaId, ADataIni, ADataFim);

  // 5. Feriados (tabela cadastrada pelo módulo de feriados; chave 'dd/mm' para
  //    recorrentes e 'dd/mm/yyyy' para datas fixas)
  Feriados := TStringList.Create;
  try
    var QryFer := TFDQuery.Create(nil);
    try
      QryFer.Connection := dmDados.FDConnection;
      QryFer.SQL.Text :=
        'SELECT FER_DATA, FER_DESCRICAO, COALESCE(FER_RECORRENTE, ''S'') AS REC FROM TB_PONTO_FERIADO';
      QryFer.Open;
      while not QryFer.Eof do
      begin
        if QryFer.FieldByName('REC').AsString = 'S' then
          Feriados.Values[FormatDateTime('dd/mm', QryFer.FieldByName('FER_DATA').AsDateTime)] :=
            QryFer.FieldByName('FER_DESCRICAO').AsString
        else
          Feriados.Values[FormatDateTime('dd/mm/yyyy', QryFer.FieldByName('FER_DATA').AsDateTime)] :=
            QryFer.FieldByName('FER_DESCRICAO').AsString;
        QryFer.Next;
      end;
    finally
      QryFer.Free;
    end;
  except
    // Banco sem a tabela de feriados: segue sem considerar feriados
  end;

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
          if (DayOfWeek(DataCur) = 6) and (CargaSextaMin > 0) then
            DiaItem.CargaPrevistaMin := CargaSextaMin;
          Inc(TotalUteis);
        end;
      end;

      // Jornada específica do dia da semana (DayOfTheWeek: 1 = segunda ... 7 = domingo)
      DiaIso := DayOfTheWeek(DataCur);
      if DiaCfgExiste[DiaIso] then
      begin
        if DiaItem.CargaPrevistaMin > 0 then
          Dec(TotalUteis);
        if DiaCfgFolga[DiaIso] then
        begin
          DiaItem.CargaPrevistaMin := 0;
          if DiaIso = 7 then
          begin
            DiaItem.TipoDia := tdDomingoDSR;
            DiaItem.Ocorrencia := 'DSR / Folga';
          end
          else if (DiaIso = 6) and CompensaSabado then
          begin
            DiaItem.TipoDia := tdSabadoCompensado;
            DiaItem.Ocorrencia := 'Sabado Compensado';
          end
          else
          begin
            DiaItem.TipoDia := tdFolga;
            DiaItem.Ocorrencia := 'Folga semanal';
          end;
        end
        else
        begin
          DiaItem.CargaPrevistaMin := DiaCfgCarga[DiaIso];
          DiaItem.Ocorrencia := '';
          if DiaIso = 6 then
            DiaItem.TipoDia := tdSabadoTrabalhado
          else
            DiaItem.TipoDia := tdUtil;
          if DiaItem.CargaPrevistaMin > 0 then
            Inc(TotalUteis);
        end;
      end;

      // Feriado: sem carga prevista (horas trabalhadas viram extra)
      FeriadoDesc := Feriados.Values[FormatDateTime('dd/mm/yyyy', DataCur)];
      if FeriadoDesc = '' then
        FeriadoDesc := Feriados.Values[FormatDateTime('dd/mm', DataCur)];
      if (FeriadoDesc <> '') and (DiaItem.CargaPrevistaMin > 0) then
      begin
        DiaItem.TipoDia := tdFeriado;
        DiaItem.CargaPrevistaMin := 0;
        DiaItem.Ocorrencia := 'Feriado (' + FeriadoDesc + ')';
        Dec(TotalUteis);
      end;

      // Dias futuros não têm carga nem falta (antes inflavam o resumo)
      if DataCur > Date then
      begin
        if DiaItem.CargaPrevistaMin > 0 then
          Dec(TotalUteis);
        DiaItem.CargaPrevistaMin := 0;
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

      // Descarta leituras repetidas (menos de 10 min da anterior), que
      // deslocariam os pares Entrada/Saída e distorceriam as horas.
      SetLength(Filtradas, 0);
      for I := 0 to High(BatidasDia) do
        if (Length(Filtradas) = 0) or
           (MinutesBetween(BatidasDia[I], Filtradas[High(Filtradas)]) >= 10) then
        begin
          SetLength(Filtradas, Length(Filtradas) + 1);
          Filtradas[High(Filtradas)] := BatidasDia[I];
        end;
      BatidasDia := Filtradas;

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
            // O abono cobre só o que faltou para a carga do dia. Antes, um
            // atestado de meio período abonava o dia inteiro e as horas
            // trabalhadas viravam hora extra.
            if (AbonoMin <= 0) or (AbonoMin > DiaItem.CargaPrevistaMin - DiaItem.TrabalhadoMin) then
              AbonoMin := DiaItem.CargaPrevistaMin - DiaItem.TrabalhadoMin;
            if AbonoMin < 0 then
              AbonoMin := 0;

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
      // (hoje sem batidas ainda não é falta: o expediente pode não ter começado)
      if (DiaItem.CargaPrevistaMin > 0) and (NumBatidas = 0) and (not TemJus) and
         (DataCur < Date) then
      begin
        DiaItem.FaltaMin := DiaItem.CargaPrevistaMin;
        DiaItem.Ocorrencia := 'Falta Nao Justificada';
        Inc(TotalFalt);
      end;

      // Hoje, com expediente ainda em andamento (sem batida ou batida ímpar),
      // não lança falta parcial: ela só é apurada depois que o dia termina.
      if (DataCur = Date) and ((NumBatidas = 0) or Odd(NumBatidas)) then
        DiaItem.FaltaMin := 0;

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
    Feriados.Free;
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
  Espelho.FResumo.CreditoHorasMin := CreditoMin;
  Espelho.FResumo.SaldoTotalMin := TotExt - TotFalt + CreditoMin;
end;

end.
