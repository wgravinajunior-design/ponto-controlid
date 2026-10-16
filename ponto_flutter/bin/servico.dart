// Go Up Ponto - Serviço em segundo plano (sem tela).
// Faz a coleta automática dos relógios, atende o modo online da Control iD e o backup diário,
// mesmo sem ninguém logado no Windows. Usa o Config.ini da pasta do executável.
//
// Compilar:  dart compile exe bin/servico.dart -o build/GoUpPontoServico.exe
// Instalar:  pelo próprio aplicativo (Configurações > Coleta e Atualização > Serviço em segundo plano)
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ponto_flutter/core/config.dart';
import 'package:ponto_flutter/data/database.dart';
import 'package:ponto_flutter/services/backup_service.dart';
import 'package:ponto_flutter/services/log_service.dart';
import 'package:ponto_flutter/services/ponto_service.dart';
import 'package:ponto_flutter/services/servidor_online.dart';

void _log(String m, [bool erro = false]) {
  LogService.gravar(m, erro: erro, origem: 'servico');
  stdout.writeln(m);
}

Future<void> main(List<String> args) async {
  final cfg = AppConfig.instance..load(args.isNotEmpty ? args.first : null);
  // Uma instância por máquina
  final trava = File(p.join(Directory.systemTemp.path, 'GoUpPontoServico.lock'));
  RandomAccessFile? lock;
  try {
    lock = trava.openSync(mode: FileMode.write)..lockSync();
  } catch (_) {
    _log('Já existe um serviço do Go Up Ponto em execução.');
    exit(0);
  }

  Db.instance.usuarioLogado = 'servico';
  _log('Serviço Go Up Ponto iniciado. Configuração: ${cfg.iniPath}');
  final ponto = PontoService((m, e) => _log(m, e));

  Future<bool> garantirBanco() async {
    if (Db.instance.isConectado) return true;
    final ok = await Db.instance.conectar();
    _log(ok ? 'Conectado à base ${cfg.firebird.database}.' : 'Sem conexão com a base: ${Db.instance.lastError}', !ok);
    return ok;
  }

  await garantirBanco();

  ServidorOnline? online;
  if (cfg.online.ativo) {
    online = ServidorOnline(porta: cfg.online.porta, portaFechadura: cfg.online.portaFechadura, onLog: _log);
    try {
      await online.iniciar();
    } catch (e) {
      _log('Não foi possível abrir a porta ${cfg.online.porta}: $e', true);
    }
  }

  var coletando = false;
  Future<void> ciclo() async {
    if (coletando) return;
    coletando = true;
    try {
      if (!await garantirBanco()) return;
      if (!cfg.modoHamsterDx) await ponto.coletarTodosRelogios();
      await BackupService.backupDiario(onLog: _log);
    } catch (e) {
      _log('Erro no ciclo do serviço: $e', true);
      await Db.instance.desconectar(); // reconecta no próximo ciclo
    } finally {
      coletando = false;
    }
  }

  var seg = cfg.controlId.intervaloColetaSegundos;
  if (seg < 30) seg = 30;
  await ciclo();
  Timer.periodic(Duration(seconds: seg), (_) => ciclo());

  ProcessSignal.sigint.watch().listen((_) async {
    await online?.parar();
    await Db.instance.desconectar();
    lock?.unlockSync();
    _log('Serviço encerrado.');
    exit(0);
  });
}
