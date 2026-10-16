import 'package:flutter/material.dart';

import '../../core/util.dart';
import '../../data/database.dart';
import '../../services/calculo_service.dart';
import '../app_state.dart';
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
          '(${fmtData(_ini)} a ${fmtData(_fim)}): saldo ${minutosParaHora(e.resumo.saldoTotalMin, exibirSinal: true)}.');
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

  Future<void> _corrigirBatida() async {
    if (_pessoaId <= 0) return mensagem(context, 'Selecione primeiro o colaborador no Espelho de Ponto.');
    final v = await inputQuery(context, 'Corrigir / Incluir Batida - $_nomeColab', [
      'Data da Batida (DD/MM/AAAA):',
      'Hora da Batida (HH:MM:SS):',
      'Tipo de Batida (E = Entrada, S = Saída):',
      'Motivo da Inclusão/Correção (Portaria 671):'
    ], [
      fmtData(_sel?.data ?? _ini),
      '08:00:00',
      'E',
      'Esquecimento de registro'
    ]);
    if (v == null || !mounted) return;
    final d = parseData(v[0]), h = parseHora(v[1]), t = v[2].trim().toUpperCase();
    if (d == null) return mensagem(context, 'Data informada é inválida.');
    if (h == null) return mensagem(context, 'Hora informada é inválida.');
    if (t != 'E' && t != 'S') return mensagem(context, 'Tipo de batida inválido. Informe E para Entrada ou S para Saída.');
    final id = await Db.instance.inserirMarcacaoManual(_pessoaId, 0, d.add(h), t, v[3]);
    if (id > 0) {
      _app.logTs('✏️ Batida inserida/corrigida no espelho ID $id para ${fmtDataHora(d.add(h))} ($t) - $_nomeColab');
      _app.dadosAlterados();
      await _calcular();
    } else if (mounted) {
      await mensagem(context, 'Erro ao registrar batida no banco de dados.');
    }
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

  Color? _corLinha(DiaEspelho d) {
    if (d.tipoDia == TipoDia.feriado) return Colors.blue.withValues(alpha: .08);
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
        Btn('Apurar Ponto', Icons.calculate, _calcular),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: [
        Btn('Lançar Justificativa', Icons.note_add, _justificativa, tonal: true),
        Btn('Corrigir / Incluir Batida', Icons.edit_calendar, _corrigirBatida, tonal: true),
        Btn('Imprimir / Exportar HTML', Icons.print, _exportarHtml, cor: Colors.indigo),
      ]),
      const SizedBox(height: 8),
      if (r != null) ...[
        Text('Jornada: ${r.jornadaDescricao}   •   Dias úteis: ${r.totalDiasUteis}   •   Dias trabalhados: '
            '${r.totalDiasTrabalhados}   •   Faltas: ${r.totalFaltas}   •   DSR descontados: ${r.dsrDescontados}'
            '${r.diasExtraAcima2h > 0 ? '   •   Dias com extra acima de 2h: ${r.diasExtraAcima2h}' : ''}'),
        Row(children: [
          _resumo('Previsto', minutosParaHora(r.totalPrevistoMin)),
          _resumo('Realizado', minutosParaHora(r.totalTrabalhadoMin)),
          _resumo('Extras 50%', '+${minutosParaHora(r.totalExtras50Min)}', Colors.green.shade700),
          _resumo('Extras 100%', '+${minutosParaHora(r.totalExtras100Min)}', Colors.green.shade800),
          _resumo('Noturno', minutosParaHora(r.totalNoturnoMin), Colors.indigo),
          _resumo('Atrasos', '-${minutosParaHora(r.totalAtrasosMin)}', Colors.red.shade700),
          _resumo('Interv. suprimido', minutosParaHora(r.totalIntervaloSuprimidoMin), Colors.orange.shade800),
          _resumo('Interjornada', minutosParaHora(r.totalInterjornadaMin), Colors.orange.shade800),
          _resumo(r.usaBancoHoras ? 'Banco de horas' : 'Saldo',
              minutosParaHora(r.usaBancoHoras ? r.bancoSaldoFinalMin : r.saldoTotalMin, exibirSinal: true),
              (r.usaBancoHoras ? r.bancoSaldoFinalMin : r.saldoTotalMin) >= 0 ? Colors.green.shade700 : Colors.red.shade700),
        ]),
      ],
      const SizedBox(height: 8),
      Expanded(
        child: DataGrid<DiaEspelho>(
          itens: _espelho?.dias ?? const [],
          selecionado: _sel,
          onSelect: (d) => setState(() => _sel = d),
          corLinha: _corLinha,
          colunas: [
            GridCol('Data', 85, (d) => fmtData(d.data)),
            GridCol('Dia', 40, (d) => d.diaSemana),
            GridCol('1ª Ent', 55, (d) => d.entrada1),
            GridCol('1ª Saí', 55, (d) => d.saida1),
            GridCol('2ª Ent', 55, (d) => d.entrada2),
            GridCol('2ª Saí', 55, (d) => d.saida2),
            GridCol('Outras', 90, (d) => d.batidasExtras),
            GridCol('Previsto', 65, (d) => d.cargaPrevistaStr),
            GridCol('Realizado', 70, (d) => d.trabalhadoStr),
            GridCol('Extras', 70, (d) => d.extraMin > 0 && d.extra100 ? '${d.extraStr} 100%' : d.extraStr, cor: (d) => d.extraMin > 0 ? Colors.green.shade700 : null),
            GridCol('Noturno', 60, (d) => d.noturnoMin > 0 ? minutosParaHora(d.noturnoMin) : ''),
            GridCol('Interv.', 55, (d) => d.intervaloSuprimidoMin > 0 ? minutosParaHora(d.intervaloSuprimidoMin) : '',
                cor: (_) => Colors.orange.shade800),
            GridCol('Faltas', 60, (d) => d.faltaStr, cor: (d) => d.faltaMin > 0 ? Colors.red.shade700 : null),
            GridCol('Saldo', 65, (d) => d.saldoStr,
                cor: (d) => d.saldoMin > 0 ? Colors.green.shade700 : (d.saldoMin < 0 ? Colors.red.shade700 : null)),
            GridCol('Ocorrência / Justificativa', 200, (d) => d.ocorrencia, flex: true),
          ],
        ),
      ),
    ]);
  }
}
