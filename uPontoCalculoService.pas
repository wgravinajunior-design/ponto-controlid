unit uPontoCalculoService;

// Motor de apuração do espelho de ponto. Segue as mesmas regras do GoUp Ponto (Flutter):
// jornada por dia da semana, escalas 12x36 e ciclo, banco de horas, afastamentos, vínculo
// (admissão/demissão), tolerância (CLT art. 58 §1º), adicional noturno com prorrogação
// (Súmula 60 TST), intervalo intrajornada (art. 71), interjornada (art. 66), limite de
// extras (art. 59) e perda de DSR/feriado por falta na semana (Lei 605/49, art. 6º).

interface

uses
  System.SysUtils, System.StrUtils, System.Classes, System.DateUtils, System.Math, System.IniFiles,
  System.Generics.Defaults, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Stan.Param, Data.DB, uConfig, uDataModule;

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
    NoturnoMin: Integer;               // 22h às 5h (relógio), com prorrogação (Súmula 60)
    AbonoMin: Integer;
    IntervaloMin: Integer;             // intervalo intrajornada usufruído
    IntervaloSuprimidoMin: Integer;    // art. 71 §4º
    InterjornadaFaltanteMin: Integer;  // art. 66 (11h entre jornadas)
    FaltaDiaInteiro: Boolean;          // dia previsto sem batida e sem justificativa
    Impar: Boolean;                    // número ímpar de batidas
    DsrDescontado: Boolean;            // DSR/feriado perdido por falta na semana (Lei 605/49, art. 6º)
    Extra100: Boolean;                 // domingo, feriado ou folga da escala
    ForaContrato: Boolean;             // antes da admissão ou depois da demissão
    Afastamento: string;               // férias, licença, INSS...
    Feriado: string;
    Alertas: string;
    Justificativa: string;
    function Ocorrencia: string;
    procedure AddAlerta(const AAlerta: string);
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
    TotalExtras50Min: Integer;
    TotalExtras100Min: Integer;
    TotalExtrasFaixa2Min: Integer;     // extras em dias normais acima da 1ª faixa (convenção coletiva)
    TotalNoturnoMin: Integer;
    TotalAtrasosMin: Integer;
    TotalAbonadoMin: Integer;
    TotalIntervaloSuprimidoMin: Integer;
    TotalInterjornadaMin: Integer;
    DsrDescontados: Integer;           // domingos perdidos por falta injustificada na semana
    DiasExtraAcima2h: Integer;
    TotalFeriadosTrabalhados: Integer;
    TotalFeriados: Integer;            // feriados do período (carga zerada: não descontam do total)
    FeriadosDescontados: Integer;      // feriados perdidos por falta injustificada na semana
    DiasAfastado: Integer;
    // Banco de horas: créditos (extras 50%) e débitos (atrasos) do período não vão para a folha
    UsaBancoHoras: Boolean;
    BancoCreditoMin: Integer;
    BancoDebitoMin: Integer;
    BancoSaldoAnteriorMin: Integer;
    DiasJornadaAcima10h: Integer;      // art. 59: máximo de 10h por dia
    DiasSemDescanso: Integer;          // art. 67: descanso semanal remunerado
    NoturnoPagoMin: Integer;           // noturno em hora reduzida (art. 73 §1º: 52min30s = 1h)
    ReflexoDsrExtrasMin: Integer;      // reflexo das extras no DSR (Súmula 172 TST); 0 com banco de horas
    // Saldo anterior: lançamentos manuais (ex.: saldo vindo de outro sistema) datados antes do período.
    // Sempre entra no saldo, com ou sem banco de horas; com banco inclui também os fechamentos anteriores.
    SaldoAnteriorMin: Integer;
    // Créditos/débitos de horas lançados manualmente (TB_PONTO_BANCO_HORAS) com data no período
    CreditoHorasMin: Integer;
    SaldoTotalMin: Integer;            // saldo final: banco acumulado, ou extras - faltas + créditos lançados
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
    // Tolerância por marcação (CLT art. 58 §1º), descanso entre jornadas (art. 66) e limite de extras (art. 59)
    const ToleranciaPorMarcacao = 5;
    const InterjornadaMinima = 11 * 60;
    const LimiteExtrasDia = 120;
    // Recebe falhas de leitura de dados auxiliares (afastamentos, banco de horas, feriados...), uma vez por tipo.
    // Tabelas que não existem em bases antigas não são falha e não chegam aqui.
    class var LogErro: TProc<string>;
    class function MinutosParaHora(AMinutos: Integer; AExibirSinal: Boolean = False): string;
    class function HoraParaMinutos(const AHoraStr: string): Integer;
    class function MinutosNoturnos(AIni, AFim: TDateTime; AProrrogacao: Boolean = True): Integer;
    class function Pascoa(AAno: Integer): TDateTime;
    class function CalcularEspelho(APessoaId: Integer; ADataIni, ADataFim: TDateTime): TEspelhoPonto;
  end;

implementation

type
  // Parâmetros de jornada usados pela apuração
  TJornada = record
    Descricao: string;
    Tolerancia, Carga, IntervaloMin: Integer;
    TrabalhaSabado, BancoHoras, CompensaSabado: Boolean;
    E1, S1, E2, S2, SabE1, SabS1: Integer;   // minutos desde 00:00 (-1 = vazio)
    Escala: string;
    EscalaInicio: TDateTime;                 // 0 = sem início definido
    ViradaMin: Integer;                      // batidas antes deste horário pertencem ao dia anterior
    CicloTrabalho, CicloFolga: Integer;
    CargaSexta: Integer;                     // saída diferenciada da sexta (-1 = não tem)
    // Jornada específica por dia da semana (1 = segunda ... 7 = domingo)
    DiaExiste, DiaFolga: array[1..7] of Boolean;
    DiaCarga: array[1..7] of Integer;
    DiaE1, DiaS1, DiaE2, DiaS2: array[1..7] of Integer;
    function ECiclo: Boolean;
    function E12x36: Boolean;
    function CargaSabado: Integer;
  end;

  TAfastamento = record
    Ini, Fim: TDateTime;
    Tipo: string;
  end;

function TJornada.ECiclo: Boolean;
begin
  Result := (Escala = 'CICLO') and (EscalaInicio > 0) and (CicloTrabalho > 0) and (CicloFolga > 0);
end;

function TJornada.E12x36: Boolean;
begin
  Result := (Escala = '12X36') and (EscalaInicio > 0);
end;

function TJornada.CargaSabado: Integer;
begin
  if (SabE1 >= 0) and (SabS1 > SabE1) then
    Result := SabS1 - SabE1
  else
    Result := 240;
end;

{ Funcoes Utilitarias }

// Diferença em minutos inteiros (truncada) entre dois instantes
function DifMin(AIni, AFim: TDateTime): Integer;
begin
  Result := Trunc((AFim - AIni) * 1440 + 0.0001);
end;

function CampoStr(AQry: TDataSet; const ACampo: string): string;
var
  F: TField;
begin
  Result := '';
  F := AQry.FindField(ACampo);
  if (F <> nil) and (not F.IsNull) then
    Result := Trim(F.AsString);
end;

function CampoInt(AQry: TDataSet; const ACampo: string): Integer;
var
  F: TField;
begin
  Result := 0;
  F := AQry.FindField(ACampo);
  if (F <> nil) and (not F.IsNull) then
    Result := F.AsInteger;
end;

// Data do campo (0 quando nulo ou inexistente)
function CampoData(AQry: TDataSet; const ACampo: string): TDateTime;
var
  F: TField;
begin
  Result := 0;
  F := AQry.FindField(ACampo);
  if (F <> nil) and (not F.IsNull) then
    Result := Trunc(F.AsDateTime);
end;

// Horário gravado como TIME -> minutos (-1 quando vazio)
function CampoMin(AQry: TDataSet; const ACampo: string): Integer;
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

const
  // Feriados nacionais fixos (Lei 662/49, Lei 6.802/80, Lei 14.759/23), os mesmos do GoUp Ponto
  FeriadosNacionaisMes: array[0..8] of Word = (1, 4, 5, 9, 10, 11, 11, 11, 12);
  FeriadosNacionaisDia: array[0..8] of Word = (1, 21, 1, 7, 12, 2, 15, 20, 25);
  FeriadosNacionaisNome: array[0..8] of string = ('Confraternização Universal', 'Tiradentes',
    'Dia do Trabalho', 'Independência do Brasil', 'Nossa Senhora Aparecida', 'Finados',
    'Proclamação da República', 'Dia Nacional de Zumbi e da Consciência Negra', 'Natal');

var
  FalhasJaRegistradas: TStringList;
  GPreApuracao: Boolean;   // True enquanto apura a semana anterior ao período (evita recursão)

// Dado auxiliar que não pôde ser lido: segue o cálculo sem ele, mas avisa (uma vez por contexto)
// em vez de esconder a falha. Tabela inexistente (base antiga) é esperada e fica em silêncio.
procedure RegistrarFalha(const AContexto, ATabela: string; E: Exception);
begin
  if (ATabela <> '') and (not dmDados.TabelaExiste(ATabela)) then
    Exit;
  if FalhasJaRegistradas = nil then
    FalhasJaRegistradas := TStringList.Create;
  if FalhasJaRegistradas.IndexOf(AContexto) >= 0 then
    Exit;
  FalhasJaRegistradas.Add(AContexto);
  if Assigned(TPontoCalculoService.LogErro) then
    TPontoCalculoService.LogErro('Espelho de ponto: não foi possível ler ' + AContexto + ' (' + E.Message +
      '). O cálculo seguiu sem esses dados.');
end;

function EscHtml(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

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

// Minutos de um intervalo trabalhado no período noturno (22h às 5h, CLT art. 73).
// Com AProrrogacao (Súmula 60 TST): se a jornada cumpriu todo o período noturno e continuou
// depois das 5h, as horas prorrogadas também são noturnas.
class function TPontoCalculoService.MinutosNoturnos(AIni, AFim: TDateTime; AProrrogacao: Boolean): Integer;
var
  D, JIni, JFim, A, B, Limite: TDateTime;
begin
  Result := 0;
  if AFim <= AIni then
    Exit;
  D := Trunc(AIni) - 1;
  while D <= Trunc(AFim) do
  begin
    JIni := D + 22 / 24;
    JFim := D + 1 + 5 / 24;
    if AIni > JIni then A := AIni else A := JIni;
    if AFim < JFim then B := AFim else B := JFim;
    if B > A then
      Inc(Result, DifMin(A, B));
    if AProrrogacao and (AIni <= JIni) and (AFim > JFim) then
    begin
      Limite := D + 1 + 22 / 24;
      if AFim < Limite then
        Inc(Result, DifMin(JFim, AFim))
      else
        Inc(Result, DifMin(JFim, Limite));
    end;
    D := D + 1;
  end;
end;

// Domingo de Páscoa (algoritmo de Meeus/Jones/Butcher)
class function TPontoCalculoService.Pascoa(AAno: Integer): TDateTime;
var
  A, B, C, D, E, F, G, H, I, K, L, M, Mes, Dia: Integer;
begin
  A := AAno mod 19;
  B := AAno div 100;
  C := AAno mod 100;
  D := B div 4;
  E := B mod 4;
  F := (B + 8) div 25;
  G := (B - F + 1) div 3;
  H := (19 * A + B - D - G + 15) mod 30;
  I := C div 4;
  K := C mod 4;
  L := (32 + 2 * E + 2 * I - H - K) mod 7;
  M := (A + 11 * H + 22 * L) div 451;
  Mes := (H + L - 7 * M + 114) div 31;
  Dia := ((H + L - 7 * M + 114) mod 31) + 1;
  Result := EncodeDate(AAno, Mes, Dia);
end;

{ TDiaEspelho }

function TDiaEspelho.Ocorrencia: string;
begin
  Result := Justificativa;
  if Alertas <> '' then
  begin
    if Result <> '' then
      Result := Result + ' • ';
    Result := Result + Alertas;
  end;
end;

procedure TDiaEspelho.AddAlerta(const AAlerta: string);
begin
  if Alertas <> '' then
    Alertas := Alertas + ' • ';
  Alertas := Alertas + AAlerta;
end;

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
  CorLinha, CorSaldo, TxtExtra: string;
  R: TResumoEspelho;

  function Card(const ATitulo, AValor: string; const ACls: string = ''): string;
  begin
    Result := '    <div class="card"><div>' + ATitulo + '</div><div class="val ' + ACls + '">' + AValor + '</div></div>';
  end;

  function Z(AMin: Integer): string;
  begin
    if AMin = 0 then
      Result := ''
    else
      Result := TPontoCalculoService.MinutosParaHora(AMin);
  end;

begin
  R := FResumo;
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
    SB.AppendLine('    th { background: #2b579a; color: #fff; padding: 6px 4px; text-align: center; font-size: 10px; }');
    SB.AppendLine('    td { border: 1px solid #e1e4e8; padding: 4px 3px; text-align: center; font-size: 10px; }');
    SB.AppendLine('    tr:nth-child(even) { background-color: #fcfcfc; }');
    SB.AppendLine('    .dsr { background-color: #f7f7f7 !important; color: #888; }');
    SB.AppendLine('    .feriado { background-color: #eef6ff !important; color: #1d4ed8; }');
    SB.AppendLine('    .falta { background-color: #fef0f0 !important; color: #c53030; font-weight: bold; }');
    SB.AppendLine('    .extra { color: #2e7d32; font-weight: bold; }');
    SB.AppendLine('    .impar { background-color: #fff9db !important; color: #d97706; font-weight: bold; }');
    SB.AppendLine('    .resumo-box { display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px; margin-bottom: 30px; }');
    SB.AppendLine('    .card { background: #fff; border: 1px solid #d0d7de; border-radius: 6px; padding: 8px; text-align: center; font-size: 11px; }');
    SB.AppendLine('    .card .val { font-size: 16px; font-weight: bold; margin-top: 4px; }');
    SB.AppendLine('    .val-pos { color: #2e7d32; }');
    SB.AppendLine('    .val-neg { color: #c53030; }');
    SB.AppendLine('    .legenda { font-size: 10px; color: #666; margin-bottom: 10px; }');
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
    SB.AppendLine('    <p><b>Empregador:</b> ' + EscHtml(ARazaoEmpresa) + ' &nbsp;&nbsp;|&nbsp;&nbsp; <b>CNPJ:</b> ' + EscHtml(ACnpjEmpresa) + '</p>');
    SB.AppendLine('    <p>Relatório gerado em conformidade com as diretrizes da Portaria MTE 671/2021.</p>');
    SB.AppendLine('  </div>');

    SB.AppendLine('  <div class="info-box">');
    SB.AppendLine('    <div class="info-grid">');
    SB.AppendLine('      <div class="info-item"><b>Colaborador:</b> ' + EscHtml(R.ColaboradorNome) + '</div>');
    SB.AppendLine('      <div class="info-item"><b>CPF:</b> ' + EscHtml(R.ColaboradorCPF) + '</div>');
    SB.AppendLine('      <div class="info-item"><b>PIS:</b> ' + EscHtml(R.ColaboradorPIS) + '</div>');
    SB.AppendLine('      <div class="info-item"><b>Matrícula:</b> ' + EscHtml(R.ColaboradorMatricula) + '</div>');
    SB.AppendLine('      <div class="info-item"><b>Função/Cargo:</b> ' + EscHtml(R.ColaboradorFuncao) + '</div>');
    SB.AppendLine('      <div class="info-item"><b>Jornada:</b> ' + EscHtml(R.JornadaDescricao) + '</div>');
    SB.AppendLine('    </div>');
    SB.AppendLine('  </div>');

    SB.AppendLine('  <table>');
    SB.AppendLine('    <thead><tr><th>Data</th><th>Dia</th><th>1ª Ent</th><th>1ª Saí</th><th>2ª Ent</th><th>2ª Saí</th>' +
      '<th>Outras</th><th>Previsto</th><th>Realizado</th><th>Extras</th><th>Faltas</th><th>Noturno</th>' +
      '<th>Interv. supr.</th><th>Saldo</th><th>Ocorrência / Justificativa</th></tr></thead>');
    SB.AppendLine('    <tbody>');

    for I := 0 to High(FDias) do
    begin
      CorLinha := '';
      if FDias[I].DsrDescontado then
        CorLinha := ' class="falta"'
      else if FDias[I].TipoDia = tdFeriado then
        CorLinha := ' class="feriado"'
      else if FDias[I].TipoDia in [tdDomingoDSR, tdSabadoCompensado, tdFolga] then
        CorLinha := ' class="dsr"'
      else if FDias[I].Impar then
        CorLinha := ' class="impar"'
      else if FDias[I].FaltaDiaInteiro then
        CorLinha := ' class="falta"';

      CorSaldo := '';
      if FDias[I].SaldoMin > 0 then
        CorSaldo := ' class="extra"'
      else if FDias[I].SaldoMin < 0 then
        CorSaldo := ' style="color: #c53030; font-weight: bold;"';

      TxtExtra := FDias[I].ExtraStr;
      if FDias[I].Extra100 and (FDias[I].ExtraMin > 0) then
        TxtExtra := TxtExtra + ' (100%)';

      SB.AppendLine('      <tr' + CorLinha + '><td>' + FormatDateTime('dd/mm/yyyy', FDias[I].Data) + '</td><td>' +
        FDias[I].DiaSemana + '</td><td>' + FDias[I].Entrada1 + '</td><td>' + FDias[I].Saida1 + '</td><td>' +
        FDias[I].Entrada2 + '</td><td>' + FDias[I].Saida2 + '</td><td>' + FDias[I].BatidasExtras + '</td><td>' +
        FDias[I].CargaPrevistaStr + '</td><td>' + FDias[I].TrabalhadoStr + '</td><td>' + TxtExtra + '</td><td>' +
        FDias[I].FaltaStr + '</td><td>' + Z(FDias[I].NoturnoMin) + '</td><td>' + Z(FDias[I].IntervaloSuprimidoMin) +
        '</td><td' + CorSaldo + '>' + FDias[I].SaldoStr + '</td><td>' + EscHtml(FDias[I].Ocorrencia) + '</td></tr>');
    end;

    SB.AppendLine('    </tbody>');
    SB.AppendLine('  </table>');

    SB.AppendLine('  <p class="legenda">Tolerância conforme CLT art. 58 §1º (5 min por marcação, máximo de 10 min diários). ' +
      'Extras em domingos, feriados e folgas da escala: 100%. Adicional noturno das 22h às 5h com prorrogação ' +
      '(Súmula 60 TST). Intervalo suprimido: art. 71 §4º. Descanso entre jornadas: art. 66. ' +
      'Feriado e DSR perdidos por falta injustificada na semana: Lei 605/49, art. 6º.</p>');

    SB.AppendLine('  <div class="resumo-box">');
    SB.AppendLine(Card('Previsto', TPontoCalculoService.MinutosParaHora(R.TotalPrevistoMin)));
    SB.AppendLine(Card('Realizado', TPontoCalculoService.MinutosParaHora(R.TotalTrabalhadoMin)));
    SB.AppendLine(Card('Extras 50%', '+' + TPontoCalculoService.MinutosParaHora(R.TotalExtras50Min + R.TotalExtrasFaixa2Min), 'val-pos'));
    SB.AppendLine(Card('Extras 100%', '+' + TPontoCalculoService.MinutosParaHora(R.TotalExtras100Min), 'val-pos'));
    SB.AppendLine(Card('Adicional noturno (relógio)', TPontoCalculoService.MinutosParaHora(R.TotalNoturnoMin)));
    SB.AppendLine(Card('Noturno em hora reduzida (52min30s)', TPontoCalculoService.MinutosParaHora(R.NoturnoPagoMin)));
    SB.AppendLine(Card('Faltas', IntToStr(R.TotalFaltas) + ' dia(s)', 'val-neg'));
    SB.AppendLine(Card('Atrasos / saídas', '-' + TPontoCalculoService.MinutosParaHora(R.TotalAtrasosMin), 'val-neg'));
    SB.AppendLine(Card('Intervalo suprimido', TPontoCalculoService.MinutosParaHora(R.TotalIntervaloSuprimidoMin)));
    SB.AppendLine(Card('Interjornada &lt; 11h', TPontoCalculoService.MinutosParaHora(R.TotalInterjornadaMin)));
    SB.AppendLine(Card('DSR descontados', IntToStr(R.DsrDescontados), IfThen(R.DsrDescontados > 0, 'val-neg', '')));
    SB.AppendLine(Card('Feriados (não descontados do previsto)', IntToStr(R.TotalFeriados)));
    SB.AppendLine(Card('Feriados descontados', IntToStr(R.FeriadosDescontados), IfThen(R.FeriadosDescontados > 0, 'val-neg', '')));
    SB.AppendLine(Card('Abonado', TPontoCalculoService.MinutosParaHora(R.TotalAbonadoMin)));
    if R.ReflexoDsrExtrasMin > 0 then
      SB.AppendLine(Card('Reflexo das extras no DSR', TPontoCalculoService.MinutosParaHora(R.ReflexoDsrExtrasMin), 'val-pos'));
    if R.SaldoAnteriorMin <> 0 then
      SB.AppendLine(Card('Saldo anterior', TPontoCalculoService.MinutosParaHora(R.SaldoAnteriorMin, True),
        IfThen(R.SaldoAnteriorMin >= 0, 'val-pos', 'val-neg')));
    if R.CreditoHorasMin <> 0 then
      SB.AppendLine(Card('Crédito de horas lançado', TPontoCalculoService.MinutosParaHora(R.CreditoHorasMin, True),
        IfThen(R.CreditoHorasMin >= 0, 'val-pos', 'val-neg')));
    SB.AppendLine(Card(IfThen(R.UsaBancoHoras, 'Banco de horas (saldo)', 'Saldo do período'),
      R.SaldoTotalStr, IfThen(R.SaldoTotalMin >= 0, 'val-pos', 'val-neg')));
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
  R: TResumoEspelho;
  Ini, Fim, Hoje, Dia: TDateTime;
  HorId, I, K, N, Pares, DiaIso: Integer;
  J: TJornada;
  Admissao, Demissao: TDateTime;
  Consecutivos, DUteis, DDescanso: Integer;
  FaltasAnt: TArray<TDateTime>;   // faltas dos dias logo antes do período (para DSR e dias seguidos)
  PreEsp: TEspelhoPonto;
  Excluidos: TStringList;   // dia-mês de feriados nacionais desativados pelo usuário
  Afastamentos: TArray<TAfastamento>;
  Feriados: TDictionary<Integer, string>;
  PorDia: TObjectDictionary<Integer, TList<TDateTime>>;
  JusPorDia: TDictionary<Integer, TArray<string>>;  // 0 = tipo, 1 = motivo, 2 = abono
  AjusteDia: TDictionary<Integer, Integer>;         // bit 1 = não contar hora extra, bit 2 = feriado manual
  AjBits: Integer;
  SemExtraDia, FeriadoManual: Boolean;
  Faixa1: Integer;
  DividirFaixas: Boolean;
  Qry: TFDQuery;
  Lst: TList<TDateTime>;
  Bat: TArray<TDateTime>;
  It: TDiaEspelho;
  Programado: TArray<Integer>;
  Fer, AfaTipo: string;
  ForaContrato, TemJus, Dentro: Boolean;
  Abono, Faltou, Diff, Considerar, Soma, V, Exigido, Descanso, F2, Pos0: Integer;
  JusInfo: TArray<string>;
  Ant, Prog, Ref: TDateTime;
  IniSemana, FimSemana: TDateTime;
  SabComp: Boolean;
  Carga: Integer;
  Ini2: TIniFile;

  procedure AddProg(AMin: Integer);
  begin
    if AMin >= 0 then
    begin
      SetLength(Programado, Length(Programado) + 1);
      Programado[High(Programado)] := AMin;
    end;
  end;

  procedure ProgramaPadrao;
  begin
    SetLength(Programado, 0);
    AddProg(J.E1);
    AddProg(J.S1);
    AddProg(J.E2);
    AddProg(J.S2);
  end;

  function AfastamentoEm(ADia: TDateTime): string;
  var
    X: Integer;
  begin
    Result := '';
    for X := 0 to High(Afastamentos) do
      if (ADia >= Afastamentos[X].Ini) and (ADia <= Afastamentos[X].Fim) then
      begin
        Result := Afastamentos[X].Tipo;
        if Result = '' then
          Result := 'Afastamento';
        Exit;
      end;
  end;

  // Há falta injustificada de dia inteiro entre as datas (no período ou nos dias logo antes dele)?
  function TemFaltaEntre(AIni, AFim: TDateTime): Boolean;
  var
    X: Integer;
  begin
    Result := False;
    for X := 0 to High(Espelho.FDias) do
      if Espelho.FDias[X].FaltaDiaInteiro and (Espelho.FDias[X].Data >= AIni) and (Espelho.FDias[X].Data <= AFim) then
        Exit(True);
    for X := 0 to High(FaltasAnt) do
      if (FaltasAnt[X] >= AIni) and (FaltasAnt[X] <= AFim) then
        Exit(True);
  end;

  // Última saída dentro dos 3 dias anteriores (interjornada)
  function UltimaSaidaAnterior(ADia: TDateTime; out ASaida: TDateTime): Boolean;
  var
    X: Integer;
    L: TList<TDateTime>;
  begin
    Result := False;
    ASaida := 0;
    for X := 1 to 3 do
      if PorDia.TryGetValue(Trunc(ADia) - X, L) and (L.Count > 0) then
      begin
        ASaida := L[L.Count - 1];
        Exit(True);
      end;
  end;

begin
  Espelho := TEspelhoPonto.Create;
  Result := Espelho;
  Hoje := Trunc(Date);
  Ini := Trunc(ADataIni);
  Fim := Trunc(ADataFim);
  if Fim > Hoje then
    Fim := Hoje;   // dias futuros não são apurados
  if (APessoaId <= 0) or (Ini > Fim) then
    Exit;

  Initialize(R);
  Initialize(J);

  // 1. Colaborador
  Qry := dmDados.GetPessoaPorId(APessoaId);
  try
    if Qry.IsEmpty then
      Exit;
    R.ColaboradorNome := Qry.FieldByName('PES_RSOCIAL_NOME').AsString;
    R.ColaboradorCPF := Qry.FieldByName('COL_CPF').AsString;
    if R.ColaboradorCPF = '' then
      R.ColaboradorCPF := Qry.FieldByName('PES_CNPJ_CPF').AsString;
    R.ColaboradorPIS := Qry.FieldByName('COL_PIS').AsString;
    R.ColaboradorMatricula := Qry.FieldByName('COL_CARTAO_PONTO').AsString;
    R.ColaboradorFuncao := Qry.FieldByName('COL_FUNCAO').AsString;
    HorId := Qry.FieldByName('COL_HORARIO').AsInteger;
    if HorId <= 0 then
      HorId := 1; // Padrao Comercial
  finally
    Qry.Free;
  end;

  // Vínculo: dias antes da admissão ou depois da demissão não contam
  Admissao := 0;
  Demissao := 0;
  try
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := dmDados.FDConnection;
      Qry.SQL.Text := 'SELECT * FROM TB_COLABORADOR WHERE COL_PESSOA = :P';
      Qry.ParamByName('P').AsInteger := APessoaId;
      Qry.Open;
      if not Qry.IsEmpty then
      begin
        Admissao := CampoData(Qry, 'COL_DATA_ADMISSAO');
        Demissao := CampoData(Qry, 'COL_DATA_DEMISSAO');
      end;
    finally
      Qry.Free;
    end;
  except
    on E: Exception do
      RegistrarFalha('o vínculo do colaborador (admissão/demissão)', 'TB_COLABORADOR', E);
  end;

  // 2. Jornada
  J.Descricao := 'Comercial 44h (Padrao)';
  J.Tolerancia := 10;
  J.Carga := 528;
  J.IntervaloMin := 60;
  J.CompensaSabado := True;
  J.Escala := 'SEMANAL';
  J.E1 := -1; J.S1 := -1; J.E2 := -1; J.S2 := -1; J.SabE1 := -1; J.SabS1 := -1;
  J.CargaSexta := -1;
  for DiaIso := 1 to 7 do
  begin
    J.DiaE1[DiaIso] := -1; J.DiaS1[DiaIso] := -1; J.DiaE2[DiaIso] := -1; J.DiaS2[DiaIso] := -1;
  end;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := dmDados.FDConnection;
    Qry.SQL.Text := 'SELECT * FROM TB_PONTO_HORARIO WHERE HOR_ID = :ID';
    Qry.ParamByName('ID').AsInteger := HorId;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      J.Descricao := CampoStr(Qry, 'HOR_DESCRICAO');
      J.Tolerancia := CampoInt(Qry, 'HOR_TOLERANCIA_MIN');
      if J.Tolerancia <= 0 then J.Tolerancia := 10;
      J.Carga := CampoInt(Qry, 'HOR_CARGA_DIARIA_MIN');
      if J.Carga <= 0 then J.Carga := 528;
      J.CompensaSabado := CampoStr(Qry, 'HOR_COMPENSA_SABADO') = 'S';
      J.TrabalhaSabado := CampoStr(Qry, 'HOR_TRABALHA_SABADO') = 'S';
      J.BancoHoras := CampoStr(Qry, 'HOR_BANCO_HORAS') = 'S';
      J.E1 := CampoMin(Qry, 'HOR_ENTRADA_1');
      J.S1 := CampoMin(Qry, 'HOR_SAIDA_1');
      J.E2 := CampoMin(Qry, 'HOR_ENTRADA_2');
      J.S2 := CampoMin(Qry, 'HOR_SAIDA_2');
      J.SabE1 := CampoMin(Qry, 'HOR_SAB_ENTRADA_1');
      J.SabS1 := CampoMin(Qry, 'HOR_SAB_SAIDA_1');
      J.Escala := UpperCase(CampoStr(Qry, 'HOR_TIPO_ESCALA'));
      if J.Escala = '' then
        J.Escala := 'SEMANAL';
      J.EscalaInicio := CampoData(Qry, 'HOR_ESCALA_INICIO');
      J.ViradaMin := HoraParaMinutos(CampoStr(Qry, 'HOR_VIRADA_DIA'));
      J.IntervaloMin := CampoInt(Qry, 'HOR_INTERVALO_MIN');
      if J.IntervaloMin <= 0 then J.IntervaloMin := 60;
      J.CicloTrabalho := CampoInt(Qry, 'HOR_CICLO_TRABALHO');
      J.CicloFolga := CampoInt(Qry, 'HOR_CICLO_FOLGA');

      // Carga diária derivada dos horários cadastrados (seg-qui) e da saída diferenciada
      // da sexta-feira. Ex.: 08-12/13-18 = 9h; sexta até 17h = 8h.
      if CargaPorHorarios(J.E1, J.S1, J.E2, J.S2) > 0 then
        J.Carga := CargaPorHorarios(J.E1, J.S1, J.E2, J.S2);
      if CampoMin(Qry, 'HOR_SEX_SAIDA_2') >= 0 then
      begin
        if J.S2 >= 0 then
          J.CargaSexta := CargaPorHorarios(J.E1, J.S1, J.E2, CampoMin(Qry, 'HOR_SEX_SAIDA_2'))
        else
          J.CargaSexta := CargaPorHorarios(J.E1, CampoMin(Qry, 'HOR_SEX_SAIDA_2'), -1, -1);
      end;
    end;
  finally
    Qry.Free;
  end;
  R.JornadaDescricao := J.Descricao;
  R.UsaBancoHoras := J.BancoHoras;

  // 2b. Jornada por dia da semana gravada no cadastro: dia configurado usa a própria carga ou folga
  try
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := dmDados.FDConnection;
      Qry.SQL.Text := 'SELECT HDI_DIA_SEMANA, HDI_ENTRADA_1, HDI_SAIDA_1, HDI_ENTRADA_2, HDI_SAIDA_2, ' +
        'HDI_CARGA_MIN, HDI_FOLGA FROM TB_PONTO_HORARIO_DIA WHERE HDI_HORARIO = :H';
      Qry.ParamByName('H').AsInteger := HorId;
      Qry.Open;
      while not Qry.Eof do
      begin
        DiaIso := Qry.FieldByName('HDI_DIA_SEMANA').AsInteger;
        if (DiaIso >= 1) and (DiaIso <= 7) then
        begin
          J.DiaExiste[DiaIso] := True;
          J.DiaFolga[DiaIso] := Qry.FieldByName('HDI_FOLGA').AsString = 'S';
          J.DiaCarga[DiaIso] := Qry.FieldByName('HDI_CARGA_MIN').AsInteger;
          J.DiaE1[DiaIso] := HoraOuNada(Qry.FieldByName('HDI_ENTRADA_1').AsString);
          J.DiaS1[DiaIso] := HoraOuNada(Qry.FieldByName('HDI_SAIDA_1').AsString);
          J.DiaE2[DiaIso] := HoraOuNada(Qry.FieldByName('HDI_ENTRADA_2').AsString);
          J.DiaS2[DiaIso] := HoraOuNada(Qry.FieldByName('HDI_SAIDA_2').AsString);
          if (not J.DiaFolga[DiaIso]) and (J.DiaCarga[DiaIso] <= 0) then
            J.DiaCarga[DiaIso] := CargaPorHorarios(J.DiaE1[DiaIso], J.DiaS1[DiaIso], J.DiaE2[DiaIso], J.DiaS2[DiaIso]);
        end;
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;
  except
    on E: Exception do
      RegistrarFalha('a jornada por dia da semana', 'TB_PONTO_HORARIO_DIA', E);
  end;

  // Afastamentos (férias, licenças, INSS...) no período
  SetLength(Afastamentos, 0);
  try
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := dmDados.FDConnection;
      Qry.SQL.Text := 'SELECT AFA_INICIO, AFA_FIM, AFA_TIPO FROM TB_PONTO_AFASTAMENTO ' +
        'WHERE AFA_PESSOA = :P AND AFA_FIM >= :I AND AFA_INICIO <= :F';
      Qry.ParamByName('P').AsInteger := APessoaId;
      Qry.ParamByName('I').AsDate := Ini;
      Qry.ParamByName('F').AsDate := Fim;
      Qry.Open;
      while not Qry.Eof do
      begin
        SetLength(Afastamentos, Length(Afastamentos) + 1);
        Afastamentos[High(Afastamentos)].Ini := Trunc(Qry.FieldByName('AFA_INICIO').AsDateTime);
        Afastamentos[High(Afastamentos)].Fim := Trunc(Qry.FieldByName('AFA_FIM').AsDateTime);
        Afastamentos[High(Afastamentos)].Tipo := Qry.FieldByName('AFA_TIPO').AsString;
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;
  except
    on E: Exception do
      RegistrarFalha('os afastamentos', 'TB_PONTO_AFASTAMENTO', E);
  end;

  // Faixas de extras em dias normais (convenção coletiva), gravadas na seção [FOLHA] do INI
  Faixa1 := 120;
  DividirFaixas := False;
  try
    Ini2 := TIniFile.Create(AppConfig.IniPath);
    try
      Faixa1 := Ini2.ReadInteger('FOLHA', 'ExtraFaixa1Min', 120);
      DividirFaixas := Ini2.ReadInteger('FOLHA', 'PctFaixa1', 50) <> Ini2.ReadInteger('FOLHA', 'PctFaixa2', 50);
    finally
      Ini2.Free;
    end;
  except
    on E: Exception do
      RegistrarFalha('as faixas de horas extras do arquivo de configuração', '', E);
  end;

  // 2c. Lançamentos de horas: tudo antes do período forma o saldo anterior do banco; os manuais
  //     (crédito de horas, ajuste, pagamento, folga) com data no período entram no saldo dele.
  //     Créditos/débitos apurados (C/D) do período não entram: são o próprio cálculo já fechado.
  try
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := dmDados.FDConnection;
      Qry.SQL.Text := 'SELECT BH_DATA, BH_MINUTOS, BH_TIPO FROM TB_PONTO_BANCO_HORAS ' +
        'WHERE BH_PESSOA = :P AND BH_DATA <= :F';
      Qry.ParamByName('P').AsInteger := APessoaId;
      Qry.ParamByName('F').AsDate := Fim;
      Qry.Open;
      while not Qry.Eof do
      begin
        if Trunc(Qry.FieldByName('BH_DATA').AsDateTime) < Ini then
        begin
          // Com banco de horas todo o histórico forma o saldo anterior; sem banco, só os lançamentos
          // manuais (saldo de outro sistema, ajustes), pois extras e atrasos dos meses fechados já foram pagos.
          if J.BancoHoras or ((Qry.FieldByName('BH_TIPO').AsString <> 'C') and (Qry.FieldByName('BH_TIPO').AsString <> 'D')) then
          begin
            Inc(R.SaldoAnteriorMin, Qry.FieldByName('BH_MINUTOS').AsInteger);
            if J.BancoHoras then
              Inc(R.BancoSaldoAnteriorMin, Qry.FieldByName('BH_MINUTOS').AsInteger);
          end;
        end
        else if (Qry.FieldByName('BH_TIPO').AsString <> 'C') and (Qry.FieldByName('BH_TIPO').AsString <> 'D') then
          Inc(R.CreditoHorasMin, Qry.FieldByName('BH_MINUTOS').AsInteger);
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;
  except
    on E: Exception do
      RegistrarFalha('os lançamentos do banco de horas', 'TB_PONTO_BANCO_HORAS', E);
  end;

  Feriados := TDictionary<Integer, string>.Create;
  PorDia := TObjectDictionary<Integer, TList<TDateTime>>.Create([doOwnsValues]);
  JusPorDia := TDictionary<Integer, TArray<string>>.Create;
  AjusteDia := TDictionary<Integer, Integer>.Create;
  Excluidos := TStringList.Create;
  try
    // Ajustes manuais do dia (não contar hora extra / feriado)
    try
      Qry := TFDQuery.Create(nil);
      try
        Qry.Connection := dmDados.FDConnection;
        Qry.SQL.Text := 'SELECT DAJ_DATA, DAJ_SEM_EXTRA, DAJ_FERIADO FROM TB_PONTO_DIA_AJUSTE ' +
          'WHERE DAJ_PESSOA = :P AND DAJ_DATA BETWEEN :I AND :F';
        Qry.ParamByName('P').AsInteger := APessoaId;
        Qry.ParamByName('I').AsDate := Ini;
        Qry.ParamByName('F').AsDate := Fim;
        Qry.Open;
        while not Qry.Eof do
        begin
          AjBits := 0;
          if Qry.FieldByName('DAJ_SEM_EXTRA').AsString = 'S' then AjBits := AjBits or 1;
          if Qry.FieldByName('DAJ_FERIADO').AsString = 'S' then AjBits := AjBits or 2;
          AjusteDia.AddOrSetValue(Trunc(Qry.FieldByName('DAJ_DATA').AsDateTime), AjBits);
          Qry.Next;
        end;
      finally
        Qry.Free;
      end;
    except
      on E: Exception do
        RegistrarFalha('os ajustes manuais do dia', 'TB_PONTO_DIA_AJUSTE', E);
    end;

    // 3. Batidas (um dia antes e depois, para turno noturno e interjornada) agrupadas por dia de trabalho
    Qry := dmDados.GetMarcacoes(Ini - 2, Fim + 1, 0, APessoaId, True);
    try
      while not Qry.Eof do
      begin
        Dia := Qry.FieldByName('PMA_DATA_HORA').AsDateTime;
        K := Trunc(Dia);
        if (J.ViradaMin > 0) and (Round(Frac(Dia) * 1440) < J.ViradaMin) then
          Dec(K);
        if not PorDia.TryGetValue(K, Lst) then
        begin
          Lst := TList<TDateTime>.Create;
          PorDia.Add(K, Lst);
        end;
        Lst.Add(Dia);
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;
    for Lst in PorDia.Values do
      Lst.Sort;

    // 4. Justificativas
    Qry := dmDados.GetJustificativasPeriodo(APessoaId, Ini, Fim);
    try
      while not Qry.Eof do
      begin
        K := Trunc(Qry.FieldByName('JUS_DATA').AsDateTime);
        if not JusPorDia.ContainsKey(K) then
          JusPorDia.Add(K, [Qry.FieldByName('JUS_TIPO').AsString, Qry.FieldByName('JUS_MOTIVO').AsString,
            IntToStr(Qry.FieldByName('JUS_ABONO_MINUTOS').AsInteger)]);
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;

    // 5. Feriados cadastrados (recorrentes expandidos ano a ano) + Sexta-feira Santa (móvel, Lei 9.093/95)
    try
      Qry := TFDQuery.Create(nil);
      try
        Qry.Connection := dmDados.FDConnection;
        Qry.SQL.Text := 'SELECT * FROM TB_PONTO_FERIADO';
        Qry.Open;
        while not Qry.Eof do
        begin
          Dia := Trunc(Qry.FieldByName('FER_DATA').AsDateTime);
          // Feriado nacional que o usuário desativou: não vale (nem o embutido, nem o cadastrado)
          if SameText(CampoStr(Qry, 'FER_ABRANGENCIA'), 'EXCLUIDO') then
          begin
            Excluidos.Add(Format('%d-%d', [MonthOf(Dia), DayOf(Dia)]));
            Qry.Next;
            Continue;
          end;
          if CampoStr(Qry, 'FER_RECORRENTE') <> 'N' then
          begin
            for K := YearOf(Ini) to YearOf(Fim) do
            begin
              // Consciência Negra só é feriado nacional a partir de 2024 (Lei 14.759/23); antes, só se o
              // cadastro for municipal/estadual
              if (MonthOf(Dia) = 11) and (DayOf(Dia) = 20) and (K < 2024) and
                 SameText(CampoStr(Qry, 'FER_ABRANGENCIA'), 'NACIONAL') then
                Continue;
              if TryEncodeDate(K, MonthOf(Dia), DayOf(Dia), Prog) and (Prog >= Ini) and (Prog <= Fim) then
                Feriados.AddOrSetValue(Trunc(Prog), Qry.FieldByName('FER_DESCRICAO').AsString);
            end;
          end
          else if (Dia >= Ini) and (Dia <= Fim) then
            Feriados.AddOrSetValue(Trunc(Dia), Qry.FieldByName('FER_DESCRICAO').AsString);
          Qry.Next;
        end;
      finally
        Qry.Free;
      end;
    except
      on E: Exception do
        RegistrarFalha('os feriados cadastrados', 'TB_PONTO_FERIADO', E);
    end;
    for K := YearOf(Ini) to YearOf(Fim) do
    begin
      Prog := Pascoa(K) - 2;
      if (Prog >= Ini) and (Prog <= Fim) and (not Feriados.ContainsKey(Trunc(Prog))) then
        Feriados.Add(Trunc(Prog), 'Sexta-feira Santa');
      // Feriados nacionais fixos sempre valem, mesmo que a tabela esteja incompleta (ex.: Finados, 02/11)
      for N := Low(FeriadosNacionaisMes) to High(FeriadosNacionaisMes) do
        if (not ((FeriadosNacionaisMes[N] = 11) and (FeriadosNacionaisDia[N] = 20) and (K < 2024))) and
           (Excluidos.IndexOf(Format('%d-%d', [FeriadosNacionaisMes[N], FeriadosNacionaisDia[N]])) < 0) and
           TryEncodeDate(K, FeriadosNacionaisMes[N], FeriadosNacionaisDia[N], Prog) and
           (Prog >= Ini) and (Prog <= Fim) and (not Feriados.ContainsKey(Trunc(Prog))) then
          Feriados.Add(Trunc(Prog), FeriadosNacionaisNome[N]);
    end;

    // 5.1 Semana anterior ao período: o descanso semanal (domingo/feriado) do começo do período depende das
    //     faltas dos dias logo antes, e a contagem de dias seguidos trabalhados também. Apura essa semana
    //     uma vez (sem repetir a apuração dentro dela).
    SetLength(FaltasAnt, 0);
    Consecutivos := 0;
    if not GPreApuracao then
    begin
      GPreApuracao := True;
      try
        PreEsp := CalcularEspelho(APessoaId, Ini - 7, Ini - 1);
        try
          for I := 0 to High(PreEsp.Dias) do
            if PreEsp.Dias[I].FaltaDiaInteiro then
            begin
              SetLength(FaltasAnt, Length(FaltasAnt) + 1);
              FaltasAnt[High(FaltasAnt)] := PreEsp.Dias[I].Data;
            end;
          for I := High(PreEsp.Dias) downto 0 do
            if PreEsp.Dias[I].Entrada1 <> '' then
              Inc(Consecutivos)
            else
              Break;
        finally
          PreEsp.Free;
        end;
      finally
        GPreApuracao := False;
      end;
    end;

    // 6. Apuração dia a dia
    Dia := Ini;
    while Dia <= Fim do
    begin
      Inc(R.TotalDiasPeriodo);
      It := Default(TDiaEspelho);
      It.Data := Dia;
      case DayOfTheWeek(Dia) of
        1: It.DiaSemana := 'Seg';
        2: It.DiaSemana := 'Ter';
        3: It.DiaSemana := 'Qua';
        4: It.DiaSemana := 'Qui';
        5: It.DiaSemana := 'Sex';
        6: It.DiaSemana := 'Sab';
        7: It.DiaSemana := 'Dom';
      end;
      DiaIso := DayOfTheWeek(Dia);
      if not Feriados.TryGetValue(Trunc(Dia), Fer) then
        Fer := '';
      SetLength(Programado, 0);

      ForaContrato := ((Admissao > 0) and (Dia < Admissao)) or ((Demissao > 0) and (Dia > Demissao));
      if ForaContrato then
        AfaTipo := ''
      else
        AfaTipo := AfastamentoEm(Dia);

      if ForaContrato then
      begin
        It.TipoDia := tdFolga;
        It.ForaContrato := True;
        if (Admissao > 0) and (Dia < Admissao) then
          It.AddAlerta('Antes da admissão (' + FormatDateTime('dd/mm/yyyy', Admissao) + ')')
        else
          It.AddAlerta('Após a demissão (' + FormatDateTime('dd/mm/yyyy', Demissao) + ')');
      end
      else if AfaTipo <> '' then
      begin
        It.TipoDia := tdFolga;
        It.Afastamento := AfaTipo;
        It.AddAlerta(AfaTipo);
        Inc(R.DiasAfastado);
      end
      else if J.ECiclo then
      begin
        Pos0 := ((Trunc(Dia) - Trunc(J.EscalaInicio)) mod (J.CicloTrabalho + J.CicloFolga) +
          (J.CicloTrabalho + J.CicloFolga)) mod (J.CicloTrabalho + J.CicloFolga);
        if Pos0 < J.CicloTrabalho then
        begin
          It.CargaPrevistaMin := J.Carga;
          ProgramaPadrao;
          Inc(R.TotalDiasUteis);
          if Fer <> '' then
          begin
            It.TipoDia := tdFeriado;
            It.Feriado := Fer;
            It.CargaPrevistaMin := 0;
            It.AddAlerta('Feriado: ' + Fer);
            Dec(R.TotalDiasUteis);
            SetLength(Programado, 0);
          end;
        end
        else
        begin
          It.TipoDia := tdFolga;
          It.AddAlerta(Format('Folga da escala %dx%d', [J.CicloTrabalho, J.CicloFolga]));
        end;
      end
      else if J.DiaExiste[DiaIso] and (Fer = '') and (not J.E12x36) then
      begin
        // Jornada específica deste dia da semana
        if J.DiaFolga[DiaIso] then
        begin
          SabComp := (DiaIso = 6) and J.CompensaSabado;
          if DiaIso = 7 then
          begin
            It.TipoDia := tdDomingoDSR;
            It.AddAlerta('DSR / Folga');
          end
          else if SabComp then
          begin
            It.TipoDia := tdSabadoCompensado;
            It.AddAlerta('Sabado Compensado');
          end
          else
          begin
            It.TipoDia := tdFolga;
            It.AddAlerta('Folga semanal');
          end;
        end
        else
        begin
          AddProg(J.DiaE1[DiaIso]);
          AddProg(J.DiaS1[DiaIso]);
          AddProg(J.DiaE2[DiaIso]);
          AddProg(J.DiaS2[DiaIso]);
          It.CargaPrevistaMin := J.DiaCarga[DiaIso];
          if DiaIso = 6 then
            It.TipoDia := tdSabadoTrabalhado
          else
            It.TipoDia := tdUtil;
          Inc(R.TotalDiasUteis);
        end;
      end
      else if J.E12x36 then
      begin
        if not Odd(Trunc(Dia) - Trunc(J.EscalaInicio)) then
        begin
          It.CargaPrevistaMin := J.Carga;
          ProgramaPadrao;
          Inc(R.TotalDiasUteis);
        end
        else
        begin
          It.TipoDia := tdFolga;
          It.AddAlerta('Folga da escala 12x36');
        end;
        // Na 12x36 o feriado trabalhado já é compensado (CLT art. 59-A, parágrafo único)
        if Fer <> '' then
          It.Feriado := Fer;
      end
      else if Fer <> '' then
      begin
        It.TipoDia := tdFeriado;
        It.Feriado := Fer;
        It.AddAlerta('Feriado: ' + Fer);
      end
      else if DiaIso = 7 then
      begin
        It.TipoDia := tdDomingoDSR;
        It.AddAlerta('DSR / Folga');
      end
      else if DiaIso = 6 then
      begin
        if J.TrabalhaSabado then
        begin
          It.TipoDia := tdSabadoTrabalhado;
          It.CargaPrevistaMin := J.CargaSabado;
          AddProg(J.SabE1);
          AddProg(J.SabS1);
          Inc(R.TotalDiasUteis);
        end
        else
        begin
          It.TipoDia := tdSabadoCompensado;
          It.AddAlerta('Sabado Compensado');
        end;
      end
      else
      begin
        It.TipoDia := tdUtil;
        It.CargaPrevistaMin := J.Carga;
        if (DiaIso = 5) and (J.CargaSexta > 0) then
          It.CargaPrevistaMin := J.CargaSexta;
        ProgramaPadrao;
        Inc(R.TotalDiasUteis);
      end;

      // Ajuste manual do dia
      if not AjusteDia.TryGetValue(Trunc(Dia), AjBits) then
        AjBits := 0;
      SemExtraDia := (AjBits and 1) <> 0;
      FeriadoManual := (AjBits and 2) <> 0;
      // Feriado marcado à mão: zera previsto e faltas do dia (vale em qualquer escala)
      if FeriadoManual and (It.TipoDia <> tdFeriado) and (not It.ForaContrato) and (It.Afastamento = '') then
      begin
        if It.CargaPrevistaMin > 0 then
          Dec(R.TotalDiasUteis);
        It.CargaPrevistaMin := 0;
        It.TipoDia := tdFeriado;
        It.Feriado := 'Feriado (marcado manualmente)';
        SetLength(Programado, 0);
        It.AddAlerta('Feriado (marcado manualmente)');
      end;

      // 100%: domingo (DSR), feriado e folga das escalas 12x36 / ciclo; folga semanal comum segue a faixa normal
      It.Extra100 := (It.TipoDia = tdFeriado) or (It.TipoDia = tdDomingoDSR) or
        ((It.TipoDia = tdFolga) and (J.E12x36 or J.ECiclo) and (not It.ForaContrato) and (It.Afastamento = ''));

      // Batidas e horas trabalhadas
      if PorDia.TryGetValue(Trunc(Dia), Lst) then
        Bat := Lst.ToArray
      else
        SetLength(Bat, 0);
      N := Length(Bat);
      if N > 0 then
      begin
        It.Entrada1 := FormatDateTime('hh:nn', Bat[0]);
        if N >= 2 then It.Saida1 := FormatDateTime('hh:nn', Bat[1]);
        if N >= 3 then It.Entrada2 := FormatDateTime('hh:nn', Bat[2]);
        if N >= 4 then It.Saida2 := FormatDateTime('hh:nn', Bat[3]);
        for I := 4 to N - 1 do
          It.BatidasExtras := Trim(It.BatidasExtras + ' ' + FormatDateTime('hh:nn', Bat[I]));
        Pares := N div 2;
        for I := 0 to Pares - 1 do
        begin
          Inc(It.TrabalhadoMin, DifMin(Bat[I * 2], Bat[I * 2 + 1]));
          Inc(It.NoturnoMin, MinutosNoturnos(Bat[I * 2], Bat[I * 2 + 1]));
          if I > 0 then
            Inc(It.IntervaloMin, DifMin(Bat[I * 2 - 1], Bat[I * 2]));
        end;
        if Odd(N) then
        begin
          It.Impar := True;
          It.AddAlerta('Marcacao Impar');
        end;
        Inc(R.TotalDiasTrabalhados);
        if It.TipoDia = tdFeriado then
          Inc(R.TotalFeriadosTrabalhados);

        // Descanso mínimo de 11h entre jornadas (art. 66)
        if UltimaSaidaAnterior(Dia, Ant) then
        begin
          Descanso := DifMin(Ant, Bat[0]);
          if (Descanso >= 0) and (Descanso < InterjornadaMinima) then
          begin
            It.InterjornadaFaltanteMin := InterjornadaMinima - Descanso;
            It.AddAlerta('Interjornada de ' + MinutosParaHora(Descanso) + ' (mínimo 11h)');
          end;
        end;

        // Intervalo intrajornada (art. 71): 15 min acima de 4h; o da jornada (mínimo 1h) acima de 6h
        if not It.Impar then
        begin
          if It.TrabalhadoMin > 360 then
            Exigido := IfThen(J.IntervaloMin < 60, 60, J.IntervaloMin)
          else if It.TrabalhadoMin > 240 then
            Exigido := 15
          else
            Exigido := 0;
          if (Exigido > 0) and (It.IntervaloMin < Exigido) then
          begin
            It.IntervaloSuprimidoMin := Exigido - It.IntervaloMin;
            It.AddAlerta('Intervalo de ' + MinutosParaHora(It.IntervaloMin) + ' (mínimo ' + MinutosParaHora(Exigido) + ')');
          end;
        end;
      end;

      // Limites legais (alertas; não alteram o cálculo): intervalo máximo de 2h (art. 71), jornada máxima de
      // 10h (art. 59) e descanso semanal: mais de 6 dias seguidos trabalhados (art. 67 e Lei 605/49)
      if N > 0 then
      begin
        Inc(Consecutivos);
        if (not It.Impar) and (It.IntervaloMin > 120) and (not J.E12x36) then
          It.AddAlerta('Intervalo de ' + MinutosParaHora(It.IntervaloMin) + ' acima de 2h (art. 71)');
        if (It.TrabalhadoMin > 600) and (not J.E12x36) then
        begin
          It.AddAlerta('Jornada acima de 10h (art. 59)');
          Inc(R.DiasJornadaAcima10h);
        end;
        if (Consecutivos >= 7) and (not J.E12x36) then
        begin
          It.AddAlerta(Format('%dº dia seguido sem descanso semanal (art. 67)', [Consecutivos]));
          Inc(R.DiasSemDescanso);
        end;
      end
      else
        Consecutivos := 0;

      // Justificativa / abono
      Abono := 0;
      TemJus := JusPorDia.TryGetValue(Trunc(Dia), JusInfo);
      if TemJus then
      begin
        Abono := StrToIntDef(JusInfo[2], 0);
        // O abono cobre só o que faltou: um atestado de meio período não pode virar hora extra
        Faltou := It.CargaPrevistaMin - It.TrabalhadoMin;
        if (Abono <= 0) or (Abono > Faltou) then
          Abono := Faltou;
        if Abono < 0 then
          Abono := 0;
        It.Justificativa := JusInfo[0];
        if JusInfo[1] <> '' then
          It.Justificativa := It.Justificativa + ' (' + JusInfo[1] + ')';
      end;

      // Diferença do dia com tolerância (art. 58 §1º e Súmula 366 TST)
      Diff := It.TrabalhadoMin + Abono - It.CargaPrevistaMin;
      Considerar := Diff;
      if (not It.Impar) and (N > 0) and (Length(Programado) = N) and (It.CargaPrevistaMin > 0) then
      begin
        // Variação de cada marcação em relação ao horário programado
        Soma := 0;
        Dentro := True;
        Ref := 0;
        for I := 0 to N - 1 do
        begin
          Prog := Dia + Programado[I] / 1440;
          if (Ref > 0) and (Prog < Ref) then
            Prog := Prog + 1; // virada da noite
          Ref := Prog;
          V := Abs(DifMin(Prog, Bat[I]));
          Inc(Soma, V);
          if V > ToleranciaPorMarcacao then
            Dentro := False;
        end;
        if Dentro and (Soma <= J.Tolerancia) then
          Considerar := 0;
      end
      else if Abs(Diff) <= J.Tolerancia then
        Considerar := 0;
      It.ExtraMin := IfThen(Considerar > 0, Considerar, 0);
      It.FaltaMin := IfThen(Considerar < 0, -Considerar, 0);
      // "Não contar hora extra neste dia": o que passou do horário não vira extra nem saldo
      if SemExtraDia then
      begin
        if It.ExtraMin > 0 then
          It.AddAlerta('Hora extra de ' + MinutosParaHora(It.ExtraMin) + ' não contada (ajuste do dia)');
        It.ExtraMin := 0;
      end;

      // Dia previsto sem batida e sem justificativa: falta do dia inteiro
      // (hoje sem batidas ainda não é falta: o expediente pode não ter começado)
      if (It.CargaPrevistaMin > 0) and (N = 0) and (not TemJus) and (Dia < Hoje) then
      begin
        It.FaltaMin := It.CargaPrevistaMin;
        It.FaltaDiaInteiro := True;
        It.AddAlerta('Falta Nao Justificada');
        Inc(R.TotalFaltas);
      end;
      // Hoje, com expediente em andamento (sem batida ou batida ímpar), não lança falta parcial
      if (Dia = Hoje) and ((N = 0) or Odd(N)) then
        It.FaltaMin := 0;

      if It.ExtraMin > LimiteExtrasDia then
      begin
        It.AddAlerta('Extra acima de 2h (art. 59)');
        Inc(R.DiasExtraAcima2h);
      end;

      It.SaldoMin := It.ExtraMin - It.FaltaMin;
      if TemJus then
        It.AbonoMin := Min(Abono, It.CargaPrevistaMin);

      if It.Extra100 then
        Inc(R.TotalExtras100Min, It.ExtraMin)
      else
      begin
        F2 := 0;
        if DividirFaixas and (It.ExtraMin > Faixa1) then
          F2 := It.ExtraMin - Faixa1;
        Inc(R.TotalExtras50Min, It.ExtraMin - F2);
        Inc(R.TotalExtrasFaixa2Min, F2);
      end;
      if not It.FaltaDiaInteiro then
        Inc(R.TotalAtrasosMin, It.FaltaMin);
      Inc(R.TotalPrevistoMin, It.CargaPrevistaMin);
      Inc(R.TotalTrabalhadoMin, It.TrabalhadoMin);
      Inc(R.TotalExtrasMin, It.ExtraMin);
      Inc(R.TotalNoturnoMin, It.NoturnoMin);
      Inc(R.TotalAbonadoMin, It.AbonoMin);
      Inc(R.TotalIntervaloSuprimidoMin, It.IntervaloSuprimidoMin);
      Inc(R.TotalInterjornadaMin, It.InterjornadaFaltanteMin);
      Inc(R.TotalFaltasMin, It.FaltaMin);

      SetLength(Espelho.FDias, Length(Espelho.FDias) + 1);
      Espelho.FDias[High(Espelho.FDias)] := It;
      Dia := Dia + 1;
    end;
  finally
    Excluidos.Free;
    AjusteDia.Free;
    JusPorDia.Free;
    PorDia.Free;
    Feriados.Free;
  end;

  // 7. Perda do DSR (Lei 605/49, art. 6º): falta injustificada na semana desconta o domingo seguinte
  if not J.E12x36 then
    for I := 0 to High(Espelho.FDias) do
      if (Espelho.FDias[I].TipoDia = tdDomingoDSR) and
         TemFaltaEntre(Espelho.FDias[I].Data - 6, Espelho.FDias[I].Data - 1) then
      begin
        Espelho.FDias[I].DsrDescontado := True;
        Espelho.FDias[I].AddAlerta('DSR descontado (falta na semana)');
        Inc(R.DsrDescontados);
      end;

  // 7.1 Feriado: não é descontado do total (a carga prevista do dia já é zero e a hora é remunerada),
  //     mas, pela mesma regra do art. 6º da Lei 605/49, perde a remuneração quem faltou sem justificativa
  //     na semana (segunda a sábado) em que ele cai.
  for I := 0 to High(Espelho.FDias) do
    if (Espelho.FDias[I].TipoDia = tdFeriado) and (not Espelho.FDias[I].ForaContrato) then
    begin
      Inc(R.TotalFeriados);
      if J.E12x36 then
        Continue;
      IniSemana := Trunc(Espelho.FDias[I].Data) - (DayOfTheWeek(Espelho.FDias[I].Data) - 1);
      FimSemana := IniSemana + 5;
      if TemFaltaEntre(IniSemana, FimSemana) then
      begin
        Espelho.FDias[I].DsrDescontado := True;
        Espelho.FDias[I].AddAlerta('Feriado descontado (falta na semana)');
        Inc(R.FeriadosDescontados);
      end;
    end;

  // Reflexo das horas extras habituais no descanso remunerado (Súmula 172 TST):
  // extras ÷ dias úteis (segunda a sábado, sem feriados) × domingos e feriados do período.
  // O sábado de quem faz 5x2 entra como dia útil não trabalhado. Com banco de horas as extras não são pagas.
  // Domingo ou feriado perdido por falta na semana não gera reflexo.
  if (not J.BancoHoras) and ((R.TotalExtras50Min + R.TotalExtrasFaixa2Min) > 0) then
  begin
    DUteis := 0;
    DDescanso := 0;
    for I := 0 to High(Espelho.FDias) do
    begin
      if Espelho.FDias[I].ForaContrato or (Espelho.FDias[I].Afastamento <> '') then
        Continue;
      if (Espelho.FDias[I].TipoDia = tdDomingoDSR) or (Espelho.FDias[I].TipoDia = tdFeriado) then
      begin
        if not Espelho.FDias[I].DsrDescontado then
          Inc(DDescanso);
      end
      else if DayOfTheWeek(Espelho.FDias[I].Data) <> 7 then
        Inc(DUteis);
    end;
    if DUteis > 0 then
      R.ReflexoDsrExtrasMin := Round((R.TotalExtras50Min + R.TotalExtrasFaixa2Min) * DDescanso / DUteis);
  end;

  // Adicional noturno: cada 52min30s trabalhados à noite contam como 1h (hora reduzida)
  R.NoturnoPagoMin := Round(R.TotalNoturnoMin * 60 / 52.5);

  // 8. Banco de horas: extras 50% viram crédito e atrasos viram débito (não vão para a folha)
  if J.BancoHoras then
  begin
    R.BancoCreditoMin := R.TotalExtras50Min + R.TotalExtrasFaixa2Min;
    R.BancoDebitoMin := R.TotalAtrasosMin;
  end;
  if R.UsaBancoHoras then
    R.SaldoTotalMin := R.BancoCreditoMin - R.BancoDebitoMin
  else
    R.SaldoTotalMin := R.TotalExtrasMin - R.TotalFaltasMin;
  Inc(R.SaldoTotalMin, R.SaldoAnteriorMin + R.CreditoHorasMin);

  Espelho.FResumo := R;
end;

initialization

finalization
  FreeAndNil(FalhasJaRegistradas);

end.
