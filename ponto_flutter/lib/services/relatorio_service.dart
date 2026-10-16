import '../core/util.dart';
import '../data/database.dart';

class _Batida {
  final DateTime dataHora;
  final bool manual;
  _Batida(this.dataHora, this.manual);
}

/// Relatório (cartão de ponto) de Entradas e Saídas (port de TRelatorioPonto).
class RelatorioPonto {
  static const _diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  /// [pessoaId] = 0 gera para todos os colaboradores ativos (e inativos com batidas no período).
  static Future<String> gerarEntradasSaidasHtml(
      DateTime dataIni, DateTime dataFim, int pessoaId, String razaoEmpresa, String cnpjEmpresa) async {
    final ini = soData(dataIni), fim = soData(dataFim);
    final db = Db.instance;

    // 1. Batidas do período agrupadas por colaborador
    final params = <dynamic>[inicioDoDia(ini), fimDoDia(fim)];
    if (pessoaId > 0) params.add(pessoaId);
    final rows = await db.query(
        'SELECT PMA_PESSOA, PMA_DATA_HORA, PMA_ORIGEM FROM TB_PONTO_MARCACAO '
        'WHERE PMA_PESSOA IS NOT NULL AND PMA_DATA_HORA BETWEEN ? AND ? AND ${Db.validas} '
        '${pessoaId > 0 ? 'AND PMA_PESSOA = ? ' : ''}ORDER BY PMA_PESSOA, PMA_DATA_HORA',
        params);
    final batidas = <int, List<_Batida>>{};
    for (final r in rows) {
      final dh = asDate(r['PMA_DATA_HORA']);
      if (dh == null) continue;
      batidas.putIfAbsent(asInt(r['PMA_PESSOA']), () => []).add(_Batida(dh, asStr(r['PMA_ORIGEM']).toUpperCase() == 'M'));
    }

    final sb = StringBuffer()
      ..writeln('<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8">')
      ..writeln('<title>Relatório de Entradas e Saídas</title><style>')
      ..writeln('body { font-family: Segoe UI, Arial, sans-serif; font-size: 12px; color: #222; margin: 20px; }')
      ..writeln('.colab { page-break-after: always; margin-bottom: 30px; } .colab:last-child { page-break-after: auto; }')
      ..writeln('.header { border-bottom: 2px solid #2b579a; padding-bottom: 8px; margin-bottom: 12px; }')
      ..writeln('.header h2 { margin: 0 0 4px 0; color: #1e395b; } .header p { margin: 2px 0; font-size: 11px; color: #555; }')
      ..writeln('.info-box { background: #f4f6f9; border: 1px solid #d5dbe3; border-radius: 4px; padding: 10px; margin-bottom: 12px; }')
      ..writeln('.info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }')
      ..writeln('table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }')
      ..writeln('th { background: #2b579a; color: #fff; padding: 6px 4px; text-align: center; font-size: 11px; }')
      ..writeln('td { border: 1px solid #e1e4e8; padding: 5px 4px; text-align: center; font-size: 11px; }')
      ..writeln('tr:nth-child(even) { background-color: #fcfcfc; }')
      ..writeln('.fds { background-color: #f3f3f3 !important; color: #888; }')
      ..writeln('.impar { background-color: #fff9db !important; color: #b45309; font-weight: bold; }')
      ..writeln('.total td { font-weight: bold; background: #eef2f7; } .legenda { font-size: 10px; color: #666; }')
      ..writeln('.signatures { display: grid; grid-template-columns: 1fr 1fr; gap: 60px; margin-top: 40px; text-align: center; }')
      ..writeln('.sign-line { border-top: 1px solid #333; padding-top: 5px; margin-top: 40px; }')
      ..writeln('@media print { body { margin: 8mm; } }')
      ..writeln('</style></head><body>');

    // 3. Colaboradores: ativos + quem tiver batida no período
    final pp = <dynamic>[inicioDoDia(ini), fimDoDia(fim)];
    if (pessoaId > 0) pp.add(pessoaId);
    final colabs = await db.query(
        'SELECT P.PES_ID, P.PES_RSOCIAL_NOME, P.PES_CNPJ_CPF, C.COL_PIS, C.COL_CARTAO_PONTO, C.COL_FUNCAO '
        'FROM TB_PESSOA P LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID '
        "WHERE (P.PES_COLABORADOR = 'S' OR C.COL_PESSOA IS NOT NULL) "
        "AND (COALESCE(P.PES_STATUS, 'A') = 'A' OR EXISTS (SELECT 1 FROM TB_PONTO_MARCACAO M "
        'WHERE M.PMA_PESSOA = P.PES_ID AND M.PMA_DATA_HORA BETWEEN ? AND ?)) '
        '${pessoaId > 0 ? 'AND P.PES_ID = ? ' : ''}ORDER BY P.PES_RSOCIAL_NOME',
        pp);
    if (colabs.isEmpty) sb.writeln('<p>Nenhum colaborador encontrado para o período.</p>');

    for (final c in colabs) {
      final lista = batidas[asInt(c['PES_ID'])] ?? const <_Batida>[];
      sb
        ..writeln('<div class="colab"><div class="header"><h2>Relatório de Entradas e Saídas</h2>')
        ..writeln('<p><b>Empregador:</b> ${esc(razaoEmpresa)} &nbsp;&nbsp; <b>CNPJ/CPF:</b> ${esc(formatarDoc(cnpjEmpresa))}</p>')
        ..writeln('<p><b>Período:</b> ${fmtData(ini)} a ${fmtData(fim)} &nbsp;&nbsp; <b>Emitido em:</b> '
            '${fmtData(DateTime.now())} ${fmtHora(DateTime.now())}</p></div>')
        ..writeln('<div class="info-box"><div class="info-grid">')
        ..writeln('<div><b>Colaborador:</b> ${esc(asStr(c['PES_RSOCIAL_NOME']))}</div>')
        ..writeln('<div><b>CPF:</b> ${esc(formatarDoc(asStr(c['PES_CNPJ_CPF'])))}</div>')
        ..writeln('<div><b>PIS:</b> ${esc(asStr(c['COL_PIS']))}</div>')
        ..writeln('<div><b>Matrícula:</b> ${esc(asStr(c['COL_CARTAO_PONTO']))}</div>')
        ..writeln('<div><b>Função:</b> ${esc(asStr(c['COL_FUNCAO']))}</div>')
        ..writeln('</div></div><table>')
        ..writeln('<tr><th>Data</th><th>Dia</th><th>1ª Entrada</th><th>1ª Saída</th><th>2ª Entrada</th>'
            '<th>2ª Saída</th><th>Demais Batidas</th><th>Horas Trabalhadas</th><th>Observação</th></tr>');

      var minTotal = 0, diasTrab = 0;
      for (var dia = ini; !dia.isAfter(fim); dia = DateTime(dia.year, dia.month, dia.day + 1)) {
        final doDia = lista.where((b) => soData(b.dataHora) == dia).toList();
        var minDia = 0;
        for (var i = 0; i < doDia.length ~/ 2; i++) {
          minDia += minutesBetween(doDia[i * 2 + 1].dataHora, doDia[i * 2].dataHora);
        }
        final incompleto = doDia.length.isOdd;
        final fds = dia.weekday == DateTime.saturday || dia.weekday == DateTime.sunday;
        if (doDia.isNotEmpty) diasTrab++;
        minTotal += minDia;

        String cel(_Batida b) => fmtHora(b.dataHora) + (b.manual ? '*' : '');
        sb.write('<tr${incompleto ? ' class="impar"' : (fds ? ' class="fds"' : '')}><td>${fmtData(dia)}</td>'
            '<td>${_diasSemana[dia.weekday - 1]}</td>');
        for (var i = 0; i < 4; i++) {
          sb.write('<td>${i < doDia.length ? cel(doDia[i]) : '—'}</td>');
        }
        final demais = doDia.skip(4).map(cel).join(' ');
        sb.write('<td>${demais.isEmpty ? '—' : demais}</td>');
        sb.write('<td>${doDia.isNotEmpty ? minutosParaHora(minDia).replaceAll('-', '') : '—'}</td>');
        final obs = incompleto ? 'Batida ímpar (falta registro)' : (doDia.isEmpty && !fds ? 'Sem registro' : '');
        sb.writeln('<td>$obs</td></tr>');
      }
      sb
        ..writeln('<tr class="total"><td colspan="7">Total do período ($diasTrab dia(s) com registro)</td>'
            '<td>${minutosParaHora(minTotal)}</td><td></td></tr></table>')
        ..writeln('<p class="legenda">* Batida incluída/corrigida manualmente. Horas trabalhadas calculadas pelos '
            'pares Entrada/Saída de cada dia.</p>')
        ..writeln('<div class="signatures"><div class="sign-line">Assinatura do Colaborador</div>'
            '<div class="sign-line">Assinatura do Empregador</div></div></div>');
    }
    sb.writeln('</body></html>');
    return sb.toString();
  }
}
