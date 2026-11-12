// ignore_for_file: avoid_print
// Teste de fumaça somente leitura do acesso ao Firebird.
// Uso: dart run tool/smoke_test.dart <caminho do Config.ini>
import 'package:ponto_flutter/core/config.dart';
import 'package:ponto_flutter/core/util.dart';
import 'package:ponto_flutter/data/database.dart';
import 'package:ponto_flutter/services/calculo_service.dart';
import 'package:ponto_flutter/services/relatorio_service.dart';

Future<void> main(List<String> args) async {
  AppConfig.instance.load(args.isNotEmpty ? args.first : null);
  final db = Db.instance;
  if (!await db.conectar(migrar: false)) {
    print('FALHA: ${db.lastError}');
    return;
  }
  print('Conectado. Versão schema: ${await db.obterVersaoBanco()}');
  final colabs = await db.getColaboradores(apenasAtivos: false);
  print('Colaboradores: ${colabs.length}  ex: ${colabs.isEmpty ? '-' : colabs.first}');
  final hor = await db.getHorarios(apenasAtivos: false);
  print('Horários: ${hor.length}  ex: ${hor.isEmpty ? '-' : hor.first}');
  print('Relógios: ${(await db.getRelogios()).length}');
  final fim = DateTime.now(), ini = DateTime(fim.year, fim.month - 1, 1);
  final marc = await db.getMarcacoes(ini, fim);
  print('Marcações desde ${fmtData(ini)}: ${marc.length}  ex: ${marc.isEmpty ? '-' : marc.first}');
  print('Total hoje: ${await db.getTotalMarcacoesHoje()} | colaboradores: ${await db.getTotalColaboradores()} | '
      'biometrias: ${await db.getTotalBiometrias()}');
  final emp = await db.getEmpresaPrincipal();
  print('Empresa: ${emp?.razao} ${emp?.cnpj}');
  print('Versões BD: ${(await db.obterHistoricoVersoes()).length}');
  if (marc.isNotEmpty) {
    final pid = asInt(marc.first['PMA_PESSOA']);
    if (pid > 0) {
      final e = await PontoCalculoService.calcularEspelho(pid, ini, fim);
      print('Espelho pessoa $pid: ${e.dias.length} dias, trabalhado ${minutosParaHora(e.resumo.totalTrabalhadoMin)}, '
          'saldo ${minutosParaHora(e.resumo.saldoTotalMin, exibirSinal: true)}');
      final html = await RelatorioPonto.gerarEntradasSaidasHtml(ini, fim, pid, emp?.razao ?? '', emp?.cnpj ?? '');
      print('Relatório E/S: ${html.length} caracteres');
    }
  }
  await db.desconectar();
  print('OK');
}
