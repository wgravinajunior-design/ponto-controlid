program PontoCalculoTests;

// Testes das regras puras do cálculo do ponto (sem banco de dados).
// Compilar e executar:  dcc32 -B -U.. -NSSystem;Winapi;Data;FireDAC;Vcl PontoCalculoTests.dpr  &&  PontoCalculoTests.exe
// Sai com código 1 se algum teste falhar.

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.DateUtils, uPontoCalculoService;

var
  Falhas, Total: Integer;

procedure Confere(const ANome: string; AEsperado, AObtido: Integer); overload;
begin
  Inc(Total);
  if AEsperado <> AObtido then
  begin
    Inc(Falhas);
    WriteLn('FALHA  ', ANome, ': esperado ', AEsperado, ', obtido ', AObtido);
  end;
end;

procedure Confere(const ANome, AEsperado, AObtido: string); overload;
begin
  Inc(Total);
  if AEsperado <> AObtido then
  begin
    Inc(Falhas);
    WriteLn('FALHA  ', ANome, ': esperado "', AEsperado, '", obtido "', AObtido, '"');
  end;
end;

function DH(A, M, D, H, Mi: Word): TDateTime;
begin
  Result := EncodeDateTime(A, M, D, H, Mi, 0, 0);
end;

begin
  Falhas := 0;
  Total := 0;

  // Formatação e leitura de horas
  Confere('00:00', '00:00', TPontoCalculoService.MinutosParaHora(0));
  Confere('08:48', '08:48', TPontoCalculoService.MinutosParaHora(528));
  Confere('negativo', '-01:05', TPontoCalculoService.MinutosParaHora(-65));
  Confere('sinal +', '+00:30', TPontoCalculoService.MinutosParaHora(30, True));
  Confere('HH:MM', 528, TPontoCalculoService.HoraParaMinutos('08:48'));
  Confere('vazio', 0, TPontoCalculoService.HoraParaMinutos(''));

  // Páscoa (Sexta-feira Santa = Páscoa - 2)
  Confere('Páscoa 2024', 20240331, YearOf(TPontoCalculoService.Pascoa(2024)) * 10000 +
    MonthOf(TPontoCalculoService.Pascoa(2024)) * 100 + DayOf(TPontoCalculoService.Pascoa(2024)));
  Confere('Páscoa 2025', 20250420, YearOf(TPontoCalculoService.Pascoa(2025)) * 10000 +
    MonthOf(TPontoCalculoService.Pascoa(2025)) * 100 + DayOf(TPontoCalculoService.Pascoa(2025)));
  Confere('Páscoa 2026', 20260405, YearOf(TPontoCalculoService.Pascoa(2026)) * 10000 +
    MonthOf(TPontoCalculoService.Pascoa(2026)) * 100 + DayOf(TPontoCalculoService.Pascoa(2026)));

  // Adicional noturno (22h às 5h, art. 73) e prorrogação (Súmula 60 TST)
  Confere('diurno', 0, TPontoCalculoService.MinutosNoturnos(DH(2026, 3, 2, 8, 0), DH(2026, 3, 2, 17, 0)));
  Confere('22h às 23h', 60, TPontoCalculoService.MinutosNoturnos(DH(2026, 3, 2, 22, 0), DH(2026, 3, 2, 23, 0)));
  Confere('noite inteira sem prorrogação', 420,
    TPontoCalculoService.MinutosNoturnos(DH(2026, 3, 2, 22, 0), DH(2026, 3, 3, 5, 0)));
  Confere('prorrogação até 6h', 480,
    TPontoCalculoService.MinutosNoturnos(DH(2026, 3, 2, 22, 0), DH(2026, 3, 3, 6, 0)));
  Confere('entrou depois das 22h, sem prorrogação', 360,
    TPontoCalculoService.MinutosNoturnos(DH(2026, 3, 2, 23, 0), DH(2026, 3, 3, 6, 0), False));
  Confere('fim antes do início', 0, TPontoCalculoService.MinutosNoturnos(DH(2026, 3, 2, 23, 0), DH(2026, 3, 2, 22, 0)));

  WriteLn(Format('%d teste(s), %d falha(s).', [Total, Falhas]));
  if Falhas > 0 then
    Halt(1);
end.
