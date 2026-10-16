import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/config.dart';
import '../../core/util.dart';
import '../../data/database.dart';
import '../../services/controlid_client.dart';
import '../../services/feriados_service.dart';
import '../../services/backup_service.dart';
import '../../services/hamster.dart';
import '../../services/servico_windows.dart';
import '../app_state.dart';
import '../descoberta_dialog.dart';
import '../theme.dart';
import '../widgets.dart';
import 'usuarios_tab.dart';

class ConfigPage extends StatefulWidget {
  /// Chamado quando o tipo de relógio muda (a navegação é refeita).
  final VoidCallback onModoAlterado;
  /// Antes do login (tela de entrada) só a conexão com o banco pode ser alterada.
  final bool somenteBanco;
  const ConfigPage({super.key, required this.onModoAlterado, this.somenteBanco = false});
  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _cfg = AppConfig.instance;
  final _app = AppState.instance;

  late final _server = TextEditingController(text: _cfg.firebird.server);
  late final _porta = TextEditingController(text: '${_cfg.firebird.port}');
  late final _database = TextEditingController(text: _cfg.firebird.database);
  late final _user = TextEditingController(text: _cfg.firebird.user);
  late final _pass = TextEditingController(text: _cfg.firebird.password);
  late final _vendor = TextEditingController(text: _cfg.firebird.vendorLib);
  late final _intervalo = TextEditingController(text: '${_cfg.controlId.intervaloColetaSegundos}');
  late final _intervaloBatida = TextEditingController(text: '${_cfg.relogio.intervaloMinimoBatidaMin}');
  late bool _autoIniciar = _cfg.controlId.autoIniciarColeta;
  late bool _autoAtualizar = _cfg.atualizacao.autoAtualizar;
  late bool _onlineAtivo = _cfg.online.ativo, _backupAtivo = _cfg.backup.ativo;
  late final _portaOnline = TextEditingController(text: '${_cfg.online.porta}');
  late final _portaFechadura = TextEditingController(text: '${_cfg.online.portaFechadura}');
  late final _backupPasta = TextEditingController(text: _cfg.backup.pasta);
  late final _backupManter = TextEditingController(text: '${_cfg.backup.manter}');
  late TipoRelogio _tipo = _cfg.relogio.tipo;
  late int _nivel = _cfg.relogio.nivelSeguranca;
  late bool _abrirTerminal = _cfg.relogio.abrirTerminalAoIniciar;
  late bool _imprimirComprovante = _cfg.relogio.imprimirComprovante;
  String _requisitos = '';

  // Empregador
  final _razao = TextEditingController(), _cnpj = TextEditingController(), _endereco = TextEditingController();
  final _cei = TextEditingController(), _cpfResp = TextEditingController();
  int _docType = 1, _relogioEmp = 0;
  String _ufEmp = '';
  int _ibgeEmp = 0;
  String _municipioEmp = '';
  List<MunicipioIbge> _municipios = [];
  bool _buscandoCnpj = false;
  List<DbRow> _relogios = [];

  // Versões
  List<VersaoBdItem> _versoes = [];
  VersaoBdItem? _versaoSel;
  final _buscaVersao = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
    if (_tipo == TipoRelogio.hamsterDx) _verificarRequisitos();
  }

  Future<void> _carregarDados() async {
    if (!Db.instance.isConectado) return;
    try {
      final rel = await Db.instance.getRelogios(apenasAtivos: true);
      final vers = await Db.instance.obterHistoricoVersoes();
      setState(() {
        _relogios = rel;
        if (rel.isNotEmpty && _relogioEmp == 0) _relogioEmp = asInt(rel.first['PRE_ID']);
        _versoes = vers;
        _versaoSel = vers.isEmpty ? null : vers.first;
      });
      await _carregarEmpBanco(silencioso: true);
      _carregarMunicipios();
    } catch (e) {
      _app.logTs('❌ $e', true);
    }
  }

  Future<void> _salvar() async {
    final anterior = _cfg.relogio.tipo;
    _salvarSomenteBanco();
    _cfg.firebird
      ..server = _server.text.trim()
      ..port = int.tryParse(_porta.text) ?? 3060
      ..database = _database.text.trim()
      ..user = _user.text.trim()
      ..password = _pass.text.trim()
      ..vendorLib = _vendor.text.trim()
      ..charset = 'WIN1252';
    _cfg.controlId
      ..intervaloColetaSegundos = int.tryParse(_intervalo.text) ?? 60
      ..autoIniciarColeta = _autoIniciar;
    _cfg.atualizacao.autoAtualizar = _autoAtualizar;
    _salvarOnlineBackup();
    _cfg.relogio
      ..tipo = _tipo
      ..nivelSeguranca = _nivel
      ..intervaloMinimoBatidaMin = (int.tryParse(_intervaloBatida.text) ?? 2).clamp(0, 999)
      ..abrirTerminalAoIniciar = _abrirTerminal
      ..imprimirComprovante = _imprimirComprovante;
    _cfg.save();
    _app.logTs('💾 Configurações salvas em ${_cfg.iniPath}.');
    if (anterior != _tipo) {
      _app.logTs('🔁 Tipo de relógio alterado para: ${tipoRelogioDescricao(_tipo)}');
      if (_tipo == TipoRelogio.hamsterDx) _app.pararAutoColeta();
      widget.onModoAlterado();
    }
    if (mounted) await mensagem(context, 'Configurações salvas com sucesso!');
  }

  Future<void> _testarConexao() async {
    _salvarSomenteBanco();
    final erro = await comProgresso(context, Db.instance.testarConexao, texto: 'Conectando ao banco de dados...');
    _app.conectado = erro == null;
    if (erro == null) {
      _app.logTs('✅ Conexão com o banco de dados estabelecida com sucesso!');
      _app.setStatus('Conectado ao banco de dados');
      _app.dadosAlterados();
      await _app.atualizarEmpregador();
      await _carregarDados();
      if (mounted) await mensagem(context, 'Conexão estabelecida com sucesso!');
    } else {
      _app.logTs('❌ $erro', true);
      if (mounted) await mensagem(context, erro);
    }
  }

  void _salvarSomenteBanco() {
    _cfg.firebird
      ..server = _server.text.trim()
      ..port = int.tryParse(_porta.text) ?? 3060
      ..database = _database.text.trim()
      ..user = _user.text.trim()
      ..password = _pass.text.trim()
      ..vendorLib = _vendor.text.trim();
    _cfg.save();
  }

  Future<void> _verificarRequisitos() async {
    setState(() => _requisitos = 'Verificando requisitos do leitor...');
    final r = await HamsterDx.verificarRequisitos();
    if (mounted) {
      setState(() => _requisitos = '${r.driver ? '✅' : '❌'} Driver do Hamster DX (FPUSB)\n'
          '${r.sdk ? '✅' : '❌'} SDK Nitgen eNBSP (NBioBSPCOM.dll 32 bits)');
    }
  }

  Future<void> _carregarMunicipios() async {
    if (_ufEmp.isEmpty) return;
    try {
      final m = await FeriadosService.municipios(_ufEmp);
      if (mounted) setState(() => _municipios = m);
    } catch (_) {
      // sem internet: o município atual continua válido
    }
  }

  /// Preenche razão social, endereço, UF e município pelo CNPJ (consulta à Receita Federal via BrasilAPI).
  Future<void> _preencherPeloCnpj() async {
    setState(() => _buscandoCnpj = true);
    try {
      final d = await FeriadosService.consultarCnpj(_cnpj.text);
      setState(() {
        if (_razao.text.trim().isEmpty) _razao.text = d.razao;
        if (_endereco.text.trim().isEmpty) _endereco.text = d.endereco;
        _ufEmp = d.uf;
        _ibgeEmp = d.codIbge;
        _municipioEmp = d.municipio;
      });
      await _carregarMunicipios();
    } catch (e) {
      if (mounted) await mensagem(context, '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _buscandoCnpj = false);
    }
  }

  Future<void> _carregarEmpBanco({bool silencioso = false}) async {
    final e = await Db.instance.getEmpresaPrincipal();
    if (e == null) {
      if (!silencioso && mounted) await mensagem(context, 'Nenhuma empresa ativa encontrada em TB_EMPRESA.');
      return;
    }
    setState(() {
      _razao.text = e.razao;
      _cnpj.text = e.cnpj;
      _endereco.text = e.endereco;
      _ufEmp = e.uf;
      _ibgeEmp = e.codIbge;
      _municipioEmp = e.municipio;
      _docType = onlyDigits(e.cnpj).length == 11 ? 2 : 1;
    });
  }

  ControlIdCompany get _company => ControlIdCompany()
    ..docType = _docType
    ..cpfCnpj = _cnpj.text.trim()
    ..name = _razao.text.trim()
    ..address = _endereco.text.trim()
    ..cei = _cei.text.trim()
    ..cpfResp = _cpfResp.text.trim();

  // ---------------- UI ----------------

  Widget _abaBanco() => ListView(children: [
        Secao('Base de dados do ponto (Firebird 5)', [
          Wrap(spacing: 10, runSpacing: 12, children: [
            Campo('Servidor', _server, largura: 240),
            Campo('Porta', _porta, largura: 100),
            Campo('Usuário', _user, largura: 160),
            Campo('Senha', _pass, largura: 160, senha: true),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Campo('Arquivo da base (.FDB)', _database, largura: 560),
              IconButton(
                  tooltip: 'Escolher arquivo',
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['fdb', 'FDB']);
                    if (r.isNotEmpty && r.first.path != null) setState(() => _database.text = r.first.path!);
                  }),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Campo('Cliente fbclient.dll (64 bits)', _vendor, largura: 560),
              IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['dll']);
                    if (r.isNotEmpty && r.first.path != null) setState(() => _vendor.text = r.first.path!);
                  }),
            ]),
          ]),
          const SizedBox(height: 8),
          const Text(
              'Base exclusiva do ponto. Se o arquivo não existir, ele é criado automaticamente no servidor Firebird 5 '
              r'com todas as tabelas. Use o fbclient.dll de 64 bits (ex.: C:\Program Files\Firebird\Firebird_5_0\fbclient.dll).',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            Btn('Conectar / criar base', Icons.power_rounded, _testarConexao, tonal: true),
            Btn('Salvar', Icons.save, _salvar),
          ]),
        ]),
      ]);

  void _salvarOnlineBackup() {
    _cfg.online
      ..ativo = _onlineAtivo
      ..porta = int.tryParse(_portaOnline.text.trim()) ?? 8080
      ..portaFechadura = int.tryParse(_portaFechadura.text.trim()) ?? 1;
    _cfg.backup
      ..ativo = _backupAtivo
      ..pasta = _backupPasta.text.trim()
      ..manter = int.tryParse(_backupManter.text.trim()) ?? 15;
    _cfg.save();
  }

  Future<void> _servico(Future<String?> Function() acao) async {
    _salvarOnlineBackup();
    final erro = await comProgresso(context, acao, texto: 'Aguardando confirmação de administrador...');
    _app.logTs(erro == null ? '⚙️ Serviço em segundo plano atualizado.' : '❌ $erro', erro != null);
    if (mounted && erro != null) await mensagem(context, erro);
    if (mounted) setState(() {});
  }

  Future<void> _restaurarBackup() async {
    final r = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['fbk'], initialDirectory: BackupService.pasta);
    if (r.isEmpty || r.first.path == null || !mounted) return;
    final fbk = r.first.path!;
    final destino = p.join(p.dirname(_cfg.firebird.database),
        'PONTO_RESTAURADO_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.FDB');
    if (!await confirmar(context,
        'Restaurar ${p.basename(fbk)} em uma NOVA base:\n$destino\n\nA base atual não é alterada. '
        'Depois, se quiser usar a restaurada, aponte o arquivo da base para ela.')) {
      return;
    }
    if (!mounted) return;
    final res = await comProgresso(context, () => BackupService.restaurar(fbk, destino), texto: 'Restaurando backup...');
    if (res == null) return;
    _app.logTs(res.ok ? '♻️ ${res.mensagem}' : '❌ ${res.mensagem}', !res.ok);
    if (mounted) await mensagem(context, res.mensagem);
  }

  Widget _abaColeta() => ListView(children: [
        Secao('Modo online (Control iD iDAccess / iDFace / iDFlex)', [
          const Text(
              'O próprio equipamento envia cada identificação para este computador, que grava a batida na hora e '
              'libera a porta. Configure no equipamento: Modo de operação = Online, servidor = IP deste computador e a porta abaixo.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Campo('Porta do servidor', _portaOnline, largura: 150),
            Campo('Porta (relé) da fechadura', _portaFechadura, largura: 190),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(value: _onlineAtivo, onChanged: (v) => setState(() => _onlineAtivo = v!)),
              const Text('Ativar ao abrir o sistema'),
            ]),
            StatusChip(_app.servidorOnlineAtivo ? '● Servidor online ativo' : '● Parado',
                _app.servidorOnlineAtivo ? AppCores.verde : Colors.blueGrey),
            Btn(_app.servidorOnlineAtivo ? 'Parar' : 'Iniciar agora', _app.servidorOnlineAtivo ? Icons.stop : Icons.play_arrow,
                () async {
              _salvarOnlineBackup();
              _app.servidorOnlineAtivo ? await _app.pararServidorOnline() : await _app.iniciarServidorOnline();
              setState(() {});
            }, tonal: true),
          ]),
        ]),
        Secao('Backup automático da base', [
          Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(value: _backupAtivo, onChanged: (v) => setState(() => _backupAtivo = v!)),
              const Text('Fazer um backup por dia'),
            ]),
            Campo('Pasta dos backups', _backupPasta, largura: 420, dica: BackupService.pastaPadrao),
            Campo('Manter cópias', _backupManter, largura: 130),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Btn('Fazer backup agora', Icons.backup, () async {
              _salvarOnlineBackup();
              final r = await comProgresso(context, BackupService.fazerBackup, texto: 'Gerando backup da base...');
              if (r == null) return;
              _app.logTs(r.ok ? '💾 ${r.mensagem}' : '❌ ${r.mensagem}', !r.ok);
              if (mounted) await mensagem(context, r.mensagem);
              setState(() {});
            }),
            Btn('Abrir pasta', Icons.folder_open, () {
              Directory(BackupService.pasta).createSync(recursive: true);
              Process.start('explorer.exe', [BackupService.pasta]);
            }, tonal: true),
            Btn('Restaurar backup...', Icons.restore, _restaurarBackup, tonal: true),
          ]),
          const SizedBox(height: 6),
          Text(
              BackupService.gbak == null
                  ? '⚠️ gbak.exe não encontrado: instale as ferramentas do Firebird 5 para habilitar o backup.'
                  : 'Último backup: ${BackupService.copias().isEmpty ? 'nenhum' : p.basename(BackupService.copias().first.path)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
        Secao('Serviço em segundo plano', [
          const Text(
              'Instala o GoUpPontoServico no Windows: a coleta automática, o modo online e o backup continuam funcionando '
              'mesmo com o sistema fechado ou sem ninguém logado. Pede confirmação de administrador.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          FutureBuilder<List<bool>>(
            future: Future.wait([ServicoWindows.instalado(), ServicoWindows.emExecucao()]),
            builder: (context, s) {
              final inst = s.data?[0] ?? false, exec = s.data?[1] ?? false;
              return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                StatusChip(
                    !ServicoWindows.disponivel
                        ? 'Serviço não incluído nesta instalação'
                        : (inst ? (exec ? '● Instalado e em execução' : '● Instalado (parado)') : '● Não instalado'),
                    inst && exec ? AppCores.verde : Colors.blueGrey),
                if (!inst)
                  Btn('Instalar serviço', Icons.settings_applications, ServicoWindows.disponivel ? () => _servico(ServicoWindows.instalar) : null),
                if (inst) ...[
                  Btn('Reiniciar', Icons.restart_alt, () => _servico(ServicoWindows.reiniciar), tonal: true),
                  Btn('Remover', Icons.delete, () => _servico(ServicoWindows.remover), cor: Colors.red.shade700),
                ],
              ]);
            },
          ),
        ]),
        Secao('Coleta automática (Control iD)', [
          Campo('Intervalo de coleta (segundos)', _intervalo, largura: 240),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Iniciar coleta automática ao abrir o sistema'),
              value: _autoIniciar,
              onChanged: (v) => setState(() => _autoIniciar = v!)),
        ]),
        Secao('Atualização do sistema', [
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Atualizar automaticamente quando houver nova versão no GitHub'),
              value: _autoAtualizar,
              onChanged: (v) => setState(() => _autoAtualizar = v!)),
          Wrap(spacing: 8, children: [
            Btn('Verificar agora', Icons.system_update, () async {
              await _app.checarAtualizacao();
              if (mounted && _app.atualizacao == null) await mensagem(context, 'O sistema está atualizado.');
            }, tonal: true),
            Btn('Salvar', Icons.save, _salvar),
          ]),
        ]),
      ]);

  Widget _abaRelogio() => ListView(children: [
        Secao('Tipo de relógio de ponto', [
          RadioGroup<TipoRelogio>(
            groupValue: _tipo,
            onChanged: (v) {
              setState(() => _tipo = v!);
              if (v == TipoRelogio.hamsterDx) _verificarRequisitos();
            },
            child: Column(children: [
              for (final t in TipoRelogio.values)
                RadioListTile<TipoRelogio>(
                    contentPadding: EdgeInsets.zero, value: t, title: Text(tipoRelogioDescricao(t))),
            ]),
          ),
        ]),
        if (_tipo == TipoRelogio.hamsterDx)
          Secao('Leitor Nitgen Hamster DX', [
            Wrap(spacing: 10, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<int>(
                  initialValue: _nivel,
                  decoration:
                      const InputDecoration(labelText: 'Nível de segurança', isDense: true),
                  items: [
                    for (var i = 1; i <= 9; i++)
                      DropdownMenuItem(
                          value: i, child: Text('$i${i == 1 ? ' (tolerante)' : i == 9 ? ' (rigoroso)' : i == 5 ? ' (padrão)' : ''}'))
                  ],
                  onChanged: (v) => setState(() => _nivel = v!),
                ),
              ),
              Campo('Intervalo mínimo entre batidas (min)', _intervaloBatida, largura: 280),
            ]),
            CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Abrir o Terminal de Ponto ao iniciar o sistema'),
                value: _abrirTerminal,
                onChanged: (v) => setState(() => _abrirTerminal = v!)),
            CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Imprimir o comprovante de registro a cada batida (impressora padrão do Windows)'),
                subtitle: const Text(r'Portaria 671, art. 82. O comprovante também fica salvo em Documentos\Go Up Ponto\Comprovantes.'),
                value: _imprimirComprovante,
                onChanged: (v) => setState(() => _imprimirComprovante = v!)),
            Text(_requisitos),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              Btn('Verificar requisitos', Icons.checklist, _verificarRequisitos, tonal: true),
              Btn('Testar leitor', Icons.fingerprint, () async {
                final r = await comProgresso(context, HamsterDx.testarLeitor, texto: 'Abrindo o leitor...');
                if (mounted && r != null) await mensagem(context, r.ok ? '✅ Leitor Hamster DX conectado e pronto!' : r.erro);
              }, tonal: true),
            ]),
            const SizedBox(height: 8),
            const Text('Pré-requisitos: driver do Hamster DX e SDK Nitgen eNBSP (32 bits). Coloque o NBSP2Por.dll na pasta '
                'do executável para o assistente de cadastro em português.',
                style: TextStyle(fontSize: 12)),
          ]),
        Btn('Salvar', Icons.save, _salvar),
      ]);

  Widget _abaEmpregador() => ListView(children: [
        Secao('Dados do empregador (Portaria 671 / 1510)', [
          Wrap(spacing: 10, runSpacing: 12, children: [
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<int>(
                initialValue: _docType,
                decoration: const InputDecoration(labelText: 'Documento', isDense: true),
                items: const [DropdownMenuItem(value: 1, child: Text('CNPJ')), DropdownMenuItem(value: 2, child: Text('CPF'))],
                onChanged: (v) => setState(() => _docType = v!),
              ),
            ),
            Campo('CNPJ / CPF', _cnpj, largura: 200),
            Campo('Razão social', _razao, largura: 400),
            Campo('Endereço', _endereco, largura: 560),
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                initialValue: FeriadosService.listaUfs.contains(_ufEmp) ? _ufEmp : null,
                decoration: const InputDecoration(labelText: 'UF'),
                items: [for (final u in FeriadosService.listaUfs) DropdownMenuItem(value: u, child: Text(u))],
                onChanged: (v) {
                  setState(() {
                    _ufEmp = v ?? '';
                    _ibgeEmp = 0;
                    _municipioEmp = '';
                    _municipios = [];
                  });
                  _carregarMunicipios();
                },
              ),
            ),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _municipios.any((m) => m.codigo == _ibgeEmp) ? _ibgeEmp : null,
                decoration: InputDecoration(
                    labelText: 'Município', helperText: _ibgeEmp > 0 && _municipios.isEmpty ? _municipioEmp : null),
                items: [for (final m in _municipios) DropdownMenuItem(value: m.codigo, child: Text(m.nome))],
                onChanged: (v) => setState(() {
                  _ibgeEmp = v ?? 0;
                  _municipioEmp = _municipios.firstWhere((m) => m.codigo == v).nome;
                }),
              ),
            ),
            Campo('CEI', _cei, largura: 180),
            Campo('CPF do responsável', _cpfResp, largura: 180),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Btn(_buscandoCnpj ? 'Consultando...' : 'Preencher pelo CNPJ', Icons.travel_explore, _buscandoCnpj ? null : _preencherPeloCnpj,
                tonal: true),
            Btn('Carregar do Banco', Icons.download, () => _carregarEmpBanco(), tonal: true),
            Btn('Salvar no Banco', Icons.save, () async {
              final ok = await Db.instance.salvarEmpresaPrincipal(_razao.text.trim(), _cnpj.text.trim(), _endereco.text.trim(),
                  uf: _ufEmp, codIbge: _ibgeEmp, municipio: _municipioEmp);
              if (ok && (_ufEmp.isNotEmpty || _ibgeEmp > 0)) {
                // UF/município podem ter mudado: refaz os feriados estaduais e municipais em segundo plano
                () async {
                  for (final ano in [DateTime.now().year, DateTime.now().year + 1]) {
                    try {
                      await FeriadosService.importar(ano, uf: _ufEmp, codIbge: _ibgeEmp);
                    } catch (_) {}
                  }
                  _app.logTs('📅 Feriados de $_municipioEmp/$_ufEmp atualizados.');
                  _app.dadosAlterados();
                }();
              }
              _app.logTs(ok ? '💾 Dados do empregador salvos no banco.' : '❌ Nenhuma empresa encontrada em TB_EMPRESA.', !ok);
              await _app.atualizarEmpregador();
              if (mounted) await mensagem(context, ok ? 'Empregador salvo com sucesso!' : 'Não foi possível salvar o empregador.');
            }),
          ]),
        ]),
        if (!_cfg.modoHamsterDx)
          Secao('Empregador no relógio', [
            SizedBox(
              width: 400,
              child: DropdownButtonFormField<int>(
                initialValue: _relogioEmp > 0 ? _relogioEmp : null,
                decoration: const InputDecoration(labelText: 'Relógio', isDense: true),
                items: [
                  for (final r in _relogios) DropdownMenuItem(value: asInt(r['PRE_ID']), child: Text(asStr(r['PRE_NOME'])))
                ],
                onChanged: (v) => setState(() => _relogioEmp = v ?? 0),
              ),
            ),
            if (_relogios.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Nenhum relógio ativo cadastrado. Ao enviar, o sistema procura o relógio na rede.',
                    style: TextStyle(fontSize: 12, color: AppCores.laranja)),
              ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              Btn('Enviar ao Relógio', Icons.upload, _enviarEmpregador, cor: Colors.green.shade700),
              Btn('Ler do Relógio', Icons.search, _lerEmpregador, tonal: true),
            ]),
          ]),
      ]);

  /// Garante um relógio para o empregador: recarrega a lista e, se não houver nenhum
  /// cadastrado, procura na rede e cadastra o encontrado.
  Future<int?> _relogioParaEmpregador() async {
    final rel = await Db.instance.getRelogios(apenasAtivos: true);
    setState(() {
      _relogios = rel;
      if (!rel.any((r) => asInt(r['PRE_ID']) == _relogioEmp)) _relogioEmp = rel.isEmpty ? 0 : asInt(rel.first['PRE_ID']);
    });
    if (_relogioEmp > 0) return _relogioEmp;
    if (!mounted) return null;
    final achado = await procurarRelogios(context);
    if (achado == null) return null;
    final id = await Db.instance.salvarRelogio(0, achado.serial.isNotEmpty ? 'Relógio ${achado.serial}' : 'Relógio ${achado.ip}',
        achado.ip, achado.porta, achado.ssl, 'admin', 'admin', 'IDCLASS', achado.modelo.startsWith('REP') ? 'AFD_671' : 'API', true);
    _app.logTs('📡 Relógio ${achado.ip}:${achado.porta} cadastrado automaticamente (ID $id).');
    _app.dadosAlterados();
    await _carregarDados();
    setState(() => _relogioEmp = id);
    return id;
  }

  Future<void> _enviarEmpregador() async {
    final doc = onlyDigits(_cnpj.text);
    if (_razao.text.trim().isEmpty) return mensagem(context, 'Informe a razão social do empregador.');
    if ((_docType == 1 && doc.length != 14) || (_docType == 2 && doc.length != 11)) {
      return mensagem(context, _docType == 1 ? 'Informe um CNPJ com 14 dígitos.' : 'Informe um CPF com 11 dígitos.');
    }
    final id = await _relogioParaEmpregador();
    if (id == null || !mounted) return;
    final ok = await comProgresso(context, () => _app.ponto.enviarEmpregador(id, _company),
        texto: 'Enviando empregador ao relógio...');
    if (!mounted) return;
    await mensagem(
        context,
        ok == true
            ? '✅ Empregador "${_razao.text.trim()}" gravado no relógio com sucesso!'
            : '❌ O relógio não aceitou o empregador.\n\n${_ultimoErroLog()}');
  }

  Future<void> _lerEmpregador() async {
    final id = await _relogioParaEmpregador();
    if (id == null || !mounted) return;
    final c = await comProgresso(context, () => _app.ponto.obterEmpregador(id), texto: 'Lendo empregador do relógio...');
    if (!mounted) return;
    if (c == null) return mensagem(context, '❌ Não foi possível ler o empregador.\n\n${_ultimoErroLog()}');
    if (onlyDigits(c.cpfCnpj).replaceAll('0', '').isEmpty && c.name.isEmpty) {
      return mensagem(context, 'O relógio ainda não tem empregador cadastrado.');
    }
    setState(() {
      _docType = c.docType;
      _cnpj.text = c.cpfCnpj;
      _razao.text = c.name;
      _endereco.text = c.address;
      _cei.text = c.cei == '0' ? '' : c.cei;
      _cpfResp.text = c.cpfResp == '0' ? '' : c.cpfResp;
    });
  }

  String _ultimoErroLog() {
    final erros = _app.logs.where((l) => l.erro);
    return erros.isEmpty ? 'Veja o log de eventos para detalhes.' : erros.last.texto.replaceFirst(RegExp(r'^\[[\d:]+\] '), '');
  }

  Widget _abaVersoes() {
    final q = _buscaVersao.text.trim().toLowerCase();
    final itens = q.isEmpty
        ? _versoes
        : _versoes
            .where((v) => v.descricao.toLowerCase().contains(q) || v.acao.toLowerCase().contains(q) || '${v.numero}' == q)
            .toList();
    final s = _versaoSel;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _buscaVersao,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Pesquisar versão', isDense: true),
          ),
        ),
        const SizedBox(width: 8),
        Btn('Atualizar Estrutura', Icons.build, () async {
          final log = await comProgresso(context, Db.instance.verificarEAtualizarEstruturaBanco,
              texto: 'Verificando estrutura do banco...');
          if (log != null) _app.logTs('🛠️ $log');
          await _carregarDados();
        }, tonal: true),
      ]),
      const SizedBox(height: 8),
      Expanded(
        flex: 2,
        child: DataGrid<VersaoBdItem>(
          itens: itens,
          selecionado: s,
          onSelect: (v) => setState(() => _versaoSel = v),
          colunas: [
            GridCol('Status', 70, (v) => v.status == 'A' ? '✅ OK' : (v.status == 'E' ? '❌ Erro' : '⏳'),
                cor: (v) => v.status == 'A' ? Colors.green : Colors.red),
            GridCol('Código', 60, (v) => '${v.numero}'),
            GridCol('Versão', 70, (v) => v.sistema),
            GridCol('Data/Hora', 140, (v) => fmtDataHora(v.dataHora)),
            GridCol('Ação', 110, (v) => v.acao),
            GridCol('Descrição', 300, (v) => v.descricao, flex: true),
          ],
        ),
      ),
      const SizedBox(height: 8),
      if (s != null)
        Expanded(
          flex: 2,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final e in {'Script': s.script, 'Progresso': s.progresso, 'Erros': s.erros}.entries)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Divider(),
                      Expanded(
                          child: SingleChildScrollView(
                              child: SelectableText(e.value,
                                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 12)))),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.somenteBanco) return _abaBanco();
    return DefaultTabController(
      length: 6,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHeader('Configurações', Icons.settings_outlined),
        const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
          Tab(icon: Icon(Icons.storage), text: 'Banco de Dados'),
          Tab(icon: Icon(Icons.sync), text: 'Coleta e Atualização'),
          Tab(icon: Icon(Icons.fingerprint), text: 'Relógio de Ponto'),
          Tab(icon: Icon(Icons.business), text: 'Empregador'),
          Tab(icon: Icon(Icons.history), text: 'Controle de Versão'),
          Tab(icon: Icon(Icons.manage_accounts), text: 'Usuários'),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
              children: [_abaBanco(), _abaColeta(), _abaRelogio(), _abaEmpregador(), _abaVersoes(), const UsuariosTab()]),
        ),
      ]),
    );
  }
}
