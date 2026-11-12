import 'package:flutter/material.dart';

import '../../core/util.dart';
import '../../data/database.dart';
import '../app_state.dart';
import '../importar_afd_dialog.dart';
import '../descoberta_dialog.dart';
import '../widgets.dart';

class RelogiosPage extends StatefulWidget {
  const RelogiosPage({super.key});
  @override
  State<RelogiosPage> createState() => _RelogiosPageState();
}

class _RelogiosPageState extends State<RelogiosPage> {
  final _app = AppState.instance;
  List<DbRow> _itens = [];
  DbRow? _sel;
  int _id = 0;
  final _nome = TextEditingController(), _ip = TextEditingController(), _porta = TextEditingController(text: '80');
  final _usuario = TextEditingController(text: 'admin'), _senha = TextEditingController(text: 'admin');
  bool _ssl = false, _ativo = true;
  String _modelo = 'IDCLASS', _modo = 'API';

  static const _modelos = ['IDCLASS', 'IDX', 'IDACCESS', 'IDFACE', 'IDFLEX'];
  static const _modos = {'API': 'API (access_logs)', 'AFD_671': 'AFD Portaria 671', 'AFD_1510': 'AFD Portaria 1510'};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!Db.instance.isConectado) return;
    final itens = await Db.instance.getRelogios();
    setState(() => _itens = itens);
    if (itens.isNotEmpty) {
      _preencher(itens.firstWhere((r) => r['PRE_ID'] == _id, orElse: () => itens.first));
    } else {
      _limpar();
    }
  }

  void _limpar() => setState(() {
        _sel = null;
        _id = 0;
        _nome.clear();
        _ip.clear();
        _porta.text = '80';
        _usuario.text = 'admin';
        _senha.text = 'admin';
        _ssl = false;
        _ativo = true;
        _modelo = 'IDCLASS';
        _modo = 'API';
      });

  void _preencher(DbRow r) => setState(() {
        _sel = r;
        _id = asInt(r['PRE_ID']);
        _nome.text = asStr(r['PRE_NOME']);
        _ip.text = asStr(r['PRE_IP']);
        _porta.text = '${asInt(r['PRE_PORTA'])}';
        _usuario.text = asStr(r['PRE_USUARIO']);
        _senha.text = asStr(r['PRE_SENHA']);
        _ssl = asStr(r['PRE_USAR_SSL']) == 'S';
        _ativo = asStr(r['PRE_ATIVO']) != 'N';
        final m = asStr(r['PRE_MODELO']).toUpperCase();
        _modelo = _modelos.contains(m) ? m : 'IDCLASS';
        final mc = asStr(r['PRE_MODO_COLETA']).toUpperCase();
        _modo = _modos.containsKey(mc) ? mc : 'API';
      });

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty || _ip.text.trim().isEmpty) {
      return mensagem(context, 'Informe o nome e o endereço IP do relógio.');
    }
    try {
      _id = await Db.instance.salvarRelogio(_id, _nome.text.trim(), _ip.text.trim(), int.tryParse(_porta.text) ?? 80,
          _ssl, _usuario.text.trim(), _senha.text, _modelo, _modo, _ativo);
      _app.logTs('💾 Relógio [${_nome.text.trim()}] salvo com sucesso (ID $_id).');
      _app.dadosAlterados();
      await _carregar();
    } catch (e) {
      if (mounted) mensagem(context, 'Erro ao salvar relógio: $e');
    }
  }

  Future<void> _procurarNaRede() async {
    final r = await procurarRelogios(context, ipsCadastrados: {for (final i in _itens) asStr(i['PRE_IP']).trim()});
    if (r == null) return;
    _limpar();
    setState(() {
      _nome.text = r.serial.isNotEmpty ? 'Relógio ${r.serial}' : 'Relógio ${r.ip}';
      _ip.text = r.ip;
      _porta.text = '${r.porta}';
      _ssl = r.ssl;
      _modo = r.modelo.startsWith('REP') ? 'AFD_671' : 'API';
    });
    _app.logTs('📡 Relógio encontrado na rede: ${r.ip}:${r.porta} ${r.descricao}');
    if (mounted) {
      await mensagem(
          context,
          'Relógio ${r.ip} preenchido no formulário.'
          '${r.autenticado ? '' : '\n\nO usuário/senha informados não funcionaram: digite a senha do equipamento.'}'
          '\n\nConfira os dados e clique em Salvar.');
    }
  }

  Future<void> _excluir() async {
    if (_id <= 0) return;
    if (!await confirmar(context, 'Deseja excluir o relógio [${_nome.text}]?')) return;
    try {
      await Db.instance.excluirRelogio(_id);
      _app.logTs('🗑️ Relógio [${_nome.text}] excluído.');
      _id = 0;
      _app.dadosAlterados();
      await _carregar();
    } catch (e) {
      if (mounted) mensagem(context, 'Não foi possível excluir o relógio (possui marcações vinculadas?): $e');
    }
  }

  Future<void> _acao(Future<dynamic> Function(int id) f, String texto) async {
    if (_id <= 0) return mensagem(context, 'Selecione ou salve um relógio primeiro.');
    await comProgresso(context, () => f(_id), texto: texto);
    _app.dadosAlterados();
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('Relógios de Ponto', Icons.access_time, acoes: [
        Btn('Procurar na rede', Icons.wifi_find_rounded, _procurarNaRede),
        Btn('Importar AFD (pendrive)', Icons.usb_rounded, () => importarAfdDoPendrive(context), tonal: true),
        Btn('Novo', Icons.add, _limpar, tonal: true),
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
                GridCol('ID', 50, (r) => '${r['PRE_ID']}'),
                GridCol('Nome', 160, (r) => asStr(r['PRE_NOME']), flex: true),
                GridCol('IP', 120, (r) => asStr(r['PRE_IP'])),
                GridCol('Porta', 55, (r) => '${asInt(r['PRE_PORTA'])}'),
                GridCol('Modo', 80, (r) => asStr(r['PRE_MODO_COLETA'])),
                GridCol('Último Log', 80, (r) => '${asInt(r['PRE_ULTIMO_LOG_ID'])}'),
                GridCol('Última Coleta', 130, (r) => fmtDataHora(asDate(r['PRE_ULTIMA_COLETA']))),
                GridCol('Ativo', 50, (r) => asStr(r['PRE_ATIVO']),
                    cor: (r) => asStr(r['PRE_ATIVO']) == 'S' ? Colors.green : Colors.red),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Secao(_id > 0 ? 'Relógio #$_id' : 'Novo relógio', [
                Wrap(spacing: 10, runSpacing: 12, children: [
                  Campo('Nome', _nome, largura: 348),
                  Campo('Endereço IP', _ip, largura: 230),
                  Campo('Porta', _porta, largura: 108),
                  Campo('Usuário', _usuario, largura: 169),
                  Campo('Senha', _senha, largura: 169, senha: true),
                  SizedBox(
                    width: 169,
                    child: DropdownButtonFormField<String>(
                      initialValue: _modelo,
                      decoration: const InputDecoration(labelText: 'Modelo', isDense: true),
                      items: [for (final m in _modelos) DropdownMenuItem(value: m, child: Text(m))],
                      onChanged: (v) => setState(() => _modelo = v!),
                    ),
                  ),
                  SizedBox(
                    width: 169,
                    child: DropdownButtonFormField<String>(
                      initialValue: _modo,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Modo de coleta', isDense: true),
                      items: [for (final e in _modos.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                      onChanged: (v) => setState(() => _modo = v!),
                    ),
                  ),
                ]),
                CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usar SSL (HTTPS)'),
                    value: _ssl,
                    onChanged: (v) => setState(() => _ssl = v!)),
                CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Relógio ativo para coleta'),
                    value: _ativo,
                    onChanged: (v) => setState(() => _ativo = v!)),
                if (_sel != null) ...[
                  Text('Nº série: ${asStr(_sel!['PRE_SERIAL'])}   Firmware: ${asStr(_sel!['PRE_VERSAO_FW'])}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Btn('Salvar', Icons.save, _salvar),
                  Btn('Excluir', Icons.delete, _id > 0 ? _excluir : null, cor: Colors.red.shade700),
                ]),
                const Divider(height: 24),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Btn('Testar', Icons.wifi_tethering, () => _acao(_app.ponto.testarRelogio, 'Testando comunicação...'),
                      tonal: true),
                  Btn('Sinc. Hora', Icons.schedule,
                      () => _acao(_app.ponto.sincronizarHorario, 'Sincronizando data/hora...'), tonal: true),
                  Btn('Coletar', Icons.download, () => _acao(_app.ponto.coletarMarcacoes, 'Coletando marcações...'),
                      cor: Colors.green.shade700),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}
