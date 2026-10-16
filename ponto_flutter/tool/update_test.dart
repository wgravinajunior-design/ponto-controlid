// ignore_for_file: avoid_print
// Testa o fluxo de atualização com um servidor local que imita a API de releases do GitHub.
// Uso (com a variável GOUP_UPDATE_API apontando para o servidor de teste):
//   $env:GOUP_UPDATE_API='http://127.0.0.1:18282'; dart run tool/update_test.dart <Config.ini> <pasta temporária>
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ponto_flutter/core/build_info.dart';
import 'package:ponto_flutter/core/config.dart';
import 'package:ponto_flutter/services/update_service.dart';

var falhas = 0;
void check(bool cond, String msg) {
  if (!cond) falhas++;
  print('${cond ? 'ok ' : 'XX '} $msg');
}

const porta = 18282;

Future<void> main(List<String> args) async {
  final cfg = AppConfig.instance..load(args[0]);
  final tmp = Directory(p.join(args[1], 'update_teste'));
  if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  tmp.createSync(recursive: true);

  // Pacote "novo": executável novo, arquivo novo e um Config.ini que NÃO pode sobrescrever o do cliente
  final novo = Directory(p.join(tmp.path, 'pacote'))..createSync();
  File(p.join(novo.path, 'GoUpPonto.exe')).writeAsStringSync('EXE NOVO');
  File(p.join(novo.path, 'recurso_novo.dll')).writeAsStringSync('DLL NOVA');
  File(p.join(novo.path, 'Config.ini')).writeAsStringSync('[X]\r\nvindo=do pacote\r\n');
  final zip = p.join(tmp.path, 'GoUpPonto.zip');
  await Process.run('powershell', ['-NoProfile', '-Command', "Compress-Archive -Path '${novo.path}\\*' -DestinationPath '$zip'"]);

  const notas = '## Novidades\n- Tela de feriados online\n- Banco de horas\n\n## Melhorias\n- Horários mais organizados\n\n## Correções\n- Cálculo do DSR';
  Map<String, dynamic> release(String tag, String nome) => {
        'tag_name': tag,
        'name': nome,
        'body': notas,
        'published_at': '2026-10-16T12:00:00Z',
        'assets': [
          {'name': 'GoUpPonto.zip', 'browser_download_url': 'http://127.0.0.1:$porta/download/GoUpPonto.zip', 'size': File(zip).lengthSync()}
        ],
      };
  final nomeRepo = '/repos/$githubOwner/$githubRepo';
  final srv = await HttpServer.bind(InternetAddress.loopbackIPv4, porta);
  srv.listen((req) async {
    final path = req.uri.path;
    if (path == '$nomeRepo/releases/latest') {
      req.response.write(jsonEncode(release('v99.0.0-b7', 'v99.0.0 (Build 7)')));
    } else if (path == '$nomeRepo/releases/tags/v$buildVersion-b$buildNumber') {
      req.response.write(jsonEncode(release('v$buildVersion-b$buildNumber', 'v$buildVersion (Build $buildNumber)')));
    } else if (path == '/download/GoUpPonto.zip') {
      await req.response.addStream(File(zip).openRead());
    } else {
      req.response.statusCode = 404;
    }
    await req.response.close();
  });

  // 1. Verificação
  final info = await UpdateService.checarAtualizacao();
  check(info != null && info.hasUpdate && info.latestVersion == '99.0.0' && info.latestBuild == 7, '1a. detecta a versão 99.0.0 (Build 7) disponível');
  check(info != null && info.releaseNotes.contains('## Novidades') && info.assetFileName == 'GoUpPonto.zip' && info.assetSize > 0,
      '1b. lê as notas e o pacote da release');
  check(UpdateService.compararVersoes('2.4.0', '2.10.0') < 0 && UpdateService.limparVersao('v2.4.0-b3') == '2.4.0' &&
      UpdateService.extrairBuild('v2.4.0 (Build 12)') == 12, '1c. comparação de versões e leitura da tag/build');

  // 2. Troca dos arquivos pelo script de atualização (sem encerrar este processo)
  final destino = Directory(p.join(tmp.path, 'instalado'))..createSync();
  File(p.join(destino.path, 'GoUpPonto.exe')).writeAsStringSync('EXE ANTIGO');
  File(p.join(destino.path, 'Config.ini')).writeAsStringSync('[BANCO]\r\nDatabase=do cliente\r\n');
  File(p.join(destino.path, 'PONTO.FDB')).writeAsStringSync('BASE DO CLIENTE');
  final bat = File(p.join(tmp.path, 'atualizar.bat'))
    ..writeAsStringSync(UpdateService.montarScript(
      zip: zip,
      extraido: p.join(tmp.path, 'extraido'),
      pasta: destino.path,
      exe: r'C:\Windows\System32\whoami.exe',
      backup: p.join(tmp.path, 'backup'),
      pid: 4000000, // processo inexistente: o script não espera
      log: p.join(tmp.path, 'atualizacao.log'),
    ));
  final r = await Process.run('cmd.exe', ['/c', bat.path]);
  print('    script terminou com código ${r.exitCode}');
  check(File(p.join(destino.path, 'GoUpPonto.exe')).readAsStringSync() == 'EXE NOVO', '2a. executável substituído pela versão nova');
  check(File(p.join(destino.path, 'recurso_novo.dll')).existsSync(), '2b. arquivos novos do pacote copiados');
  check(File(p.join(destino.path, 'Config.ini')).readAsStringSync().contains('do cliente'), '2c. Config.ini do cliente preservado');
  check(File(p.join(destino.path, 'PONTO.FDB')).readAsStringSync() == 'BASE DO CLIENTE', '2d. base de dados do cliente preservada');
  check(File(p.join(tmp.path, 'backup', 'GoUpPonto.exe')).readAsStringSync() == 'EXE ANTIGO', '2e. cópia de segurança da versão anterior');

  // 3. Pacote inválido não derruba a instalação
  final ruim = File(p.join(tmp.path, 'ruim.zip'))..writeAsStringSync('nao e zip');
  File(p.join(destino.path, 'GoUpPonto.exe')).writeAsStringSync('EXE QUE FICA');
  final bat2 = File(p.join(tmp.path, 'atualizar2.bat'))
    ..writeAsStringSync(UpdateService.montarScript(
      zip: ruim.path,
      extraido: p.join(tmp.path, 'extraido2'),
      pasta: destino.path,
      exe: r'C:\Windows\System32\whoami.exe',
      backup: p.join(tmp.path, 'backup2'),
      pid: 4000000,
      log: p.join(tmp.path, 'atualizacao2.log'),
    ));
  await Process.run('cmd.exe', ['/c', bat2.path]);
  check(File(p.join(destino.path, 'GoUpPonto.exe')).readAsStringSync() == 'EXE QUE FICA', '3. pacote inválido: arquivos atuais mantidos');

  // 4. "O que há de novo" depois de atualizar
  cfg.atualizacao.ultimaVista = '1.0.0.1';
  final n = await UpdateService.novidadesDaVersaoAtual();
  check(n != null && n.notas.contains('## Correções') && n.versao == buildVersion && n.build == buildNumber,
      '4a. primeira abertura da nova versão mostra as notas da release');
  check(await UpdateService.novidadesDaVersaoAtual() == null && cfg.atualizacao.ultimaVista == '$buildVersion.$buildNumber',
      '4b. não repete as novidades nas aberturas seguintes');
  cfg.atualizacao.ultimaVista = '';
  check(await UpdateService.novidadesDaVersaoAtual() == null, '4c. instalação nova não mostra novidades');

  await srv.close(force: true);
  tmp.deleteSync(recursive: true);
  print(falhas == 0 ? '\nATUALIZAÇÃO OK' : '\n$falhas FALHA(S)');
  exit(falhas == 0 ? 0 : 1);
}
