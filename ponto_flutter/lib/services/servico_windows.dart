import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/config.dart';

/// Instala o serviço em segundo plano (GoUpPontoServico.exe) como tarefa do Agendador do Windows,
/// executada na inicialização com a conta SYSTEM - funciona sem ninguém logado.
class ServicoWindows {
  static const tarefa = 'GoUpPontoServico';

  static String get exe => p.join(AppConfig.pastaExe, 'GoUpPontoServico.exe');
  static bool get disponivel => File(exe).existsSync();

  static Future<bool> instalado() async => (await Process.run('schtasks', ['/Query', '/TN', tarefa])).exitCode == 0;

  static Future<bool> emExecucao() async {
    final r = await Process.run('tasklist', ['/FI', 'IMAGENAME eq GoUpPontoServico.exe', '/NH']);
    return '${r.stdout}'.contains('GoUpPontoServico.exe');
  }

  /// Executa comandos que exigem administrador (abre a confirmação do UAC).
  static Future<int> _comoAdmin(String comandos) async {
    final r = await Process.run('powershell', [
      '-NoProfile', '-Command',
      "\$p = Start-Process cmd.exe -ArgumentList '/c', '$comandos' -Verb RunAs -WindowStyle Hidden -Wait -PassThru; exit \$p.ExitCode"
    ]);
    return r.exitCode;
  }

  static Future<String?> instalar() async {
    if (!disponivel) return 'GoUpPontoServico.exe não encontrado na pasta do sistema.';
    final tr = '\\"$exe\\" \\"${AppConfig.instance.iniPath}\\"';
    final cmd = 'schtasks /Create /TN $tarefa /TR "$tr" /SC ONSTART /RU SYSTEM /RL HIGHEST /F && schtasks /Run /TN $tarefa';
    final code = await _comoAdmin(cmd.replaceAll("'", "''"));
    return code == 0 ? null : 'Não foi possível instalar (código $code). A confirmação de administrador foi aceita?';
  }

  static Future<String?> remover() async {
    final code = await _comoAdmin('schtasks /End /TN $tarefa & taskkill /F /IM GoUpPontoServico.exe & schtasks /Delete /TN $tarefa /F');
    return code == 0 || !await instalado() ? null : 'Não foi possível remover (código $code).';
  }

  static Future<String?> reiniciar() async {
    final code = await _comoAdmin('schtasks /End /TN $tarefa & taskkill /F /IM GoUpPontoServico.exe & schtasks /Run /TN $tarefa');
    return code == 0 ? null : 'Não foi possível reiniciar (código $code).';
  }
}
