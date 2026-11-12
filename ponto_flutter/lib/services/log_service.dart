import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Log de eventos gravado em arquivo diário (Documentos\Go Up Ponto\Logs\AAAA-MM-DD.log), mantendo 90 dias.
class LogService {
  static String get pasta {
    final docs = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
    return p.join(docs, 'Documents', 'Go Up Ponto', 'Logs');
  }

  static String? _limpo;

  static void gravar(String msg, {bool erro = false, String origem = 'app'}) {
    try {
      final dir = Directory(pasta)..createSync(recursive: true);
      final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
      File(p.join(dir.path, '$hoje.log')).writeAsStringSync(
          '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} [$origem]${erro ? ' [ERRO]' : ''} $msg\r\n',
          mode: FileMode.append);
      if (_limpo != hoje) {
        _limpo = hoje;
        final limite = DateTime.now().subtract(const Duration(days: 90));
        for (final f in dir.listSync().whereType<File>()) {
          if (f.lastModifiedSync().isBefore(limite)) f.deleteSync();
        }
      }
    } catch (_) {
      // Log em arquivo nunca derruba o sistema
    }
  }
}
