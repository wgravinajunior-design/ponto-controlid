import 'package:flutter/material.dart';

import '../../core/util.dart';
import '../../data/database.dart';
import '../app_state.dart';
import '../widgets.dart';

/// Justificativas de um dia (atestado, declaração...) e afastamentos por período (férias, licenças, INSS).
class JustificativasPage extends StatefulWidget {
  const JustificativasPage({super.key});
  @override
  State<JustificativasPage> createState() => _JustificativasPageState();
}

class _JustificativasPageState extends State<JustificativasPage> {
  final _app = AppState.instance;
  List<DbRow> _colabs = [], _jus = [], _afa = [];
  int _pessoaId = 0;
  DateTime _ini = DateTime(DateTime.now().year, DateTime.now().month - 2, 1), _fim = DateTime(DateTime.now().year, 12, 31);
  DbRow? _selJus, _selAfa;

  static const _tiposJus = ['Atestado Médico', 'Declaração de Comparecimento', 'Folga', 'Feriado', 'Abono', 'Outros'];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final c = await Db.instance.getColaboradores();
    final j = await Db.instance.getJustificativas(pessoaId: _pessoaId, ini: _ini, fim: _fim);
    final a = await Db.instance.getAfastamentos(pessoaId: _pessoaId, ini: _ini, fim: _fim);
    if (mounted) {
      setState(() {
        _colabs = c;
        _jus = j;
        _afa = a;
        _selJus = _selAfa = null;
      });
    }
  }

  /// Diálogo com colaborador, data(s), tipo, motivo e (justificativa) minutos abonados.
  Future<({int pessoa, DateTime ini, DateTime fim, String tipo, String motivo, int abono})?> _dialogo(
      {required bool periodo, DbRow? atual}) {
    var pessoa = asInt(atual?[periodo ? 'AFA_PESSOA' : 'JUS_PESSOA']);
    if (pessoa == 0) pessoa = _pessoaId;
    var ini = asDate(atual?[periodo ? 'AFA_INICIO' : 'JUS_DATA']) ?? DateTime.now();
    var fim = asDate(atual?['AFA_FIM']) ?? ini;
    final tipos = periodo ? Db.tiposAfastamento : _tiposJus;
    var tipo = asStr(atual?[periodo ? 'AFA_TIPO' : 'JUS_TIPO']);
    if (!tipos.contains(tipo)) tipo = tipos.first;
    final motivo = TextEditingController(text: asStr(atual?[periodo ? 'AFA_MOTIVO' : 'JUS_MOTIVO']));
    final abono = TextEditingController(text: '${asInt(atual?['JUS_ABONO_MINUTOS'])}');
    return showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(periodo ? 'Afastamento' : 'Justificativa'),
          content: SizedBox(
            width: 460,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                initialValue: pessoa > 0 ? pessoa : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Colaborador'),
                items: [
                  for (final x in _colabs)
                    DropdownMenuItem(value: asInt(x['PES_ID']), child: Text(asStr(x['PES_RSOCIAL_NOME'])))
                ],
                onChanged: (v) => set(() => pessoa = v ?? 0),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(periodo ? 'De ${fmtData(ini)}' : 'Dia ${fmtData(ini)}'),
                    onPressed: () async {
                      final d = await escolherData(c, ini);
                      if (d != null) set(() => ini = d);
                    },
                  ),
                ),
                if (periodo) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text('Até ${fmtData(fim)}'),
                      onPressed: () async {
                        final d = await escolherData(c, fim);
                        if (d != null) set(() => fim = d);
                      },
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [for (final t in tipos) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) => set(() => tipo = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: motivo, decoration: const InputDecoration(labelText: 'Motivo / documento')),
              if (!periodo) ...[
                const SizedBox(height: 12),
                TextField(
                    controller: abono,
                    decoration: const InputDecoration(labelText: 'Minutos a abonar (0 = dia inteiro)')),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (pessoa <= 0) return;
                Navigator.pop(c, (
                  pessoa: pessoa,
                  ini: ini,
                  fim: fim.isBefore(ini) ? ini : fim,
                  tipo: tipo,
                  motivo: motivo.text,
                  abono: int.tryParse(abono.text.trim()) ?? 0
                ));
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _novaJustificativa([DbRow? atual]) async {
    final v = await _dialogo(periodo: false, atual: atual);
    if (v == null) return;
    if (atual != null) await Db.instance.excluirJustificativa(asInt(atual['JUS_ID']));
    await Db.instance.salvarJustificativa(v.pessoa, v.ini, v.tipo, v.motivo, v.abono);
    _app.logTs('📝 Justificativa "${v.tipo}" de ${fmtData(v.ini)} salva (colaborador ${v.pessoa}).');
    _app.dadosAlterados();
    await _carregar();
  }

  Future<void> _excluirJustificativa() async {
    final j = _selJus;
    if (j == null || !await confirmar(context, 'Excluir a justificativa "${asStr(j['JUS_TIPO'])}" de ${fmtData(asDate(j['JUS_DATA']))}?')) {
      return;
    }
    await Db.instance.excluirJustificativa(asInt(j['JUS_ID']));
    _app.logTs('🗑️ Justificativa #${asInt(j['JUS_ID'])} excluída.');
    _app.dadosAlterados();
    await _carregar();
  }

  Future<void> _novoAfastamento([DbRow? atual]) async {
    final v = await _dialogo(periodo: true, atual: atual);
    if (v == null) return;
    await Db.instance.salvarAfastamento(asInt(atual?['AFA_ID']), v.pessoa, v.ini, v.fim, v.tipo, v.motivo);
    _app.logTs('🏖️ Afastamento "${v.tipo}" de ${fmtData(v.ini)} a ${fmtData(v.fim)} salvo.');
    _app.dadosAlterados();
    await _carregar();
  }

  Future<void> _excluirAfastamento() async {
    final a = _selAfa;
    if (a == null || !await confirmar(context, 'Excluir o afastamento "${asStr(a['AFA_TIPO'])}"?')) return;
    await Db.instance.excluirAfastamento(asInt(a['AFA_ID']));
    _app.dadosAlterados();
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader('Justificativas', Icons.note_alt, acoes: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<int>(
              initialValue: _pessoaId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Colaborador'),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Todos os colaboradores')),
                for (final c in _colabs)
                  DropdownMenuItem(value: asInt(c['PES_ID']), child: Text(asStr(c['PES_RSOCIAL_NOME'])))
              ],
              onChanged: (v) {
                setState(() => _pessoaId = v ?? 0);
                _carregar();
              },
            ),
          ),
          OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text('De ${fmtData(_ini)}'),
              onPressed: () async {
                final d = await escolherData(context, _ini);
                if (d != null) {
                  setState(() => _ini = d);
                  _carregar();
                }
              }),
          OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text('Até ${fmtData(_fim)}'),
              onPressed: () async {
                final d = await escolherData(context, _fim);
                if (d != null) {
                  setState(() => _fim = d);
                  _carregar();
                }
              }),
        ]),
        const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
          Tab(icon: Icon(Icons.event_note), text: 'Justificativas (por dia)'),
          Tab(icon: Icon(Icons.beach_access), text: 'Afastamentos (férias, licenças, INSS)'),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [
                Btn('Nova justificativa', Icons.add, () => _novaJustificativa()),
                Btn('Editar', Icons.edit, _selJus == null ? null : () => _novaJustificativa(_selJus), tonal: true),
                Btn('Excluir', Icons.delete, _selJus == null ? null : _excluirJustificativa, cor: Colors.red.shade700),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: DataGrid<DbRow>(
                  itens: _jus,
                  selecionado: _selJus,
                  onSelect: (r) => setState(() => _selJus = r),
                  onDoubleTap: (r) => _novaJustificativa(r),
                  colunas: [
                    GridCol('Data', 90, (r) => fmtData(asDate(r['JUS_DATA']))),
                    GridCol('Colaborador', 220, (r) => asStr(r['PES_RSOCIAL_NOME']), flex: true),
                    GridCol('Tipo', 180, (r) => asStr(r['JUS_TIPO'])),
                    GridCol('Motivo', 220, (r) => asStr(r['JUS_MOTIVO'])),
                    GridCol('Abono', 70, (r) => asInt(r['JUS_ABONO_MINUTOS']) == 0 ? 'Dia todo' : minutosParaHora(asInt(r['JUS_ABONO_MINUTOS']))),
                    GridCol('Lançado por', 100, (r) => asStr(r['JUS_USUARIO'])),
                  ],
                ),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [
                Btn('Novo afastamento', Icons.add, () => _novoAfastamento()),
                Btn('Editar', Icons.edit, _selAfa == null ? null : () => _novoAfastamento(_selAfa), tonal: true),
                Btn('Excluir', Icons.delete, _selAfa == null ? null : _excluirAfastamento, cor: Colors.red.shade700),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: DataGrid<DbRow>(
                  itens: _afa,
                  selecionado: _selAfa,
                  onSelect: (r) => setState(() => _selAfa = r),
                  onDoubleTap: (r) => _novoAfastamento(r),
                  colunas: [
                    GridCol('Início', 90, (r) => fmtData(asDate(r['AFA_INICIO']))),
                    GridCol('Fim', 90, (r) => fmtData(asDate(r['AFA_FIM']))),
                    GridCol('Dias', 50, (r) {
                      final i = asDate(r['AFA_INICIO']), f = asDate(r['AFA_FIM']);
                      return i == null || f == null ? '' : '${soData(f).difference(soData(i)).inDays + 1}';
                    }),
                    GridCol('Colaborador', 220, (r) => asStr(r['PES_RSOCIAL_NOME']), flex: true),
                    GridCol('Tipo', 180, (r) => asStr(r['AFA_TIPO'])),
                    GridCol('Motivo', 200, (r) => asStr(r['AFA_MOTIVO'])),
                    GridCol('Lançado por', 100, (r) => asStr(r['AFA_USUARIO'])),
                  ],
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
