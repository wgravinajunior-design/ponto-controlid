import 'dart:convert';

import '../core/util.dart';
import '../data/database.dart';
import 'controlid_client.dart';
import 'descoberta_service.dart';

typedef LogCallback = void Function(String msg, bool isError);

/// Orquestra a comunicação relógio <-> banco (port de TPontoService).
class PontoService {
  final LogCallback? onLog;
  PontoService([this.onLog]);

  Db get _db => Db.instance;

  void _log(String msg, [bool isError = false]) => onLog?.call('[${fmtHoraSeg(DateTime.now())}] $msg', isError);

  ControlIdClient _cliente(DbRow r) {
    var porta = asInt(r['PRE_PORTA']);
    if (porta <= 0) porta = 80;
    return ControlIdClient(
        host: asStr(r['PRE_IP']), port: porta, useSsl: asStr(r['PRE_USAR_SSL']).toUpperCase() == 'S')
      ..user = asStr(r['PRE_USUARIO'])
      ..password = asStr(r['PRE_SENHA'])
      ..portaria671 = asStr(r['PRE_MODO_COLETA']).toUpperCase() == 'AFD_671';
  }

  /// Abre relógio + sessão; executa [acao] e faz logout.
  Future<T?> _comRelogio<T>(int relogioId, String falhaLogin, Future<T?> Function(ControlIdClient c, String nome, DbRow r) acao) async {
    final r = await _db.getRelogioPorId(relogioId);
    if (r == null) {
      _log('❌ Relógio #$relogioId não encontrado no banco de dados.', true);
      return null;
    }
    final nome = asStr(r['PRE_NOME']);
    var c = _cliente(r);
    if (!await c.login(c.user, c.password)) {
      // Sem resposta no IP cadastrado: o relógio pode ter recebido outro IP (DHCP)
      final novo = c.lastError.startsWith('Falha de comunicação') ? await _relocalizar(relogioId, r) : null;
      if (novo == null) {
        _log('❌ $falhaLogin [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
        return null;
      }
      c = novo;
    }
    try {
      return await acao(c, nome, r);
    } finally {
      await c.logout();
    }
  }

  // Evita varrer a rede a cada coleta automática quando o relógio está desligado
  static final _ultimaBusca = <int, DateTime>{};

  /// Procura na rede o relógio pelo número de série e atualiza o IP cadastrado.
  Future<ControlIdClient?> _relocalizar(int relogioId, DbRow r) async {
    final serial = asStr(r['PRE_SERIAL']).trim();
    final nome = asStr(r['PRE_NOME']);
    if (serial.isEmpty) return null;
    final ultima = _ultimaBusca[relogioId];
    if (ultima != null && DateTime.now().difference(ultima) < const Duration(minutes: 10)) return null;
    _ultimaBusca[relogioId] = DateTime.now();

    _log('📡 [$nome] não respondeu em ${asStr(r['PRE_IP'])}. Procurando o relógio (série $serial) na rede...');
    RelogioEncontrado? achado;
    await DescobertaService.procurar(
      usuario: asStr(r['PRE_USUARIO']),
      senha: asStr(r['PRE_SENHA']),
      onEncontrado: (e) {
        if (e.serial == serial) achado = e;
      },
      cancelado: () => achado != null,
    );
    final a = achado;
    if (a == null) {
      _log('⚠️ Relógio [$nome] (série $serial) não foi encontrado na rede.', true);
      return null;
    }
    await _db.atualizarEnderecoRelogio(relogioId, a.ip, a.porta, a.ssl);
    _log('✅ Relógio [$nome] reconhecido automaticamente no novo endereço ${a.ip}:${a.porta}. Cadastro atualizado.');
    final c = ControlIdClient(host: a.ip, port: a.porta, useSsl: a.ssl)
      ..user = asStr(r['PRE_USUARIO'])
      ..password = asStr(r['PRE_SENHA']);
    return await c.login(c.user, c.password) ? c : null;
  }

  Future<bool> testarRelogio(int relogioId) async {
    final r = await _db.getRelogioPorId(relogioId);
    if (r != null) _log('🔍 Testando comunicação com [${asStr(r['PRE_NOME'])}] (${asStr(r['PRE_IP'])}:${asInt(r['PRE_PORTA'])})...');
    return await _comRelogio(relogioId, 'Não foi possível comunicar com o relógio', (c, nome, r) async {
          _log('🔑 Conexão estabelecida com sucesso com o equipamento [$nome]!');
          final info = await c.getSystemInformation();
          if (info == null) {
            _log('⚠️ Conexão OK, mas não foi possível ler os dados do sistema em [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
            return false;
          }
          _log('✅ Equipamento [$nome] online e pronto para uso!');
          _log('   📋 Informações: Nº Série: ${info.serial} | Firmware: ${info.fwVersion} | Horário do Relógio: ${fmtDataHora(info.time)}');
          final cont = await c.getInfo();
          if (cont != null && cont['user_count'] != null) {
            _log('   👥 Usuários no relógio: ${cont['user_count']} | Digitais: ${cont['template_count'] ?? 0} | Cartões: ${cont['rfid_count'] ?? 0}');
          }
          await _db.atualizarUltimoLogRelogio(relogioId, asInt(r['PRE_ULTIMO_LOG_ID']), info.serial, info.fwVersion);
          return true;
        }) ??
        false;
  }

  Future<bool> sincronizarHorario(int relogioId) async {
    final agora = DateTime.now();
    return await _comRelogio(relogioId, 'Não foi possível autenticar no relógio', (c, nome, _) async {
          _log('🕒 Sincronizando horário do relógio [$nome] com o computador (${fmtHoraSeg(agora)})...');
          if (await c.setSystemTime(agora)) {
            _log('✅ Horário do relógio [$nome] sincronizado com sucesso para ${fmtDataHora(agora)}!');
            return true;
          }
          _log('❌ Falha ao atualizar o horário em [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
          return false;
        }) ??
        false;
  }

  Future<ControlIdUser?> _montarUsuario(int pessoaId,
      {String senha = '', int rfid = 0, bool admin = false, String barras = '', bool matriculaCompleta = false}) async {
    final p = await _db.getPessoaPorId(pessoaId);
    if (p == null) return null;
    var matricula = asStr(p['COL_CARTAO_PONTO']).trim();
    if (matriculaCompleta) {
      if (matricula.isEmpty) matricula = asStr(p['COL_PIS']).trim();
      if (matricula.isEmpty) matricula = asStr(p['COL_CPF']).trim();
    }
    if (matricula.isEmpty) matricula = '$pessoaId';
    final codAcesso = asStr(p['PES_CODIGO_ACESSO']).trim();
    return ControlIdUser()
      ..id = pessoaId
      ..name = asStr(p['PES_RSOCIAL_NOME']).trim()
      ..cpf = asStr(p['PES_CNPJ_CPF']).trim()
      ..pis = asStr(p['COL_PIS']).trim()
      ..registration = matricula
      ..bars = barras.isNotEmpty ? barras : matricula
      ..rfid = rfid
      ..code = int.tryParse(codAcesso) ?? int.tryParse(matricula) ?? pessoaId
      ..password = senha
      ..admin = admin
      ..templates = _templates(await _db.getBiometriaControlId(pessoaId));
  }

  static List<String> _templates(String json) {
    if (json.trim().isEmpty) return [];
    try {
      return (jsonDecode(json) as List).map((e) => '$e').where((e) => e.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Lê do relógio as digitais cadastradas no próprio equipamento e guarda no banco
  /// (para copiar aos outros relógios). Retorna quantos colaboradores tinham digital.
  Future<int?> lerDigitaisDoRelogio(int relogioId) =>
      _comRelogio(relogioId, 'Não foi possível conectar ao relógio para ler as digitais', (c, nome, _) async {
        final users = await c.getUsers();
        if (users == null) {
          _log('❌ Falha ao ler os usuários de [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
          return null;
        }
        var n = 0, semCadastro = 0;
        for (final u in users.where((u) => u.templates.isNotEmpty)) {
          final pid = await _db.buscarPessoaPorPisOuCpf(u.pis, u.cpf);
          if (pid <= 0) {
            semCadastro++;
            continue;
          }
          await _db.salvarBiometriaControlId(pid, jsonEncode(u.templates));
          n++;
          _log('   👆 ${u.name}: ${u.templates.length} digital(is) lida(s) do relógio.');
        }
        final total = users.fold<int>(0, (s, u) => s + u.templates.length);
        _log(n > 0
            ? '✅ $n colaborador(es) com digitais importadas de [$nome] ($total digital(is)).'
            : 'ℹ️ Nenhuma digital retornada por [$nome]. Cadastre as digitais no relógio (Menu > Usuários > Biometria) e leia novamente.');
        if (semCadastro > 0) _log('⚠️ $semCadastro usuário(s) do relógio sem colaborador correspondente (CPF/PIS).', true);
        return n;
      });

  /// Envia o cadastro (com as digitais guardadas) do colaborador para todos os relógios ativos.
  Future<int> enviarParaTodosRelogios(int pessoaId) async {
    var ok = 0;
    for (final r in await _db.getRelogios(apenasAtivos: true)) {
      if (await enviarColaboradorIndividual(asInt(r['PRE_ID']), pessoaId)) ok++;
    }
    return ok;
  }

  Future<({int sucessos, int falhas})> sincronizarColaboradores(int relogioId, List<int> pessoaIds) async {
    var ok = 0, falhas = 0;
    await _comRelogio(relogioId, 'Não foi possível conectar ao relógio para envio de colaboradores', (c, nome, _) async {
      _log('📤 Enviando ${pessoaIds.length} colaborador(es) para o relógio [$nome]...');
      for (final id in pessoaIds) {
        final u = await _montarUsuario(id, matriculaCompleta: true);
        if (u == null) continue;
        if (await c.addUser(u) != null) {
          await _db.marcarColaboradorSincronizado(id);
          ok++;
          _log('  ✅ [${u.name}] cadastrado com sucesso no relógio (Matrícula: ${u.registration}).');
        } else if (await c.modifyUser(u)) {
          await _db.marcarColaboradorSincronizado(id);
          ok++;
          _log('  🔄 [${u.name}] dados cadastrais atualizados no relógio (Matrícula: ${u.registration}).');
        } else {
          falhas++;
          _log('  ⚠️ Não foi possível cadastrar [${u.name}]: ${formatarErroAmigavel(c.lastError)}', true);
        }
      }
      if (falhas == 0) {
        _log('🎉 Todos os $ok colaboradores foram sincronizados com sucesso no relógio [$nome]!');
      } else {
        _log('🏁 Envio de colaboradores finalizado em [$nome]: $ok enviados com sucesso, $falhas pendência(s).');
      }
      return true;
    });
    return (sucessos: ok, falhas: falhas);
  }

  Future<bool> enviarColaboradorIndividual(int relogioId, int pessoaId,
      {String senha = '', int rfid = 0, bool admin = false, String barras = ''}) async {
    final u = await _montarUsuario(pessoaId, senha: senha, rfid: rfid, admin: admin, barras: barras);
    if (u == null) {
      _log('❌ Colaborador não localizado no banco de dados.', true);
      return false;
    }
    return await _comRelogio(relogioId, 'Não foi possível conectar ao relógio', (c, nome, _) async {
          _log('📤 Enviando cadastro de [${u.name}] para o relógio [$nome]...');
          if (await c.addUser(u) != null || await c.modifyUser(u)) {
            await _db.marcarColaboradorSincronizado(pessoaId);
            _log('✅ Colaborador [${u.name}] sincronizado com sucesso no relógio [$nome] (Matrícula: ${u.registration})!');
            return true;
          }
          _log('❌ Falha ao enviar [${u.name}] para [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
          return false;
        }) ??
        false;
  }

  Future<bool> removerColaboradorDoRelogio(int relogioId, int pessoaId) async {
    final p = await _db.getPessoaPorId(pessoaId);
    return await _comRelogio(relogioId, 'Não foi possível conectar ao relógio', (c, nome, _) async {
          final cpf = int.tryParse(onlyDigits(asStr(p?['PES_CNPJ_CPF'])));
          final pis = int.tryParse(onlyDigits(asStr(p?['COL_PIS'])));
          final delId = (c.portaria671 ? (cpf ?? pis) : (pis ?? cpf)) ?? pessoaId;
          if (await c.destroyUser(delId) || await c.destroyUser(pessoaId)) {
            _log('🗑️ Colaborador (ID $pessoaId) removido com sucesso da memória do relógio [$nome].');
            await _db.marcarColaboradorNaoSincronizado(pessoaId);
            return true;
          }
          _log('❌ Não foi possível remover o colaborador (ID $pessoaId) de [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
          return false;
        }) ??
        false;
  }

  Future<int?> limparTodosColaboradoresDoRelogio(int relogioId) =>
      _comRelogio(relogioId, 'Falha ao autenticar em', (c, nome, _) async {
        _log('🧹 Iniciando limpeza de todos os colaboradores do relógio [$nome]...');
        final n = await c.clearAllUsers() ?? 0;
        if (n > 0) {
          _log('✅ Memória do relógio [$nome] limpa com sucesso! Total de $n colaborador(es) removido(s).');
        } else {
          _log('ℹ️ Não havia colaboradores para remover ou memória já limpa em [$nome].');
        }
        return n;
      });

  Future<int?> importarUsuariosDoRelogio(int relogioId) =>
      _comRelogio(relogioId, 'Não foi possível conectar ao relógio para ler usuários', (c, nome, _) async {
        final users = await c.getUsers();
        if (users == null) {
          _log('❌ Não foi possível obter os usuários do relógio [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
          return null;
        }
        if (users.isEmpty) {
          _log('ℹ️ O relógio [$nome] está sem colaboradores cadastrados na memória.');
        } else {
          _log('📋 Leitura concluída: ${users.length} colaborador(es) cadastrado(s) no relógio [$nome]:');
          for (final u in users) {
            _log('   👤 ID: ${u.id} | Nome: ${u.name} | Matrícula: ${u.registration}');
          }
        }
        return users.length;
      });

  Future<bool> enviarEmpregador(int relogioId, ControlIdCompany comp) async =>
      await _comRelogio(relogioId, 'Falha ao autenticar em', (c, nome, _) async {
        _log('🏢 Enviando dados do empregador [${comp.name}] para o relógio [$nome]...');
        if (await c.setCompany(comp)) {
          _log('✅ Empregador [${comp.name}] (CNPJ/CPF ${comp.cpfCnpj}) atualizado com sucesso no relógio [$nome]!');
          return true;
        }
        _log('❌ Falha ao gravar empregador em [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
        return false;
      }) ??
      false;

  Future<ControlIdCompany?> obterEmpregador(int relogioId) =>
      _comRelogio(relogioId, 'Falha ao autenticar em', (c, nome, _) async {
        final comp = await c.getCompany();
        if (comp != null) {
          _log('🔍 Dados do empregador consultados no relógio [$nome]: ${comp.name} (CNPJ: ${comp.cpfCnpj}).');
        } else {
          _log('❌ Falha ao ler empregador de [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
        }
        return comp;
      });

  Future<bool> sincronizarJornadaRelogio(
          int relogioId, int jornadaId, String desc, String e1, String s1, String e2, String s2) async =>
      await _comRelogio(relogioId, 'Falha ao autenticar em', (c, nome, _) async {
        _log('⏰ Sincronizando jornada [$desc] (ID $jornadaId) e ajustando relógio [$nome]...');
        if (await c.syncTimeZone(jornadaId, desc, e1, s1, e2, s2)) {
          await c.setSystemTime(DateTime.now());
          _log('✅ Jornada [$desc] e data/hora atualizados com sucesso no relógio [$nome]!');
          return true;
        }
        _log('⚠️ Falha ao registrar jornada em [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
        return false;
      }) ??
      false;

  /// Retorna a quantidade de novas marcações, ou null em caso de falha.
  Future<int?> coletarMarcacoes(int relogioId) async {
    final rel = await _db.getRelogioPorId(relogioId);
    if (rel == null) return null;
    final ultimoLog = asInt(rel['PRE_ULTIMO_LOG_ID']);
    _log('📥 Buscando novas marcações no relógio [${asStr(rel['PRE_NOME'])}] (a partir do registro #$ultimoLog)...');

    return _comRelogio(relogioId, 'Não foi possível conectar ao relógio', (c, nome, r) async {
      var modo = asStr(r['PRE_MODO_COLETA']).trim().toUpperCase();
      if (modo.isEmpty) modo = 'API';
      var maxLog = ultimoLog, novas = 0;
      final info = await c.getSystemInformation();
      final serial = info?.serial ?? '', fw = info?.fwVersion ?? '';

      if (modo == 'API') {
        // MODO 1: coleta via API (access_logs)
        final logs = await c.getAccessLogs(ultimoLog);
        if (logs == null) {
          _log('❌ Falha ao obter registros de acesso em [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
          return null;
        }
        for (final l in logs) {
          var pessoaId = l.userId;
          if (pessoaId > 0 && await _db.getPessoaPorId(pessoaId) == null) pessoaId = 0;
          if (await _db.gravarMarcacao(pessoaId, relogioId, l.time ?? DateTime.now(), l.event, l.id, 'C', l.id, '',
              '', 'Batida Ponto', 'Control iD API')) {
            novas++;
            if (l.id > maxLog) maxLog = l.id;
          }
        }
        if (maxLog > ultimoLog) await _db.atualizarUltimoLogRelogio(relogioId, maxLog, serial, fw);
        _log(novas > 0
            ? '✅ Coleta finalizada com sucesso em [$nome]: $novas nova(s) batida(s) de ponto gravada(s)!'
            : 'ℹ️ O relógio [$nome] já está em dia (nenhuma nova batida encontrada).');
        return novas;
      }

      // MODO 2: coleta via AFD (REP Portaria 671 / 1510)
      final is671 = modo == 'AFD_671' || modo == 'AFD';
      final afd = await c.getAfd(ultimoLog + 1, is671);
      if (afd == null) {
        _log('❌ Falha ao exportar registros AFD em [$nome]: ${formatarErroAmigavel(c.lastError)}', true);
        return null;
      }
      for (final a in ControlIdClient.parseAfd(afd)) {
        final pessoaId = await _db.buscarPessoaPorPisOuCpf(a.pis, a.cpf);
        if (await _db.gravarMarcacao(
            pessoaId, relogioId, a.dataHora, 7, a.nsr, 'C', a.nsr, a.pis, a.cpf, 'Batida Ponto', 'REP AFD')) {
          novas++;
          if (a.nsr > maxLog) maxLog = a.nsr;
        }
      }
      if (maxLog > ultimoLog) await _db.atualizarUltimoLogRelogio(relogioId, maxLog, serial, fw);
      _log(novas > 0
          ? '✅ Coleta via AFD finalizada em [$nome]: $novas batida(s) processada(s) e gravada(s)!'
          : 'ℹ️ O relógio [$nome] já está em dia (nenhuma nova batida no arquivo AFD).');
      return novas;
    });
  }

  Future<({bool ok, int total})> coletarTodosRelogios() async {
    final rels = await _db.getRelogios(apenasAtivos: true);
    if (rels.isEmpty) {
      _log('ℹ️ Nenhum relógio de ponto ativo configurado para coleta.');
      return (ok: true, total: 0);
    }
    var total = 0, ok = true;
    for (final r in rels) {
      final n = await coletarMarcacoes(asInt(r['PRE_ID']));
      if (n == null) {
        ok = false;
      } else {
        total += n;
      }
    }
    _log(total > 0
        ? '🎉 Coleta geral finalizada: $total nova(s) batida(s) importada(s) no total!'
        : 'ℹ️ Coleta geral finalizada: todos os relógios estão em dia (nenhuma batida pendente).');
    return (ok: ok, total: total);
  }
}
