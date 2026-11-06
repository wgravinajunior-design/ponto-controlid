// ignore_for_file: avoid_print
// Monta um cenário fixo em um banco TEMPORÁRIO e imprime o espelho calculado pelo GoUp Ponto,
// para comparar com o cálculo do Delphi (ComparaDelphi) sobre o mesmo banco.
// Uso: dart run tool/comparar_calculo.dart <Config.ini> <pasta temporária>
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ponto_flutter/core/config.dart';
import 'package:ponto_flutter/core/util.dart';
import 'package:ponto_flutter/data/database.dart';
import 'package:ponto_flutter/services/calculo_service.dart';

final db = Db.instance;
DateTime d(int dia, [int h = 0, int m = 0]) => DateTime(2026, 9, dia, h, m); // 07/09/2026 = segunda (feriado)

Future<void> main(List<String> args) async {
  final cfg = AppConfig.instance..load(args[0]);
  final arq = p.join(args[1], 'comparar.fdb');
  if (File(arq).existsSync()) File(arq).deleteSync();
  cfg.firebird.database = arq;
  if (!await db.conectar()) {
    print('Falha ao conectar: ${db.lastError}');
    exit(1);
  }
  // Seg a qui 08-12/13-18 (9h), sexta 08-12/13-17 (8h), sábado folga compensado, domingo folga
  final h = await db.salvarHorario(0, 'Comparacao', '08:00', '12:00', '13:00', '18:00', 10, 540, true, false, '', '', true);
  await db.salvarHorarioDias(h, {
    for (var x = 1; x <= 4; x++) x: (e1: '08:00', s1: '12:00', e2: '13:00', s2: '18:00', carga: 540, folga: false),
    5: (e1: '08:00', s1: '12:00', e2: '13:00', s2: '17:00', carga: 480, folga: false),
    6: (e1: '', s1: '', e2: '', s2: '', carga: 0, folga: true),
    7: (e1: '', s1: '', e2: '', s2: '', carga: 0, folga: true),
  });
  final pid = await db.salvarColaborador(0, 'Comparacao Calculo', '', '', '', '', '', true, h);
  Future<void> bater(int dia, List<List<int>> hs) async {
    for (final x in hs) {
      await db.inserirMarcacaoManual(pid, 0, d(dia, x[0], x[1]), 'E', 'teste');
    }
  }

  const normal = [[8, 0], [12, 0], [13, 0], [18, 0]];
  for (final dia in [8, 9, 10, 11, 14]) {
    await bater(dia, normal);
  }
  await bater(15, [[8, 0], [12, 0], [13, 0], [17, 0]]); // terça: saiu 17h -> 1h a menos
  await bater(16, [[8, 0], [12, 0], [13, 0], [19, 0]]); // quarta: saiu 19h -> 1h a mais
  await bater(17, [[8, 0], [12, 0], [13, 0], [18, 30]]); // quinta: 18:30 corrigida para 18:00
  final m = (await db.getMarcacoes(d(17), d(17), pessoaId: pid)).firstWhere((x) => fmtHora(asDate(x['PMA_DATA_HORA'])) == '18:30');
  await db.corrigirMarcacao(asInt(m['PMA_ID']), d(17, 18), 'S', 'Saída registrada errada');
  await bater(18, [[8, 0], [12, 0], [13, 0], [17, 0]]); // sexta 8h
  await db.lancarBancoHoras(pid, d(15), 300, 'S', 'Saldo do sistema anterior'); // +05:00

  final e = await PontoCalculoService.calcularEspelho(pid, d(7), d(20));
  print('PESSOA=$pid');
  for (final x in e.dias) {
    print('${fmtData(x.data)} prev=${x.cargaPrevistaStr} trab=${x.trabalhadoStr} extra=${x.extraStr} falta=${x.faltaStr}');
  }
  final r = e.resumo;
  print('TOTAL prev=${minutosParaHora(r.totalPrevistoMin)} trab=${minutosParaHora(r.totalTrabalhadoMin)} '
      'extra=${minutosParaHora(r.totalExtrasMin)} falta=${minutosParaHora(r.totalFaltasMin)} '
      'credito=${minutosParaHora(r.creditoHorasMin, exibirSinal: true)} saldo=${minutosParaHora(r.saldoFinalMin, exibirSinal: true)}');
  exit(0);
}
