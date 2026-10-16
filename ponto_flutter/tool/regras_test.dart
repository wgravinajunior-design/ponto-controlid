// ignore_for_file: avoid_print
// Testa as regras CLT / Portaria 671 do cálculo em um banco Firebird TEMPORÁRIO.
// Uso: dart run tool/regras_test.dart <Config.ini> <pasta temporária>
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ponto_flutter/core/config.dart';
import 'package:ponto_flutter/core/util.dart';
import 'package:ponto_flutter/data/database.dart';
import 'package:ponto_flutter/services/assinatura_service.dart';
import 'package:ponto_flutter/services/banco_horas_service.dart';
import 'package:ponto_flutter/services/backup_service.dart';
import 'package:ponto_flutter/services/calculo_service.dart';
import 'package:ponto_flutter/services/comprovante_service.dart';
import 'package:ponto_flutter/services/servidor_online.dart';

var falhas = 0;
void check(bool cond, String msg) {
  if (!cond) falhas++;
  print('${cond ? 'ok ' : 'XX '} $msg');
}

final db = Db.instance;

Future<int> colab(String nome, int horario) => db.salvarColaborador(0, nome, '', '', '', '', '', true, horario);

Future<void> bater(int pid, List<DateTime> horas) async {
  for (final h in horas) {
    await db.inserirMarcacaoManual(pid, 0, h, 'E', 'teste');
  }
}

DateTime d(int dia, [int h = 0, int m = 0]) => DateTime(2026, 9, dia, h, m); // setembro/2026: dia 7 é segunda

Future<DiaEspelho> dia(int pid, int diaMes) async =>
    (await PontoCalculoService.calcularEspelho(pid, d(diaMes), d(diaMes))).dias.first;

Future<void> main(List<String> args) async {
  final cfg = AppConfig.instance..load(args[0]);
  final arq = p.join(args[1], 'regras_teste.fdb');
  if (File(arq).existsSync()) File(arq).deleteSync();
  cfg.firebird.database = arq;
  if (!await db.conectar()) {
    print('Falha ao conectar: ${db.lastError}');
    exit(1);
  }
  print('Base criada: ${db.lastMigracaoLog}');

  // Jornada comercial 08-12 / 13-17 (480 min), tolerância diária 10
  final h8 = await db.salvarHorario(0, '8h teste', '08:00', '12:00', '13:00', '17:00', 10, 480, false, false, '', '', true);

  // ---------- 1. Batidas preservadas (Portaria 671) ----------
  final a = await colab('Batidas Preservadas', h8);
  await bater(a, [d(8, 8), d(8, 12), d(8, 13), d(8, 17, 30)]);
  final m = (await db.getMarcacoes(d(8), d(8), pessoaId: a)).firstWhere((x) => fmtHora(asDate(x['PMA_DATA_HORA'])) == '17:30');
  final novo = await db.corrigirMarcacao(asInt(m['PMA_ID']), d(8, 17), 'S', 'Saída registrada com atraso');
  final todas = await db.getMarcacoes(d(8), d(8), pessoaId: a, incluirDesconsideradas: true);
  final orig = todas.firstWhere((x) => asInt(x['PMA_ID']) == asInt(m['PMA_ID']));
  check(novo > 0 && todas.length == 5 && asStr(orig['PMA_DESCONSIDERADA']) == 'S', '1a. correção mantém a original desconsiderada');
  check(fmtHora(asDate(orig['PMA_DATA_HORA'])) == '17:30', '1b. horário original não foi alterado');
  check((await dia(a, 8)).trabalhadoMin == 480, '1c. cálculo usa só a batida corrigida');
  final dup = await db.inserirMarcacaoManual(a, 0, d(8, 17, 1), 'S');
  await db.desconsiderarMarcacao(dup, 'Batida em duplicidade');
  check((await dia(a, 8)).batidas.length == 4, '1d. batida desconsiderada não entra no cálculo');
  await db.restaurarMarcacao(dup);
  check((await dia(a, 8)).batidas.length == 5, '1e. restaurar volta a considerar');
  await db.desconsiderarMarcacao(dup, 'Batida em duplicidade');

  // ---------- 2. Feriados ----------
  final fer = await db.feriadosNoPeriodo(DateTime(2026, 1, 1), DateTime(2026, 12, 31));
  check(fer[DateTime(2026, 4, 3)] == 'Sexta-feira Santa', '2a. Sexta-feira Santa 2026 calculada (03/04)');
  check(fer[DateTime(2026, 9, 7)] == 'Independência do Brasil' && fer[DateTime(2026, 11, 20)] != null,
      '2b. feriados nacionais semeados (7/9, 20/11)');
  final b = await colab('Feriados', h8);
  final dFer = await dia(b, 7);
  check(dFer.tipoDia == TipoDia.feriado && !dFer.faltaDiaInteiro && dFer.faltaMin == 0, '2c. feriado não trabalhado não é falta');
  await bater(b, [d(7, 8), d(7, 12)]);
  final dFer2 = await dia(b, 7);
  check(dFer2.extraMin == 240 && dFer2.extra100, '2d. feriado trabalhado = 4h extra 100%');

  // ---------- 3. Perda do DSR ----------
  final c = await colab('DSR', h8);
  for (final x in [14, 15, 17, 18]) {
    await bater(c, [d(x, 8), d(x, 12), d(x, 13), d(x, 17)]);
  }
  final eC = await PontoCalculoService.calcularEspelho(c, d(14), d(20));
  check(eC.resumo.totalFaltas == 1 && eC.resumo.dsrDescontados == 1 && eC.dias.last.dsrDescontado,
      '3. falta na quarta 16/9 desconta o DSR do domingo 20/9');

  // ---------- 4. Intervalo intrajornada ----------
  final dd = await colab('Intervalo', h8);
  await bater(dd, [d(21, 8), d(21, 12), d(21, 12, 30), d(21, 16, 30)]);
  final dI = await dia(dd, 21);
  check(dI.intervaloMin == 30 && dI.intervaloSuprimidoMin == 30, '4a. intervalo de 30 min: 30 min suprimidos');
  await bater(dd, [d(22, 8), d(22, 16, 30)]);
  check((await dia(dd, 22)).intervaloSuprimidoMin == 60, '4b. jornada sem intervalo: 1h suprimida');

  // ---------- 5. Interjornada ----------
  final e = await colab('Interjornada', h8);
  await bater(e, [d(23, 14), d(23, 18), d(23, 19), d(23, 23)]);
  await bater(e, [d(24, 7), d(24, 12), d(24, 13), d(24, 17)]);
  final dJ = await dia(e, 24);
  check(dJ.interjornadaFaltanteMin == 180, '5. descanso de 8h entre jornadas: faltaram 3h das 11h');

  // ---------- 6. Tolerância por marcação ----------
  final f = await colab('Tolerancia', h8);
  await bater(f, [d(25, 8, 4), d(25, 12), d(25, 13), d(25, 17, 3)]);
  final dT = await dia(f, 25);
  check(dT.extraMin == 0 && dT.faltaMin == 0, '6a. variações de 4 e 3 min (total 7): desconsideradas');
  await bater(f, [d(28, 8, 7), d(28, 12), d(28, 13), d(28, 17)]);
  final dT2 = await dia(f, 28);
  check(dT2.faltaMin == 7, '6b. atraso de 7 min (> 5 na marcação): conta os 7 minutos');
  await bater(f, [d(29, 8, 4), d(29, 12, 4), d(29, 13, 4), d(29, 17)]);
  final dT3 = await dia(f, 29);
  check(dT3.faltaMin == 4, '6c. três variações de 4 min (total 12 > 10): conta o saldo do dia');

  // ---------- 7. Banco de horas ----------
  final hBh = await db.salvarHorario(0, 'BH teste', '08:00', '12:00', '13:00', '17:00', 10, 480, false, false, '', '', true);
  await db.salvarRegrasHorario(hBh, 'SEMANAL', null, '00:00', 60, true);
  final g = await colab('Banco Horas', hBh);
  await bater(g, [d(1, 8), d(1, 12), d(1, 13), d(1, 19)]); // +2h
  await bater(g, [d(2, 8, 30), d(2, 12), d(2, 13), d(2, 17)]); // -30 min
  final eG = await PontoCalculoService.calcularEspelho(g, d(1), d(2));
  check(eG.resumo.usaBancoHoras && eG.resumo.bancoCreditoMin == 120 && eG.resumo.bancoDebitoMin == 30 &&
      eG.resumo.extras50FolhaMin == 0, '7a. extras e atrasos vão para o banco, não para a folha');
  final fech = await BancoHorasService.fecharCompetencia(DateTime(2026, 9, 1));
  await BancoHorasService.fecharCompetencia(DateTime(2026, 9, 1)); // refazer não duplica
  final sG = (await BancoHorasService.saldos()).firstWhere((s) => s.pessoaId == g);
  check(fech >= 1 && sG.saldoMin == 90, '7b. fechamento da competência: saldo +1:30 (refazer não duplica)');
  await db.lancarBancoHoras(g, DateTime(2025, 1, 10), 300, 'A', 'Crédito antigo');
  await db.lancarBancoHoras(g, DateTime(2026, 9, 30), -60, 'F', 'Folga');
  final sG2 = (await BancoHorasService.saldos()).firstWhere((s) => s.pessoaId == g);
  check(sG2.saldoMin == 330 && sG2.minutosVencidos == 210, '7c. crédito antigo vencido: 5h - 0:30 (atraso) - 1h (folga) = 3:30 (FIFO)');

  // ---------- 8. Limite de 2h extras ----------
  final hh = await colab('Extra 2h', h8);
  await bater(hh, [d(30, 8), d(30, 12), d(30, 13), d(30, 20)]);
  final dX = await dia(hh, 30);
  check(dX.extraMin == 180 && dX.alertas.any((x) => x.contains('acima de 2h')), '8. extra de 3h gera alerta (art. 59)');

  // ---------- 9. Sábado com horário cadastrado ----------
  final hSab = await db.salvarHorario(0, 'Sab teste', '08:00', '12:00', '13:00', '17:00', 10, 480, false, true, '08:00', '13:00', true);
  final i = await colab('Sabado', hSab);
  check((await dia(i, 5)).cargaPrevistaMin == 300, '9. sábado 08:00-13:00 = carga de 5h');

  // ---------- 10. Escala 12x36 ----------
  final h12 = await db.salvarHorario(0, '12x36 teste', '07:00', '13:00', '14:00', '19:00', 10, 660, false, false, '', '', true);
  await db.salvarRegrasHorario(h12, '12X36', d(7), '00:00', 60, false);
  final k = await colab('Escala 12x36', h12);
  final e12 = await PontoCalculoService.calcularEspelho(k, d(7), d(9));
  check(e12.dias[0].cargaPrevistaMin == 660 && e12.dias[1].tipoDia == TipoDia.folga && e12.dias[2].cargaPrevistaMin == 660,
      '10a. 12x36: trabalha 7/9, folga 8/9, trabalha 9/9');
  check(e12.dias[0].faltaDiaInteiro && !e12.dias[0].extra100 && !e12.dias[1].faltaDiaInteiro,
      '10b. 12x36: feriado no dia de escala é dia normal (art. 59-A); folga não é falta');

  // ---------- 11. Turno noturno (virada do dia e Súmula 60) ----------
  final hN = await db.salvarHorario(0, 'Noturno teste', '22:00', '06:00', '', '', 10, 420, false, false, '', '', true);
  await db.salvarRegrasHorario(hN, 'SEMANAL', null, '12:00', 60, false);
  final n = await colab('Noturno', hN);
  await bater(n, [d(15, 22), d(16, 2), d(16, 3), d(16, 6)]);
  final dN = await dia(n, 15);
  check(dN.batidas.length == 4 && dN.trabalhadoMin == 420, '11a. batidas da madrugada contam no dia 15 (virada 12:00)');
  check(dN.noturnoMin == 360, '11b. adicional noturno 22h-02h e 03h-05h = 6h');
  check(minutosNoturnos(d(15, 22), d(16, 7)) == 540, '11c. prorrogação após as 5h também é noturna (Súmula 60)');
  check(minutosNoturnos(d(15, 23), d(16, 7)) == 360, '11d. sem cumprir todo o período noturno não há prorrogação');

  // ---------- 13. Admissão e demissão ----------
  final ad = await colab('Admitido dia 9', h8);
  await db.salvarContratoColaborador(ad, admissao: d(9), demissao: d(10));
  final eAd = await PontoCalculoService.calcularEspelho(ad, d(8), d(11));
  check(eAd.dias[0].foraContrato && !eAd.dias[0].faltaDiaInteiro && eAd.dias[1].faltaDiaInteiro &&
      eAd.dias[3].foraContrato && eAd.resumo.totalFaltas == 2, '13. antes da admissão e após a demissão não há falta');

  // ---------- 14. Afastamentos ----------
  final af = await colab('Ferias', h8);
  await db.salvarAfastamento(0, af, d(8), d(10), 'Férias', 'Período aquisitivo 2025');
  final eAf = await PontoCalculoService.calcularEspelho(af, d(8), d(11));
  check(eAf.dias.take(3).every((x) => x.afastamento == 'Férias' && !x.faltaDiaInteiro) && eAf.dias[3].faltaDiaInteiro &&
      eAf.resumo.diasAfastado == 3, '14. férias de 8 a 10/9 sem falta; 11/9 volta a contar');

  // ---------- 15. Jornada por dia da semana ----------
  final hDia = await db.salvarHorario(0, 'Sexta curta', '08:00', '12:00', '13:00', '18:00', 10, 540, false, false, '', '', true);
  await db.salvarHorarioDias(hDia, {
    5: (e1: '08:00', s1: '12:00', e2: '13:00', s2: '17:00', carga: 0, folga: false),
    3: (e1: '', s1: '', e2: '', s2: '', carga: 0, folga: true),
  });
  final jd = await colab('Jornada por dia', hDia);
  final eJd = await PontoCalculoService.calcularEspelho(jd, d(14), d(18));
  check(eJd.dias[0].cargaPrevistaMin == 540 && eJd.dias[2].tipoDia == TipoDia.folga && !eJd.dias[2].faltaDiaInteiro &&
      eJd.dias[4].cargaPrevistaMin == 480, '15. seg 9h, quarta folga fixa, sexta 8h (carga pelos horários)');

  // ---------- 16. Ciclo 6x1 ----------
  final h61 = await db.salvarHorario(0, '6x1 teste', '08:00', '12:00', '13:00', '16:20', 10, 440, false, false, '', '', true);
  await db.salvarRegrasHorario(h61, 'CICLO', d(1), '00:00', 60, false);
  await db.salvarCicloHorario(h61, 6, 1);
  final c61 = await colab('Escala 6x1', h61);
  final e61 = await PontoCalculoService.calcularEspelho(c61, d(1), d(14));
  final folgas = [for (final x in e61.dias) if (x.tipoDia == TipoDia.folga) x.data.day];
  check(folgas.length == 2 && folgas[0] == 7 && folgas[1] == 14 && e61.dias[6].faltaDiaInteiro == false,
      '16. 6x1 a partir de 1/9: folgas nos dias 7 e 14 ($folgas)');

  // ---------- 17. Faixas de hora extra ----------
  cfg.folha
    ..pctFaixa1 = 50
    ..pctFaixa2 = 70
    ..extraFaixa1Min = 120;
  final fx = await colab('Faixas', h8);
  await bater(fx, [d(10, 8), d(10, 12), d(10, 13), d(10, 20)]); // +3h
  final eFx = await PontoCalculoService.calcularEspelho(fx, d(10), d(10));
  check(eFx.resumo.totalExtras50Min == 120 && eFx.resumo.totalExtrasFaixa2Min == 60,
      '17. 3h extras: 2h a 50% e 1h a 70%');
  cfg.folha.pctFaixa2 = 50;

  // ---------- 18. Usuários e auditoria ----------
  await db.garantirUsuarioAdmin();
  check(await db.autenticar('admin', 'errada') == null && await db.autenticar('ADMIN', 'admin') != null,
      '18a. admin inicial: senha errada recusada, login sem diferenciar maiúsculas');
  final uid = await db.salvarUsuario(0, 'maria', 'Maria RH', 'OPERADOR', true, senha: 'senha123');
  final u = await db.autenticar('maria', 'senha123');
  check(uid > 0 && u != null && asStr(u['USU_PERFIL']) == 'OPERADOR' && db.usuarioLogado == 'maria', '18b. operador autentica');
  final aud = await db.inserirMarcacaoManual(a, 0, d(9, 8), 'E', 'Esqueceu de bater');
  final rAud = await db.queryOne('SELECT PMA_USUARIO_ALTERACAO AS U FROM TB_PONTO_MARCACAO WHERE PMA_ID = ?', [aud]);
  check(asStr(rAud?['U']) == 'maria', '18c. batida manual registra quem incluiu (maria)');
  await db.salvarUsuario(uid, 'maria', 'Maria RH', 'OPERADOR', false);
  check(await db.autenticar('maria', 'senha123') == null, '18d. usuário inativo não entra');

  // ---------- 19. Comprovante de registro ----------
  final bio = await db.registrarBatidaBiometrica(a, DateTime.now(), 0);
  final comp = await ComprovanteService.gerar(bio.marcacaoId);
  final txtComp = comp == null ? '' : File(comp).readAsStringSync(encoding: latin1);
  check(bio.marcacaoId > 0 && txtComp.contains('COMPROVANTE DE REGISTRO DE PONTO') &&
      txtComp.contains('NSR: ${bio.marcacaoId.toString().padLeft(9, '0')}'), '19. comprovante com NSR gerado');
  if (comp != null) {
    File(comp).deleteSync();
    File(comp.replaceAll('.txt', '.html')).deleteSync();
  }

  // ---------- 20. Modo online ----------
  final srv = ServidorOnline(porta: 18181);
  await srv.iniciar();
  Future<String> postOnline(String ep, String body) async {
    final h = HttpClient();
    final req = await h.postUrl(Uri.parse('http://127.0.0.1:18181/$ep'));
    req.write(body);
    final r = await req.close();
    final t = await r.transform(const SystemEncoding().decoder).join();
    h.close();
    return t;
  }
  final agoraUnix = DateTime(2026, 9, 21, 7, 58).millisecondsSinceEpoch ~/ 1000;
  final libera = await postOnline('new_user_identified.fcgi', '{"user_id":$a,"device_id":5,"event":7,"time":$agoraUnix}');
  final nega = await postOnline('new_user_identified.fcgi', '{"user_id":0,"device_id":5}');
  final reenvio = await postOnline('new_user_identified.fcgi', '{"user_id":$a,"device_id":5,"event":7,"time":$agoraUnix}');
  await srv.parar();
  final onl = (await db.getMarcacoes(d(21), d(21), pessoaId: a)).where((x) => asStr(x['PMA_TIPO_IDENTIFICACAO']) == 'Control iD Online');
  check(libera.contains('"event":7') && libera.contains('door=1') && nega.contains('"event":6') && reenvio.contains('"event":7') &&
      onl.length == 1, '20. online: libera cadastrado, nega desconhecido e não duplica reenvio');

  // ---------- 21. Backup ----------
  cfg.backup.pasta = p.join(args[1], 'bkp');
  final bk = await BackupService.fazerBackup();
  check(bk.ok && File(bk.arquivo).lengthSync() > 0, '21a. backup .fbk gerado (${bk.mensagem})');
  final restaurada = p.join(args[1], 'restaurada_teste.fdb');
  if (File(restaurada).existsSync()) File(restaurada).deleteSync();
  final rs = await BackupService.restaurar(bk.arquivo, restaurada);
  check(rs.ok && File(restaurada).existsSync(), '21b. backup restaurado em uma nova base');
  if (File(restaurada).existsSync()) File(restaurada).deleteSync();
  Directory(cfg.backup.pasta).deleteSync(recursive: true);

  // ---------- 12. Assinatura eletrônica ----------
  final dir = Directory(p.join(args[1], 'assin'))..createSync(recursive: true);
  final pfx = p.join(dir.path, 'teste.pfx');
  final gerar = await Process.run('powershell', [
    '-NoProfile', '-Command',
    "\$c = New-SelfSignedCertificate -Subject 'CN=GO UP TESTE' -CertStoreLocation Cert:\\CurrentUser\\My -KeyExportPolicy Exportable;"
        " Export-PfxCertificate -Cert \$c -FilePath '$pfx' -Password (ConvertTo-SecureString '1234' -AsPlainText -Force) | Out-Null;"
        " Remove-Item \$c.PSPath"
  ]);
  final txt = File(p.join(dir.path, 'AEJ_teste.txt'))..writeAsStringSync('01|1|12345678000199\r\n99|1\r\n');
  try {
    final s = await AssinaturaService.assinar([txt.path], pfx, '1234');
    final ver = await Process.run('powershell', [
      '-NoProfile', '-Command',
      "Add-Type -AssemblyName System.Security; \$ci = New-Object System.Security.Cryptography.Pkcs.ContentInfo(,[IO.File]::ReadAllBytes('${txt.path}'));"
          " \$cms = New-Object System.Security.Cryptography.Pkcs.SignedCms(\$ci, \$true); \$cms.Decode([IO.File]::ReadAllBytes('${txt.path}.p7s'));"
          " \$cms.CheckSignature(\$true); 'VALIDA'"
    ]);
    check(s.titular.contains('GO UP TESTE') && '${ver.stdout}'.contains('VALIDA'), '12a. .p7s gerado e assinatura válida');
    var senhaErrada = false;
    try {
      await AssinaturaService.assinar([txt.path], pfx, 'errada');
    } catch (_) {
      senhaErrada = true;
    }
    check(senhaErrada, '12b. senha incorreta é recusada');
  } catch (e) {
    check(false, '12. assinatura: $e ${gerar.stderr}');
  }

  await db.desconectar();
  File(arq).deleteSync();
  dir.deleteSync(recursive: true);
  print(falhas == 0 ? '\nTODAS AS REGRAS OK' : '\n$falhas FALHA(S)');
  exit(falhas == 0 ? 0 : 1);
}
