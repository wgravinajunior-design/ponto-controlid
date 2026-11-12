import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../core/config.dart';

class ResultadoBackup {
  final bool ok;
  final String arquivo, mensagem;
  ResultadoBackup(this.ok, this.arquivo, this.mensagem);
}

/// Backup da base do ponto com o gbak do Firebird (arquivo .fbk), com rotação das cópias.
class BackupService {
  static String get pastaPadrao {
    final docs = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
    return p.join(docs, 'Documents', 'Go Up Ponto', 'Backup');
  }

  static String get pasta {
    final c = AppConfig.instance.backup.pasta.trim();
    return c.isEmpty ? pastaPadrao : c;
  }

  /// gbak.exe: ao lado do fbclient.dll configurado ou na instalação padrão do Firebird 5.
  static String? get gbak {
    final cands = [
      p.join(p.dirname(AppConfig.instance.firebird.vendorLib), 'gbak.exe'),
      r'C:\Program Files\Firebird\Firebird_5_0\gbak.exe',
      r'C:\Program Files\Firebird\Firebird_4_0\gbak.exe',
      r'C:\Program Files\Firebird\Firebird_3_0\gbak.exe',
    ];
    for (final c in cands) {
      if (File(c).existsSync()) return c;
    }
    return null;
  }

  static String _conexao(String arquivo) {
    final f = AppConfig.instance.firebird;
    final host = f.server.trim().isEmpty ? 'localhost' : f.server.trim();
    return '$host/${f.port > 0 ? f.port : 3050}:$arquivo';
  }

  /// Usuário e senha por variável de ambiente (não aparecem na lista de processos).
  static Map<String, String> get _env =>
      {'ISC_USER': AppConfig.instance.firebird.user, 'ISC_PASSWORD': AppConfig.instance.firebird.password};

  static List<File> copias() {
    final d = Directory(pasta);
    if (!d.existsSync()) return [];
    return d.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.fbk')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }

  static Future<ResultadoBackup> fazerBackup() async {
    final exe = gbak;
    if (exe == null) return ResultadoBackup(false, '', 'gbak.exe não encontrado (instale as ferramentas do Firebird 5).');
    final dir = Directory(pasta)..createSync(recursive: true);
    final nome = 'PONTO_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.fbk';
    final destino = p.join(dir.path, nome);
    final r = await Process.run(exe, ['-b', '-g', _conexao(AppConfig.instance.firebird.database), destino], environment: _env);
    if (r.exitCode != 0 || !File(destino).existsSync()) {
      return ResultadoBackup(false, destino, 'Falha no backup: ${'${r.stderr}${r.stdout}'.trim()}');
    }
    // Rotação: mantém só as cópias mais recentes
    final manter = AppConfig.instance.backup.manter < 1 ? 1 : AppConfig.instance.backup.manter;
    for (final antigo in copias().skip(manter)) {
      try {
        antigo.deleteSync();
      } catch (_) {}
    }
    final mb = (File(destino).lengthSync() / 1048576).toStringAsFixed(1);
    return ResultadoBackup(true, destino, 'Backup gerado: $nome ($mb MB).');
  }

  /// Faz o backup do dia (uma vez por dia) em segundo plano.
  static Future<void> backupDiario({void Function(String msg, [bool erro])? onLog}) async {
    if (!AppConfig.instance.backup.ativo) return;
    final hoje = DateFormat('yyyyMMdd').format(DateTime.now());
    if (copias().any((f) => p.basename(f.path).startsWith('PONTO_$hoje'))) return;
    final r = await fazerBackup();
    onLog?.call(r.ok ? '💾 ${r.mensagem}' : '❌ ${r.mensagem}', !r.ok);
  }

  /// Restaura um .fbk em um NOVO arquivo de base (nunca sobrescreve a base em uso).
  static Future<ResultadoBackup> restaurar(String fbk, String novaBase) async {
    final exe = gbak;
    if (exe == null) return ResultadoBackup(false, '', 'gbak.exe não encontrado.');
    if (File(novaBase).existsSync()) {
      return ResultadoBackup(false, novaBase, 'O arquivo de destino já existe. Escolha um nome novo.');
    }
    final r = await Process.run(exe, ['-c', fbk, _conexao(novaBase)], environment: _env);
    return r.exitCode == 0
        ? ResultadoBackup(true, novaBase, 'Base restaurada em $novaBase. Aponte as Configurações do banco para ela.')
        : ResultadoBackup(false, novaBase, 'Falha na restauração: ${'${r.stderr}${r.stdout}'.trim()}');
  }
}
