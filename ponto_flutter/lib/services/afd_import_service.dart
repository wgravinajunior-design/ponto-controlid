import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/util.dart';
import '../data/database.dart';
import 'controlid_client.dart';

class ArquivoAfd {
  final String caminho;
  ArquivoAfd(this.caminho);
  String get nome => p.basename(caminho);
  int get tamanho => File(caminho).lengthSync();
  DateTime get modificado => File(caminho).lastModifiedSync();

  /// Nº de série do relógio no nome do arquivo gerado pelo REP: `AFD` + série (17 dígitos) + CNPJ + `REP_C.txt`
  String get serial => RegExp(r'^AFD(\d{17})', caseSensitive: false).firstMatch(nome)?[1] ?? '';
}

class ResultadoImportacao {
  int lidas = 0, novas = 0, duplicadas = 0, semColaborador = 0, vinculadas = 0;
  final naoIdentificados = <String>{};
  DateTime? de, ate;
  String relogio = '';
  String? erro;
}

/// Coleta manual: importa o arquivo AFD gravado pelo relógio em um pendrive.
class AfdImportService {
  /// Procura arquivos AFD*.txt nos pendrives (unidades removíveis) conectados.
  static Future<List<ArquivoAfd>> procurarNoPendrive() async {
    final r = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      r"Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter } | ForEach-Object { $_.DriveLetter + ':\' }"
    ]);
    final achados = <ArquivoAfd>[];
    for (final unidade in '${r.stdout}'.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty)) {
      try {
        for (final e in Directory(unidade).listSync(recursive: true, followLinks: false)) {
          if (e is File && RegExp(r'^AFD.*\.txt$', caseSensitive: false).hasMatch(p.basename(e.path))) {
            achados.add(ArquivoAfd(e.path));
          }
        }
      } catch (_) {
        // pasta sem permissão de leitura
      }
    }
    achados.sort((a, b) => b.modificado.compareTo(a.modificado));
    return achados;
  }

  /// Relógio cadastrado cujo nº de série é o do arquivo (0 se não encontrar).
  static Future<int> relogioDoArquivo(ArquivoAfd a) async {
    if (a.serial.isEmpty) return 0;
    for (final r in await Db.instance.getRelogios()) {
      if (onlyDigits(asStr(r['PRE_SERIAL'])).replaceFirst(RegExp(r'^0+'), '') == a.serial.replaceFirst(RegExp(r'^0+'), '')) {
        return asInt(r['PRE_ID']);
      }
    }
    return 0;
  }

  static String _ler(String caminho) {
    final bytes = File(caminho).readAsBytesSync();
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes); // AFD da Portaria 1510 costuma ser ISO-8859-1
    }
  }

  /// Importa as marcações do arquivo. [relogioId] = 0 grava sem relógio (a duplicidade é checada pelo NSR).
  static Future<ResultadoImportacao> importar(String caminho, int relogioId) async {
    final db = Db.instance;
    final res = ResultadoImportacao();
    try {
      final registros = ControlIdClient.parseAfd(_ler(caminho));
      if (registros.isEmpty) {
        res.erro = 'Nenhuma marcação de ponto encontrada no arquivo. Confira se é o AFD exportado pelo relógio.';
        return res;
      }
      if (relogioId > 0) {
        res.relogio = asStr((await db.getRelogioPorId(relogioId))?['PRE_NOME']);
      }
      // NSRs já gravados deste relógio (coleta pela rede ou importação anterior)
      final existentes = <int, (int, int)>{
        for (final r in await db.query(
            relogioId > 0
                ? 'SELECT PMA_CONTROLID_LOG_ID AS K, PMA_ID, PMA_PESSOA FROM TB_PONTO_MARCACAO WHERE PMA_RELOGIO = ?'
                : 'SELECT PMA_CONTROLID_LOG_ID AS K, PMA_ID, PMA_PESSOA FROM TB_PONTO_MARCACAO WHERE PMA_RELOGIO IS NULL',
            relogioId > 0 ? [relogioId] : []))
          asInt(r['K']): (asInt(r['PMA_ID']), asInt(r['PMA_PESSOA']))
      };
      final cache = <String, int>{}; // CPF/PIS -> colaborador
      final dias = <String, (int, DateTime)>{};
      var maxNsr = 0;

      for (final a in registros) {
        res.lidas++;
        res.de = res.de == null || a.dataHora.isBefore(res.de!) ? a.dataHora : res.de;
        res.ate = res.ate == null || a.dataHora.isAfter(res.ate!) ? a.dataHora : res.ate;
        if (a.nsr > maxNsr) maxNsr = a.nsr;
        final chave = '${a.pis}|${a.cpf}';
        final pessoa = cache[chave] ??= await db.buscarPessoaPorPisOuCpf(a.pis, a.cpf);
        final ja = existentes[a.nsr];
        if (ja != null) {
          res.duplicadas++;
          // Marcação importada antes sem colaborador: agora o colaborador existe, então vincula
          if (ja.$2 <= 0 && pessoa > 0) {
            await db.exec('UPDATE TB_PONTO_MARCACAO SET PMA_PESSOA = ? WHERE PMA_ID = ?', [pessoa, ja.$1]);
            res.vinculadas++;
            dias['$pessoa-${soData(a.dataHora)}'] = (pessoa, a.dataHora);
          }
          continue;
        }
        if (pessoa <= 0) {
          res.semColaborador++;
          res.naoIdentificados.add(a.cpf.isNotEmpty ? formatarDoc(a.cpf) : a.pis);
        }
        final ok = await db.gravarMarcacao(
            pessoa, relogioId, a.dataHora, 7, a.nsr, 'C', a.nsr, a.pis, a.cpf, 'Batida Ponto', 'AFD Pendrive',
            recalcularTipo: false);
        if (!ok) {
          res.erro = db.lastError;
          return res;
        }
        existentes[a.nsr] = (0, pessoa);
        res.novas++;
        if (pessoa > 0) dias['$pessoa-${soData(a.dataHora)}'] = (pessoa, a.dataHora);
      }
      // Entrada/Saída de cada dia afetado
      for (final d in dias.values) {
        await db.recalcularTiposDia(d.$1, d.$2);
      }
      // A coleta pela rede continua depois do último NSR importado
      if (relogioId > 0 && maxNsr > 0) {
        final r = await db.getRelogioPorId(relogioId);
        if (maxNsr > asInt(r?['PRE_ULTIMO_LOG_ID'])) await db.atualizarUltimoLogRelogio(relogioId, maxNsr, '', '');
      }
    } catch (e) {
      res.erro = '$e';
    }
    return res;
  }
}
