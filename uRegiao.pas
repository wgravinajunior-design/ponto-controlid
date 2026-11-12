unit uRegiao;

// Padrão regional do sistema: português do Brasil.
// - Datas sempre dd/mm/aaaa e horas hh:nn (ou hh:nn:ss), com nomes de meses e dias em português;
// - os seletores de data (TDateTimePicker) usam o mesmo formato, em qualquer tela ou sub-tela.
// O calendário que abre no seletor é desenhado pelo Windows: o idioma dele segue a região do sistema.
// Aqui o programa pede pt-BR para si mesmo, o que vale mesmo com o Windows em outro idioma na maioria das versões.

interface

uses
  System.Classes;

// Chamar uma vez, antes de criar qualquer formulário
procedure ConfigurarRegiaoBrasil;

// Aplica o formato de data/hora aos seletores de data do formulário (e de seus filhos)
procedure PadronizarSeletoresDeData(AContainer: TComponent);

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.ComCtrls;

procedure ConfigurarRegiaoBrasil;
var
  Br: TFormatSettings;
  I: Integer;
begin
  try
    SetThreadLocale($0416);          // pt-BR
    SetThreadUILanguage($0416);
  except
  end;

  Br := TFormatSettings.Create('pt-BR');
  // só o que é data e hora: separadores decimais e de milhar continuam os do sistema
  FormatSettings.DateSeparator := '/';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.ShortDateFormat := 'dd/mm/yyyy';
  FormatSettings.LongDateFormat := 'dddd, d "de" mmmm "de" yyyy';
  FormatSettings.ShortTimeFormat := 'hh:nn';
  FormatSettings.LongTimeFormat := 'hh:nn:ss';
  FormatSettings.TimeAMString := '';
  FormatSettings.TimePMString := '';
  for I := 1 to 12 do
  begin
    FormatSettings.ShortMonthNames[I] := Br.ShortMonthNames[I];
    FormatSettings.LongMonthNames[I] := Br.LongMonthNames[I];
  end;
  for I := 1 to 7 do
  begin
    FormatSettings.ShortDayNames[I] := Br.ShortDayNames[I];
    FormatSettings.LongDayNames[I] := Br.LongDayNames[I];
  end;
end;

procedure PadronizarSeletoresDeData(AContainer: TComponent);
var
  I: Integer;
  C: TComponent;
begin
  for I := 0 to AContainer.ComponentCount - 1 do
  begin
    C := AContainer.Components[I];
    if C is TDateTimePicker then
    begin
      case TDateTimePicker(C).Kind of
        dtkDate: TDateTimePicker(C).Format := 'dd/MM/yyyy';
        dtkTime: TDateTimePicker(C).Format := 'HH:mm:ss';
      end;
    end;
    if C.ComponentCount > 0 then
      PadronizarSeletoresDeData(C);
  end;
end;

end.
