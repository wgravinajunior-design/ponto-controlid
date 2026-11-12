import 'package:flutter/material.dart';

import '../../core/util.dart';
import '../../data/database.dart';
import '../../services/calculo_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class EspelhoPage extends StatefulWidget {
  const EspelhoPage({super.key});
  @override
  State<EspelhoPage> createState() => _EspelhoPageState();
}

class _EspelhoPageState extends State<EspelhoPage> {
  final _app = AppState.instance;
  List<DbRow> _colabs = [];
  int _pessoaId = 0;
  DateTime _ini = DateTime.now(), _fim = DateTime.now();
  EspelhoPonto? _espelho;
  DiaEspelho? _sel;

  @override
  void initState() {
    super.initState();
    final h = DateTime.now();
    _ini = DateTime(h.year, h.month, 1);
    _fim = DateTime(h.year, h.month + 1, 0);
    _app.versaoDados.addListener(_aoMudarDados);
    _carregarColabs();
  }

  @override
  void dispose() {
    _app.versaoDados.removeListener(_aoMudarDados);
    super.dispose();
  }

  /// Batida nova (coleta, importação, ajuste): refaz a apuração mostrada, sem janela de progresso.
  void _aoMudarDados() {
    if (_pessoaId > 0 && mounted) _calcular(silencioso: true);
  }

  Future<void> _carregarColabs() async {
    if (!Db.instance.isConectado) return;
    final c = await Db.instance.getColaboradores();
    setState(() {
      _colabs = c;
      if (_pessoaId == 0 && c.isNotEmpty) _pessoaId = asInt(c.first['PES_ID']);
    });
    if (_pessoaId > 0 && _espelho == null) _calcular(silencioso: true);
  }

  String get _nomeColab =>
      asStr(_colabs.firstWhere((c) => asInt(c['PES_ID']) == _pessoaId, orElse: () => {})['PES_RSOCIAL_NOME']);

  Future<void> _calcular({bool silencioso = false}) async {
    if (_pessoaId <= 0) return silencioso ? null : mensagem(context, 'Selecione um colaborador.');
    final e = silencioso
        ? await PontoCalculoService.calcularEspelho(_pessoaId, _ini, _fim)
        : await comProgresso(context, () => PontoCalculoService.calcularEspelho(_pessoaId, _ini, _fim),
            texto: 'Apurando ponto...');
    if (e != null && mounted) {
      setState(() {
        _espelho = e;
        _sel = null;
      });
      if (!silencioso) {
        _app.logTs('🧮 Espelho de ponto apurado para ${e.resumo.colaboradorNome} '
          '(${fmtData(_ini)} a ${fmtData(_fim)}): saldo ${minutosParaHora(e.resumo.saldoFinalMin, exibirSinal: true)}.');
      }
    }
  }

  Future<void> _justificativa() async {
    if (_pessoaId <= 0) return mensagem(context, 'Selecione um colaborador antes de lançar uma ocorrência.');
    final v = await inputQuery(context, 'Lançar Ocorrência / Justificativa (Portaria 671)', [
      'Data da Ocorrência (DD/MM/AAAA):',
      'Tipo (Atestado Médico, Folga, Feriado, Declaração):',
      'Motivo / Justificativa detalhada:',
      'Minutos a Abonar (0 para o dia integral):'
    ], [
      fmtData(_sel?.data ?? DateTime.now()),
      'Atestado Médico',
      'Atestado médico de consulta',
      '0'
    ]);
    if (v == null || !mounted) return;
    final d = parseData(v[0]);
    if (d == null) return mensagem(context, 'Data informada é inválida.');
    final tipo = v[1].trim().isEmpty ? 'Atestado Médico' : v[1].trim();
    try {
      await Db.instance.salvarJustificativa(_pessoaId, d, tipo, v[2], int.tryParse(v[3].trim()) ?? 0);
      _app.logTs('📝 Justificativa registrada para o colaborador (ID $_pessoaId) no dia ${fmtData(d)}: $tipo (${v[2].trim()}).');
      await _calcular();
    } catch (e) {
      if (mounted) await mensagem(context, 'Erro ao registrar justificativa no banco de dados: $e');
    }
  }

  /// Corrigir: abre a tela do dia selecionado (também aberta com duplo clique na linha).
  Future<void> _corrigirBatida() async {
    if (_pessoaId <= 0) return mensagem(context, 'Selecione primeiro o colaborador no Espelho de Ponto.');
    final d = _sel;
    if (d == null) return mensagem(context, 'Selecione o dia na grade (ou dê duplo clique nele) para corrigir as batidas.');
    await _telaDia(d);
  }

  /// Tela de alteração do dia: lista as batidas, permite corrigir, desconsiderar/restaurar e incluir.
  Future<void> _telaDia(DiaEspelho dia) async {
    if (_pessoaId <= 0) return;
    var alterou = false;
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, set) {
        return AlertDialog(
          title: Text('${fmtData(dia.data)} (${dia.diaSemana}) - $_nomeColab'),
          content: SizedBox(
            width: 560,
            child: FutureBuilder<List<DbRow>>(
              key: ValueKey(DateTime.now().microsecondsSinceEpoch),
              future: Db.instance.getMarcacoes(dia.data, dia.data, pessoaId: _pessoaId, incluirDesconsideradas: true),
              builder: (c, snap) {
                if (!snap.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                final itens = snap.data!.reversed.toList();
                if (itens.isEmpty) return const Text('Nenhuma batida neste dia. Use "Incluir batida".');
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final m in itens)
                    Builder(builder: (_) {
                      final desc = asStr(m['PMA_DESCONSIDERADA']) == 'S';
                      final dh = asDate(m['PMA_DATA_HORA']);
                      return ListTile(
                        dense: true,
                        title: Text('${fmtHoraSeg(dh)}  (${asStr(m['PMA_TIPO_BATIDA']).trim().isEmpty ? '-' : asStr(m['PMA_TIPO_BATIDA'])})'
                            '${desc ? '  - desconsiderada' : ''}',
                            style: TextStyle(decoration: desc ? TextDecoration.lineThrough : null)),
                        subtitle: Text(desc ? asStr(m['PMA_MOTIVO_DESCONSIDERACAO']) : asStr(m['PMA_MOTIVO_AJUSTE'])),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!desc)
                            IconButton(
                              tooltip: 'Corrigir',
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                if (await _corrigirExistente(m)) set(() => alterou = true);
                              },
                            ),
                          IconButton(
                            tooltip: desc ? 'Restaurar' : 'Desconsiderar',
                            icon: Icon(desc ? Icons.restore : Icons.block),
                            onPressed: () async {
                              if (await _alternarDesconsiderada(m, desc)) set(() => alterou = true);
                            },
                          ),
                        ]),
                      );
                    }),
                ]);
              },
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.add_alarm),
              label: const Text('Incluir batida'),
              onPressed: () async {
                if (await _incluirBatida(dia.data)) set(() => alterou = true);
              },
            ),
            FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar')),
          ],
        );
      }),
    );
    if (alterou && mounted) await _calcular();
  }

  Future<bool> _corrigirExistente(DbRow m) async {
    final id = asInt(m['PMA_ID']);
    final dh = asDate(m['PMA_DATA_HORA']);
    var tipo = asStr(m['PMA_TIPO_BATIDA']).trim().toUpperCase();
    if (tipo != 'E' && tipo != 'S') tipo = 'E';
    final v = await inputQuery(context, 'Corrigir batida #$id - $_nomeColab', [
      'Data da Batida (DD/MM/AAAA):',
      'Hora da Batida (HH:MM:SS):',
      'Tipo de Batida (E = Entrada, S = Saída):',
      'Motivo da Correção (Portaria 671 MTE):'
    ], [
      fmtData(dh),
      fmtHoraSeg(dh),
      tipo,
      'Esquecimento de registro'
    ]);
    if (v == null || !mounted) return false;
    final d = parseData(v[0]), h = parseHora(v[1]), t = v[2].trim().toUpperCase();
    if (d == null || h == null) {
      await mensagem(context, 'Data ou hora inválida.');
      return false;
    }
    if (t != 'E' && t != 'S') {
      await mensagem(context, 'Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
      return false;
    }
    if (v[3].trim().length < 5) {
      await mensagem(context, 'Informe o motivo da correção (mínimo 5 caracteres).');
      return false;
    }
    final novo = await Db.instance.corrigirMarcacao(id, d.add(h), t, v[3]);
    if (novo > 0) {
      _app.logTs('✏️ Batida #$id corrigida pela #$novo em ${fmtDataHora(d.add(h))} ($t) - $_nomeColab [Motivo: ${v[3].trim()}]');
      _app.dadosAlterados();
      return true;
    }
    if (mounted) await mensagem(context, 'Não foi possível corrigir a batida.');
    return false;
  }

  Future<bool> _alternarDesconsiderada(DbRow m, bool desconsiderada) async {
    final id = asInt(m['PMA_ID']);
    if (desconsiderada) {
      if (!await confirmar(context, 'Voltar a considerar a batida #$id?')) return false;
      await Db.instance.restaurarMarcacao(id);
      _app.logTs('↩️ Batida #$id voltou a ser considerada - $_nomeColab.');
    } else {
      final v = await inputQuery(context, 'Desconsiderar batida #$id',
          ['Motivo (obrigatório pela Portaria 671 - a batida original fica guardada):'], ['Batida em duplicidade']);
      if (v == null || !mounted) return false;
      if (v[0].trim().length < 5) {
        await mensagem(context, 'Informe o motivo com pelo menos 5 caracteres.');
        return false;
      }
      if (!await Db.instance.desconsiderarMarcacao(id, v[0])) return false;
      _app.logTs('🚫 Batida #$id desconsiderada - $_nomeColab. Motivo: ${v[0].trim()}');
    }
    _app.dadosAlterados();
    return true;
  }

  /// Incluir: nova batida manual; a data sugerida é a do dia selecionado (ou a de hoje).
  Future<bool> _incluirBatida([DateTime? dia]) async {
    if (_pessoaId <= 0) {
      await mensagem(context, 'Selecione primeiro o colaborador no Espelho de Ponto.');
      return false;
    }
    final v = await inputQuery(context, 'Incluir Batida - $_nomeColab', [
      'Data da Batida (DD/MM/AAAA):',
      'Hora da Batida (HH:MM:SS):',
      'Tipo de Batida (E = Entrada, S = Saída):',
      'Motivo da Inclusão/Correção (Portaria 671):'
    ], [
      fmtData(dia ?? _sel?.data ?? DateTime.now()),
      '08:00:00',
      'E',
      'Esquecimento de registro'
    ]);
    if (v == null || !mounted) return false;
    final d = parseData(v[0]), h = parseHora(v[1]), t = v[2].trim().toUpperCase();
    if (d == null) {
      await mensagem(context, 'Data informada é inválida.');
      return false;
    }
    if (h == null) {
      await mensagem(context, 'Hora informada é inválida.');
      return false;
    }
    if (t != 'E' && t != 'S') {
      await mensagem(context, 'Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
      return false;
    }
    final id = await Db.instance.inserirMarcacaoManual(_pessoaId, 0, d.add(h), t, v[3]);
    if (id > 0) {
      _app.logTs('➕ Batida incluída no espelho ID $id para ${fmtDataHora(d.add(h))} ($t) - $_nomeColab');
      _app.dadosAlterados();
      return true;
    }
    if (mounted) await mensagem(context, 'Erro ao registrar batida no banco de dados.');
    return false;
  }

  Future<void> _incluirEApurar() async {
    if (await _incluirBatida() && mounted) await _calcular();
  }

  Future<void> _exportarHtml() async {
    final e = _espelho;
    if (e == null) return mensagem(context, 'Por favor, clique em "Apurar Ponto" antes de exportar ou visualizar o espelho.');
    final emp = await Db.instance.getEmpresaPrincipal();
    final arq = await abrirHtml('Espelho_Ponto_$_pessoaId.html', e.gerarRelatorioHtml(emp?.razao ?? '', emp?.cnpj ?? ''));
    _app.logTs('🖨️ Espelho de ponto exportado: $arq');
  }

  Widget _data(String rotulo, DateTime valor, ValueChanged<DateTime> f) => OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month, size: 18),
        label: Text('$rotulo ${fmtData(valor)}'),
        onPressed: () async {
          final d = await escolherData(context, valor);
          if (d != null) f(d);
        },
      );

  Widget _resumo(String t, String v, [Color? cor]) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Text(t, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cor)),
            ]),
          ),
        ),
      );

  /// Dias depois de hoje aparecem na grade, mas sem informações.
  bool _futuro(DiaEspelho d) {
    final h = DateTime.now();
    return d.data.isAfter(DateTime(h.year, h.month, h.day));
  }

  Color? _corLinha(DiaEspelho d) {
    if (_futuro(d)) return null;
    if (d.tipoDia == TipoDia.feriado) {
      return d.dsrDescontado ? Colors.red.withValues(alpha: .08) : Colors.blue.withValues(alpha: .08);
    }
    if (d.tipoDia == TipoDia.domingoDsr || d.tipoDia == TipoDia.sabadoCompensado || d.tipoDia == TipoDia.folga) {
      return d.dsrDescontado ? Colors.red.withValues(alpha: .08) : Colors.grey.withValues(alpha: .15);
    }
    if (d.impar) return Colors.amber.withValues(alpha: .2);
    if (d.faltaDiaInteiro) return Colors.red.withValues(alpha: .1);
    if (d.intervaloSuprimidoMin > 0 || d.interjornadaFaltanteMin > 0) return Colors.orange.withValues(alpha: .08);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final r = _espelho?.resumo;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('Espelho de Ponto', Icons.table_chart_outlined, acoes: [
        SizedBox(
          width: 280,
          child: DropdownButtonFormField<int>(
            initialValue: _pessoaId > 0 ? _pessoaId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Colaborador', isDense: true),
            items: [
              for (final c in _colabs)
                DropdownMenuItem(value: asInt(c['PES_ID']), child: Text(asStr(c['PES_RSOCIAL_NOME'])))
            ],
            onChanged: (v) {
              setState(() => _pessoaId = v ?? 0);
              _calcular(silencioso: true);
            },
          ),
        ),
        _data('De', _ini, (d) {
          setState(() => _ini = d);
          _calcular(silencioso: true);
        }),
        _data('Até', _fim, (d) {
          setState(() => _fim = d);
          _calcular(silencioso: true);
        }),
        Btn('Recalcular', Icons.calculate, _calcular),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: [
        Btn('Lançar Justificativa', Icons.note_add, _justificativa, tonal: true),
        Btn('Corrigir', Icons.edit, _corrigirBatida, tonal: true),
        Btn('Incluir', Icons.add_alarm, _incluirEApurar, tonal: true),
        Btn('Imprimir / Exportar HTML', Icons.print, _exportarHtml, cor: AppCores.roxo),
      ]),
      const SizedBox(height: 8),
      if (r != null) ...[
        Text('Jornada: ${r.jornadaDescricao}   •   Dias úteis: ${r.totalDiasUteis}   •   Dias trabalhados: '
            '${r.totalDiasTrabalhados}   •   Faltas: ${r.totalFaltas}   •   DSR descontados: ${r.dsrDescontados}'
            '   •   Feriados: ${r.totalFeriados} (descontados: ${r.feriadosDescontados})'
            '${r.diasExtraAcima2h > 0 ? '   •   Dias com extra acima de 2h: ${r.diasExtraAcima2h}' : ''}'),
        Row(children: [
          _resumo('Previsto', minutosParaHora(r.totalPrevistoMin)),
          _resumo('Realizado', minutosParaHora(r.totalTrabalhadoMin)),
          _resumo('Extras 50%', '+${minutosParaHora(r.totalExtras50Min)}', Colors.green.shade700),
          _resumo('Extras 100%', '+${minutosParaHora(r.totalExtras100Min)}', Colors.green.shade800),
          _resumo('Noturno', minutosParaHora(r.totalNoturnoMin), AppCores.roxo),
          _resumo('Atrasos', '-${minutosParaHora(r.totalAtrasosMin)}', Colors.red.shade700),
          _resumo('Interv. suprimido', minutosParaHora(r.totalIntervaloSuprimidoMin), Colors.orange.shade800),
          _resumo('Interjornada', minutosParaHora(r.totalInterjornadaMin), Colors.orange.shade800),
          if (r.creditoHorasMin != 0)
            _resumo('Crédito lançado', minutosParaHora(r.creditoHorasMin, exibirSinal: true),
                r.creditoHorasMin >= 0 ? Colors.green.shade700 : Colors.red.shade700),
          _resumo(r.usaBancoHoras ? 'Banco de horas' : 'Saldo', minutosParaHora(r.saldoFinalMin, exibirSinal: true),
              r.saldoFinalMin >= 0 ? Colors.green.shade700 : Colors.red.shade700),
        ]),
      ],
      const SizedBox(height: 8),
      Expanded(
        child: DataGrid<DiaEspelho>(
          itens: _espelho?.dias ?? const [],
          selecionado: _sel,
          onSelect: (d) => setState(() => _sel = d),
          onDoubleTap: (d) {
            setState(() => _sel = d);
            if (!_futuro(d)) _telaDia(d);
          },
          corLinha: _corLinha,
          colunas: [
            GridCol('Data', 85, (d) => fmtData(d.data)),
            GridCol('Dia', 40, (d) => d.diaSemana),
            GridCol('1ª Ent', 55, (d) => _futuro(d) ? '' : d.entrada1),
            GridCol('1ª Saí', 55, (d) => _futuro(d) ? '' : d.saida1),
            GridCol('2ª Ent', 55, (d) => _futuro(d) ? '' : d.entrada2),
            GridCol('2ª Saí', 55, (d) => _futuro(d) ? '' : d.saida2),
            GridCol('Outras', 90, (d) => _futuro(d) ? '' : d.batidasExtras),
            GridCol('Previsto', 65, (d) => _futuro(d) ? '' : d.cargaPrevistaStr),
            GridCol('Realizado', 70, (d) => _futuro(d) ? '' : d.trabalhadoStr),
            GridCol('Extras', 70, (d) => _futuro(d) ? '' : d.extraMin > 0 && d.extra100 ? '${d.extraStr} 100%' : d.extraStr, cor: (d) => _futuro(d) ? null : d.extraMin > 0 ? Colors.green.shade700 : null),
            GridCol('Noturno', 60, (d) => _futuro(d) ? '' : d.noturnoMin > 0 ? minutosParaHora(d.noturnoMin) : ''),
            GridCol('Interv.', 55, (d) => _futuro(d) ? '' : d.intervaloSuprimidoMin > 0 ? minutosParaHora(d.intervaloSuprimidoMin) : '',
                cor: (_) => Colors.orange.shade800),
            GridCol('Faltas', 60, (d) => _futuro(d) ? '' : d.faltaStr, cor: (d) => _futuro(d) ? null : d.faltaMin > 0 ? Colors.red.shade700 : null),
            GridCol('Saldo', 65, (d) => _futuro(d) ? '' : d.saldoStr,
                cor: (d) => _futuro(d) ? null : d.saldoMin > 0 ? Colors.green.shade700 : (d.saldoMin < 0 ? Colors.red.shade700 : null)),
            GridCol('Ocorrência / Justificativa', 200, (d) => _futuro(d) ? '' : d.ocorrencia, flex: true),
          ],
        ),
      ),
    ]);
  }
}
