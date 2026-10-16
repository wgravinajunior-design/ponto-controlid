import 'package:flutter/material.dart';

import '../../core/util.dart';
import '../../data/database.dart';
import '../../services/feriados_service.dart';
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
  EmpresaInfo? _empresa;
  Map<DateTime, String> _tipoDoAno = {};
  bool _baixando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final itens = await Db.instance.getFeriados();
    final ano = await Db.instance.feriadosNoPeriodo(DateTime(_ano, 1, 1), DateTime(_ano, 12, 31));
    final emp = await Db.instance.getEmpresaPrincipal();
    final abr = <DateTime, String>{};
    for (final r in itens) {
      final d = asDate(r['FER_DATA']);
      if (d == null) continue;
      final x = asStr(r['FER_RECORRENTE']) == 'S' ? DateTime(_ano, d.month, d.day) : soData(d);
      abr[x] = asStr(r['FER_ABRANGENCIA']);
    }
    if (mounted) {
      setState(() {
        _itens = itens;
        _doAno = ano;
        _empresa = emp;
        _tipoDoAno = abr;
      });
    }
  }

  Future<void> _atualizarOnline() async {
    final e = _empresa;
    if (e == null || (e.uf.isEmpty && e.codIbge <= 0)) {
      return mensagem(context,
          'Informe a UF e o município da empresa em Configurações > Empregador (use "Preencher pelo CNPJ") para importar os feriados estaduais e municipais.');
    }
    setState(() => _baixando = true);
    try {
      final hoje = DateTime.now().year;
      final tot = ResultadoFeriados();
      final avisos = <String>[];
      for (final ano in {hoje - 1, hoje, hoje + 1}) {
        try {
          final r = await FeriadosService.importar(ano, uf: e.uf, codIbge: e.codIbge);
          tot.nacionais += r.nacionais;
          tot.estaduais += r.estaduais;
          tot.municipais += r.municipais;
          if (ano == hoje) avisos.addAll(r.avisos);
        } catch (err) {
          if (ano <= hoje) rethrow; // o arquivo do ano seguinte pode ainda não existir
          avisos.add('Feriados de $ano ainda não disponíveis na fonte.');
        }
      }
      _app.logTs('📅 Feriados online atualizados para ${e.municipio}/${e.uf}: ${tot.estaduais} estaduais, ${tot.municipais} municipais.');
      _app.dadosAlterados();
      await _carregar();
      if (mounted) {
        final local = e.municipio.isEmpty ? e.uf : '${e.municipio}/${e.uf}';
        await mensagem(
            context,
            'Feriados de $local atualizados.\n\n'
            'Estaduais: ${tot.estaduais}   Municipais: ${tot.municipais}\n'
            '${avisos.isEmpty ? '' : '\n${avisos.join('\n')}\n'}\n'
            'A fonte é uma base colaborativa aberta: confira o calendário oficial do município e ajuste manualmente se precisar.');
      }
    } catch (err) {
      if (mounted) await mensagem(context, 'Não foi possível baixar os feriados (sem internet?): $err');
    } finally {
      if (mounted) setState(() => _baixando = false);
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
        Btn(_baixando ? 'Baixando...' : 'Atualizar feriados online', Icons.cloud_download, _baixando ? null : _atualizarOnline),
        Btn('Novo', Icons.add, _novo, tonal: true),
        Btn('Atualizar', Icons.refresh, _carregar, tonal: true),
      ]),
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppCores.azul.withValues(alpha: .07), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.place_rounded, color: AppCores.azul),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _empresa == null || (_empresa!.uf.isEmpty && _empresa!.codIbge <= 0)
                  ? 'Localização da empresa não informada: só os feriados nacionais são considerados. '
                      'Cadastre a UF e o município em Configurações > Empregador.'
                  : 'Empresa em ${_empresa!.municipio.isEmpty ? '' : '${_empresa!.municipio} / '}${_empresa!.uf}: '
                      'valem os feriados nacionais, os estaduais de ${_empresa!.uf} e os municipais de '
                      '${_empresa!.municipio.isEmpty ? 'seu município' : _empresa!.municipio}.',
            ),
          ),
        ]),
      ),
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
                GridCol('Abrangência', 100, (r) {
                  final a = asStr(r['FER_ABRANGENCIA']);
                  return a.isEmpty ? '' : '${a[0]}${a.substring(1).toLowerCase()}';
                }),
                GridCol('Origem', 80, (r) => asStr(r['FER_ORIGEM']) == 'IMPORTADO' ? 'Online' : 'Manual'),
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
                          '  •  ${e.value}'
                          '${_tipoDoAno[e.key] == null || _tipoDoAno[e.key] == 'NACIONAL' ? '' : '  (${_tipoDoAno[e.key]!.toLowerCase()})'}'),
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
