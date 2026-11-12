unit uRelatorioPonto;

{
  Relatório padrão de Entradas e Saídas (cartão de ponto).

  Lista, para cada colaborador e cada dia do período, as batidas registradas
  (1ª Entrada / 1ª Saída / 2ª Entrada / 2ª Saída / demais) e as horas
  trabalhadas pelos pares Entrada-Saída. Independe da origem da marcação
  (relógio Control iD, leitor biométrico Hamster DX ou lançamento manual).
}

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.StrUtils, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Stan.Param, Data.DB, uDataModule;

type
  TRelatorioPonto = class
  public
    // APessoaId = 0 gera para todos os colaboradores ativos (e inativos com batidas no período)
    class function GerarEntradasSaidasHTML(ADataIni, ADataFim: TDateTime; APessoaId: Integer;
      const ARazaoEmpresa, ACnpjEmpresa: string): string;
  end;

implementation

type
  TBatida = record
    DataHora: TDateTime;
    Manual: Boolean;
  end;

function Esc(const S: string): string;
begin
  Result := S.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;');
end;

function MinutosParaHHMM(AMinutos: Integer): string;
begin
  Result := Format('%.2d:%.2d', [AMinutos div 60, AMinutos mod 60]);
end;

function FormatarDoc(const ADoc: string): string;
var
  D: string;
  C: Char;
begin
  D := '';
  for C in ADoc do
    if CharInSet(C, ['0'..'9']) then
      D := D + C;
  if Length(D) = 14 then
    Result := Format('%s.%s.%s/%s-%s', [Copy(D, 1, 2), Copy(D, 3, 3), Copy(D, 6, 3), Copy(D, 9, 4), Copy(D, 13, 2)])
  else if Length(D) = 11 then
    Result := Format('%s.%s.%s-%s', [Copy(D, 1, 3), Copy(D, 4, 3), Copy(D, 7, 3), Copy(D, 10, 2)])
  else
    Result := ADoc;
end;

const
  DIAS_SEMANA: array[1..7] of string = ('Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado');

class function TRelatorioPonto.GerarEntradasSaidasHTML(ADataIni, ADataFim: TDateTime; APessoaId: Integer;
  const ARazaoEmpresa, ACnpjEmpresa: string): string;
var
  Qry: TFDQuery;
  Batidas: TObjectDictionary<Integer, TList<TBatida>>;
  Lista, DoDia: TList<TBatida>;
  B: TBatida;
  SB: TStringBuilder;
  PessoaId, I, MinDia, MinTotal, DiasTrab, Pares: Integer;
  Dia: TDateTime;
  Celula, ClasseLinha, Obs: string;
  TemIncompleto: Boolean;
begin
  ADataIni := Trunc(ADataIni);
  ADataFim := Trunc(ADataFim);

  Batidas := TObjectDictionary<Integer, TList<TBatida>>.Create([doOwnsValues]);
  DoDia := TList<TBatida>.Create;
  SB := TStringBuilder.Create;
  Qry := TFDQuery.Create(nil);
  try
    if not dmDados.IsConectado then
      dmDados.Conectar;
    Qry.Connection := dmDados.FDConnection;

    // 1. Batidas do período agrupadas por colaborador
    Qry.SQL.Text :=
      'SELECT PMA_PESSOA, PMA_DATA_HORA, PMA_ORIGEM FROM TB_PONTO_MARCACAO ' +
      'WHERE PMA_PESSOA IS NOT NULL AND PMA_DATA_HORA BETWEEN :INI AND :FIM ' + dmDados.CondMarcacaoValida +
      IfThen(APessoaId > 0, 'AND PMA_PESSOA = :PESSOA ', '') +
      'ORDER BY PMA_PESSOA, PMA_DATA_HORA';
    Qry.ParamByName('INI').AsDateTime := StartOfTheDay(ADataIni);
    Qry.ParamByName('FIM').AsDateTime := EndOfTheDay(ADataFim);
    if APessoaId > 0 then
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.Open;
    while not Qry.Eof do
    begin
      PessoaId := Qry.FieldByName('PMA_PESSOA').AsInteger;
      if not Batidas.TryGetValue(PessoaId, Lista) then
      begin
        Lista := TList<TBatida>.Create;
        Batidas.Add(PessoaId, Lista);
      end;
      B.DataHora := Qry.FieldByName('PMA_DATA_HORA').AsDateTime;
      B.Manual := SameText(Qry.FieldByName('PMA_ORIGEM').AsString, 'M');
      Lista.Add(B);
      Qry.Next;
    end;
    Qry.Close;

    // 2. Cabeçalho do documento
    SB.AppendLine('<!DOCTYPE html>');
    SB.AppendLine('<html lang="pt-BR">');
    SB.AppendLine('<head>');
    SB.AppendLine('  <meta charset="UTF-8">');
    SB.AppendLine('  <title>Relatório de Entradas e Saídas</title>');
    SB.AppendLine('  <style>');
    SB.AppendLine('    body { font-family: Segoe UI, Arial, sans-serif; font-size: 12px; color: #222; margin: 20px; }');
    SB.AppendLine('    .colab { page-break-after: always; margin-bottom: 30px; }');
    SB.AppendLine('    .colab:last-child { page-break-after: auto; }');
    SB.AppendLine('    .header { border-bottom: 2px solid #2b579a; padding-bottom: 8px; margin-bottom: 12px; }');
    SB.AppendLine('    .header h2 { margin: 0 0 4px 0; color: #1e395b; }');
    SB.AppendLine('    .header p { margin: 2px 0; font-size: 11px; color: #555; }');
    SB.AppendLine('    .info-box { background: #f4f6f9; border: 1px solid #d5dbe3; border-radius: 4px; padding: 10px; margin-bottom: 12px; }');
    SB.AppendLine('    .info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }');
    SB.AppendLine('    table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }');
    SB.AppendLine('    th { background: #2b579a; color: #fff; padding: 6px 4px; text-align: center; font-size: 11px; }');
    SB.AppendLine('    td { border: 1px solid #e1e4e8; padding: 5px 4px; text-align: center; font-size: 11px; }');
    SB.AppendLine('    tr:nth-child(even) { background-color: #fcfcfc; }');
    SB.AppendLine('    .fds { background-color: #f3f3f3 !important; color: #888; }');
    SB.AppendLine('    .impar { background-color: #fff9db !important; color: #b45309; font-weight: bold; }');
    SB.AppendLine('    .total td { font-weight: bold; background: #eef2f7; }');
    SB.AppendLine('    .legenda { font-size: 10px; color: #666; }');
    SB.AppendLine('    .signatures { display: grid; grid-template-columns: 1fr 1fr; gap: 60px; margin-top: 40px; text-align: center; }');
    SB.AppendLine('    .sign-line { border-top: 1px solid #333; padding-top: 5px; margin-top: 40px; }');
    SB.AppendLine('    @media print { body { margin: 8mm; } }');
    SB.AppendLine('  </style>');
    SB.AppendLine('</head>');
    SB.AppendLine('<body>');

    // 3. Colaboradores: ativos + quem tiver batida no período
    Qry.SQL.Text :=
      'SELECT P.PES_ID, P.PES_RSOCIAL_NOME, P.PES_CNPJ_CPF, C.COL_PIS, C.COL_CARTAO_PONTO, C.COL_FUNCAO ' +
      'FROM TB_PESSOA P ' +
      'LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID ' +
      'WHERE (P.PES_COLABORADOR = ''S'' OR C.COL_PESSOA IS NOT NULL) ' +
      '  AND (COALESCE(P.PES_STATUS, ''A'') = ''A'' OR EXISTS (SELECT 1 FROM TB_PONTO_MARCACAO M ' +
      '       WHERE M.PMA_PESSOA = P.PES_ID AND M.PMA_DATA_HORA BETWEEN :INI AND :FIM ' +
      dmDados.CondMarcacaoValida('M.') + ')) ' +
      IfThen(APessoaId > 0, 'AND P.PES_ID = :PESSOA ', '') +
      'ORDER BY P.PES_RSOCIAL_NOME';
    Qry.ParamByName('INI').AsDateTime := StartOfTheDay(ADataIni);
    Qry.ParamByName('FIM').AsDateTime := EndOfTheDay(ADataFim);
    if APessoaId > 0 then
      Qry.ParamByName('PESSOA').AsInteger := APessoaId;
    Qry.Open;

    if Qry.IsEmpty then
      SB.AppendLine('<p>Nenhum colaborador encontrado para o período.</p>');

    while not Qry.Eof do
    begin
      PessoaId := Qry.FieldByName('PES_ID').AsInteger;
      if not Batidas.TryGetValue(PessoaId, Lista) then
        Lista := nil;

      SB.AppendLine('<div class="colab">');
      SB.AppendLine('  <div class="header">');
      SB.AppendLine('    <h2>Relatório de Entradas e Saídas</h2>');
      SB.AppendLine(Format('    <p><b>Empregador:</b> %s &nbsp;&nbsp; <b>CNPJ/CPF:</b> %s</p>',
        [Esc(ARazaoEmpresa), Esc(FormatarDoc(ACnpjEmpresa))]));
      SB.AppendLine(Format('    <p><b>Período:</b> %s a %s &nbsp;&nbsp; <b>Emitido em:</b> %s</p>',
        [FormatDateTime('dd/mm/yyyy', ADataIni), FormatDateTime('dd/mm/yyyy', ADataFim),
         FormatDateTime('dd/mm/yyyy hh:nn', Now)]));
      SB.AppendLine('  </div>');
      SB.AppendLine('  <div class="info-box"><div class="info-grid">');
      SB.AppendLine(Format('    <div><b>Colaborador:</b> %s</div>', [Esc(Qry.FieldByName('PES_RSOCIAL_NOME').AsString)]));
      SB.AppendLine(Format('    <div><b>CPF:</b> %s</div>', [Esc(FormatarDoc(Qry.FieldByName('PES_CNPJ_CPF').AsString))]));
      SB.AppendLine(Format('    <div><b>PIS:</b> %s</div>', [Esc(Qry.FieldByName('COL_PIS').AsString)]));
      SB.AppendLine(Format('    <div><b>Matrícula:</b> %s</div>', [Esc(Qry.FieldByName('COL_CARTAO_PONTO').AsString)]));
      SB.AppendLine(Format('    <div><b>Função:</b> %s</div>', [Esc(Qry.FieldByName('COL_FUNCAO').AsString)]));
      SB.AppendLine('  </div></div>');

      SB.AppendLine('  <table>');
      SB.AppendLine('    <tr><th>Data</th><th>Dia</th><th>1ª Entrada</th><th>1ª Saída</th><th>2ª Entrada</th>' +
        '<th>2ª Saída</th><th>Demais Batidas</th><th>Horas Trabalhadas</th><th>Observação</th></tr>');

      MinTotal := 0;
      DiasTrab := 0;
      Dia := ADataIni;
      while Dia <= ADataFim do
      begin
        DoDia.Clear;
        if Lista <> nil then
          for B in Lista do
            // ignora leitura repetida (< 10 min da anterior), igual ao espelho
            if (Trunc(B.DataHora) = Dia) and ((DoDia.Count = 0) or
               (MinutesBetween(B.DataHora, DoDia[DoDia.Count - 1].DataHora) >= 10)) then
              DoDia.Add(B);

        // Horas pelos pares Entrada/Saída do dia
        MinDia := 0;
        Pares := DoDia.Count div 2;
        for I := 0 to Pares - 1 do
          MinDia := MinDia + MinutesBetween(DoDia[I * 2 + 1].DataHora, DoDia[I * 2].DataHora);
        TemIncompleto := Odd(DoDia.Count);
        if DoDia.Count > 0 then
          Inc(DiasTrab);
        MinTotal := MinTotal + MinDia;

        if TemIncompleto then
          ClasseLinha := ' class="impar"'
        else if DayOfWeek(Dia) in [1, 7] then
          ClasseLinha := ' class="fds"'
        else
          ClasseLinha := '';

        SB.Append(Format('    <tr%s><td>%s</td><td>%s</td>',
          [ClasseLinha, FormatDateTime('dd/mm/yyyy', Dia), DIAS_SEMANA[DayOfWeek(Dia)]]));
        for I := 0 to 3 do
        begin
          if I < DoDia.Count then
          begin
            Celula := FormatDateTime('hh:nn', DoDia[I].DataHora);
            if DoDia[I].Manual then
              Celula := Celula + '*';
          end
          else
            Celula := '—';
          SB.Append('<td>' + Celula + '</td>');
        end;
        Celula := '';
        for I := 4 to DoDia.Count - 1 do
        begin
          if Celula <> '' then
            Celula := Celula + ' ';
          Celula := Celula + FormatDateTime('hh:nn', DoDia[I].DataHora);
          if DoDia[I].Manual then
            Celula := Celula + '*';
        end;
        if Celula = '' then
          Celula := '—';
        SB.Append('<td>' + Celula + '</td>');

        if DoDia.Count > 0 then
          SB.Append('<td>' + MinutosParaHHMM(MinDia) + '</td>')
        else
          SB.Append('<td>—</td>');

        if TemIncompleto then
          Obs := 'Batida ímpar (falta registro)'
        else if (DoDia.Count = 0) and not (DayOfWeek(Dia) in [1, 7]) then
          Obs := 'Sem registro'
        else
          Obs := '';
        SB.AppendLine('<td>' + Obs + '</td></tr>');

        Dia := IncDay(Dia);
      end;

      SB.AppendLine(Format('    <tr class="total"><td colspan="7">Total do período (%d dia(s) com registro)</td><td>%s</td><td></td></tr>',
        [DiasTrab, MinutosParaHHMM(MinTotal)]));
      SB.AppendLine('  </table>');
      SB.AppendLine('  <p class="legenda">* Batida incluída/corrigida manualmente. Horas trabalhadas calculadas pelos pares Entrada/Saída de cada dia.</p>');
      SB.AppendLine('  <div class="signatures">');
      SB.AppendLine('    <div class="sign-line">Assinatura do Colaborador</div>');
      SB.AppendLine('    <div class="sign-line">Assinatura do Empregador</div>');
      SB.AppendLine('  </div>');
      SB.AppendLine('</div>');

      Qry.Next;
    end;

    SB.AppendLine('</body>');
    SB.AppendLine('</html>');
    Result := SB.ToString;
  finally
    Qry.Free;
    SB.Free;
    DoDia.Free;
    Batidas.Free;
  end;
end;

end.
