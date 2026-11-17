import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/util.dart';
import '../../data/database.dart';
import '../../services/hamster.dart';
import '../app_state.dart';
import '../widgets.dart';

class ColaboradoresPage extends StatefulWidget {
  const ColaboradoresPage({super.key});
  @override
  State<ColaboradoresPage> createState() => _ColaboradoresPageState();
}

class _ColaboradoresPageState extends State<ColaboradoresPage> {
  final _app = AppState.instance;
  List<DbRow> _todos = [], _itens = [];
  List<DbRow> _horarios = [], _relogios = [];
  DbRow? _sel;
  int _id = 0, _horarioId = 0, _relogioDestino = 0;
  bool _ativo = true;
  final _busca = TextEditingController();
  final _nome = TextEditingController(), _cpf = TextEditingController(), _pis = TextEditingController();
  final _matricula = TextEditingController(), _funcao = TextEditingController(), _codigo = TextEditingController();
  final _senhaRel = TextEditingController(), _rfid = TextEditingController();
  bool _adminRel = false;
  DateTime? _admissao, _demissao;
  int _digitaisRelogio = 0;

  bool get _hamster => AppConfig.instance.modoHamsterDx;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!Db.instance.isConectado) return;
    final db = Db.instance;
    final todos = await db.getColaboradores(apenasAtivos: false);
    final hor = await db.getHorarios();
    final rel = _hamster ? <DbRow>[] : await db.getRelogios(apenasAtivos: true);
    setState(() {
      _todos = todos;
      _horarios = hor;
      _relogios = rel;
      if (_relogioDestino == 0 || !rel.any((r) => r['PRE_ID'] == _relogioDestino)) {
        _relogioDestino = rel.isEmpty ? 0 : asInt(rel.first['PRE_ID']);
      }
      _filtrar();
    });
    final atual = todos.where((r) => asInt(r['PES_ID']) == _id);
    if (atual.isNotEmpty) {
      _preencher(atual.first);
    } else if (_itens.isNotEmpty && _id == 0) {
      _preencher(_itens.first);
    }
  }

  void _filtrar() {
    final q = _busca.text.trim().toLowerCase();
    _itens = q.isEmpty
        ? _todos
        : _todos
            .where((r) =>
                asStr(r['PES_RSOCIAL_NOME']).toLowerCase().contains(q) ||
                asStr(r['PES_CNPJ_CPF']).contains(q) ||
                asStr(r['COL_CARTAO_PONTO']).toLowerCase().contains(q) ||
                '${r['PES_ID']}' == q)
            .toList();
  }

  void _limpar() => setState(() {
        _sel = null;
        _id = 0;
        for (final c in [_nome, _cpf, _pis, _matricula, _funcao, _codigo, _senhaRel, _rfid]) {
          c.clear();
        }
        _ativo = true;
        _adminRel = false;
        _admissao = null;
        _demissao = null;
        _horarioId = _horarios.isEmpty ? 0 : asInt(_horarios.first['HOR_ID']);
      });

  Future<void> _contarDigitais(int pid) async {
    final j = await Db.instance.getBiometriaControlId(pid);
    var n = 0;
    try {
      n = j.trim().isEmpty ? 0 : (jsonDecode(j) as List).length;
    } catch (_) {}
    if (mounted && pid == _id) setState(() => _digitaisRelogio = n);
  }

  Future<void> _lerDigitais() async {
    if (!_temRelogio()) return;
    final n = await comProgresso(context, () => _app.ponto.lerDigitaisDoRelogio(_relogioDestino),
        texto: 'Lendo as digitais cadastradas no relógio...');
    if (_id > 0) await _contarDigitais(_id);
    if (mounted && n != null) {
      await mensagem(context, n > 0
          ? '$n colaborador(es) com digitais importadas do relógio. Use "Enviar para todos os relógios" para copiá-las.'
          : 'O relógio não retornou digitais. Cadastre a digital no relógio e leia novamente.');
    }
  }

  Future<void> _enviarTodos() async {
    if (_id <= 0) return;
    final ok = await comProgresso(context, () => _app.ponto.enviarParaTodosRelogios(_id), texto: 'Enviando aos relógios...');
    if (mounted) await mensagem(context, 'Cadastro (com digitais) enviado para ${ok ?? 0} relógio(s).');
    await _carregar();
  }

  void _preencher(DbRow r) => setState(() {
        _digitaisRelogio = 0;
        _contarDigitais(asInt(r['PES_ID']));
        _sel = r;
        _id = asInt(r['PES_ID']);
        _nome.text = asStr(r['PES_RSOCIAL_NOME']);
        _cpf.text = asStr(r['PES_CNPJ_CPF']);
        _pis.text = asStr(r['COL_PIS']);
        _matricula.text = asStr(r['COL_CARTAO_PONTO']);
        _funcao.text = asStr(r['COL_FUNCAO']);
        _codigo.text = asStr(r['PES_CODIGO_ACESSO']);
        _ativo = asStr(r['PES_STATUS']) != 'I';
        _horarioId = asInt(r['COL_HORARIO']);
        _admissao = asDate(r['COL_DATA_ADMISSAO']);
        _demissao = asDate(r['COL_DATA_DEMISSAO']);
        _senhaRel.text = asStr(r['COL_SENHA_RELOGIO']);
        _rfid.text = asInt(r['COL_RFID']) > 0 ? '${asInt(r['COL_RFID'])}' : '';
        _adminRel = asStr(r['COL_ADMIN_RELOGIO']) == 'S';
      });

  Future<bool> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      await mensagem(context, 'Informe o nome do colaborador.');
      return false;
    }
    try {
      final id = await Db.instance.salvarColaborador(_id, _nome.text, _cpf.text, _pis.text, _matricula.text,
          _funcao.text, _codigo.text, _ativo, _horarioId);
      if (id <= 0) throw Exception('O banco não retornou o código do colaborador.');
      _id = id;
      await Db.instance.salvarContratoColaborador(id,
          admissao: _admissao,
          demissao: _demissao,
          senhaRelogio: _senhaRel.text,
          rfid: int.tryParse(_rfid.text.trim()) ?? 0,
          adminRelogio: _adminRel);
      _app.logTs('💾 Colaborador [${_nome.text.trim()}] salvo com sucesso (ID $_id).');
      _app.dadosAlterados();
      await _carregar();
      return true;
    } catch (e) {
      if (mounted) await mensagem(context, 'Erro ao salvar colaborador: $e');
      return false;
    }
  }

  Widget _dataBtn(String rotulo, DateTime? valor, ValueChanged<DateTime?> f) => SizedBox(
        width: 179,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: rotulo,
            suffixIcon: valor == null
                ? null
                : IconButton(icon: const Icon(Icons.clear, size: 18), tooltip: 'Limpar', onPressed: () => f(null)),
          ),
          child: InkWell(
            onTap: () async {
              final d = await escolherData(context, valor ?? DateTime.now());
              if (d != null) f(d);
            },
            child: Text(valor == null ? 'Não informada' : fmtData(valor),
                style: TextStyle(color: valor == null ? Colors.grey : null)),
          ),
        ),
      );

  bool _temRelogio() {
    if (_relogioDestino > 0) return true;
    mensagem(context, 'Nenhum relógio ativo cadastrado para envio.');
    return false;
  }

  Future<void> _enviar() async {
    if (_id <= 0 || !_temRelogio()) return;
    await comProgresso(
        context,
        () => _app.ponto.enviarColaboradorIndividual(_relogioDestino, _id,
            senha: _senhaRel.text.trim(), rfid: int.tryParse(_rfid.text.trim()) ?? 0, admin: _adminRel),
        texto: 'Enviando colaborador ao relógio...');
    await _carregar();
  }

  Future<void> _remover() async {
    if (_id <= 0 || !_temRelogio()) return;
    if (!await confirmar(context, 'Remover [${_nome.text}] da memória do relógio?')) return;
    if (!mounted) return;
    await comProgresso(context, () => _app.ponto.removerColaboradorDoRelogio(_relogioDestino, _id));
    await _carregar();
  }

  Future<void> _enviarPendentes() async {
    if (!_temRelogio()) return;
    final ids = [
      for (final r in _todos)
        if (asStr(r['COL_SINCRONIZADO_RELOGIO']) != 'S' && asStr(r['PES_STATUS']) != 'I') asInt(r['PES_ID'])
    ];
    if (ids.isEmpty) return mensagem(context, 'Todos os colaboradores ativos já estão sincronizados.');
    if (!await confirmar(context, 'Enviar ${ids.length} colaborador(es) pendente(s) ao relógio?')) return;
    if (!mounted) return;
    final r = await comProgresso(context, () => _app.ponto.sincronizarColaboradores(_relogioDestino, ids),
        texto: 'Enviando colaboradores...');
    if (mounted && r != null) await mensagem(context, 'Envio concluído: ${r.sucessos} sucesso(s), ${r.falhas} falha(s).');
    await _carregar();
  }

  Future<void> _limparRelogio() async {
    if (!_temRelogio()) return;
    if (!await confirmar(context,
        'ATENÇÃO: todos os colaboradores serão removidos da memória do relógio. Deseja continuar?')) {
      return;
    }
    if (!mounted) return;
    await comProgresso(context, () => _app.ponto.limparTodosColaboradoresDoRelogio(_relogioDestino));
  }

  Future<void> _excluirBanco() async {
    if (_id <= 0) return;
    if (!await confirmar(context, 'Excluir o colaborador [${_nome.text}] do banco de dados?')) return;
    final r = await Db.instance.excluirColaborador(_id);
    if (!mounted) return;
    if (!r.ok) return mensagem(context, 'Erro ao excluir colaborador: ${r.erro}');
    if (r.inativado) {
      _app.logTs('⚠️ Colaborador [${_nome.text}] possui vínculos e foi INATIVADO.');
      await mensagem(context, 'O colaborador possui marcações vinculadas e foi inativado para preservar o histórico.');
    } else {
      _app.logTs('🗑️ Colaborador [${_nome.text}] excluído do banco de dados.');
      _id = 0;
    }
    _app.dadosAlterados();
    await _carregar();
  }

  // ---------------- Biometria ----------------

  Future<void> _cadastrarDigital() async {
    if (_id <= 0) return mensagem(context, 'Salve o colaborador antes de cadastrar a digital.');
    final r = await comProgresso(context, HamsterDx.cadastrar, texto: 'Siga as instruções do assistente do leitor...');
    if (!mounted || r == null) return;
    if (r.template == null) return mensagem(context, r.erro);
    if (await Db.instance.salvarBiometriaColaborador(_id, r.template!)) {
      _app.logTs('👆 Digital de [${_nome.text}] cadastrada com sucesso.');
      _app.dadosAlterados();
      if (mounted) await mensagem(context, 'Digital cadastrada com sucesso!');
      await _carregar();
    } else if (mounted) {
      await mensagem(context, Db.instance.lastError);
    }
  }

  Future<void> _testarDigital() async {
    if (_id <= 0) return;
    final armazenada = await Db.instance.getBiometriaColaborador(_id);
    if (!mounted) return;
    if (armazenada.isEmpty) return mensagem(context, 'Este colaborador não possui digital cadastrada.');
    final cap = await comProgresso(context, HamsterDx.capturar, texto: 'Coloque o dedo no leitor...');
    if (!mounted || cap == null) return;
    if (cap.template == null) return mensagem(context, cap.erro);
    final cmp = await HamsterDx.comparar(cap.template!, armazenada);
    if (!mounted) return;
    await mensagem(context, !cmp.ok ? cmp.erro : (cmp.igual ? '✅ Digital confere!' : '❌ A digital NÃO confere.'));
  }

  Future<void> _removerDigital() async {
    if (_id <= 0) return;
    if (!await confirmar(context, 'Remover a digital cadastrada de [${_nome.text}]?')) return;
    await Db.instance.removerBiometriaColaborador(_id);
    _app.logTs('🗑️ Digital de [${_nome.text}] removida.');
    _app.dadosAlterados();
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final bio = _sel != null && asStr(_sel!['COL_BIOMETRIA_CADASTRADA']) == 'S';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader('Colaboradores', Icons.groups_outlined, acoes: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _busca,
            onChanged: (_) => setState(_filtrar),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Buscar por nome, CPF ou matrícula', isDense: true,
                border: OutlineInputBorder()),
          ),
        ),
        Btn('Novo', Icons.person_add, _limpar, tonal: true),
        Btn('Atualizar', Icons.refresh, _carregar, tonal: true),
        if (!_hamster) ...[
          Btn('Enviar Pendentes', Icons.upload, _enviarPendentes, tonal: true),
          Btn('Listar do Relógio', Icons.list_alt, () async {
            if (_temRelogio()) await comProgresso(context, () => _app.ponto.importarUsuariosDoRelogio(_relogioDestino));
          }, tonal: true),
          Btn('Limpar Relógio', Icons.cleaning_services, _limparRelogio, cor: Colors.red.shade700),
        ],
      ]),
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: DataGrid<DbRow>(
              itens: _itens,
              selecionado: _sel,
              onSelect: _preencher,
              colunas: [
                GridCol('Código', 60, (r) => '${r['PES_ID']}'),
                GridCol('Nome', 200, (r) => asStr(r['PES_RSOCIAL_NOME']), flex: true),
                GridCol('CPF', 110, (r) => formatarDoc(asStr(r['PES_CNPJ_CPF']))),
                GridCol('Matrícula', 80, (r) => asStr(r['COL_CARTAO_PONTO'])),
                GridCol('Horário', 140, (r) => asStr(r['HOR_DESCRICAO'])),
                if (_hamster)
                  GridCol('Digital', 60, (r) => asStr(r['COL_BIOMETRIA_CADASTRADA']) == 'S' ? '👆 Sim' : 'Não')
                else
                  GridCol('Sinc.', 50, (r) => asStr(r['COL_SINCRONIZADO_RELOGIO']) == 'S' ? '✅' : '⏳'),
                GridCol('Status', 60, (r) => asStr(r['PES_STATUS']) == 'I' ? 'Inativo' : 'Ativo',
                    cor: (r) => asStr(r['PES_STATUS']) == 'I' ? Colors.red : null),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(children: [
                Secao(_id > 0 ? 'Colaborador #$_id' : 'Novo colaborador', [
                  Wrap(spacing: 10, runSpacing: 12, children: [
                    Campo('Nome completo', _nome, largura: 368),
                    Campo('CPF', _cpf, largura: 179),
                    Campo('PIS', _pis, largura: 179),
                    Campo('Matrícula / Cartão', _matricula, largura: 179),
                    Campo('Código de acesso', _codigo, largura: 179),
                    Campo('Função / Cargo', _funcao, largura: 368),
                    _dataBtn('Admissão', _admissao, (d) => setState(() => _admissao = d)),
                    _dataBtn('Demissão', _demissao, (d) => setState(() => _demissao = d)),
                    SizedBox(
                      width: 368,
                      child: DropdownButtonFormField<int>(
                        initialValue: _horarios.any((h) => asInt(h['HOR_ID']) == _horarioId) ? _horarioId : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Horário / Jornada', isDense: true),
                        items: [
                          for (final h in _horarios)
                            DropdownMenuItem(value: asInt(h['HOR_ID']), child: Text(asStr(h['HOR_DESCRICAO'])))
                        ],
                        onChanged: (v) => setState(() => _horarioId = v ?? 0),
                      ),
                    ),
                  ]),
                  CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Colaborador ativo'),
                      value: _ativo,
                      onChanged: (v) => setState(() => _ativo = v!)),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Btn('Salvar', Icons.save, _salvar),
                    if (!_hamster)
                      Btn('Salvar e Enviar', Icons.send, () async {
                        if (await _salvar()) await _enviar();
                      }, cor: Colors.green.shade700),
                    Btn('Excluir', Icons.delete, _id > 0 ? _excluirBanco : null, cor: Colors.red.shade700),
                  ]),
                ]),
                if (_hamster)
                  Secao('Biometria (Hamster DX)', [
                    Text(bio
                        ? '👆 Digital cadastrada em ${fmtDataHora(asDate(_sel!['COL_BIOMETRIA_DATA']))}'
                        : 'Nenhuma digital cadastrada para este colaborador.'),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Btn('Cadastrar Digital', Icons.fingerprint, _id > 0 ? _cadastrarDigital : null),
                      Btn('Testar', Icons.science, bio ? _testarDigital : null, tonal: true),
                      Btn('Remover', Icons.delete_outline, bio ? _removerDigital : null, cor: Colors.red.shade700),
                    ]),
                  ])
                else
                  Secao('Envio ao relógio', [
                    DropdownButtonFormField<int>(
                      initialValue: _relogioDestino > 0 ? _relogioDestino : null,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Relógio de destino', isDense: true),
                      items: [
                        for (final r in _relogios)
                          DropdownMenuItem(value: asInt(r['PRE_ID']), child: Text(asStr(r['PRE_NOME'])))
                      ],
                      onChanged: (v) => setState(() => _relogioDestino = v ?? 0),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 12, children: [
                      Campo('Senha no relógio', _senhaRel, largura: 179),
                      Campo('Cartão RFID', _rfid, largura: 179),
                    ]),
                    CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Administrador do relógio'),
                        value: _adminRel,
                        onChanged: (v) => setState(() => _adminRel = v!)),
                    if (_sel != null)
                      Text(
                          asStr(_sel!['COL_SINCRONIZADO_RELOGIO']) == 'S'
                              ? '✅ Sincronizado em ${fmtDataHora(asDate(_sel!['COL_ULTIMA_SINCRONIZACAO']))}'
                              : '⏳ Pendente de envio ao relógio',
                          style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Btn('Enviar ao Relógio', Icons.upload, _id > 0 ? _enviar : null, cor: Colors.green.shade700),
                      Btn('Remover do Relógio', Icons.person_remove, _id > 0 ? _remover : null, tonal: true),
                    ]),
                    const Divider(height: 24),
                    Row(children: [
                      const Icon(Icons.fingerprint, size: 20),
                      const SizedBox(width: 6),
                      const Text('Digital no relógio', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(_digitaisRelogio > 0 ? '👆 $_digitaisRelogio digital(is) guardada(s)' : 'Nenhuma digital guardada',
                          style: TextStyle(fontSize: 12, color: _digitaisRelogio > 0 ? Colors.green.shade700 : Colors.grey)),
                    ]),
                    const SizedBox(height: 6),
                    const Text(
                        '1. Envie o colaborador ao relógio.\n'
                        '2. No relógio: Menu > Usuários > escolha o colaborador > Biometria > cadastre o dedo.\n'
                        '3. Clique em "Ler digitais do relógio" para guardar no sistema.\n'
                        '4. "Enviar para todos os relógios" copia o cadastro e as digitais para os demais.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Btn('Ler digitais do relógio', Icons.download, _lerDigitais, tonal: true),
                      Btn('Enviar para todos os relógios', Icons.devices, _id > 0 ? _enviarTodos : null, tonal: true),
                    ]),
                  ]),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}
