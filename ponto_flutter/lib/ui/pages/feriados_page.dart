import 'package:flutter/material.dart';

import '../../core/util.dart';
import '../../data/database.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Cadastro de feriados (nacionais, estaduais e municipais). Feriado não trabalhado não gera falta;
/// trabalhado vira hora extra 100%.
class FeriadosPage extends StatefulWidget {
  const FeriadosPage({super.key});
  @override
  State<FeriadosPage> createState() => _FeriadosPageState();
}

class _FeriadosPageState extends State<FeriadosPage> {
  final _app = AppState.instance;
  List<DbRow> _itens = [];
  Map<DateTime, String> _doAno = {};
  DbRow? _sel;
  int _id = 0;
  DateTime _data = DateTime.now();
  final _desc = TextEditingController();
  bool _recorrente = true;
  String _abrangencia = 'MUNICIPAL';
  int _ano = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final itens = await Db.instance.getFeriados();
    final ano = await Db.instance.feriadosNoPeriodo(DateTime(_ano, 1, 1), DateTime(_ano, 12, 31));
    if (mounted) {
      setState(() {
        _itens = itens;
        _doAno = ano;
      });
    }
  }

  void _novo() => setState(() {
        _sel = null;
        _id = 0;
        _data = DateTime.now();
        _desc.clear();
        _recorrente = true;
        _abrangencia = 'MUNICIPAL';
      });

  void _preencher(DbRow r) => setState(() {
        _sel = r;
        _id = asInt(r['FER_ID']);
        _data = asDate(r['FER_DATA']) ?? DateTime.now();
        _desc.text = asStr(r['FER_DESCRICAO']);
        _recorrente = asStr(r['FER_RECORRENTE']) == 'S';
        _abrangencia = asStr(r['FER_ABRANGENCIA']);
      });

  Future<void> _salvar() async {
    if (_desc.text.trim().isEmpty) return mensagem(context, 'Informe a descrição do feriado.');
    _id = await Db.instance.salvarFeriado(_id, _data, _desc.text, _recorrente, _abrangencia);
    _app.logTs('📅 Feriado [${_desc.text.trim()}] salvo (${fmtData(_data)}).');
    _app.dadosAlterados();
    await _carregar();
  }

  Future<void> _excluir() async {
    if (_id <= 0 || !await confirmar(context, 'Excluir o feriado [${_desc.text}]?')) return;
    await Db.instance.excluirFeriado(_id);
    _app.dadosAlterados();
    _novo();
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final doAno = _doAno.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('Feriados', Icons.event, acoes: [
        Btn('Novo', Icons.add, _novo, tonal: true),
        Btn('Atualizar', Icons.refresh, _carregar, tonal: true),
      ]),
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: DataGrid<DbRow>(
              itens: _itens,
              selecionado: _sel,
              onSelect: _preencher,
              colunas: [
                GridCol('Data', 90, (r) {
                  final d = asDate(r['FER_DATA']);
                  return asStr(r['FER_RECORRENTE']) == 'S' && d != null
                      ? '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}'
                      : fmtData(d);
                }),
                GridCol('Descrição', 220, (r) => asStr(r['FER_DESCRICAO']), flex: true),
                GridCol('Abrangência', 100, (r) => asStr(r['FER_ABRANGENCIA'])),
                GridCol('Repete', 70, (r) => asStr(r['FER_RECORRENTE']) == 'S' ? 'Todo ano' : 'Só nesta data'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 360,
            child: ListView(children: [
              Secao(_id > 0 ? 'Feriado #$_id' : 'Novo feriado', [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text('Data: ${fmtData(_data)}'),
                  onPressed: () async {
                    final d = await escolherData(context, _data);
                    if (d != null) setState(() => _data = d);
                  },
                ),
                const SizedBox(height: 12),
                Campo('Descrição', _desc, largura: 320),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _abrangencia,
                  decoration: const InputDecoration(labelText: 'Abrangência'),
                  items: const [
                    DropdownMenuItem(value: 'NACIONAL', child: Text('Nacional')),
                    DropdownMenuItem(value: 'ESTADUAL', child: Text('Estadual')),
                    DropdownMenuItem(value: 'MUNICIPAL', child: Text('Municipal')),
                    DropdownMenuItem(value: 'EMPRESA', child: Text('Folga da empresa')),
                  ],
                  onChanged: (v) => setState(() => _abrangencia = v!),
                ),
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Repete todo ano no mesmo dia'),
                    value: _recorrente,
                    onChanged: (v) => setState(() => _recorrente = v!)),
                Wrap(spacing: 8, children: [
                  Btn('Salvar', Icons.save, _salvar),
                  Btn('Excluir', Icons.delete, _id > 0 ? _excluir : null, cor: Colors.red.shade700),
                ]),
              ]),
              Painel(
                'Feriados de $_ano',
                Icons.event_available_rounded,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconButton(
                        onPressed: () {
                          _ano--;
                          _carregar();
                        },
                        icon: const Icon(Icons.chevron_left)),
                    Text('$_ano', style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                        onPressed: () {
                          _ano++;
                          _carregar();
                        },
                        icon: const Icon(Icons.chevron_right)),
                  ]),
                  for (final e in doAno)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('${fmtData(e.key)}  ${const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][e.key.weekday - 1]}'
                          '  •  ${e.value}'),
                    ),
                  const SizedBox(height: 6),
                  const Text('A Sexta-feira Santa é calculada automaticamente pela data da Páscoa.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
