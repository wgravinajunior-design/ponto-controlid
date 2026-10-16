import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/build_info.dart';
import '../core/config.dart';
import '../core/util.dart';
import '../data/database.dart';
import 'app_state.dart';
import 'pages/colaboradores_page.dart';
import 'login_page.dart';
import 'pages/banco_horas_page.dart';
import 'pages/config_page.dart';
import 'pages/contabilidade_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/espelho_page.dart';
import 'pages/feriados_page.dart';
import 'pages/horarios_page.dart';
import 'pages/justificativas_page.dart';
import 'pages/marcacoes_page.dart';
import 'pages/relogios_page.dart';
import 'terminal_page.dart';
import 'theme.dart';
import '../services/update_service.dart';
import 'update_dialog.dart';

class _Pagina {
  final String titulo;
  final IconData icone;
  final Widget Function() criar;
  _Pagina(this.titulo, this.icone, this.criar);
}

/// Janela principal (port de TfrmMain): navegação lateral, cabeçalho, log e rodapé.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _app = AppState.instance;
  int _idx = 0;
  bool _logAberto = false;
  int _geracao = 0; // recria as páginas quando o modo do relógio muda

  bool get _hamster => AppConfig.instance.modoHamsterDx;

  List<_Pagina> get _paginas => [
        _Pagina('Painel', Icons.dashboard_outlined, () => const DashboardPage()),
        if (!_hamster) _Pagina('Relógios', Icons.access_time, () => const RelogiosPage()),
        _Pagina('Colaboradores', Icons.groups_outlined, () => const ColaboradoresPage()),
        _Pagina('Marcações', Icons.fact_check_outlined, () => const MarcacoesPage()),
        _Pagina('Horários', Icons.schedule, () => const HorariosPage()),
        _Pagina('Espelho', Icons.table_chart_outlined, () => const EspelhoPage()),
        _Pagina('Justificativas', Icons.note_alt_rounded, () => const JustificativasPage()),
        _Pagina('Feriados', Icons.event_rounded, () => const FeriadosPage()),
        _Pagina('Banco de Horas', Icons.savings_rounded, () => const BancoHorasPage()),
        if (_app.isAdmin) _Pagina('Contabilidade', Icons.account_balance_rounded, () => const ContabilidadePage()),
        if (_app.isAdmin) _Pagina('Configurações', Icons.settings_outlined, () => ConfigPage(onModoAlterado: _modoAlterado)),
      ];

  @override
  void initState() {
    super.initState();
    _app.ofertaAtualizacao.addListener(_ofertaAtualizacao);
    _app.iniciar().then((_) {
      if (mounted) _mostrarNovidades();
      if (mounted && _hamster && AppConfig.instance.relogio.abrirTerminalAoIniciar && _app.conectado) _abrirTerminal();
    });
  }

  @override
  void dispose() {
    _app.ofertaAtualizacao.removeListener(_ofertaAtualizacao);
    super.dispose();
  }

  void _ofertaAtualizacao() {
    final info = _app.ofertaAtualizacao.value;
    if (info != null && mounted) mostrarAtualizacao(context, info, automatico: true);
  }

  void _modoAlterado() => setState(() {
        _geracao++;
        _idx = _paginas.length - 1; // continua em Configurações
      });

  void _abrirTerminal() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TerminalPage(), fullscreenDialog: true));

  Future<void> _salvarLog() async {
    await FilePicker.saveFile(
        dialogTitle: 'Salvar log',
        fileName: 'log_ponto_${fmtData(DateTime.now()).replaceAll('/', '')}.txt',
        bytes: Uint8List.fromList(utf8.encode(_app.logs.map((l) => l.texto).join('\r\n'))));
  }

  @override
  Widget build(BuildContext context) {
    final paginas = _paginas;
    if (_idx >= paginas.length) _idx = 0;
    final atual = paginas[_idx];
    return ListenableBuilder(
      listenable: _app,
      builder: (context, _) => Scaffold(
        body: Row(children: [
          _sidebar(paginas),
          Expanded(
            child: Column(children: [
              _topo(atual),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: _app.conectado || atual.titulo == 'Configurações'
                      ? KeyedSubtree(key: ValueKey('$_geracao-${atual.titulo}'), child: atual.criar())
                      : _semConexao(paginas),
                ),
              ),
              _painelLog(Theme.of(context).colorScheme),
              _rodape(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sidebar(List<_Pagina> paginas) => Container(
        width: 232,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppCores.sidebar, AppCores.sidebar2])),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            child: Row(children: [
              Image.asset('assets/logo.png', width: 46, height: 46, filterQuality: FilterQuality.high),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Go Up ', style: TextStyle(color: Color(0xFF60A5FA))),
                      TextSpan(text: 'Ponto', style: TextStyle(color: Colors.white)),
                    ]),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.3),
                  ),
                  Text('Controle de ponto eletrônico', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              for (var i = 0; i < paginas.length; i++) _itemMenu(paginas[i], i == _idx, () => setState(() => _idx = i)),
            ]),
          ),
          if (_hamster)
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppCores.verde),
                  onPressed: _app.conectado ? _abrirTerminal : null,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Terminal de Ponto'),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppCores.azul,
                child: Text(_app.usuarioNome.isEmpty ? '?' : _app.usuarioNome[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_app.usuarioNome, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(_app.isAdmin ? 'Administrador' : 'Operador', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
              IconButton(
                tooltip: 'Sair',
                icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                onPressed: () {
                  _app.logTs('🔒 Usuário ${Db.instance.usuarioLogado} saiu do sistema.');
                  Db.instance.usuarioLogado = 'sistema';
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
                },
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(versaoCompleta(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        ]),
      );

  Widget _itemMenu(_Pagina p, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: sel ? Colors.white.withValues(alpha: .10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Icon(p.icone, size: 20, color: sel ? const Color(0xFF60A5FA) : Colors.white60),
                const SizedBox(width: 14),
                Text(p.titulo,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.white70, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                if (sel) ...[
                  const Spacer(),
                  Container(
                      width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF60A5FA), shape: BoxShape.circle)),
                ],
              ]),
            ),
          ),
        ),
      );

  Widget _topo(_Pagina atual) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(children: [
          Text(atual.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const Spacer(),
          if (_app.atualizacao != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppCores.laranja),
                onPressed: () => mostrarAtualizacao(context, _app.atualizacao!),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text('Nova versão v${_app.atualizacao!.latestVersion}'),
              ),
            ),
          StatusChip(_app.conectado ? '● ${Db.instance.nomeBanco} conectado' : '● Sem conexão',
              _app.conectado ? AppCores.verde : AppCores.vermelho),
          if (!_hamster) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: _app.autoColetaAtiva ? 'Clique para parar a coleta automática' : 'Clique para iniciar a coleta automática',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _app.alternarAutoColeta,
                child: StatusChip(_app.autoColetaAtiva ? '⏱ Coleta automática ativa' : '⏸ Coleta parada - clique para iniciar',
                    _app.autoColetaAtiva ? AppCores.azul : AppCores.laranja),
              ),
            ),
          ],
        ]),
      );

  Widget _semConexao(List<_Pagina> paginas) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: AppCores.vermelho),
              const SizedBox(height: 12),
              Text(_app.statusMsg, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: () => setState(() => _idx = paginas.length - 1),
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Abrir configurações do banco')),
            ]),
          ),
        ),
      );

  Widget _rodape() => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(children: [
          Text(_app.statusMsg, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(width: 16),
          if (!_hamster) Text(_app.statusColeta, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const Spacer(),
          if (_app.empregadorRodape.isNotEmpty)
            Text('🏢 ${_app.empregadorRodape}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(width: 16),
          _statusAtualizacao(),
        ]),
      );

  /// Rodapé: "Atualização disponível" (clique para atualizar) ou "Sistema atualizado" (clique para verificar).
  Widget _statusAtualizacao() {
    final u = _app.atualizacao;
    if (u != null) {
      return Tooltip(
        message: 'Clique para ver as novidades e atualizar',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => mostrarAtualizacao(context, u),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppCores.laranja, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.system_update_alt_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text('Atualização disponível: ${u.descricao}  •  clique para atualizar',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
    }
    final quando = _app.ultimaChecagem == null ? '' : ' (verificado às ${fmtHora(_app.ultimaChecagem)})';
    return Tooltip(
      message: 'Clique para verificar agora',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _app.checandoAtualizacao ? null : _verificarAgora,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_app.checandoAtualizacao)
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 6),
            Text(_app.checandoAtualizacao ? 'Verificando atualizações...' : '${versaoCompleta()} - sistema atualizado$quando',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ]),
        ),
      ),
    );
  }

  Future<void> _verificarAgora() async {
    await _app.checarAtualizacao();
    if (mounted && _app.atualizacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O sistema já está na versão mais recente.')));
    }
  }

  /// Primeira abertura após atualizar: mostra o que veio de novo nesta versão.
  Future<void> _mostrarNovidades() async {
    final n = await UpdateService.novidadesDaVersaoAtual();
    if (n != null && mounted) await mostrarNovidades(context, n);
  }

  Widget _painelLog(ColorScheme cs) => Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant))),
        child: Column(children: [
          Row(children: [
            const SizedBox(width: 12),
            const Icon(Icons.terminal, size: 16),
            const SizedBox(width: 6),
            const Text('Log de eventos', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(tooltip: 'Salvar log', icon: const Icon(Icons.save_alt, size: 18), onPressed: _salvarLog),
            IconButton(tooltip: 'Limpar log', icon: const Icon(Icons.delete_sweep, size: 18), onPressed: _app.limparLog),
            IconButton(
                tooltip: _logAberto ? 'Recolher' : 'Expandir',
                icon: Icon(_logAberto ? Icons.expand_more : Icons.expand_less, size: 18),
                onPressed: () => setState(() => _logAberto = !_logAberto)),
          ]),
          if (_logAberto)
            Container(
              height: 160,
              width: double.infinity,
              color: const Color(0xFF1E1E1E),
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: _app.logs.length,
                itemBuilder: (_, i) {
                  final l = _app.logs[_app.logs.length - 1 - i];
                  return SelectableText(l.texto,
                      style: TextStyle(
                          fontFamily: 'Consolas', fontSize: 12, color: l.erro ? Colors.redAccent : Colors.greenAccent));
                },
              ),
            ),
        ]),
      );
}
