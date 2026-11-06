import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/util.dart';
import '../../data/database.dart';
import '../app_state.dart';
import '../widgets.dart';

class HorariosPage extends StatefulWidget {
  const HorariosPage({super.key});
  @override
  State<HorariosPage> createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> {
  final _app = AppState.instance;
  List<DbRow> _itens = [];
  DbRow? _sel;
  int _id = 0;
  final _desc = TextEditingController(), _e1 = TextEditingController(), _s1 = TextEditingController();
  final _e2 = TextEditingController(), _s2 = TextEditingController(), _tol = TextEditingController(text: '10');
  final _carga = TextEditingController(text: '08:48'), _sabE1 = TextEditingController(), _sabS1 = TextEditingController();
  bool _compensaSab = true, _trabalhaSab = false, _ativo = true;
  String _escala = 'SEMANAL';
  final _cicloTrab = TextEditingController(text: '6'), _cicloFolga = TextEditingController(text: '1');
  // Jornada semanal por dia (1 = segunda ... 7 = domingo): entrada, saída almoço, volta almoço, saída
  static const _nomesDias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
  final _dia = {for (var d = 1; d <= 7; d++) d: List.generate(4, (_) => TextEditingController())};
  final _folgaDia = {for (var d = 1; d <= 7; d++) d: d >= 6};
  DateTime? _escalaInicio;
  bool _bancoHoras = false;
  final _virada = TextEditingController(text: '00:00'), _intervalo = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!Db.instance.isConectado) return;
    final itens = await Db.instance.getHorarios(apenasAtivos: false);
    setState(() => _itens = itens);
    if (itens.isNotEmpty) {
      _preencher(itens.firstWhere((r) => asInt(r['HOR_ID']) == _id, orElse: () => itens.first));
    } else {
      _limpar();
    }
  }

  void _limpar() => setState(() {
        _sel = null;
        _id = 0;
        _desc.clear();
        _e1.text = '08:00';
        _s1.text = '12:00';
        _e2.text = '13:12';
        _s2.text = '18:00';
        _tol.text = '10';
        _carga.text = '08:48';
        _sabE1.clear();
        _sabS1.clear();
        _compensaSab = true;
        _trabalhaSab = false;
        _ativo = true;
        _escala = 'SEMANAL';
        _escalaInicio = null;
        _bancoHoras = false;
        _virada.text = '00:00';
        _intervalo.text = '60';
        _preencherDiasPadrao();
      });

  /// Grade semanal a partir dos campos gerais (cadastros antigos ou novo horário).
  void _preencherDiasPadrao() {
    for (var d = 1; d <= 7; d++) {
      final c = _dia[d]!;
      if (d <= 5) {
        _folgaDia[d] = false;
        _setDia(c, _e1.text, _s1.text, _e2.text, _s2.text);
      } else if (d == 6 && _trabalhaSab) {
        _folgaDia[d] = false;
        _setDia(c, _sabE1.text, _sabS1.text, '', '');
      } else {
        _folgaDia[d] = true;
        _setDia(c, '', '', '', '');
      }
    }
  }

  /// Converte os 4 horários gravados (1ª ent/saí, 2ª ent/saí) para Entrada / Saída almoço / Volta almoço / Saída.
  void _setDia(List<TextEditingController> c, String e1, String s1, String e2, String s2) {
    final semAlmoco = e2.trim().isEmpty && s2.trim().isEmpty;
    c[0].text = e1;
    c[1].text = semAlmoco ? '' : s1;
    c[2].text = semAlmoco ? '' : e2;
    c[3].text = semAlmoco ? s1 : s2;
  }

  /// Horários do dia no formato gravado: [1ª entrada, 1ª saída, 2ª entrada, 2ª saída].
  List<String> _gravadoDia(int d) {
    final v = _dia[d]!.map((t) => t.text.trim()).toList();
    final temAlmoco = v[1].isNotEmpty || v[2].isNotEmpty;
    return temAlmoco ? [v[0], v[1], v[2], v[3]] : [v[0], v[3], '', ''];
  }

  int _cargaDia(int d) {
    if (_folgaDia[d]!) return 0;
    final g = _gravadoDia(d);
    int par(String a, String b) {
      if (parseHora(a) == null || parseHora(b) == null) return 0;
      final x = horaParaMinutos(b) - horaParaMinutos(a);
      return x >= 0 ? x : x + 1440; // passa da meia-noite
    }

    return par(g[0], g[1]) + par(g[2], g[3]);
  }

  void _preencher(DbRow r) => setState(() {
        _sel = r;
        _id = asInt(r['HOR_ID']);
        _desc.text = asStr(r['HOR_DESCRICAO']);
        _e1.text = asStr(r['HOR_ENTRADA_1']);
        _s1.text = asStr(r['HOR_SAIDA_1']);
        _e2.text = asStr(r['HOR_ENTRADA_2']);
        _s2.text = asStr(r['HOR_SAIDA_2']);
        _tol.text = '${asInt(r['HOR_TOLERANCIA_MIN'])}';
        _carga.text = minutosParaHora(asInt(r['HOR_CARGA_DIARIA_MIN']));
        _sabE1.text = asStr(r['HOR_SAB_ENTRADA_1']);
        _sabS1.text = asStr(r['HOR_SAB_SAIDA_1']);
        _compensaSab = asStr(r['HOR_COMPENSA_SABADO']) == 'S';
        _trabalhaSab = asStr(r['HOR_TRABALHA_SABADO']) == 'S';
        _ativo = asStr(r['HOR_ATIVO']) != 'N';
        final esc = asStr(r['HOR_TIPO_ESCALA']).toUpperCase();
        _escala = const ['12X36', 'CICLO'].contains(esc) ? esc : 'SEMANAL';
        _cicloTrab.text = asInt(r['HOR_CICLO_TRABALHO']) > 0 ? '${asInt(r['HOR_CICLO_TRABALHO'])}' : '6';
        _cicloFolga.text = asInt(r['HOR_CICLO_FOLGA']) > 0 ? '${asInt(r['HOR_CICLO_FOLGA'])}' : '1';
        _escalaInicio = asDate(r['HOR_ESCALA_INICIO']);
        _bancoHoras = asStr(r['HOR_BANCO_HORAS']) == 'S';
        _virada.text = asStr(r['HOR_VIRADA_DIA']).isEmpty ? '00:00' : asStr(r['HOR_VIRADA_DIA']);
        _intervalo.text = '${asInt(r['HOR_INTERVALO_MIN']) > 0 ? asInt(r['HOR_INTERVALO_MIN']) : 60}';
        _preencherDiasPadrao();
        final idSel = asInt(r['HOR_ID']);
        Db.instance.getHorarioDias(idSel).then((dias) {
          if (!mounted || _id != idSel || dias.isEmpty) return;
          setState(() {
            for (final e in dias.entries) {
              if (!_dia.containsKey(e.key)) continue;
              final x = e.value;
              _folgaDia[e.key] = asStr(x['HDI_FOLGA']) == 'S';
              _setDia(_dia[e.key]!, asStr(x['HDI_ENTRADA_1']), asStr(x['HDI_SAIDA_1']), asStr(x['HDI_ENTRADA_2']),
                  asStr(x['HDI_SAIDA_2']));
            }
          });
        });
      });

  /// Carga diária calculada pelos intervalos informados.
  void _calcularCarga() {
    int par(String e, String s) {
      final a = horaParaMinutos(e), b = horaParaMinutos(s);
      return b > a ? b - a : 0;
    }

    setState(() => _carga.text = minutosParaHora(par(_e1.text, _s1.text) + par(_e2.text, _s2.text)));
  }

  Future<bool> _salvar() async {
    if (_desc.text.trim().isEmpty) {
      await mensagem(context, 'Informe a descrição do horário.');
      return false;
    }
    final semanal = _escala == 'SEMANAL';
    if (semanal) {
      for (var d = 1; d <= 7; d++) {
        if (_folgaDia[d]!) continue;
        final v = _dia[d]!.map((t) => t.text.trim()).toList();
        final nome = _nomesDias[d - 1];
        if (v.any((x) => x.isNotEmpty && parseHora(x) == null)) {
          await mensagem(context, 'Horário inválido em $nome. Utilize o formato HH:MM.');
          return false;
        }
        if (v[0].isEmpty || v[3].isEmpty) {
          await mensagem(context, 'Informe a entrada e a saída de $nome (ou marque o dia como folga).');
          return false;
        }
        if (v[1].isEmpty != v[2].isEmpty) {
          await mensagem(context, 'Informe a saída e a volta do almoço de $nome (ou deixe as duas em branco).');
          return false;
        }
      }
      final trabalhados = [for (var d = 1; d <= 7; d++) if (!_folgaDia[d]!) d];
      if (trabalhados.isEmpty) {
        await mensagem(context, 'Informe ao menos um dia de trabalho na semana.');
        return false;
      }
      // Campos gerais (envio ao relógio e compatibilidade) = primeiro dia trabalhado da semana
      final g = _gravadoDia(trabalhados.first);
      _e1.text = g[0];
      _s1.text = g[1];
      _e2.text = g[2];
      _s2.text = g[3];
      _carga.text = minutosParaHora(_cargaDia(trabalhados.first));
      _trabalhaSab = !_folgaDia[6]!;
      final sab = _gravadoDia(6);
      _sabE1.text = _trabalhaSab ? sab[0] : '';
      _sabS1.text = _trabalhaSab ? (sab[3].isNotEmpty ? sab[3] : sab[1]) : '';
    }
    for (final c in [_e1, _s1, _e2, _s2, _sabE1, _sabS1]) {
      if (c.text.trim().isNotEmpty && parseHora(c.text) == null) {
        await mensagem(context, 'Horário inválido: "${c.text}". Utilize o formato HH:MM.');
        return false;
      }
    }
    try {
      _id = await Db.instance.salvarHorario(_id, _desc.text, _e1.text, _s1.text, _e2.text, _s2.text,
          int.tryParse(_tol.text) ?? 10, horaParaMinutos(_carga.text), _compensaSab, _trabalhaSab, _sabE1.text,
          _sabS1.text, _ativo);
      if (_escala != 'SEMANAL' && _escalaInicio == null) {
        throw Exception('Informe a data do primeiro dia trabalhado da escala 12x36.');
      }
      await Db.instance.salvarRegrasHorario(_id, _escala, _escalaInicio, _virada.text,
          int.tryParse(_intervalo.text) ?? 60, _bancoHoras);
      await Db.instance.salvarCicloHorario(_id, _escala == 'CICLO' ? int.tryParse(_cicloTrab.text) ?? 0 : 0,
          _escala == 'CICLO' ? int.tryParse(_cicloFolga.text) ?? 0 : 0);
      if (semanal) {
        await Db.instance.salvarHorarioDias(_id, {
          for (var d = 1; d <= 7; d++)
            d: (() {
              final g = _folgaDia[d]! ? ['', '', '', ''] : _gravadoDia(d);
              return (e1: g[0], s1: g[1], e2: g[2], s2: g[3], carga: _cargaDia(d), folga: _folgaDia[d]!);
            })()
        });
      }
      _app.logTs('💾 Horário [${_desc.text.trim()}] salvo com sucesso (ID $_id).');
      _app.dadosAlterados();
      await _carregar();
      return true;
    } catch (e) {
      if (mounted) await mensagem(context, 'Erro ao salvar horário: $e');
      return false;
    }
  }

  /// Copia a jornada de segunda para terça a sexta.
  void _copiarSegunda() => setState(() {
        for (var d = 2; d <= 5; d++) {
          _folgaDia[d] = _folgaDia[1]!;
          for (var k = 0; k < 4; k++) {
            _dia[d]![k].text = _dia[1]![k].text;
          }
        }
      });

  Widget _gradeSemanal() {
    const cab = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569));
    Widget celula(TextEditingController c, bool ativo) => SizedBox(
          width: 92,
          child: TextField(
            controller: c,
            enabled: ativo,
            onChanged: (_) => setState(() {}),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'HH:MM', isDense: true),
          ),
        );
    var semana = 0;
    for (var d = 1; d <= 7; d++) {
      semana += _cargaDia(d);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Jornada da semana', style: TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        TextButton.icon(
            icon: const Icon(Icons.copy_all, size: 16),
            label: const Text('Copiar segunda para terça a sexta'),
            onPressed: _copiarSegunda),
      ]),
      const SizedBox(height: 6),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            SizedBox(width: 80, child: Text('Dia', style: cab)),
            SizedBox(width: 56, child: Text('Folga', style: cab)),
            SizedBox(width: 100, child: Text('Entrada', style: cab)),
            SizedBox(width: 100, child: Text('Saída almoço', style: cab)),
            SizedBox(width: 100, child: Text('Volta almoço', style: cab)),
            SizedBox(width: 100, child: Text('Saída', style: cab)),
            SizedBox(width: 60, child: Text('Carga', style: cab)),
          ]),
          for (var d = 1; d <= 7; d++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 80, child: Text(_nomesDias[d - 1])),
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Checkbox(value: _folgaDia[d], onChanged: (v) => setState(() => _folgaDia[d] = v!)),
                  ),
                ),
                for (var k = 0; k < 4; k++)
                  Padding(padding: const EdgeInsets.only(right: 8), child: celula(_dia[d]![k], !_folgaDia[d]!)),
                SizedBox(
                  width: 60,
                  child: Text(_folgaDia[d]! ? 'Folga' : minutosParaHora(_cargaDia(d)),
                      style: TextStyle(color: _folgaDia[d]! ? Colors.grey : null, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Total semanal: ${minutosParaHora(semana)}   •   Sem almoço: deixe "Saída almoço" e '
                '"Volta almoço" em branco.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _salvarEnviar() async {
    if (!await _salvar()) return;
    final rels = await Db.instance.getRelogios(apenasAtivos: true);
    if (!mounted) return;
    if (rels.isEmpty) return mensagem(context, 'Nenhum relógio ativo para envio da jornada.');
    await comProgresso(context, () async {
      for (final r in rels) {
        await _app.ponto.sincronizarJornadaRelogio(
            asInt(r['PRE_ID']), _id, _desc.text.trim(), _e1.text, _s1.text, _e2.text, _s2.text);
      }
    }, texto: 'Enviando jornada aos relógios...');
  }

  Future<void> _excluir() async {
    if (_id <= 0) return;
    if (!await confirmar(context, 'Excluir o horário [${_desc.text}]?')) return;
    try {
      final info = await Db.instance.excluirHorario(_id);
      _app.logTs('🗑️ Horário [${_desc.text}] ${info == null ? 'excluído' : 'inativado'}.');
      if (info != null && mounted) await mensagem(context, info);
      _id = 0;
      _app.dadosAlterados();
      await _carregar();
    } catch (e) {
      if (mounted) await mensagem(context, 'Erro ao excluir horário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Largura útil do formulário: tela - menu lateral - margens - grade - espaçamentos - padding do card
    final wf = (MediaQuery.of(context).size.width - 232 - 48 - 470 - 12 - 32).clamp(340.0, 900.0);
    final wHora = (wf - 3 * 10) / 4; // 4 horários na primeira linha; carga e tolerância na seguinte
    final wMeio = (wf - 10) / 2;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('Horários e Jornadas', Icons.schedule, acoes: [
        Btn('Novo', Icons.add, _limpar, tonal: true),
        Btn('Atualizar', Icons.refresh, _carregar, tonal: true),
      ]),
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 470,
            child: DataGrid<DbRow>(
              itens: _itens,
              selecionado: _sel,
              onSelect: _preencher,
              colunas: [
                GridCol('ID', 45, (r) => '${r['HOR_ID']}'),
                GridCol('Descrição', 220, (r) => asStr(r['HOR_DESCRICAO']), flex: true),
                GridCol('Carga', 55, (r) => minutosParaHora(asInt(r['HOR_CARGA_DIARIA_MIN']))),
                GridCol('Sábado', 80, (r) => asStr(r['HOR_TRABALHA_SABADO']) == 'S'
                    ? 'Trabalha'
                    : (asStr(r['HOR_COMPENSA_SABADO']) == 'S' ? 'Compensa' : 'Folga')),
                GridCol('Escala', 60, (r) {
                  final e = asStr(r['HOR_TIPO_ESCALA']);
                  return e == '12X36' ? '12x36' : (e == 'CICLO' ? '${asInt(r['HOR_CICLO_TRABALHO'])}x${asInt(r['HOR_CICLO_FOLGA'])}' : 'Semanal');
                }),
                GridCol('BH', 35, (r) => asStr(r['HOR_BANCO_HORAS']) == 'S' ? 'Sim' : ''),
                GridCol('Ativo', 45, (r) => asStr(r['HOR_ATIVO'])),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Secao(_id > 0 ? 'Horário #$_id' : 'Novo horário', [
                Campo('Descrição', _desc, largura: wf),
                const SizedBox(height: 12),
                const Text('Regras da jornada', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'SEMANAL', label: Text('Semanal')),
                    ButtonSegment(value: '12X36', label: Text('Escala 12x36')),
                    ButtonSegment(value: 'CICLO', label: Text('Ciclo (6x1, 5x2...)')),
                  ],
                  selected: {_escala},
                  onSelectionChanged: (s) => setState(() => _escala = s.first),
                ),
                const SizedBox(height: 12),
                if (_escala == 'SEMANAL') ...[
                  _gradeSemanal(),
                  const SizedBox(height: 8),
                  Campo('Tolerância (min)', _tol, largura: wHora),
                  CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sábado de folga é compensado na semana (44h em 5 dias)'),
                      value: _compensaSab,
                      onChanged: (v) => setState(() => _compensaSab = v!)),
                ] else
                  Wrap(spacing: 10, runSpacing: 12, children: [
                    Campo('1ª Entrada', _e1, largura: wHora, dica: 'HH:MM'),
                    Campo('1ª Saída', _s1, largura: wHora, dica: 'HH:MM'),
                    Campo('2ª Entrada', _e2, largura: wHora, dica: 'HH:MM'),
                    Campo('2ª Saída', _s2, largura: wHora, dica: 'HH:MM'),
                    Campo('Carga diária', _carga, largura: wHora, dica: 'HH:MM'),
                    IconButton(
                        tooltip: 'Calcular carga pelos intervalos',
                        onPressed: _calcularCarga,
                        icon: const Icon(Icons.calculate)),
                    Campo('Tolerância (min)', _tol, largura: wHora),
                  ]),
                const Divider(height: 20),
                Wrap(spacing: 10, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (_escala == 'CICLO') ...[
                    Campo('Dias de trabalho', _cicloTrab, largura: wMeio),
                    Campo('Dias de folga', _cicloFolga, largura: wMeio),
                  ],
                  if (_escala != 'SEMANAL')
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(_escalaInicio == null ? '1º dia trabalhado' : 'Início: ${fmtData(_escalaInicio)}'),
                      onPressed: () async {
                        final d = await escolherData(context, _escalaInicio ?? DateTime.now());
                        if (d != null) setState(() => _escalaInicio = d);
                      },
                    ),
                  Campo('Intervalo mínimo (min)', _intervalo, largura: wMeio),
                  Campo('Virada do dia', _virada, largura: wMeio, dica: 'HH:MM'),
                ]),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Virada do dia: batidas antes deste horário contam no dia anterior (turno noturno, ex.: 12:00).',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ),
                CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Banco de horas (extras 50% e atrasos vão para o banco, não para a folha)'),
                    value: _bancoHoras,
                    onChanged: (v) => setState(() => _bancoHoras = v!)),
                CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Horário ativo'),
                    value: _ativo,
                    onChanged: (v) => setState(() => _ativo = v!)),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Btn('Salvar', Icons.save, _salvar),
                  if (!AppConfig.instance.modoHamsterDx)
                    Btn('Salvar e Enviar', Icons.send, _salvarEnviar, cor: Colors.green.shade700),
                  Btn('Excluir', Icons.delete, _id > 0 ? _excluir : null, cor: Colors.red.shade700),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}
