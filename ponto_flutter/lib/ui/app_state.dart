import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/util.dart';
import '../data/database.dart';
import '../services/backup_service.dart';
import '../services/feriados_service.dart';
import '../services/log_service.dart';
import '../services/ponto_service.dart';
import '../services/servidor_online.dart';
import '../services/update_service.dart';

class LogItem {
  final String texto;
  final bool erro;
  LogItem(this.texto, this.erro);
}

/// Estado global do aplicativo: log, conexão, coleta automática e atualizações.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final logs = <LogItem>[];
  late final PontoService ponto = PontoService(log);

  bool conectado = false;

  // Usuário logado
  int usuarioId = 0;
  String usuarioNome = '';
  String perfil = 'OPERADOR';
  bool get isAdmin => perfil == 'ADMIN';
  bool _iniciado = false;
  String statusMsg = 'Iniciando...';
  String empregadorRodape = '';

  Timer? _tmrColeta;
  bool _coletando = false;
  bool get autoColetaAtiva => _tmrColeta != null;
  String statusColeta = 'Coleta automática parada';

  Timer? _tmrUpdate;
  UpdateInfo? atualizacao;
  String _ultimaOferecida = '';
  /// Disparado quando há atualização a ser oferecida automaticamente.
  final ofertaAtualizacao = ValueNotifier<UpdateInfo?>(null);

  /// Incrementado sempre que os dados do banco mudam (telas recarregam).
  final versaoDados = ValueNotifier<int>(0);
  void dadosAlterados() => versaoDados.value++;

  void log(String msg, [bool erro = false]) {
    logs.add(LogItem(msg, erro));
    LogService.gravar(msg, erro: erro);
    if (logs.length > 2000) logs.removeRange(0, logs.length - 2000);
    notifyListeners();
  }

  void logTs(String msg, [bool erro = false]) => log('[${fmtHoraSeg(DateTime.now())}] $msg', erro);

  void limparLog() {
    logs.clear();
    notifyListeners();
  }

  void setStatus(String s) {
    statusMsg = s;
    notifyListeners();
  }

  Future<void> iniciar() async {
    final cfg = AppConfig.instance;
    logTs('🚀 Go Up Ponto iniciado. Configuração: ${cfg.iniPath}');
    setStatus('Conectando ao banco de dados...');
    // A tela de login já conecta e migra a base; aqui só reconecta se necessário
    conectado = Db.instance.isConectado || await Db.instance.conectar();
    if (_iniciado) {
      dadosAlterados();
      return;
    }
    _iniciado = true;
    if (conectado) {
      logTs('🗄️ Conectado ao Firebird: ${cfg.firebird.server}:${cfg.firebird.port}/${cfg.firebird.database}');
      if (Db.instance.lastMigracaoLog.isNotEmpty) logTs('🛠️ ${Db.instance.lastMigracaoLog}');
      setStatus('Conectado ao banco de dados');
      await atualizarEmpregador();
      if (cfg.controlId.autoIniciarColeta && !cfg.modoHamsterDx) iniciarAutoColeta();
      if (cfg.online.ativo) await iniciarServidorOnline();
      BackupService.backupDiario(onLog: logTs);
      // Feriados estaduais e municipais do ano (segundo plano, só se a empresa tem UF/município e ainda não foram baixados)
      FeriadosService.atualizarAutomatico().then((r) {
        if (r != null) {
          logTs('📅 Feriados atualizados: ${r.estaduais} estaduais e ${r.municipais} municipais.');
          dadosAlterados();
        }
      });
    } else {
      logTs('❌ ${Db.instance.lastError}', true);
      setStatus('Sem conexão com o banco de dados');
    }
    dadosAlterados();
    checarAtualizacao();
    _tmrUpdate = Timer.periodic(Duration(minutes: cfg.atualizacao.intervaloVerificacaoMin), (_) => checarAtualizacao());
  }

  Future<void> atualizarEmpregador() async {
    try {
      final e = await Db.instance.getEmpresaPrincipal();
      empregadorRodape = e == null ? '' : '${e.razao}  •  CNPJ ${formatarDoc(e.cnpj)}';
    } catch (_) {
      empregadorRodape = '';
    }
    notifyListeners();
  }

  // ---------------- Modo online ----------------

  ServidorOnline? _online;
  bool get servidorOnlineAtivo => _online?.ativo ?? false;

  Future<void> iniciarServidorOnline() async {
    await pararServidorOnline();
    final c = AppConfig.instance.online;
    try {
      _online = ServidorOnline(
          porta: c.porta,
          portaFechadura: c.portaFechadura,
          onLog: (m, e) {
            log(m, e);
            dadosAlterados();
          });
      await _online!.iniciar();
    } catch (e) {
      _online = null;
      logTs('❌ Não foi possível iniciar o servidor online na porta ${c.porta}: $e', true);
    }
    notifyListeners();
  }

  Future<void> pararServidorOnline() async {
    await _online?.parar();
    _online = null;
    notifyListeners();
  }

  // ---------------- Coleta automática ----------------

  /// Liga/desliga a coleta automática e lembra a escolha para as próximas aberturas.
  void alternarAutoColeta() {
    final ligar = !autoColetaAtiva;
    AppConfig.instance.controlId.autoIniciarColeta = ligar;
    AppConfig.instance.save();
    ligar ? iniciarAutoColeta() : pararAutoColeta();
  }

  void iniciarAutoColeta() {
    pararAutoColeta(silencioso: true);
    var seg = AppConfig.instance.controlId.intervaloColetaSegundos;
    if (seg < 10) seg = 10;
    _tmrColeta = Timer.periodic(Duration(seconds: seg), (_) => coletarAgora(automatico: true));
    statusColeta = 'Coleta automática ativa (a cada ${seg}s)';
    logTs('▶️ Coleta automática iniciada: intervalo de $seg segundos.');
    notifyListeners();
    coletarAgora(automatico: true);
  }

  void pararAutoColeta({bool silencioso = false}) {
    if (_tmrColeta == null) return;
    _tmrColeta?.cancel();
    _tmrColeta = null;
    statusColeta = 'Coleta automática parada';
    if (!silencioso) logTs('⏸️ Coleta automática interrompida.');
    notifyListeners();
  }

  Future<void> coletarAgora({bool automatico = false}) async {
    if (_coletando) return;
    _coletando = true;
    try {
      final r = await ponto.coletarTodosRelogios();
      if (r.total > 0) dadosAlterados();
      if (automatico) statusColeta = 'Coleta automática ativa • última: ${fmtHoraSeg(DateTime.now())}';
    } catch (e) {
      logTs('❌ Erro na coleta: $e', true);
    } finally {
      _coletando = false;
      notifyListeners();
    }
  }

  // ---------------- Atualização ----------------

  /// Estado exibido no rodapé: quando foi a última consulta e se uma consulta está em andamento.
  DateTime? ultimaChecagem;
  bool checandoAtualizacao = false;

  Future<void> checarAtualizacao() async {
    checandoAtualizacao = true;
    notifyListeners();
    final info = await UpdateService.checarAtualizacao();
    checandoAtualizacao = false;
    ultimaChecagem = DateTime.now();
    atualizacao = info;
    notifyListeners();
    if (info == null) return;
    final chave = '${info.latestVersion}.${info.latestBuild}';
    if (AppConfig.instance.atualizacao.autoAtualizar && _ultimaOferecida != chave) {
      _ultimaOferecida = chave;
      logTs('🔔 Nova atualização ${info.descricao} encontrada no GitHub. Iniciando atualização automática...');
      ofertaAtualizacao.value = info;
    } else {
      logTs('🔔 Nova atualização do sistema disponível: ${info.descricao}! Clique no botão superior para atualizar.');
    }
  }

  @override
  void dispose() {
    _tmrColeta?.cancel();
    _tmrUpdate?.cancel();
    super.dispose();
  }
}
