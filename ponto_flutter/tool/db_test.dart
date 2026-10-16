// ignore_for_file: avoid_print
// Teste completo em um banco Firebird TEMPORÁRIO: cria tabelas mínimas do ERP, roda a migração
// e exercita colaborador, horário, marcações, biometria, justificativa e espelho.
// Uso: dart run tool/db_test.dart <Config.ini> <caminho do .fdb temporário>
import 'dart:convert';
import 'dart:io';

import 'package:fbdb/fbdb.dart';
import 'package:ponto_flutter/core/config.dart';
import 'package:ponto_flutter/core/util.dart';
import 'package:ponto_flutter/data/dashboard_repo.dart';
import 'package:ponto_flutter/data/database.dart';
import 'package:ponto_flutter/services/calculo_service.dart';
import 'package:ponto_flutter/services/contabilidade_service.dart';
import 'package:ponto_flutter/services/controlid_client.dart';
import 'package:ponto_flutter/services/relatorio_service.dart';

void check(bool cond, String msg) {
  if (!cond) throw Exception('FALHOU: $msg');
  print('ok  $msg');
}

Future<void> main(List<String> args) async {
  final cfg = AppConfig.instance..load(args[0]);
  final arq = args[1];
  if (File(arq).existsSync()) File(arq).deleteSync();
  cfg.firebird.database = arq;

  final novo = await FbDb.createDatabase(
      host: cfg.firebird.server, port: cfg.firebird.port, database: arq, user: cfg.firebird.user,
      password: cfg.firebird.password, options: FbOptions(libFbClient: cfg.firebird.vendorLib, dbCharset: 'WIN1252'));
  for (final s in [
    'CREATE TABLE TB_PESSOA (PES_ID INTEGER NOT NULL PRIMARY KEY, PES_RSOCIAL_NOME VARCHAR(100), PES_CNPJ_CPF VARCHAR(20), '
        'PES_STATUS CHAR(1), PES_COLABORADOR CHAR(1), PES_CODIGO_ACESSO VARCHAR(20), PES_DT_CADASTRO TIMESTAMP)',
    'CREATE TABLE TB_COLABORADOR (COL_PESSOA INTEGER NOT NULL PRIMARY KEY, COL_EMPRESA INTEGER, COL_CPF VARCHAR(14), '
        'COL_PIS VARCHAR(15), COL_CARTAO_PONTO VARCHAR(20), COL_FUNCAO VARCHAR(50), COL_STATUS CHAR(1), COL_DT_CADASTRO TIMESTAMP)',
    'CREATE TABLE TB_EMPRESA (EMP_ID INTEGER NOT NULL PRIMARY KEY, EMP_RAZAO_SOCIAL VARCHAR(100), EMP_CNPJ VARCHAR(20), '
        'EMP_ENDERECO VARCHAR(100), EMP_NUMERO VARCHAR(10), EMP_BAIRRO VARCHAR(50), EMP_STATUS CHAR(1))',
    "INSERT INTO TB_EMPRESA VALUES (1, 'EMPRESA TESTE LTDA', '12345678000199', 'Rua A', '10', 'Centro', 'A')",
  ]) {
    await novo.execute(sql: s);
  }
  await novo.detach();

  final db = Db.instance;
  check(await db.conectar(), 'conexão + migração (${db.lastMigracaoLog}) ${db.lastError}');
  check(await db.obterVersaoBanco() == 10, 'versão do schema = 10');
  check(await db.conectar(), 'migração idempotente na 2ª conexão');

  final hor = await db.getHorarios();
  check(hor.length == 2 && asStr(hor.first['HOR_ENTRADA_1']).length == 5, 'horários padrão: ${hor.first}');
  final hid = await db.salvarHorario(0, 'Teste 6h', '08:00', '14:00', '', '', 5, 360, false, false, '', '', true);
  final h = await db.getHorarioPorId(hid);
  check(asStr(h?['HOR_SAIDA_1']) == '14:00' && asStr(h?['HOR_ENTRADA_2']).isEmpty, 'salvar horário com TIME nulo');

  final pid = await db.salvarColaborador(0, 'João da Silva Ção', '123.456.789-09', '123.45678.90-1', 'M01', 'Operador', '77', true, 1);
  check(pid > 0, 'inserir colaborador (id $pid)');
  final p = await db.getPessoaPorId(pid);
  check(asStr(p?['PES_RSOCIAL_NOME']) == 'João da Silva Ção', 'acentuação WIN1252 preservada');
  check(await db.salvarColaborador(pid, 'João da Silva Ção', '12345678909', '12345678901', 'M01', 'Gerente', '77', true, hid) == pid,
      'atualizar colaborador');
  check(await db.buscarPessoaPorPisOuCpf('', '123.456.789-09') == pid, 'buscar por CPF');

  final seg = DateTime(2026, 10, 12); // segunda-feira
  for (final hm in [[8, 0], [14, 5]]) {
    check(await db.gravarMarcacao(pid, 0, seg.add(Duration(hours: hm[0], minutes: hm[1])), 7, 1000 + hm[0], 'C', 0, '', '', 'E', 'Teste'),
        'gravar marcação ${hm[0]}:${hm[1]}');
  }
  final relId = await db.salvarRelogio(0, 'Relógio Teste', '10.0.0.1', 80, false, 'admin', 'admin', 'IDCLASS', 'API', true);
  check(relId > 0, 'salvar relógio');
  check(await db.gravarMarcacao(pid, relId, seg.add(const Duration(days: 1, hours: 8)), 7, 55, 'C', 55, '', '', '', 'API'),
      'marcação com relógio');
  check(await db.gravarMarcacao(pid, relId, seg.add(const Duration(days: 1, hours: 8)), 7, 55, 'C', 55, '', '', '', 'API'),
      'marcação duplicada ignorada');
  await db.atualizarUltimoLogRelogio(relId, 55, 'SN123', 'v.1');
  check(asInt((await db.getRelogioPorId(relId))?['PRE_ULTIMO_LOG_ID']) == 55, 'último log atualizado');

  final mid = await db.inserirMarcacaoManual(pid, 0, seg.add(const Duration(days: 1, hours: 17)), 'S', 'Esquecimento');
  check(mid > 0, 'marcação manual');
  check(await db.corrigirMarcacao(mid, seg.add(const Duration(days: 1, hours: 16, minutes: 48)), 's', 'Ajuste') > 0, 'corrigir marcação');
  await db.salvarJustificativa(pid, seg.add(const Duration(days: 2)), 'Atestado Médico', 'Consulta', 0);

  check(await db.salvarBiometriaColaborador(pid, 'FIR_TEXTO_TESTE'), 'salvar biometria');
  check((await db.getDigitaisCadastradas()).length == 1, 'digitais cadastradas');
  final b1 = await db.registrarBatidaBiometrica(pid, DateTime.now(), 2);
  final b2 = await db.registrarBatidaBiometrica(pid, DateTime.now(), 2);
  check(b1.resultado == ResultadoBatida.registrada && b1.tipoBatida == 'E', 'batida biométrica entrada');
  check(b2.resultado == ResultadoBatida.repetida, 'batida repetida bloqueada');

  final marc = await db.getMarcacoes(seg, seg.add(const Duration(days: 6)), pessoaId: pid);
  // 4 batidas na semana + a batida biométrica de hoje (2026-10-16 cai na mesma semana)
  check(marc.length == 4 + (DateTime.now().isBefore(seg.add(const Duration(days: 7))) ? 1 : 0),
      'listar marcações (${marc.length})');

  final e = await PontoCalculoService.calcularEspelho(pid, seg, seg.add(const Duration(days: 6)));
  final d0 = e.dias[0], d1 = e.dias[1], d2 = e.dias[2], d3 = e.dias[3];
  print('    ${d0.entrada1}-${d0.saida1} trab ${d0.trabalhadoStr} saldo ${d0.saldoStr} | ${d1.entrada1}-${d1.saida1} '
      '${d1.trabalhadoStr} ${d1.saldoStr} | ${d2.ocorrencia} | ${d3.ocorrencia} | ${e.dias[5].ocorrencia} ${e.dias[6].ocorrencia}');
  check(d0.tipoDia == TipoDia.feriado && d0.trabalhadoMin == 365 && d0.extraMin == 365 && d0.extra100,
      'espelho: 12/10 (feriado) trabalhado = extra 100%');
  check(d1.trabalhadoMin == 528 && d1.extraMin == 168, 'espelho: dia 2 com extra');
  check(d2.ocorrencia.startsWith('Atestado') && d2.faltaMin == 0, 'espelho: justificativa abona o dia');
  check(d3.ocorrencia == 'Falta Nao Justificada', 'espelho: falta');
  check(e.gerarRelatorioHtml('X', 'Y').contains('João da Silva Ção'), 'HTML do espelho');
  final emp = await db.getEmpresaPrincipal();
  check(emp?.endereco == 'Rua A, 10 - Centro', 'empresa principal');
  final rel = await RelatorioPonto.gerarEntradasSaidasHtml(seg, seg.add(const Duration(days: 6)), 0, emp!.razao, emp.cnpj);
  check(rel.contains('16:48*') && rel.contains('12.345.678/0001-99'), 'relatório E/S');

  final afd = ControlIdClient.parseAfd('000000001312102026080012345678901\n000000002312102026120012345678901 \n');
  check(afd.length == 2 && afd[1].dataHora == DateTime(2026, 10, 12, 12) && afd[0].cpf == '12345678901', 'parse AFD');
  final afd671 = ControlIdClient.parseAfd('0000000016202311270836020000\n'
      '00000000372026-10-12T08:01:00-0300012345678909ABCD\n'
      '00000000432026-10-12T12:00:00-0300012345678909ABCD\n');
  check(afd671.length == 2 && afd671[0].tipo == 7 && afd671[0].cpf == '12345678909' &&
      afd671[1].dataHora == DateTime(2026, 10, 12, 12), 'parse AFD Portaria 671 (tipos 7 e 3)');

  final dash = await DashboardRepo.carregar();
  check(dash.colaboradoresAtivos == 1 && dash.marcacoesHoje >= 1 && dash.presentes == 1,
      'dashboard: ativos ${dash.colaboradoresAtivos}, hoje ${dash.marcacoesHoje}, presentes ${dash.presentes}');

  check(minutosNoturnos(DateTime(2026, 1, 1, 21), DateTime(2026, 1, 2, 6)) == 480,
      'adicional noturno 22h-5h + 1h prorrogada (Súmula 60)');
  check(minutosNoturnos(DateTime(2026, 1, 1, 3), DateTime(2026, 1, 1, 8)) == 120, 'adicional noturno madrugada (120 min)');
  final pasta = '${Directory.systemTemp.path}/gouptest_contab';
  final cont = await ContabilidadeService.gerar(inicio: seg, fim: seg.add(const Duration(days: 6)), pasta: pasta, afd: false);
  for (final a in cont.arquivos) {
    print('    ${a.nome} (${a.registros})');
  }
  final aej = File(cont.arquivos.first.caminho).readAsLinesSync(encoding: latin1);
  print('    AEJ:\n      ${aej.join('\n      ')}');
  check(aej.first.startsWith('01|1|12345678000199|') && aej.last.startsWith('99|1|1|'), 'AEJ com cabeçalho, REP e trailer');
  check(aej.where((l) => l.startsWith('05|')).length == 6 && aej.any((l) => l.startsWith('05|') && l.contains('|D|')),
      'AEJ com 5 marcações + 1 desconsiderada (D)');
  final ev = File(cont.arquivos.firstWhere((a) => a.nome.startsWith('Folha_Eventos')).caminho).readAsStringSync(encoding: latin1);
  print('    Folha:\n      ${ev.trim().split('\r\n').join('\n      ')}');
  check(ev.contains(';150;Horas extras 50%;2,80') && ev.contains(';200;Horas extras 100%;6,08') &&
      ev.contains(';040;Faltas (dias);1') && ev.contains(';046;DSR descontado (dias);1'), 'eventos da folha (extras, faltas e DSR)');
  check(cont.zip != null && File(cont.zip!).existsSync(), 'pacote zip gerado');
  Directory(pasta).deleteSync(recursive: true);
  File(cont.zip!).deleteSync();

  check((await db.excluirHorario(hid)) != null, 'excluir horário em uso inativa');
  final ex = await db.excluirColaborador(pid);
  check(ex.ok, 'excluir colaborador (inativado=${ex.inativado})');
  check((await db.obterHistoricoVersoes()).length == 10, 'histórico de versões');
  await db.desconectar();
  if (!args.contains('--manter')) File(arq).deleteSync();
  print('\nTODOS OS TESTES PASSARAM');
}
