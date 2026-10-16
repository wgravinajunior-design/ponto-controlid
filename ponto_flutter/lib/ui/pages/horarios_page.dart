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
  int _diasConfigurados = 0;
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
      });

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
        Db.instance.getHorarioDias(asInt(r['HOR_ID'])).then((d) {
          if (mounted) setState(() => _diasConfigurados = d.length);
        });
        _escalaInicio = asDate(r['HOR_ESCALA_INICIO']);
        _bancoHoras = asStr(r['HOR_BANCO_HORAS']) == 'S';
        _virada.text = asStr(r['HOR_VIRADA_DIA']).isEmpty ? '00:00' : asStr(r['HOR_VIRADA_DIA']);
        _intervalo.text = '${asInt(r['HOR_INTERVALO_MIN']) > 0 ? asInt(r['HOR_INTERVALO_MIN']) : 60}';
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
      _app.logTs('💾 Horário [${_desc.text.trim()}] salvo com sucesso (ID $_id).');
      _app.dadosAlterados();
      await _carregar();
      return true;
    } catch (e) {
      if (mounted) await mensagem(context, 'Erro ao salvar horário: $e');
      return false;
    }
  }

  /// Jornada específica por dia da semana (ex.: sexta mais curta, sábado meio período, folga fixa).
  Future<void> _editarDias() async {
    const nomes = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    final atuais = await Db.instance.getHorarioDias(_id);
    final usar = <int, bool>{}, folga = <int, bool>{};
    final ctrl = <int, List<TextEditingController>>{};
    for (var d = 1; d <= 7; d++) {
      final r = atuais[d];
      usar[d] = r != null;
      folga[d] = r == null ? d == 7 : asStr(r['HDI_FOLGA']) == 'S';
      final padrao = d == 6 ? [_sabE1.text, _sabS1.text, '', ''] : [_e1.text, _s1.text, _e2.text, _s2.text];
      ctrl[d] = [
        for (var k = 0; k < 4; k++)
          TextEditingController(
              text: r == null ? padrao[k] : asStr(r[['HDI_ENTRADA_1', 'HDI_SAIDA_1', 'HDI_ENTRADA_2', 'HDI_SAIDA_2'][k]]))
      ];
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Jornada por dia da semana'),
          content: SizedBox(
            width: 720,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Marque os dias com horário diferente do geral. Dias não marcados seguem a jornada geral '
                  '(segunda a sexta), o sábado e o domingo da configuração normal.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              for (var d = 1; d <= 7; d++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(
                      width: 130,
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(nomes[d - 1]),
                        value: usar[d],
                        onChanged: (v) => set(() => usar[d] = v!),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Folga'),
                        value: folga[d],
                        onChanged: usar[d]! ? (v) => set(() => folga[d] = v!) : null,
                      ),
                    ),
                    for (var k = 0; k < 4; k++)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 105,
                          child: TextField(
                            controller: ctrl[d]![k],
                            enabled: usar[d]! && !folga[d]!,
                            decoration: InputDecoration(
                                labelText: ['1ª Ent', '1ª Saí', '2ª Ent', '2ª Saí'][k], hintText: 'HH:MM', isDense: true),
                          ),
                        ),
                      ),
                  ]),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final dias = <int, ({String e1, String s1, String e2, String s2, int carga, bool folga})>{};
    for (var d = 1; d <= 7; d++) {
      if (!usar[d]!) continue;
      final v = ctrl[d]!.map((t) => t.text.trim()).toList();
      if (!folga[d]! && v.any((x) => x.isNotEmpty && parseHora(x) == null)) {
        if (mounted) await mensagem(context, 'Horário inválido em ${nomes[d - 1]}. Use HH:MM.');
        return;
      }
      dias[d] = (e1: v[0], s1: v[1], e2: v[2], s2: v[3], carga: 0, folga: folga[d]!);
    }
    await Db.instance.salvarHorarioDias(_id, dias);
    _app.logTs('🗓️ Jornada por dia da semana salva para o horário #$_id (${dias.length} dia(s)).');
    _app.dadosAlterados();
    setState(() => _diasConfigurados = dias.length);
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
                Wrap(spacing: 10, runSpacing: 12, children: [
                  Campo('Descrição', _desc, largura: wf),
                  Campo('1ª Entrada', _e1, largura: wHora, dica: 'HH:MM'),
                  Campo('1ª Saída', _s1, largura: wHora, dica: 'HH:MM'),
                  Campo('2ª Entrada', _e2, largura: wHora, dica: 'HH:MM'),
                  Campo('2ª Saída', _s2, largura: wHora, dica: 'HH:MM'),
                  Campo('Carga diária', _carga, largura: wHora, dica: 'HH:MM'),
                  IconButton(
                      tooltip: 'Calcular carga pelos intervalos', onPressed: _calcularCarga, icon: const Icon(Icons.calculate)),
                  Campo('Tolerância (min)', _tol, largura: wHora),
                ]),
                const SizedBox(height: 8),
                CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compensa sábado (jornada de 44h em 5 dias)'),
                    value: _compensaSab,
                    onChanged: (v) => setState(() => _compensaSab = v!)),
                CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Trabalha aos sábados'),
                    value: _trabalhaSab,
                    onChanged: (v) => setState(() => _trabalhaSab = v!)),
                if (_trabalhaSab)
                  Wrap(spacing: 10, children: [
                    Campo('Sábado entrada', _sabE1, largura: wMeio, dica: 'HH:MM'),
                    Campo('Sábado saída', _sabS1, largura: wMeio, dica: 'HH:MM'),
                  ]),
                const Divider(height: 20),
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
                if (_escala == 'SEMANAL')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.view_week, size: 18),
                      label: Text(_diasConfigurados > 0
                          ? 'Jornada por dia da semana ($_diasConfigurados dia(s) configurado(s))'
                          : 'Jornada diferente por dia da semana'),
                      onPressed: _id > 0 ? _editarDias : null,
                    ),
                  ),
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
