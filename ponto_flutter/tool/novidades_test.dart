// ignore_for_file: avoid_print
// Confere gravação e leitura das novidades (jornada por dia, crédito de horas, conferência e feriados)
// em um banco Firebird TEMPORÁRIO. Uso: dart run tool/novidades_test.dart <Config.ini> <pasta temporária>
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ponto_flutter/core/config.dart';
import 'package:ponto_flutter/core/util.dart';
import 'package:ponto_flutter/data/database.dart';
import 'package:ponto_flutter/services/banco_horas_service.dart';
import 'package:ponto_flutter/services/calculo_service.dart';
import 'package:ponto_flutter/services/relatorio_service.dart';

var falhas = 0;
void check(bool cond, String msg) {
  if (!cond) falhas++;
  print('${cond ? 'ok ' : 'XX '} $msg');
}

final db = Db.instance;
DateTime d(int dia, [int h = 0, int m = 0]) => DateTime(2026, 9, dia, h, m); // 07/09/2026 = segunda (feriado)

Future<void> main(List<String> args) async {
  final cfg = AppConfig.instance..load(args[0]);
  final arq = p.join(args[1], 'novidades_teste.fdb');
  if (File(arq).existsSync()) File(arq).deleteSync();
  cfg.firebird.database = arq;
  if (!await db.conectar()) {
    print('Falha ao conectar: ${db.lastError}');
    exit(1);
  }

  // ---------- Estrutura ----------
  for (final t in ['TB_PONTO_HORARIO_DIA', 'TB_PONTO_BANCO_HORAS', 'TB_PONTO_FERIADO']) {
    check(await db.tabelaExiste(t), 'tabela $t existe');
  }
  final cols = {
    for (final r in await db.query("SELECT TRIM(RDB\$FIELD_NAME) AS C FROM RDB\$RELATION_FIELDS "
        "WHERE RDB\$RELATION_NAME IN ('TB_PONTO_HORARIO_DIA', 'TB_PONTO_HORARIO', 'TB_PONTO_BANCO_HORAS', 'TB_PONTO_FERIADO')"))
      asStr(r['C'])
  };
  for (final c in [
    'HDI_HORARIO', 'HDI_DIA_SEMANA', 'HDI_ENTRADA_1', 'HDI_SAIDA_1', 'HDI_ENTRADA_2', 'HDI_SAIDA_2', 'HDI_CARGA_MIN',
    'HDI_FOLGA', 'HOR_COMPENSA_SABADO', 'HOR_TRABALHA_SABADO', 'HOR_SAB_ENTRADA_1', 'HOR_SAB_SAIDA_1',
    'BH_TIPO', 'BH_DATA', 'BH_MINUTOS', 'FER_ORIGEM', 'FER_RECORRENTE',
  ]) {
    check(cols.contains(c), 'campo $c existe');
  }

  // ---------- Jornada por dia (como a tela grava) ----------
  final h = await db.salvarHorario(0, 'Grade teste', '08:00', '12:00', '13:00', '18:00', 10, 540, true, true, '08:00', '12:00', true);
  await db.salvarRegrasHorario(h, 'SEMANAL', null, '00:00', 60, false);
  await db.salvarHorarioDias(h, {
    for (var x = 1; x <= 4; x++) x: (e1: '08:00', s1: '12:00', e2: '13:00', s2: '18:00', carga: 540, folga: false),
    5: (e1: '08:00', s1: '12:00', e2: '13:00', s2: '17:00', carga: 480, folga: false),
    6: (e1: '08:00', s1: '12:00', e2: '', s2: '', carga: 240, folga: false),
    7: (e1: '', s1: '', e2: '', s2: '', carga: 0, folga: true),
  });
  final dias = await db.getHorarioDias(h);
  check(dias.length == 7, 'jornada grava os 7 dias (${dias.length})');
  check(asStr(dias[5]!['HDI_SAIDA_2']) == '17:00' && asInt(dias[5]!['HDI_CARGA_MIN']) == 480, 'sexta 08-12/13-17 gravada');
  check(asStr(dias[6]!['HDI_SAIDA_1']) == '12:00' && asStr(dias[6]!['HDI_ENTRADA_2']).isEmpty, 'sábado sem almoço gravado');
  check(asStr(dias[7]!['HDI_FOLGA']) == 'S', 'domingo folga gravado');
  final hr = await db.getHorarioPorId(h);
  check(asStr(hr?['HOR_COMPENSA_SABADO']) == 'S' && asStr(hr?['HOR_TRABALHA_SABADO']) == 'S', 'flags de sábado gravadas');

  final pid = await db.salvarColaborador(0, 'Grade Dia', '', '', '', '', '', true, h);
  final e = await PontoCalculoService.calcularEspelho(pid, d(8), d(13));
  final porDia = {for (final x in e.dias) x.data.day: x};
  check(porDia[8]!.cargaPrevistaMin == 540, 'terça prevista 9h (${porDia[8]!.cargaPrevistaStr})');
  check(porDia[11]!.cargaPrevistaMin == 480, 'sexta prevista 8h (${porDia[11]!.cargaPrevistaStr})');
  check(porDia[12]!.cargaPrevistaMin == 240 && porDia[12]!.tipoDia == TipoDia.sabadoTrabalhado, 'sábado previsto 4h');
  check(porDia[13]!.tipoDia == TipoDia.domingoDsr, 'domingo DSR');

  // Sábado de folga com "compensa sábado" sai como compensado
  await db.salvarHorarioDias(h, {
    6: (e1: '', s1: '', e2: '', s2: '', carga: 0, folga: true),
  });
  final sab = (await PontoCalculoService.calcularEspelho(pid, d(12), d(12))).dias.first;
  check(sab.tipoDia == TipoDia.sabadoCompensado && sab.cargaPrevistaMin == 0, 'sábado folga = compensado');

  // ---------- Crédito de horas ----------
  await db.lancarBancoHoras(pid, d(10), 750, 'S', 'Saldo do sistema anterior');
  await db.lancarBancoHoras(pid, d(10), -90, 'S', 'Débito manual');
  final bh = await db.getBancoHoras(pessoaId: pid);
  check(bh.length == 2 && asStr(bh.first['BH_TIPO']) == 'S', 'crédito de horas gravado com tipo S');
  final eCred = await PontoCalculoService.calcularEspelho(pid, d(1), d(30));
  check(eCred.resumo.creditoHorasMin == 660, 'crédito entra no período (${minutosParaHora(eCred.resumo.creditoHorasMin)})');
  check(eCred.resumo.saldoFinalMin == eCred.resumo.saldoTotalMin + 660, 'saldo final soma o crédito');
  final eFora = await PontoCalculoService.calcularEspelho(pid, DateTime(2026, 10, 1), DateTime(2026, 10, 31));
  check(eFora.resumo.creditoHorasMin == 0, 'sem banco: crédito não se repete no mês seguinte');
  await db.salvarRegrasHorario(h, 'SEMANAL', null, '00:00', 60, true);
  final eBanco = await PontoCalculoService.calcularEspelho(pid, DateTime(2026, 10, 1), DateTime(2026, 10, 31));
  check(eBanco.resumo.bancoSaldoAnteriorMin == 660, 'com banco: crédito vira saldo anterior do mês seguinte');
  final saldo = (await BancoHorasService.saldos()).firstWhere((s) => s.pessoaId == pid);
  check(saldo.saldoMin == 660, 'tela de banco mostra o saldo (${minutosParaHora(saldo.saldoMin)})');

  // ---------- Conferência do dia ----------
  await db.inserirMarcacaoManual(pid, 0, d(8, 8), 'E', 'teste');
  await db.inserirMarcacaoManual(pid, 0, d(8, 12), 'S', 'teste');
  final html = await RelatorioPonto.gerarConferenciaDiaHtml(d(8), 0, 'Empresa', '');
  check(html.contains('Grade Dia') && html.contains('08:00') && html.contains('Com registro<b>1</b>'),
      'conferência lista colaborador e batidas');
  final html1 = await RelatorioPonto.gerarConferenciaDiaHtml(d(8), pid, 'Empresa', '');
  check(html1.contains('Colaboradores<b>1</b>'), 'conferência filtra por colaborador');

  // ---------- Feriados ----------
  final finados = (await db.getFeriados()).firstWhere((f) => asStr(f['FER_DESCRICAO']) == 'Finados');
  await db.excluirFeriado(asInt(finados['FER_ID']));
  final recriados = await db.garantirFeriadosNacionaisFixos();
  final fer = await db.feriadosNoPeriodo(DateTime(2026, 1, 1), DateTime(2026, 12, 31));
  check(recriados == 1 && fer[DateTime(2026, 11, 2)] == 'Finados', '02/11 Finados recriado quando falta');
  check(fer[DateTime(2026, 11, 20)] != null && fer[DateTime(2026, 11, 15)] != null, '15/11 e 20/11 presentes');
  check(await db.garantirFeriadosNacionaisFixos() == 0, 'não duplica feriados fixos');

  // ---------- Exclusão do horário limpa os dias ----------
  final h2 = await db.salvarHorario(0, 'Excluir', '08:00', '12:00', '13:00', '17:00', 10, 480, false, false, '', '', true);
  await db.salvarHorarioDias(h2, {1: (e1: '08:00', s1: '12:00', e2: '', s2: '', carga: 240, folga: false)});
  await db.excluirHorario(h2);
  check((await db.getHorarioDias(h2)).isEmpty, 'excluir horário remove a jornada por dia');

  print(falhas == 0 ? '\nTUDO OK' : '\n$falhas FALHA(S)');
  exit(falhas == 0 ? 0 : 1);
}
