import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../core/build_info.dart';
import '../core/config.dart';
import '../core/util.dart';
import '../data/database.dart';
import 'assinatura_service.dart';
import 'calculo_service.dart';
import 'controlid_client.dart';
import 'relatorio_service.dart';

/// Arquivo gerado para a contabilidade.
class ArquivoGerado {
  final String nome, descricao, caminho;
  final int registros;
  ArquivoGerado(this.nome, this.descricao, this.caminho, this.registros);
}

class ResultadoContabil {
  final String pasta;
  final arquivos = <ArquivoGerado>[];
  final avisos = <String>[];
  String? zip;
  ResultadoContabil(this.pasta);
}

/// Gera os arquivos que a contabilidade importa: AEJ (Portaria 671), AFD dos relógios,
/// eventos da folha de pagamento, resumo de horas e espelhos de ponto.
class ContabilidadeService {
  static final _fData = DateFormat('yyyy-MM-dd');
  static final _fArq = DateFormat('yyyyMMdd');

  /// Arquivos-texto da Portaria 671 e da folha usam ISO-8859-1 (padrão dos sistemas fiscais/folha).
  static Future<File> _gravarLatin1(String caminho, String texto) =>
      File(caminho).writeAsBytes(latin1.encode(texto.replaceAll(RegExp(r'[^\x00-\xFF]'), '?')));

  static String pastaPadrao(DateTime ini) {
    final docs = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
    return p.join(docs, 'Documents', 'Go Up Ponto', 'Contabilidade', DateFormat('yyyy-MM').format(ini));
  }

  /// Data/hora no formato da Portaria 671: AAAA-MM-DDThh:mm:00-0300.
  static String _dh(DateTime d) {
    final off = d.timeZoneOffset.inMinutes;
    final tz = '${off < 0 ? '-' : '+'}${(off.abs() ~/ 60).toString().padLeft(2, '0')}${(off.abs() % 60).toString().padLeft(2, '0')}';
    return '${_fData.format(d)}T${DateFormat('HH:mm').format(d)}:00$tz';
  }

  static String _hhmm(String hora) => hora.replaceAll(':', '').padRight(4, '0').substring(0, 4);

  /// Quantidade de horas no formato escolhido para a folha.
  static String _qtHoras(int minutos) {
    if (AppConfig.instance.folha.formatoHoras == 'HHMM') return minutosParaHora(minutos);
    return (minutos / 60).toStringAsFixed(2).replaceAll('.', ',');
  }

  static Future<ResultadoContabil> gerar({
    required DateTime inicio,
    required DateTime fim,
    String? pasta,
    bool aej = true,
    bool afd = true,
    bool folha = true,
    bool espelhos = true,
    void Function(String)? onProgresso,
  }) async {
    final ini = soData(inicio), fimD = soData(fim);
    final dir = pasta ?? pastaPadrao(ini);
    await Directory(dir).create(recursive: true);
    final res = ResultadoContabil(dir);
    final db = Db.instance;

    final emp = await db.getEmpresaPrincipal();
    final cnpj = onlyDigits(emp?.cnpj ?? '');
    final razao = emp?.razao ?? '';
    if (cnpj.length != 14 && cnpj.length != 11) {
      res.avisos.add('CNPJ/CPF do empregador não cadastrado (Configurações > Empregador). Os arquivos exigem esse dado.');
    }

    // Colaboradores: ativos e quem teve batida no período
    final marcacoes = (await db.getMarcacoes(ini, fimD, incluirDesconsideradas: true)).reversed.toList(); // ordem cronológica
    final comBatida = {for (final m in marcacoes) if (asStr(m['PMA_DESCONSIDERADA']) != 'S') asInt(m['PMA_PESSOA'])};
    final colabs = [
      for (final c in await db.getColaboradores(apenasAtivos: false))
        if ((asStr(c['PES_STATUS']) != 'I' && _vinculoNoPeriodo(c, ini, fimD)) || comBatida.contains(asInt(c['PES_ID']))) c
    ];
    final semCpf = colabs.where((c) => onlyDigits(_cpf(c)).length != 11).map((c) => asStr(c['PES_RSOCIAL_NOME'])).toList();
    if (semCpf.isNotEmpty) res.avisos.add('Colaborador(es) sem CPF válido: ${semCpf.join(', ')}.');

    // Espelhos (apuração) de cada colaborador: base da folha, do AEJ (ausências) e dos relatórios
    final espelhosCalc = <int, EspelhoPonto>{};
    for (var i = 0; i < colabs.length; i++) {
      onProgresso?.call('Apurando ponto ${i + 1} de ${colabs.length}: ${asStr(colabs[i]['PES_RSOCIAL_NOME'])}');
      final id = asInt(colabs[i]['PES_ID']);
      espelhosCalc[id] = await PontoCalculoService.calcularEspelho(id, ini, fimD);
    }

    if (aej) {
      onProgresso?.call('Gerando AEJ (Portaria 671)...');
      res.arquivos.add(await _gerarAej(dir, ini, fimD, cnpj, razao, colabs, marcacoes, espelhosCalc));
    }
    if (afd && !AppConfig.instance.modoHamsterDx) {
      onProgresso?.call('Exportando AFD dos relógios...');
      await _exportarAfd(dir, ini, fimD, res);
    }
    if (folha) {
      onProgresso?.call('Gerando arquivo da folha de pagamento...');
      res.arquivos.addAll(await _gerarFolha(dir, ini, fimD, colabs, espelhosCalc));
    }
    if (espelhos) {
      onProgresso?.call('Gerando espelhos de ponto e relatório de entradas/saídas...');
      res.arquivos.add(await _gerarEspelhosHtml(dir, ini, fimD, razao, emp?.cnpj ?? '', colabs, espelhosCalc));
      final es = await RelatorioPonto.gerarEntradasSaidasHtml(ini, fimD, 0, razao, emp?.cnpj ?? '');
      final arqEs = p.join(dir, 'Relatorio_Entradas_Saidas_${_fArq.format(ini)}_${_fArq.format(fimD)}.html');
      await File(arqEs).writeAsString(es);
      res.arquivos.add(ArquivoGerado(p.basename(arqEs), 'Cartão de ponto (entradas e saídas) de todos os colaboradores', arqEs, colabs.length));
    }

    // Assinatura eletrônica (.p7s) do AEJ e dos AFD com o certificado A1 configurado
    final cert = AppConfig.instance.folha.certificadoA1.trim();
    final paraAssinar = [
      for (final a in res.arquivos)
        if (a.nome.startsWith('AEJ_') || a.nome.startsWith('AFD_')) a.caminho
    ];
    if (cert.isNotEmpty && paraAssinar.isNotEmpty) {
      onProgresso?.call('Assinando arquivos com o certificado digital...');
      try {
        final s = await AssinaturaService.assinar(paraAssinar, cert, AppConfig.instance.folha.certificadoSenha);
        for (final c in paraAssinar) {
          res.arquivos.add(ArquivoGerado('${p.basename(c)}.p7s',
              'Assinatura eletrônica (CAdES) de ${p.basename(c)} - ${s.titular}, válido até ${s.validade}', '$c.p7s', 1));
        }
      } catch (e) {
        res.avisos.add('Arquivos não assinados: ${'$e'.replaceFirst('Exception: ', '')}');
      }
    } else if (paraAssinar.isNotEmpty) {
      res.avisos.add('AEJ/AFD gerados sem assinatura eletrônica: informe o certificado A1 nas opções da folha.');
    }

    // Pacote único para enviar à contabilidade
    onProgresso?.call('Compactando arquivos...');
    final zip = p.join(p.dirname(dir), 'Ponto_${p.basename(dir)}.zip');
    final r = await Process.run('powershell', [
      '-NoProfile', '-Command',
      "Compress-Archive -Force -Path '${dir.replaceAll("'", "''")}\\*' -DestinationPath '${zip.replaceAll("'", "''")}'"
    ]);
    if (r.exitCode == 0 && File(zip).existsSync()) res.zip = zip;
    return res;
  }

  static bool _vinculoNoPeriodo(DbRow c, DateTime ini, DateTime fim) {
    final adm = asDate(c['COL_DATA_ADMISSAO']), dem = asDate(c['COL_DATA_DEMISSAO']);
    return !(adm != null && soData(adm).isAfter(fim)) && !(dem != null && soData(dem).isBefore(ini));
  }

  static String _cpf(DbRow c) => asStr(c['COL_CPF']).isNotEmpty ? asStr(c['COL_CPF']) : asStr(c['PES_CNPJ_CPF']);
  static String _matricula(DbRow c) =>
      asStr(c['COL_CARTAO_PONTO']).trim().isNotEmpty ? asStr(c['COL_CARTAO_PONTO']).trim() : '${asInt(c['PES_ID'])}';

  // ------------------------------------------------------------------------------------------
  // AEJ - Arquivo Eletrônico de Jornada (Portaria MTP 671/2021, Anexo VI). Campos separados por "|".
  // ------------------------------------------------------------------------------------------
  static Future<ArquivoGerado> _gerarAej(String dir, DateTime ini, DateTime fim, String cnpj, String razao,
      List<DbRow> colabs, List<DbRow> marcacoes, Map<int, EspelhoPonto> espelhos) async {
    final cfg = AppConfig.instance.folha;
    final linhas = <String>[];
    final qt = List<int>.filled(9, 0);
    void add(int tipo, List<Object?> campos) {
      linhas.add([tipo.toString().padLeft(2, '0'), ...campos.map((c) => '${c ?? ''}'.replaceAll('|', ' ').trim())].join('|'));
      qt[tipo]++;
    }

    // 01 - Cabeçalho
    add(1, [cnpj.length == 11 ? 2 : 1, cnpj, '', '', razao, _fData.format(ini), _fData.format(fim), _dh(DateTime.now()), '001']);

    // 02 - REPs (relógios) que registraram marcações no período
    final relogios = await Db.instance.getRelogios();
    final idRep = <int, int>{};
    for (final r in relogios) {
      final id = asInt(r['PRE_ID']);
      if (!marcacoes.any((m) => asInt(m['PMA_RELOGIO']) == id)) continue;
      idRep[id] = idRep.length + 1;
      final nr = onlyDigits(asStr(r['PRE_SERIAL'])).padLeft(17, '0');
      add(2, [idRep[id], 1, nr.substring(nr.length - 17)]);
    }

    // 03 - Vínculos (empregados)
    final idVinc = <int, int>{};
    for (final c in colabs) {
      final id = asInt(c['PES_ID']);
      idVinc[id] = idVinc.length + 1;
      add(3, [idVinc[id], onlyDigits(_cpf(c)), asStr(c['PES_RSOCIAL_NOME']).trim()]);
    }

    // 04 - Horários contratuais
    final horarios = await Db.instance.getHorarios(apenasAtivos: false);
    for (final h in horarios) {
      add(4, [
        asInt(h['HOR_ID']), asInt(h['HOR_CARGA_DIARIA_MIN']),
        for (final campo in ['HOR_ENTRADA_1', 'HOR_SAIDA_1', 'HOR_ENTRADA_2', 'HOR_SAIDA_2'])
          asStr(h[campo]).isEmpty ? '' : _hhmm(asStr(h[campo])),
      ]);
    }
    final horarioDe = {for (final c in colabs) asInt(c['PES_ID']): asInt(c['COL_HORARIO']) > 0 ? asInt(c['COL_HORARIO']) : 1};

    // 05 - Marcações (E/S alternadas por dia, com sequência do par)
    final porPessoaDia = <String, int>{};
    for (final m in marcacoes) {
      final pid = asInt(m['PMA_PESSOA']);
      final dh = asDate(m['PMA_DATA_HORA']);
      if (!idVinc.containsKey(pid) || dh == null) continue;
      final origem = asStr(m['PMA_ORIGEM']).toUpperCase();
      final manual = origem == 'M';
      final rep = manual ? '' : (idRep[asInt(m['PMA_RELOGIO'])] ?? '');
      if (asStr(m['PMA_DESCONSIDERADA']) == 'S') {
        add(5, [idVinc[pid], _dh(dh), rep, 'D', '', manual ? 'I' : 'O', horarioDe[pid], asStr(m['PMA_MOTIVO_DESCONSIDERACAO'])]);
        continue;
      }
      final chave = '$pid-${_fData.format(dh)}';
      final ordem = porPessoaDia[chave] = (porPessoaDia[chave] ?? 0) + 1;
      add(5, [
        idVinc[pid], _dh(dh), rep, ordem.isOdd ? 'E' : 'S', (ordem + 1) ~/ 2, manual ? 'I' : 'O', horarioDe[pid],
        manual ? asStr(m['PMA_MOTIVO_AJUSTE']) : '',
      ]);
    }

    // 06 - Matrícula do empregado
    for (final c in colabs) {
      add(6, [idVinc[asInt(c['PES_ID'])], _matricula(c)]);
    }

    // 07 - Ausências: 1 = DSR, 2 = falta não justificada
    for (final c in colabs) {
      final e = espelhos[asInt(c['PES_ID'])];
      if (e == null) continue;
      for (final d in e.dias) {
        if (d.tipoDia == TipoDia.domingoDsr && d.trabalhadoMin == 0) {
          add(7, [idVinc[asInt(c['PES_ID'])], 1, _fData.format(d.data), '', '']);
        } else if (d.faltaDiaInteiro) {
          add(7, [idVinc[asInt(c['PES_ID'])], 2, _fData.format(d.data), d.faltaMin, '']);
        }
      }
      final r = e.resumo;
      if (r.usaBancoHoras && r.bancoCreditoMin > 0) add(7, [idVinc[asInt(c['PES_ID'])], 3, _fData.format(fim), r.bancoCreditoMin, 1]);
      if (r.usaBancoHoras && r.bancoDebitoMin > 0) add(7, [idVinc[asInt(c['PES_ID'])], 3, _fData.format(fim), r.bancoDebitoMin, 2]);
    }

    // 08 - Identificação do programa de tratamento de ponto
    final dev = onlyDigits(cfg.desenvolvedorCnpj);
    add(8, ['Go Up Ponto', '$buildVersion.$buildNumber', dev.length == 11 ? 2 : 1, dev, cfg.desenvolvedorNome, cfg.desenvolvedorEmail]);

    // 99 - Trailer com a quantidade de registros de cada tipo
    linhas.add(['99', for (var t = 1; t <= 8; t++) qt[t]].join('|'));

    final nome = 'AEJ_${cnpj.isEmpty ? 'SEMCNPJ' : cnpj}_${_fArq.format(ini)}_${_fArq.format(fim)}.txt';
    final caminho = p.join(dir, nome);
    await _gravarLatin1(caminho, '${linhas.join('\r\n')}\r\n');
    return ArquivoGerado(nome, 'AEJ - Arquivo Eletrônico de Jornada (Portaria 671)', caminho, linhas.length);
  }

  // ------------------------------------------------------------------------------------------
  // AFD - Arquivo Fonte de Dados exportado de cada relógio (gerado pelo próprio REP)
  // ------------------------------------------------------------------------------------------
  static Future<void> _exportarAfd(String dir, DateTime ini, DateTime fim, ResultadoContabil res) async {
    for (final r in await Db.instance.getRelogios(apenasAtivos: true)) {
      final nomeRel = asStr(r['PRE_NOME']);
      final c = ControlIdClient(
          host: asStr(r['PRE_IP']), port: asInt(r['PRE_PORTA']) > 0 ? asInt(r['PRE_PORTA']) : 80,
          useSsl: asStr(r['PRE_USAR_SSL']) == 'S')
        ..user = asStr(r['PRE_USUARIO'])
        ..password = asStr(r['PRE_SENHA'])
        ..timeoutSec = 30;
      try {
        final modo = asStr(r['PRE_MODO_COLETA']).toUpperCase();
        final conteudo = await c.getAfd(0, modo != 'AFD_1510');
        if (conteudo == null || conteudo.trim().isEmpty) {
          res.avisos.add('AFD do relógio [$nomeRel] não exportado: ${formatarErroAmigavel(c.lastError)}');
          continue;
        }
        final serial = onlyDigits(asStr(r['PRE_SERIAL']));
        final nome = 'AFD_${serial.isEmpty ? asInt(r['PRE_ID']) : serial}_${_fArq.format(DateTime.now())}.txt';
        final caminho = p.join(dir, nome);
        await File(caminho).writeAsString(conteudo, encoding: latin1);
        final qtd = ControlIdClient.parseAfd(conteudo).length;
        res.arquivos.add(ArquivoGerado(nome, 'AFD original do relógio [$nomeRel] (todas as marcações do REP)', caminho, qtd));
      } catch (e) {
        res.avisos.add('AFD do relógio [$nomeRel] não exportado: $e');
      } finally {
        await c.logout();
      }
    }
  }

  // ------------------------------------------------------------------------------------------
  // Folha de pagamento: eventos por colaborador (para importação) + resumo em planilha
  // ------------------------------------------------------------------------------------------
  static Future<List<ArquivoGerado>> _gerarFolha(
      String dir, DateTime ini, DateTime fim, List<DbRow> colabs, Map<int, EspelhoPonto> espelhos) async {
    final cfg = AppConfig.instance.folha;
    final competencia = DateFormat('MM/yyyy').format(ini);
    final fator = cfg.noturnaReduzida ? 60 / 52.5 : 1.0;

    final eventos = StringBuffer('MATRICULA;CPF;NOME;COMPETENCIA;RUBRICA;DESCRICAO;QUANTIDADE\r\n');
    final resumo = StringBuffer('MATRICULA;CPF;NOME;FUNCAO;JORNADA;DIAS_UTEIS;DIAS_TRABALHADOS;FALTAS_DIAS;'
        'HORAS_PREVISTAS;HORAS_TRABALHADAS;HORAS_ABONADAS;EXTRAS_50;EXTRAS_100;ADICIONAL_NOTURNO;ATRASOS;'
        'DSR_DESCONTADOS;INTERVALO_SUPRIMIDO;INTERJORNADA;FERIADOS_TRABALHADOS;BANCO_CREDITO;BANCO_DEBITO;BANCO_SALDO;SALDO\r\n');
    var qtEventos = 0;

    for (final c in colabs) {
      final e = espelhos[asInt(c['PES_ID'])];
      if (e == null) continue;
      final r = e.resumo;
      final mat = _matricula(c), cpf = onlyDigits(_cpf(c)), nome = asStr(c['PES_RSOCIAL_NOME']).trim();
      final noturno = (r.totalNoturnoMin * fator).round();
      final normais = r.totalTrabalhadoMin - r.totalExtrasMin;

      void evento(String rubrica, String descricao, String qtd, bool temValor) {
        if (!temValor || rubrica.trim().isEmpty) return;
        eventos.write('$mat;$cpf;$nome;$competencia;${rubrica.trim()};$descricao;$qtd\r\n');
        qtEventos++;
      }

      evento(cfg.rubricaHorasNormais, 'Horas normais', _qtHoras(normais < 0 ? 0 : normais), normais > 0);
      evento(cfg.rubricaExtras50, 'Horas extras ${cfg.pctFaixa1}%', _qtHoras(r.extras50FolhaMin), r.extras50FolhaMin > 0);
      evento(cfg.rubricaExtrasFaixa2, 'Horas extras ${cfg.pctFaixa2}% (acima de ${minutosParaHora(cfg.extraFaixa1Min)} no dia)',
          _qtHoras(r.extrasFaixa2FolhaMin), r.extrasFaixa2FolhaMin > 0);
      evento(cfg.rubricaExtras100, 'Horas extras ${cfg.pctDomingoFeriado}%', _qtHoras(r.totalExtras100Min), r.totalExtras100Min > 0);
      evento(cfg.rubricaNoturno, 'Adicional noturno', _qtHoras(noturno), noturno > 0);
      evento(cfg.rubricaFaltas, 'Faltas (dias)', '${r.totalFaltas}', r.totalFaltas > 0);
      evento(cfg.rubricaAtrasos, 'Atrasos/saídas antecipadas', _qtHoras(r.atrasosFolhaMin), r.atrasosFolhaMin > 0);
      evento(cfg.rubricaDsr, 'DSR descontado (dias)', '${r.dsrDescontados}', r.dsrDescontados > 0);
      evento(cfg.rubricaIntervalo, 'Intervalo intrajornada suprimido', _qtHoras(r.totalIntervaloSuprimidoMin),
          r.totalIntervaloSuprimidoMin > 0);
      evento(cfg.rubricaInterjornada, 'Interjornada (descanso < 11h)', _qtHoras(r.totalInterjornadaMin),
          r.totalInterjornadaMin > 0);

      resumo.write([
        mat, cpf, nome, asStr(c['COL_FUNCAO']), r.jornadaDescricao, r.totalDiasUteis, r.totalDiasTrabalhados, r.totalFaltas,
        _qtHoras(r.totalPrevistoMin), _qtHoras(r.totalTrabalhadoMin), _qtHoras(r.totalAbonadoMin),
        _qtHoras(r.totalExtras50Min), _qtHoras(r.totalExtras100Min), _qtHoras(noturno), _qtHoras(r.totalAtrasosMin),
        r.dsrDescontados, _qtHoras(r.totalIntervaloSuprimidoMin), _qtHoras(r.totalInterjornadaMin), r.totalFeriadosTrabalhados,
        r.usaBancoHoras ? _qtHoras(r.bancoCreditoMin) : '', r.usaBancoHoras ? _qtHoras(r.bancoDebitoMin) : '',
        r.usaBancoHoras ? minutosParaHora(r.bancoSaldoFinalMin, exibirSinal: true) : '',
        minutosParaHora(r.saldoTotalMin, exibirSinal: true),
      ].map((v) => '$v'.replaceAll(';', ',')).join(';'));
      resumo.write('\r\n');
    }

    final per = '${_fArq.format(ini)}_${_fArq.format(fim)}';
    final arqEventos = p.join(dir, 'Folha_Eventos_$per.txt');
    final arqResumo = p.join(dir, 'Resumo_Horas_$per.csv');
    await _gravarLatin1(arqEventos, eventos.toString());
    await _gravarLatin1(arqResumo, resumo.toString());
    return [
      ArquivoGerado(p.basename(arqEventos), 'Eventos da folha (matrícula, rubrica e quantidade) para importação', arqEventos, qtEventos),
      ArquivoGerado(p.basename(arqResumo), 'Resumo de horas por colaborador (abre no Excel)', arqResumo, colabs.length),
    ];
  }

  // ------------------------------------------------------------------------------------------
  // Espelhos de ponto de todos os colaboradores em um único documento (imprimir / PDF)
  // ------------------------------------------------------------------------------------------
  static Future<ArquivoGerado> _gerarEspelhosHtml(String dir, DateTime ini, DateTime fim, String razao, String cnpj,
      List<DbRow> colabs, Map<int, EspelhoPonto> espelhos) async {
    final corpo = StringBuffer();
    String? cabecalho;
    for (final c in colabs) {
      final e = espelhos[asInt(c['PES_ID'])];
      if (e == null || e.dias.isEmpty) continue;
      final html = e.gerarRelatorioHtml(razao, formatarDoc(cnpj));
      final ib = html.indexOf('<body>'), fb = html.lastIndexOf('</body>');
      cabecalho ??= html.substring(0, ib);
      corpo.writeln('<div style="page-break-after: always;">${html.substring(ib + 6, fb)}</div>');
    }
    final caminho = p.join(dir, 'Espelhos_Ponto_${_fArq.format(ini)}_${_fArq.format(fim)}.html');
    await File(caminho).writeAsString('${cabecalho ?? '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>'}<body>$corpo</body></html>');
    return ArquivoGerado(p.basename(caminho), 'Espelhos de ponto de todos os colaboradores (imprimir ou salvar em PDF)', caminho,
        espelhos.length);
  }
}
