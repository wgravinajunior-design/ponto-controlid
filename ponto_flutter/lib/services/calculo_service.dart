import '../core/config.dart';
import '../core/util.dart';
import '../data/database.dart';

enum TipoDia { util, sabadoCompensado, sabadoTrabalhado, domingoDsr, feriado, folga }

class DiaEspelho {
  DateTime data;
  String diaSemana = '';
  TipoDia tipoDia = TipoDia.util;
  String entrada1 = '', saida1 = '', entrada2 = '', saida2 = '', batidasExtras = '';
  final batidas = <DateTime>[];
  int cargaPrevistaMin = 0, trabalhadoMin = 0, extraMin = 0, faltaMin = 0, saldoMin = 0;
  int noturnoMin = 0; // minutos entre 22h e 5h (relógio, sem redução), com prorrogação (Súmula 60)
  int abonoMin = 0;
  int intervaloMin = 0; // intervalo intrajornada usufruído
  int intervaloSuprimidoMin = 0; // art. 71 §4º
  int interjornadaFaltanteMin = 0; // art. 66 (11h entre jornadas)
  bool faltaDiaInteiro = false;
  bool impar = false;
  bool dsrDescontado = false;
  bool extra100 = false; // domingo, feriado ou folga da escala
  bool foraContrato = false; // antes da admissão ou depois da demissão
  String afastamento = ''; // férias, licença, INSS...
  String feriado = '';
  final alertas = <String>[];
  String justificativa = '';
  DiaEspelho(this.data);

  bool get domingoOuFeriado => tipoDia == TipoDia.domingoDsr || tipoDia == TipoDia.feriado;
  String get ocorrencia => [if (justificativa.isNotEmpty) justificativa, ...alertas].join(' • ');

  String get cargaPrevistaStr => minutosParaHora(cargaPrevistaMin);
  String get trabalhadoStr => minutosParaHora(trabalhadoMin);
  String get extraStr => minutosParaHora(extraMin);
  String get faltaStr => minutosParaHora(faltaMin);
  String get saldoStr => minutosParaHora(saldoMin, exibirSinal: true);
}

class ResumoEspelho {
  String colaboradorNome = '', colaboradorCpf = '', colaboradorPis = '', colaboradorMatricula = '';
  String colaboradorFuncao = '', jornadaDescricao = '';
  int totalDiasPeriodo = 0, totalDiasUteis = 0, totalDiasTrabalhados = 0, totalFaltas = 0;
  int totalPrevistoMin = 0, totalTrabalhadoMin = 0, totalExtrasMin = 0, totalFaltasMin = 0, saldoTotalMin = 0;
  int totalExtras50Min = 0, totalExtras100Min = 0, totalNoturnoMin = 0, totalAtrasosMin = 0, totalAbonadoMin = 0;
  int totalIntervaloSuprimidoMin = 0, totalInterjornadaMin = 0, dsrDescontados = 0, diasExtraAcima2h = 0;
  int totalFeriadosTrabalhados = 0;
  int totalExtrasFaixa2Min = 0; // extras em dias normais acima da 1ª faixa (convenção coletiva)
  int diasAfastado = 0;
  // Banco de horas: créditos (extras 50%) e débitos (atrasos) do período não vão para a folha
  bool usaBancoHoras = false;
  int bancoCreditoMin = 0, bancoDebitoMin = 0, bancoSaldoAnteriorMin = 0;
  int get bancoSaldoPeriodoMin => bancoCreditoMin - bancoDebitoMin;
  int get bancoSaldoFinalMin => bancoSaldoAnteriorMin + bancoSaldoPeriodoMin;

  /// Extras 50% e atrasos que vão para a folha (fora do banco de horas).
  int get extras50FolhaMin => usaBancoHoras ? 0 : totalExtras50Min;
  int get atrasosFolhaMin => usaBancoHoras ? 0 : totalAtrasosMin;
  int get extrasFaixa2FolhaMin => usaBancoHoras ? 0 : totalExtrasFaixa2Min;
}

class EspelhoPonto {
  final dias = <DiaEspelho>[];
  final resumo = ResumoEspelho();

  String gerarRelatorioHtml(String razaoEmpresa, String cnpjEmpresa) {
    final r = resumo;
    String card(String t, String v, [String cls = '']) =>
        '<div class="card"><div>$t</div><div class="val $cls">$v</div></div>';
    final sb = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="pt-BR"><head><meta charset="UTF-8">')
      ..writeln('<title>Espelho de Ponto Eletrônico - Portaria 671 MTE</title>')
      ..writeln('<style>')
      ..writeln('body { font-family: Segoe UI, Arial, sans-serif; font-size: 12px; color: #222; margin: 20px; }')
      ..writeln('.header { border-bottom: 2px solid #2b579a; padding-bottom: 8px; margin-bottom: 15px; }')
      ..writeln('.header h2 { margin: 0 0 4px 0; color: #1e395b; }')
      ..writeln('.header p { margin: 2px 0; font-size: 11px; color: #555; }')
      ..writeln('.info-box { background: #f4f6f9; border: 1px solid #d5dbe3; border-radius: 4px; padding: 10px; margin-bottom: 15px; }')
      ..writeln('.info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }')
      ..writeln('table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }')
      ..writeln('th { background: #2b579a; color: #fff; padding: 6px 4px; text-align: center; font-size: 10px; }')
      ..writeln('td { border: 1px solid #e1e4e8; padding: 4px 3px; text-align: center; font-size: 10px; }')
      ..writeln('tr:nth-child(even) { background-color: #fcfcfc; }')
      ..writeln('.dsr { background-color: #f7f7f7 !important; color: #888; }')
      ..writeln('.feriado { background-color: #eef6ff !important; color: #1d4ed8; }')
      ..writeln('.falta { background-color: #fef0f0 !important; color: #c53030; font-weight: bold; }')
      ..writeln('.extra { color: #2e7d32; font-weight: bold; }')
      ..writeln('.impar { background-color: #fff9db !important; color: #d97706; font-weight: bold; }')
      ..writeln('.resumo-box { display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px; margin-bottom: 30px; }')
      ..writeln('.card { background: #fff; border: 1px solid #d0d7de; border-radius: 6px; padding: 8px; text-align: center; font-size: 11px; }')
      ..writeln('.card .val { font-size: 16px; font-weight: bold; margin-top: 4px; }')
      ..writeln('.val-pos { color: #2e7d32; } .val-neg { color: #c53030; }')
      ..writeln('.legenda { font-size: 10px; color: #666; margin-bottom: 10px; }')
      ..writeln('.signatures { display: grid; grid-template-columns: 1fr 1fr; gap: 60px; margin-top: 40px; text-align: center; }')
      ..writeln('.sign-line { border-top: 1px solid #333; padding-top: 5px; margin-top: 40px; }')
      ..writeln('@media print { button { display: none; } body { margin: 0; } }')
      ..writeln('</style></head><body>')
      ..writeln('<div style="text-align: right; margin-bottom: 10px;"><button onclick="window.print()" '
          'style="padding: 8px 16px; background: #2b579a; color: #fff; border: none; border-radius: 4px; cursor: pointer; '
          'font-weight: bold;">Imprimir Espelho de Ponto</button></div>')
      ..writeln('<div class="header"><h2>ESPELHO DE PONTO ELETRÔNICO</h2>')
      ..writeln('<p><b>Empregador:</b> ${esc(razaoEmpresa)} &nbsp;|&nbsp; <b>CNPJ:</b> ${esc(cnpjEmpresa)}</p>')
      ..writeln('<p>Relatório gerado em conformidade com as diretrizes da Portaria MTE 671/2021.</p></div>')
      ..writeln('<div class="info-box"><div class="info-grid">')
      ..writeln('<div><b>Colaborador:</b> ${esc(r.colaboradorNome)}</div>')
      ..writeln('<div><b>CPF:</b> ${esc(r.colaboradorCpf)}</div>')
      ..writeln('<div><b>PIS:</b> ${esc(r.colaboradorPis)}</div>')
      ..writeln('<div><b>Matrícula:</b> ${esc(r.colaboradorMatricula)}</div>')
      ..writeln('<div><b>Função/Cargo:</b> ${esc(r.colaboradorFuncao)}</div>')
      ..writeln('<div><b>Jornada:</b> ${esc(r.jornadaDescricao)}</div>')
      ..writeln('</div></div>')
      ..writeln('<table><thead><tr><th>Data</th><th>Dia</th><th>1ª Ent</th><th>1ª Saí</th><th>2ª Ent</th><th>2ª Saí</th>'
          '<th>Outras</th><th>Previsto</th><th>Realizado</th><th>Extras</th><th>Faltas</th><th>Noturno</th>'
          '<th>Interv. supr.</th><th>Saldo</th><th>Ocorrência / Justificativa</th></tr></thead><tbody>');
    for (final d in dias) {
      var cls = '';
      if (d.tipoDia == TipoDia.feriado) {
        cls = ' class="feriado"';
      } else if (d.tipoDia == TipoDia.domingoDsr || d.tipoDia == TipoDia.sabadoCompensado || d.tipoDia == TipoDia.folga) {
        cls = ' class="dsr"';
      } else if (d.impar) {
        cls = ' class="impar"';
      } else if (d.faltaDiaInteiro) {
        cls = ' class="falta"';
      }
      final corSaldo = d.saldoMin > 0
          ? ' class="extra"'
          : (d.saldoMin < 0 ? ' style="color: #c53030; font-weight: bold;"' : '');
      String z(int m) => m == 0 ? '' : minutosParaHora(m);
      sb.writeln('<tr$cls><td>${fmtData(d.data)}</td><td>${d.diaSemana}</td><td>${d.entrada1}</td><td>${d.saida1}</td>'
          '<td>${d.entrada2}</td><td>${d.saida2}</td><td>${d.batidasExtras}</td><td>${d.cargaPrevistaStr}</td>'
          '<td>${d.trabalhadoStr}</td><td>${d.extraStr}${d.extra100 && d.extraMin > 0 ? ' (100%)' : ''}</td>'
          '<td>${d.faltaStr}</td><td>${z(d.noturnoMin)}</td><td>${z(d.intervaloSuprimidoMin)}</td>'
          '<td$corSaldo>${d.saldoStr}</td><td>${esc(d.ocorrencia)}</td></tr>');
    }
    sb
      ..writeln('</tbody></table>')
      ..writeln('<p class="legenda">Tolerância conforme CLT art. 58 §1º (5 min por marcação, máximo de 10 min diários). '
          'Extras em domingos, feriados e folgas da escala: 100%. Adicional noturno das 22h às 5h com prorrogação '
          '(Súmula 60 TST). Intervalo suprimido: art. 71 §4º. Descanso entre jornadas: art. 66.</p>')
      ..writeln('<div class="resumo-box">')
      ..writeln(card('Previsto', minutosParaHora(r.totalPrevistoMin)))
      ..writeln(card('Realizado', minutosParaHora(r.totalTrabalhadoMin)))
      ..writeln(card('Extras 50%', '+${minutosParaHora(r.totalExtras50Min)}', 'val-pos'))
      ..writeln(card('Extras 100%', '+${minutosParaHora(r.totalExtras100Min)}', 'val-pos'))
      ..writeln(card('Adicional noturno', minutosParaHora(r.totalNoturnoMin)))
      ..writeln(card('Faltas', '${r.totalFaltas} dia(s)', 'val-neg'))
      ..writeln(card('Atrasos / saídas', '-${minutosParaHora(r.totalAtrasosMin)}', 'val-neg'))
      ..writeln(card('Intervalo suprimido', minutosParaHora(r.totalIntervaloSuprimidoMin)))
      ..writeln(card('Interjornada < 11h', minutosParaHora(r.totalInterjornadaMin)))
      ..writeln(card('DSR descontados', '${r.dsrDescontados}', r.dsrDescontados > 0 ? 'val-neg' : ''))
      ..writeln(card('Abonado', minutosParaHora(r.totalAbonadoMin)))
      ..writeln(card(
          r.usaBancoHoras ? 'Banco de horas (saldo)' : 'Saldo do período',
          minutosParaHora(r.usaBancoHoras ? r.bancoSaldoFinalMin : r.saldoTotalMin, exibirSinal: true),
          (r.usaBancoHoras ? r.bancoSaldoFinalMin : r.saldoTotalMin) >= 0 ? 'val-pos' : 'val-neg'))
      ..writeln('</div><div class="signatures"><div><div class="sign-line">Assinatura do Colaborador</div></div>'
          '<div><div class="sign-line">Assinatura do Gestor / RH</div></div></div>')
      ..writeln('</body></html>');
    return sb.toString();
  }
}

/// Minutos de um intervalo trabalhado no período noturno (22h às 5h, CLT art. 73).
/// Com [prorrogacao] (Súmula 60 TST): se a jornada cumpriu todo o período noturno e continuou
/// depois das 5h, as horas prorrogadas também são noturnas.
int minutosNoturnos(DateTime ini, DateTime fim, {bool prorrogacao = true}) {
  if (!fim.isAfter(ini)) return 0;
  var total = 0;
  for (var d = DateTime(ini.year, ini.month, ini.day - 1);
      !d.isAfter(DateTime(fim.year, fim.month, fim.day));
      d = DateTime(d.year, d.month, d.day + 1)) {
    final jIni = DateTime(d.year, d.month, d.day, 22);
    final jFim = DateTime(d.year, d.month, d.day + 1, 5);
    final a = ini.isAfter(jIni) ? ini : jIni;
    final b = fim.isBefore(jFim) ? fim : jFim;
    if (b.isAfter(a)) total += b.difference(a).inMinutes;
    if (prorrogacao && !ini.isAfter(jIni) && fim.isAfter(jFim)) {
      // Prorrogação até o fim do intervalo (ou até as 22h seguintes, se fosse o caso)
      final limite = DateTime(d.year, d.month, d.day + 1, 22);
      total += (fim.isBefore(limite) ? fim : limite).difference(jFim).inMinutes;
    }
  }
  return total;
}

/// Parâmetros de jornada usados pela apuração.
class _Jornada {
  String descricao = 'Comercial 44h (Padrao)';
  int tolerancia = 10, carga = 528, intervaloMin = 60;
  bool trabalhaSabado = false, bancoHoras = false;
  String e1 = '', s1 = '', e2 = '', s2 = '', sabE1 = '', sabS1 = '';
  String escala = 'SEMANAL';
  DateTime? escalaInicio;
  int viradaMin = 0; // batidas antes deste horário pertencem ao dia anterior (turno noturno)

  Map<int, DbRow> dias = {}; // jornada específica por dia da semana (1 = seg ... 7 = dom)
  int cicloTrabalho = 0, cicloFolga = 0;

  bool get eCiclo => escala == 'CICLO' && escalaInicio != null && cicloTrabalho > 0 && cicloFolga > 0;

  int get cargaSabado {
    final a = horaParaMinutos(sabE1), b = horaParaMinutos(sabS1);
    return (sabE1.isNotEmpty && sabS1.isNotEmpty && b > a) ? b - a : 240;
  }

  bool get e12x36 => escala == '12X36' && escalaInicio != null;
}

/// Motor de apuração do espelho de ponto.
class PontoCalculoService {
  static const _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

  /// Tolerância por marcação (CLT art. 58 §1º).
  static const toleranciaPorMarcacao = 5;
  static const interjornadaMinima = 11 * 60;
  static const limiteExtrasDia = 120; // art. 59

  static Future<EspelhoPonto> calcularEspelho(int pessoaId, DateTime dataIni, DateTime dataFim) async {
    final esp = EspelhoPonto();
    final hoje = soData(DateTime.now());
    final ini = soData(dataIni), fim = soData(dataFim).isAfter(hoje) ? hoje : soData(dataFim); // dias futuros não são apurados
    if (pessoaId <= 0 || ini.isAfter(fim)) return esp;
    final db = Db.instance;

    // 1. Colaborador
    final p = await db.getPessoaPorId(pessoaId);
    if (p == null) return esp;
    final r = esp.resumo
      ..colaboradorNome = asStr(p['PES_RSOCIAL_NOME'])
      ..colaboradorCpf = asStr(p['COL_CPF']).isNotEmpty ? asStr(p['COL_CPF']) : asStr(p['PES_CNPJ_CPF'])
      ..colaboradorPis = asStr(p['COL_PIS'])
      ..colaboradorMatricula = asStr(p['COL_CARTAO_PONTO'])
      ..colaboradorFuncao = asStr(p['COL_FUNCAO']);
    var horId = asInt(p['COL_HORARIO']);
    if (horId <= 0) horId = 1;

    // 2. Jornada
    final j = _Jornada();
    final h = await db.getHorarioPorId(horId);
    if (h != null) {
      j
        ..descricao = asStr(h['HOR_DESCRICAO'])
        ..tolerancia = asInt(h['HOR_TOLERANCIA_MIN']) > 0 ? asInt(h['HOR_TOLERANCIA_MIN']) : 10
        ..carga = asInt(h['HOR_CARGA_DIARIA_MIN']) > 0 ? asInt(h['HOR_CARGA_DIARIA_MIN']) : 528
        ..trabalhaSabado = asStr(h['HOR_TRABALHA_SABADO']) == 'S'
        ..e1 = asStr(h['HOR_ENTRADA_1'])
        ..s1 = asStr(h['HOR_SAIDA_1'])
        ..e2 = asStr(h['HOR_ENTRADA_2'])
        ..s2 = asStr(h['HOR_SAIDA_2'])
        ..sabE1 = asStr(h['HOR_SAB_ENTRADA_1'])
        ..sabS1 = asStr(h['HOR_SAB_SAIDA_1'])
        ..escala = asStr(h['HOR_TIPO_ESCALA']).toUpperCase()
        ..escalaInicio = asDate(h['HOR_ESCALA_INICIO'])
        ..viradaMin = horaParaMinutos(asStr(h['HOR_VIRADA_DIA']))
        ..intervaloMin = asInt(h['HOR_INTERVALO_MIN']) > 0 ? asInt(h['HOR_INTERVALO_MIN']) : 60
        ..bancoHoras = asStr(h['HOR_BANCO_HORAS']) == 'S'
        ..cicloTrabalho = asInt(h['HOR_CICLO_TRABALHO'])
        ..cicloFolga = asInt(h['HOR_CICLO_FOLGA']);
      j.dias = await db.getHorarioDias(horId);
    }
    // Vínculo: dias antes da admissão ou depois da demissão não contam
    final admissao = asDate(p['COL_DATA_ADMISSAO']), demissao = asDate(p['COL_DATA_DEMISSAO']);
    // Afastamentos (férias, licenças, INSS...) no período
    final afastamentos = await db.getAfastamentos(pessoaId: pessoaId, ini: ini, fim: fim);
    String? afastamentoEm(DateTime dia) {
      for (final a in afastamentos) {
        final i = asDate(a['AFA_INICIO']), f = asDate(a['AFA_FIM']);
        if (i != null && f != null && !dia.isBefore(soData(i)) && !dia.isAfter(soData(f))) return asStr(a['AFA_TIPO']);
      }
      return null;
    }
    final faixa1 = AppConfig.instance.folha.extraFaixa1Min;
    final dividirFaixas = AppConfig.instance.folha.pctFaixa1 != AppConfig.instance.folha.pctFaixa2;
    r
      ..jornadaDescricao = j.descricao
      ..usaBancoHoras = j.bancoHoras;
    if (j.bancoHoras) {
      final lanc = await db.getBancoHoras(pessoaId: pessoaId, ate: ini.subtract(const Duration(days: 1)));
      r.bancoSaldoAnteriorMin = lanc.fold<int>(0, (s, l) => s + asInt(l['BH_MINUTOS']));
    }

    // 3. Batidas (um dia antes e depois, para turno noturno e interjornada) agrupadas por dia de trabalho
    final marc = await db.getMarcacoes(ini.subtract(const Duration(days: 2)), fim.add(const Duration(days: 1)),
        pessoaId: pessoaId);
    final porDia = <DateTime, List<DateTime>>{};
    for (final m in marc) {
      final dh = asDate(m['PMA_DATA_HORA']);
      if (dh == null) continue;
      var dia = soData(dh);
      if (j.viradaMin > 0 && dh.hour * 60 + dh.minute < j.viradaMin) dia = dia.subtract(const Duration(days: 1));
      porDia.putIfAbsent(dia, () => []).add(dh);
    }
    for (final l in porDia.values) {
      l.sort();
    }

    // 4. Justificativas e feriados
    final jusPorDia = <DateTime, DbRow>{};
    for (final x in await db.getJustificativasPeriodo(pessoaId, ini, fim)) {
      final d = asDate(x['JUS_DATA']);
      if (d != null) jusPorDia.putIfAbsent(soData(d), () => x);
    }
    final feriados = await db.feriadosNoPeriodo(ini, fim);

    DateTime? ultimaSaidaAnterior(DateTime dia) {
      for (var k = 1; k <= 3; k++) {
        final l = porDia[dia.subtract(Duration(days: k))];
        if (l != null && l.isNotEmpty) return l.last;
      }
      return null;
    }

    for (var dia = ini; !dia.isAfter(fim); dia = DateTime(dia.year, dia.month, dia.day + 1)) {
      r.totalDiasPeriodo++;
      final it = DiaEspelho(dia)..diaSemana = _diasSemana[dia.weekday - 1];
      final fer = feriados[dia];

      // Dia previsto e horários programados
      var programado = <String>[];
      final foraContrato =
          (admissao != null && dia.isBefore(soData(admissao))) || (demissao != null && dia.isAfter(soData(demissao)));
      final afastado = foraContrato ? null : afastamentoEm(dia);
      final cfgDia = j.dias[dia.weekday];
      if (foraContrato) {
        it
          ..tipoDia = TipoDia.folga
          ..foraContrato = true
          ..alertas.add(admissao != null && dia.isBefore(soData(admissao))
              ? 'Antes da admissão (${fmtData(admissao)})'
              : 'Após a demissão (${fmtData(demissao)})');
      } else if (afastado != null) {
        it
          ..tipoDia = TipoDia.folga
          ..afastamento = afastado
          ..alertas.add(afastado);
        r.diasAfastado++;
      } else if (j.eCiclo) {
        final pos = dia.difference(soData(j.escalaInicio!)).inDays % (j.cicloTrabalho + j.cicloFolga);
        if (pos >= 0 && pos < j.cicloTrabalho) {
          it.cargaPrevistaMin = j.carga;
          programado = [j.e1, j.s1, j.e2, j.s2];
          r.totalDiasUteis++;
          if (fer != null) {
            it
              ..tipoDia = TipoDia.feriado
              ..feriado = fer
              ..cargaPrevistaMin = 0
              ..alertas.add('Feriado: $fer');
            r.totalDiasUteis--;
            programado = [];
          }
        } else {
          it
            ..tipoDia = TipoDia.folga
            ..alertas.add('Folga da escala ${j.cicloTrabalho}x${j.cicloFolga}');
        }
      } else if (cfgDia != null && fer == null && !j.e12x36) {
        // Jornada específica deste dia da semana
        if (asStr(cfgDia['HDI_FOLGA']) == 'S') {
          it
            ..tipoDia = dia.weekday == DateTime.sunday ? TipoDia.domingoDsr : TipoDia.folga
            ..alertas.add(dia.weekday == DateTime.sunday ? 'DSR / Folga' : 'Folga semanal');
        } else {
          programado = [
            asStr(cfgDia['HDI_ENTRADA_1']), asStr(cfgDia['HDI_SAIDA_1']), asStr(cfgDia['HDI_ENTRADA_2']), asStr(cfgDia['HDI_SAIDA_2'])
          ];
          var carga = asInt(cfgDia['HDI_CARGA_MIN']);
          if (carga <= 0) {
            int par(String a, String b) => a.isNotEmpty && b.isNotEmpty ? horaParaMinutos(b) - horaParaMinutos(a) : 0;
            carga = par(programado[0], programado[1]) + par(programado[2], programado[3]);
          }
          it
            ..cargaPrevistaMin = carga
            ..tipoDia = dia.weekday == DateTime.saturday ? TipoDia.sabadoTrabalhado : TipoDia.util;
          r.totalDiasUteis++;
        }
      } else if (j.e12x36) {
        final trabalho = dia.difference(soData(j.escalaInicio!)).inDays.isEven;
        if (trabalho) {
          it.cargaPrevistaMin = j.carga;
          programado = [j.e1, j.s1, j.e2, j.s2];
          r.totalDiasUteis++;
        } else {
          it
            ..tipoDia = TipoDia.folga
            ..alertas.add('Folga da escala 12x36');
        }
        // Na 12x36 o feriado trabalhado já é compensado (CLT art. 59-A, parágrafo único)
        if (fer != null) it.feriado = fer;
      } else if (fer != null) {
        it
          ..tipoDia = TipoDia.feriado
          ..feriado = fer
          ..alertas.add('Feriado: $fer');
      } else if (dia.weekday == DateTime.sunday) {
        it
          ..tipoDia = TipoDia.domingoDsr
          ..alertas.add('DSR / Folga');
      } else if (dia.weekday == DateTime.saturday) {
        if (j.trabalhaSabado) {
          it
            ..tipoDia = TipoDia.sabadoTrabalhado
            ..cargaPrevistaMin = j.cargaSabado;
          programado = [j.sabE1, j.sabS1];
          r.totalDiasUteis++;
        } else {
          it
            ..tipoDia = TipoDia.sabadoCompensado
            ..alertas.add('Sabado Compensado');
        }
      } else {
        it.cargaPrevistaMin = j.carga;
        programado = [j.e1, j.s1, j.e2, j.s2];
        r.totalDiasUteis++;
      }
      programado = programado.where((x) => x.isNotEmpty).toList();
      // 100%: domingo (DSR), feriado e folga das escalas 12x36 / ciclo; folga semanal comum segue a faixa normal
      it.extra100 = it.tipoDia == TipoDia.feriado ||
          it.tipoDia == TipoDia.domingoDsr ||
          (it.tipoDia == TipoDia.folga && (j.e12x36 || j.eCiclo) && !it.foraContrato && it.afastamento.isEmpty);

      // Batidas e horas trabalhadas
      final bat = porDia[dia] ?? <DateTime>[];
      it.batidas.addAll(bat);
      final n = bat.length;
      if (n > 0) {
        it.entrada1 = fmtHora(bat[0]);
        if (n >= 2) it.saida1 = fmtHora(bat[1]);
        if (n >= 3) it.entrada2 = fmtHora(bat[2]);
        if (n >= 4) it.saida2 = fmtHora(bat[3]);
        if (n > 4) it.batidasExtras = bat.skip(4).map(fmtHora).join(' ');
        for (var i = 0; i < n ~/ 2; i++) {
          it.trabalhadoMin += bat[i * 2 + 1].difference(bat[i * 2]).inMinutes;
          it.noturnoMin += minutosNoturnos(bat[i * 2], bat[i * 2 + 1]);
          if (i > 0) it.intervaloMin += bat[i * 2].difference(bat[i * 2 - 1]).inMinutes;
        }
        if (n.isOdd) {
          it
            ..impar = true
            ..alertas.add('Marcacao Impar');
        }
        r.totalDiasTrabalhados++;
        if (it.tipoDia == TipoDia.feriado) r.totalFeriadosTrabalhados++;

        // Descanso mínimo de 11h entre jornadas (art. 66)
        final anterior = ultimaSaidaAnterior(dia);
        if (anterior != null) {
          final descanso = bat.first.difference(anterior).inMinutes;
          if (descanso >= 0 && descanso < interjornadaMinima) {
            it
              ..interjornadaFaltanteMin = interjornadaMinima - descanso
              ..alertas.add('Interjornada de ${minutosParaHora(descanso)} (mínimo 11h)');
          }
        }

        // Intervalo intrajornada (art. 71): 15 min acima de 4h; o da jornada (mínimo 1h) acima de 6h
        if (!it.impar) {
          final exigido = it.trabalhadoMin > 360 ? (j.intervaloMin < 60 ? 60 : j.intervaloMin) : (it.trabalhadoMin > 240 ? 15 : 0);
          if (exigido > 0 && it.intervaloMin < exigido) {
            it
              ..intervaloSuprimidoMin = exigido - it.intervaloMin
              ..alertas.add('Intervalo de ${minutosParaHora(it.intervaloMin)} (mínimo ${minutosParaHora(exigido)})');
          }
        }
      }

      // Justificativa / abono
      var abono = 0;
      final jus = jusPorDia[dia];
      if (jus != null) {
        abono = asInt(jus['JUS_ABONO_MINUTOS']);
        if (abono <= 0) abono = it.cargaPrevistaMin;
        final motivo = asStr(jus['JUS_MOTIVO']);
        it.justificativa = asStr(jus['JUS_TIPO']) + (motivo.isNotEmpty ? ' ($motivo)' : '');
      }

      // Diferença do dia com tolerância (art. 58 §1º e Súmula 366 TST)
      final diff = it.trabalhadoMin + abono - it.cargaPrevistaMin;
      var considerar = diff;
      if (!it.impar && n > 0 && programado.length == n && it.cargaPrevistaMin > 0) {
        // Variação de cada marcação em relação ao horário programado
        var soma = 0, dentro = true;
        DateTime? ref;
        for (var i = 0; i < n; i++) {
          var prog = dia.add(Duration(minutes: horaParaMinutos(programado[i])));
          if (ref != null && prog.isBefore(ref)) prog = prog.add(const Duration(days: 1)); // virada da noite
          ref = prog;
          final v = bat[i].difference(prog).inMinutes.abs();
          soma += v;
          if (v > toleranciaPorMarcacao) dentro = false;
        }
        if (dentro && soma <= j.tolerancia) considerar = 0;
      } else if (diff.abs() <= j.tolerancia) {
        considerar = 0;
      }
      it.extraMin = considerar > 0 ? considerar : 0;
      it.faltaMin = considerar < 0 ? -considerar : 0;

      // Dia previsto sem batida e sem justificativa: falta do dia inteiro
      if (it.cargaPrevistaMin > 0 && n == 0 && jus == null) {
        it
          ..faltaMin = it.cargaPrevistaMin
          ..faltaDiaInteiro = true
          ..alertas.add('Falta Nao Justificada');
        r.totalFaltas++;
      }
      if (it.extraMin > limiteExtrasDia) {
        it.alertas.add('Extra acima de 2h (art. 59)');
        r.diasExtraAcima2h++;
      }

      it
        ..saldoMin = it.extraMin - it.faltaMin
        ..abonoMin = jus == null ? 0 : (abono > it.cargaPrevistaMin ? it.cargaPrevistaMin : abono);

      if (it.extra100) {
        r.totalExtras100Min += it.extraMin;
      } else {
        final f2 = dividirFaixas && it.extraMin > faixa1 ? it.extraMin - faixa1 : 0;
        r
          ..totalExtras50Min += it.extraMin - f2
          ..totalExtrasFaixa2Min += f2;
      }
      if (!it.faltaDiaInteiro) r.totalAtrasosMin += it.faltaMin;
      r
        ..totalPrevistoMin += it.cargaPrevistaMin
        ..totalTrabalhadoMin += it.trabalhadoMin
        ..totalExtrasMin += it.extraMin
        ..totalNoturnoMin += it.noturnoMin
        ..totalAbonadoMin += it.abonoMin
        ..totalIntervaloSuprimidoMin += it.intervaloSuprimidoMin
        ..totalInterjornadaMin += it.interjornadaFaltanteMin
        ..totalFaltasMin += it.faltaMin;
      esp.dias.add(it);
    }

    // 5. Perda do DSR (Lei 605/49, art. 6º): falta injustificada na semana desconta o domingo seguinte
    if (!j.e12x36) {
      for (final d in esp.dias.where((d) => d.tipoDia == TipoDia.domingoDsr)) {
        final semana = esp.dias.where((x) => x.data.isBefore(d.data) && d.data.difference(x.data).inDays <= 6);
        if (semana.any((x) => x.faltaDiaInteiro)) {
          d
            ..dsrDescontado = true
            ..alertas.add('DSR descontado (falta na semana)');
          r.dsrDescontados++;
        }
      }
    }

    // 6. Banco de horas: extras 50% viram crédito e atrasos viram débito (não vão para a folha)
    if (j.bancoHoras) {
      r
        ..bancoCreditoMin = r.totalExtras50Min + r.totalExtrasFaixa2Min
        ..bancoDebitoMin = r.totalAtrasosMin;
    }
    r.saldoTotalMin = r.totalExtrasMin - r.totalFaltasMin;
    return esp;
  }
}
