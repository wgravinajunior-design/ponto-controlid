import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../core/config.dart';
import '../core/util.dart';
import 'drivers.dart';
import 'versoes_bd.dart';

export 'drivers.dart' show DbRow;

enum ResultadoBatida { registrada, repetida, erro }

class DigitalCadastrada {
  final int pessoaId;
  final String nome;
  final String template;
  DigitalCadastrada(this.pessoaId, this.nome, this.template);
}

class BatidaBiometrica {
  final ResultadoBatida resultado;
  final String tipoBatida;
  final DateTime? ultimaBatida;
  final int marcacaoId;
  BatidaBiometrica(this.resultado, this.tipoBatida, this.ultimaBatida, [this.marcacaoId = 0]);
}

class VersaoBdItem {
  int id = 0, numero = 0;
  String sistema = '', descricao = '', acao = '', status = 'A', script = '', progresso = '', erros = '';
  DateTime? dataHora;
}

class EmpresaInfo {
  String razao = '', cnpj = '', endereco = '';
}

/// Camada de acesso ao Firebird (port do TdmDados / uDataModule.pas).
class Db {
  Db._();
  static final Db instance = Db._();

  FirebirdDriver? _db;
  String lastError = '';
  String lastMigracaoLog = '';

  bool get isConectado => _db != null;

  /// Login de quem está operando o sistema (gravado nos ajustes - Portaria 671).
  String usuarioLogado = 'sistema';
  String get nomeBanco => 'Firebird 5';

  String _first1(String resto) => 'SELECT FIRST 1 $resto';
  // Campos TIME convertidos para texto HH:MM
  String _tm(String campo) => 'SUBSTRING(CAST($campo AS VARCHAR(13)) FROM 1 FOR 5) AS $campo';

  static const _colabSelect =
      'SELECT P.PES_ID, P.PES_RSOCIAL_NOME, P.PES_CNPJ_CPF, P.PES_STATUS, P.PES_CODIGO_ACESSO, '
      'C.COL_PIS, C.COL_CPF, C.COL_CARTAO_PONTO, C.COL_FUNCAO, C.COL_HORARIO, H.HOR_DESCRICAO, '
      'C.COL_SINCRONIZADO_RELOGIO, C.COL_ULTIMA_SINCRONIZACAO, C.COL_BIOMETRIA_CADASTRADA, C.COL_BIOMETRIA_DATA, '
      'C.COL_DATA_ADMISSAO, C.COL_DATA_DEMISSAO, C.COL_SENHA_RELOGIO, C.COL_RFID, C.COL_ADMIN_RELOGIO '
      'FROM TB_PESSOA P '
      'LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID '
      'LEFT JOIN TB_PONTO_HORARIO H ON H.HOR_ID = C.COL_HORARIO ';

  String get _horSelect => 'SELECT HOR_ID, HOR_DESCRICAO, ${_tm('HOR_ENTRADA_1')}, ${_tm('HOR_SAIDA_1')}, '
      '${_tm('HOR_ENTRADA_2')}, ${_tm('HOR_SAIDA_2')}, HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, '
      'HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, ${_tm('HOR_SAB_ENTRADA_1')}, ${_tm('HOR_SAB_SAIDA_1')}, HOR_ATIVO, '
      "COALESCE(HOR_TIPO_ESCALA, 'SEMANAL') AS HOR_TIPO_ESCALA, HOR_ESCALA_INICIO, COALESCE(HOR_VIRADA_DIA, '00:00') AS HOR_VIRADA_DIA, "
      "COALESCE(HOR_INTERVALO_MIN, 60) AS HOR_INTERVALO_MIN, COALESCE(HOR_BANCO_HORAS, 'N') AS HOR_BANCO_HORAS, "
      'HOR_CICLO_TRABALHO, HOR_CICLO_FOLGA '
      'FROM TB_PONTO_HORARIO ';

  // ======================= Conexão =======================

  /// Abre um banco no servidor Firebird configurado do ponto.
  static Future<FirebirdDriver> abrirFirebird([String? arquivo]) {
    final cfg = AppConfig.instance.firebird;
    return FirebirdDriver.connect(
        host: cfg.server, port: cfg.port, database: arquivo ?? cfg.database, user: cfg.user,
        password: cfg.password, libFbClient: cfg.vendorLib);
  }

  /// Abre a base exclusiva do ponto; se o arquivo não existir, cria a base no Firebird 5.
  Future<FirebirdDriver> _abrirBase() async {
    final cfg = AppConfig.instance.firebird;
    final arquivo = cfg.database;
    try {
      return await abrirFirebird(arquivo);
    } catch (erroAbrir) {
      final msg = '$erroAbrir'.toLowerCase();
      if (!(msg.contains('i/o error') || msg.contains('no such file') || msg.contains('cannot find') ||
          msg.contains('não pode encontrar') || msg.contains('nao pode encontrar') || msg.contains('-createfile'))) {
        rethrow;
      }
      final d = await FirebirdDriver.create(
          host: cfg.server, port: cfg.port, database: arquivo, user: cfg.user, password: cfg.password,
          libFbClient: cfg.vendorLib);
      lastMigracaoLog = 'Base do ponto criada em $arquivo.';
      return d;
    }
  }

  Future<bool> conectar({bool migrar = true}) async {
    lastError = '';
    await desconectar();
    try {
      _db = await _abrirBase();
      if (migrar) {
        final criada = lastMigracaoLog.startsWith('Base do ponto criada');
        final log = await verificarEAtualizarEstruturaBanco();
        lastMigracaoLog = criada ? '$lastMigracaoLog $log' : log;
      }
      return true;
    } catch (e) {
      _db = null;
      lastError = 'Falha ao conectar no banco de dados ($nomeBanco): $e';
      return false;
    }
  }

  Future<void> desconectar() async {
    final d = _db;
    _db = null;
    if (d != null) {
      try {
        await d.close();
      } catch (_) {}
    }
  }

  Future<String?> testarConexao() async => await conectar() ? null : lastError;

  Future<FirebirdDriver> _conn() async {
    if (_db == null && !await conectar()) throw Exception(lastError);
    return _db!;
  }

  Future<List<DbRow>> query(String sql, [List<dynamic> params = const []]) async =>
      (await _conn()).query(sql, params);

  Future<DbRow?> queryOne(String sql, [List<dynamic> params = const []]) async {
    final r = await query(sql, params);
    return r.isEmpty ? null : r.first;
  }

  /// `INSERT ... RETURNING CAMPO` (no MySQL usa o LAST_INSERT_ID).
  Future<DbRow?> execReturning(String sql, [List<dynamic> params = const []]) async =>
      (await _conn()).execReturning(sql, params);

  Future<int> exec(String sql, [List<dynamic> params = const []]) async => (await _conn()).exec(sql, params);

  Future<bool> execDdl(String sql) async {
    try {
      await exec(sql);
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  // ======================= Relógios =======================

  Future<List<DbRow>> getRelogios({bool apenasAtivos = false}) => query(
      'SELECT PRE_ID, PRE_NOME, PRE_IP, PRE_PORTA, PRE_USAR_SSL, PRE_USUARIO, '
      'PRE_SENHA, PRE_MODELO, PRE_MODO_COLETA, PRE_ULTIMO_LOG_ID, PRE_STATUS, '
      'PRE_ATIVO, PRE_DEVICE_ID, PRE_SERIAL, PRE_VERSAO_FW, PRE_ULTIMA_COLETA '
      'FROM TB_PONTO_RELOGIO '
      '${apenasAtivos ? "WHERE PRE_ATIVO = 'S' AND PRE_STATUS = 'A' " : ''}'
      'ORDER BY PRE_NOME');

  Future<DbRow?> getRelogioPorId(int id) => queryOne('SELECT * FROM TB_PONTO_RELOGIO WHERE PRE_ID = ?', [id]);

  Future<int> salvarRelogio(int id, String nome, String ip, int porta, bool ssl, String usuario, String senha,
      String modelo, String modoColeta, bool ativo) async {
    final p = [nome, ip, porta, ssl ? 'S' : 'N', usuario, senha, modelo, modoColeta, ativo ? 'S' : 'N'];
    if (id <= 0) {
      final r = await execReturning(
          'INSERT INTO TB_PONTO_RELOGIO (PRE_NOME, PRE_IP, PRE_PORTA, PRE_USAR_SSL, '
          'PRE_USUARIO, PRE_SENHA, PRE_MODELO, PRE_MODO_COLETA, PRE_ATIVO, PRE_STATUS, PRE_ULTIMO_LOG_ID) '
          "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'A', 0) RETURNING PRE_ID",
          p);
      return asInt(r?['PRE_ID']);
    }
    await exec(
        'UPDATE TB_PONTO_RELOGIO SET PRE_NOME = ?, PRE_IP = ?, PRE_PORTA = ?, PRE_USAR_SSL = ?, '
        'PRE_USUARIO = ?, PRE_SENHA = ?, PRE_MODELO = ?, PRE_MODO_COLETA = ?, PRE_ATIVO = ? WHERE PRE_ID = ?',
        [...p, id]);
    return id;
  }

  Future<void> atualizarEnderecoRelogio(int id, String ip, int porta, bool ssl) => exec(
      'UPDATE TB_PONTO_RELOGIO SET PRE_IP = ?, PRE_PORTA = ?, PRE_USAR_SSL = ? WHERE PRE_ID = ?',
      [ip, porta, ssl ? 'S' : 'N', id]);

  Future<void> excluirRelogio(int id) => exec('DELETE FROM TB_PONTO_RELOGIO WHERE PRE_ID = ?', [id]);

  Future<void> atualizarUltimoLogRelogio(int relogioId, int ultimoLogId, String serial, String fw) async {
    await exec(
        'UPDATE TB_PONTO_RELOGIO SET PRE_ULTIMO_LOG_ID = ?, PRE_ULTIMA_COLETA = CURRENT_TIMESTAMP WHERE PRE_ID = ?',
        [ultimoLogId, relogioId]);
    if (serial.isNotEmpty || fw.isNotEmpty) {
      await exec(
          "UPDATE TB_PONTO_RELOGIO SET PRE_SERIAL = COALESCE(NULLIF(CAST(? AS VARCHAR(50)), ''), PRE_SERIAL), "
          "PRE_VERSAO_FW = COALESCE(NULLIF(CAST(? AS VARCHAR(50)), ''), PRE_VERSAO_FW) WHERE PRE_ID = ?",
          [serial, fw, relogioId]);
    }
  }

  // ======================= Colaboradores =======================

  Future<List<DbRow>> getColaboradores({bool apenasAtivos = true}) => query(
      "${_colabSelect}WHERE (P.PES_COLABORADOR = 'S' OR C.COL_PESSOA IS NOT NULL) "
      "${apenasAtivos ? "AND COALESCE(P.PES_STATUS, 'A') = 'A' " : ''}"
      'ORDER BY P.PES_RSOCIAL_NOME');

  Future<DbRow?> getPessoaPorId(int id) => queryOne('${_colabSelect}WHERE P.PES_ID = ?', [id]);

  Future<int> buscarPessoaPorPisOuCpf(String pis, String cpf) async {
    final cPis = pis.replaceAll('.', '').replaceAll('-', '').trim();
    final cCpf = cpf.replaceAll('.', '').replaceAll('-', '').replaceAll('/', '').trim();
    if (cPis.isEmpty && cCpf.isEmpty) return 0;
    final r = await queryOne(
        _first1('P.PES_ID FROM TB_PESSOA P LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID '
        "WHERE (CAST(? AS VARCHAR(20)) <> '' AND (C.COL_PIS = ? OR C.COL_PIS CONTAINING ?)) "
        "   OR (CAST(? AS VARCHAR(20)) <> '' AND (P.PES_CNPJ_CPF = ? OR C.COL_CPF = ? OR C.COL_PIS = ?))"),
        [cPis, cPis, cPis, cCpf, cCpf, cCpf, cCpf]);
    return asInt(r?['PES_ID']);
  }

  /// Localiza pessoa por código (PES_ID) ou CPF.
  Future<DbRow?> buscarPessoaPorCodigoOuCpf(String busca) => queryOne(
      _first1('PES_ID, PES_RSOCIAL_NOME FROM TB_PESSOA WHERE PES_ID = ? OR PES_CNPJ_CPF = ? OR PES_CNPJ_CPF = ?'),
      [int.tryParse(busca) ?? 0, busca, onlyDigits(busca)]);

  /// Retorna o ID da pessoa (novo ou existente).
  Future<int> salvarColaborador(int pessoaId, String nome, String cpf, String pis, String matricula, String funcao,
      String codigoAcesso, bool ativo, int horarioId) async {
    final cCpf = cpf.replaceAll('.', '').replaceAll('-', '').replaceAll('/', '').trim();
    final cPis = pis.replaceAll('.', '').replaceAll('-', '').trim();
    final status = ativo ? 'A' : 'I';
    final horario = horarioId > 0 ? horarioId : null;
    const insertColab = 'INSERT INTO TB_COLABORADOR (COL_PESSOA, COL_EMPRESA, COL_CPF, COL_PIS, '
        'COL_CARTAO_PONTO, COL_FUNCAO, COL_STATUS, COL_HORARIO, COL_SINCRONIZADO_RELOGIO, COL_DT_CADASTRO) '
        "VALUES (?, 1, ?, ?, ?, ?, ?, ?, 'N', CURRENT_TIMESTAMP)";

    if (pessoaId <= 0) {
      final novoId = await obterProximoIdPessoa();
      final r = await execReturning(
          'INSERT INTO TB_PESSOA (PES_ID, PES_RSOCIAL_NOME, PES_CNPJ_CPF, PES_STATUS, PES_COLABORADOR, '
          "PES_CODIGO_ACESSO, PES_DT_CADASTRO) VALUES (?, ?, ?, ?, 'S', ?, CURRENT_TIMESTAMP) RETURNING PES_ID",
          [novoId, nome.trim(), cCpf, status, codigoAcesso.trim()]);
      pessoaId = asInt(r?['PES_ID']);
      if (pessoaId <= 0) return 0;
      await exec(insertColab, [pessoaId, cCpf, cPis, matricula.trim(), funcao.trim(), status, horario]);
      return pessoaId;
    }

    await exec(
        "UPDATE TB_PESSOA SET PES_RSOCIAL_NOME = ?, PES_CNPJ_CPF = ?, PES_STATUS = ?, PES_COLABORADOR = 'S', "
        'PES_CODIGO_ACESSO = ? WHERE PES_ID = ?',
        [nome.trim(), cCpf, status, codigoAcesso.trim(), pessoaId]);
    final n = await exec(
        'UPDATE TB_COLABORADOR SET COL_CPF = ?, COL_PIS = ?, COL_CARTAO_PONTO = ?, COL_FUNCAO = ?, '
        "COL_STATUS = ?, COL_HORARIO = ?, COL_SINCRONIZADO_RELOGIO = 'N' WHERE COL_PESSOA = ?",
        [cCpf, cPis, matricula.trim(), funcao.trim(), status, horario, pessoaId]);
    if (n == 0) {
      await exec(insertColab, [pessoaId, cCpf, cPis, matricula.trim(), funcao.trim(), status, horario]);
    }
    return pessoaId;
  }

  /// Retorna null em caso de sucesso (com [inativado] indicando inativação) ou a mensagem de erro.
  Future<({bool ok, bool inativado, String erro})> excluirColaborador(int pessoaId) async {
    try {
      await exec('DELETE FROM TB_COLABORADOR WHERE COL_PESSOA = ?', [pessoaId]);
      await exec('DELETE FROM TB_PESSOA WHERE PES_ID = ?', [pessoaId]);
      return (ok: true, inativado: false, erro: '');
    } catch (_) {
      // Vínculos com marcações ou outras tabelas: inativa para manter integridade
      try {
        await exec("UPDATE TB_COLABORADOR SET COL_STATUS = 'I' WHERE COL_PESSOA = ?", [pessoaId]);
        await exec("UPDATE TB_PESSOA SET PES_STATUS = 'I' WHERE PES_ID = ?", [pessoaId]);
        return (ok: true, inativado: true, erro: '');
      } catch (e2) {
        return (ok: false, inativado: false, erro: e2.toString());
      }
    }
  }

  Future<void> marcarColaboradorSincronizado(int pessoaId) async {
    final n = await exec(
        "UPDATE TB_COLABORADOR SET COL_SINCRONIZADO_RELOGIO = 'S', COL_ULTIMA_SINCRONIZACAO = CURRENT_TIMESTAMP "
        'WHERE COL_PESSOA = ?',
        [pessoaId]);
    if (n == 0) {
      await exec(
          'INSERT INTO TB_COLABORADOR (COL_PESSOA, COL_EMPRESA, COL_STATUS, COL_SINCRONIZADO_RELOGIO, '
          "COL_ULTIMA_SINCRONIZACAO) VALUES (?, 1, 'A', 'S', CURRENT_TIMESTAMP)",
          [pessoaId]);
    }
  }

  Future<void> marcarColaboradorNaoSincronizado(int pessoaId) =>
      exec("UPDATE TB_COLABORADOR SET COL_SINCRONIZADO_RELOGIO = 'N' WHERE COL_PESSOA = ?", [pessoaId]);

  // ======================= Biometria (Hamster DX) =======================

  Future<bool> salvarBiometriaColaborador(int pessoaId, String template) async {
    lastError = '';
    try {
      final n = await exec(
          "UPDATE TB_COLABORADOR SET COL_BIOMETRIA = ?, COL_BIOMETRIA_CADASTRADA = 'S', "
          'COL_BIOMETRIA_DATA = CURRENT_TIMESTAMP WHERE COL_PESSOA = ?',
          [template, pessoaId]);
      if (n == 0) {
        lastError = 'Colaborador não possui cadastro complementar (TB_COLABORADOR). '
            'Salve o colaborador antes de cadastrar a biometria.';
      }
      return n > 0;
    } catch (e) {
      lastError = 'Erro ao gravar biometria: $e';
      return false;
    }
  }

  Future<bool> removerBiometriaColaborador(int pessoaId) async =>
      await exec(
          "UPDATE TB_COLABORADOR SET COL_BIOMETRIA = NULL, COL_BIOMETRIA_CADASTRADA = 'N', COL_BIOMETRIA_DATA = NULL "
          'WHERE COL_PESSOA = ?',
          [pessoaId]) >
      0;

  Future<String> getBiometriaColaborador(int pessoaId) async {
    final r = await queryOne('SELECT COL_BIOMETRIA FROM TB_COLABORADOR WHERE COL_PESSOA = ?', [pessoaId]);
    return asStr(r?['COL_BIOMETRIA']).trim();
  }

  Future<List<DigitalCadastrada>> getDigitaisCadastradas() async {
    final rows = await query('SELECT P.PES_ID, P.PES_RSOCIAL_NOME, C.COL_BIOMETRIA FROM TB_COLABORADOR C '
        'JOIN TB_PESSOA P ON P.PES_ID = C.COL_PESSOA '
        "WHERE C.COL_BIOMETRIA_CADASTRADA = 'S' AND C.COL_BIOMETRIA IS NOT NULL "
        "AND COALESCE(P.PES_STATUS, 'A') = 'A' ORDER BY P.PES_ID");
    return [
      for (final r in rows)
        if (asStr(r['COL_BIOMETRIA']).trim().isNotEmpty)
          DigitalCadastrada(asInt(r['PES_ID']), asStr(r['PES_RSOCIAL_NOME']), asStr(r['COL_BIOMETRIA']).trim())
    ];
  }

  Future<int> getTotalBiometrias() async {
    final r = await queryOne('SELECT COUNT(*) AS QTD FROM TB_COLABORADOR C JOIN TB_PESSOA P ON P.PES_ID = C.COL_PESSOA '
        "WHERE C.COL_BIOMETRIA_CADASTRADA = 'S' AND COALESCE(P.PES_STATUS, 'A') = 'A'");
    return asInt(r?['QTD']);
  }

  Future<BatidaBiometrica> registrarBatidaBiometrica(int pessoaId, DateTime dataHora, int intervaloMinimoMin) async {
    lastError = '';
    try {
      // Quantidade de batidas do dia define Entrada (par) ou Saída (ímpar)
      final r = await queryOne(
          'SELECT COUNT(*) AS QTD, MAX(PMA_DATA_HORA) AS ULTIMA FROM TB_PONTO_MARCACAO '
          'WHERE PMA_PESSOA = ? AND PMA_DATA_HORA BETWEEN ? AND ? AND $validas',
          [pessoaId, inicioDoDia(dataHora), fimDoDia(dataHora)]);
      final qtd = asInt(r?['QTD']);
      final ultima = asDate(r?['ULTIMA']);
      var tipo = qtd.isOdd ? 'S' : 'E';

      // Leitura repetida em sequência (colaborador encostou o dedo duas vezes)
      if (ultima != null && intervaloMinimoMin > 0 && minutesBetween(dataHora, ultima) < intervaloMinimoMin) {
        tipo = qtd.isOdd ? 'E' : 'S';
        return BatidaBiometrica(ResultadoBatida.repetida, tipo, ultima);
      }

      final c = await queryOne('SELECT COL_CPF, COL_PIS FROM TB_COLABORADOR WHERE COL_PESSOA = ?', [pessoaId]);
      final ins = await execReturning(
          'INSERT INTO TB_PONTO_MARCACAO (PMA_PESSOA, PMA_RELOGIO, PMA_DATA_HORA, PMA_EVENTO, '
          'PMA_ORIGEM, PMA_PIS, PMA_CPF, PMA_TIPO_BATIDA, PMA_TIPO_IDENTIFICACAO, PMA_EXPORTADO) '
          "VALUES (?, NULL, ?, 7, 'B', ?, ?, ?, 'BIOMETRIA', 'N') RETURNING PMA_ID",
          [
            pessoaId,
            DateTime(dataHora.year, dataHora.month, dataHora.day, dataHora.hour, dataHora.minute, dataHora.second),
            asStr(c?['COL_PIS']),
            asStr(c?['COL_CPF']),
            tipo
          ]);
      final id = asInt(ins?['PMA_ID']);
      // NSR sequencial do registro eletrônico (Portaria 671): usa o próprio ID da marcação
      if (id > 0) await exec('UPDATE TB_PONTO_MARCACAO SET PMA_NSR = ? WHERE PMA_ID = ?', [id, id]);
      return BatidaBiometrica(ResultadoBatida.registrada, tipo, ultima, id);
    } catch (e) {
      lastError = 'Erro ao registrar batida: $e';
      return BatidaBiometrica(ResultadoBatida.erro, '', null);
    }
  }

  // ======================= Horários =======================

  Future<List<DbRow>> getHorarios({bool apenasAtivos = true}) => query(
      "$_horSelect${apenasAtivos ? "WHERE COALESCE(HOR_ATIVO, 'S') = 'S' " : ''}ORDER BY HOR_DESCRICAO");

  Future<DbRow?> getHorarioPorId(int id) => queryOne('${_horSelect}WHERE HOR_ID = ?', [id]);

  /// Parâmetro TIME: o driver exige DateTime (somente a parte de hora é gravada).
  static DateTime? _time(String v) {
    final d = parseHora(v);
    return d == null ? null : DateTime(2000, 1, 1).add(d);
  }

  Future<int> salvarHorario(int id, String descricao, String e1, String s1, String e2, String s2, int tolerancia,
      int carga, bool compensaSab, bool trabalhaSab, String sabE1, String sabS1, bool ativo) async {
    final p = [
      descricao.trim(), _time(e1), _time(s1), _time(e2), _time(s2), tolerancia, carga,
      compensaSab ? 'S' : 'N', trabalhaSab ? 'S' : 'N', _time(sabE1), _time(sabS1), ativo ? 'S' : 'N'
    ];
    const t = '?';
    if (id <= 0) {
      final r = await execReturning(
          'INSERT INTO TB_PONTO_HORARIO (HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, HOR_SAIDA_2, '
          'HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, '
          'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_ATIVO) '
          'VALUES (?, $t, $t, $t, $t, ?, ?, ?, ?, $t, $t, ?) RETURNING HOR_ID',
          p);
      return asInt(r?['HOR_ID']);
    }
    await exec(
        'UPDATE TB_PONTO_HORARIO SET HOR_DESCRICAO = ?, HOR_ENTRADA_1 = $t, HOR_SAIDA_1 = $t, '
        'HOR_ENTRADA_2 = $t, HOR_SAIDA_2 = $t, HOR_TOLERANCIA_MIN = ?, HOR_CARGA_DIARIA_MIN = ?, '
        'HOR_COMPENSA_SABADO = ?, HOR_TRABALHA_SABADO = ?, HOR_SAB_ENTRADA_1 = $t, HOR_SAB_SAIDA_1 = $t, '
        'HOR_ATIVO = ? WHERE HOR_ID = ?',
        [...p, id]);
    return id;
  }

  /// Retorna mensagem informativa (inativação) ou null.
  Future<String?> excluirHorario(int id) async {
    final r = await queryOne('SELECT COUNT(*) AS QTD FROM TB_COLABORADOR WHERE COL_HORARIO = ?', [id]);
    if (asInt(r?['QTD']) > 0) {
      await exec("UPDATE TB_PONTO_HORARIO SET HOR_ATIVO = 'N' WHERE HOR_ID = ?", [id]);
      return 'O horário possui colaboradores vinculados e foi inativado para preservar o histórico.';
    }
    await exec('DELETE FROM TB_PONTO_HORARIO WHERE HOR_ID = ?', [id]);
    return null;
  }

  /// Regras adicionais da jornada: escala (SEMANAL / 12X36), início da escala, virada do dia
  /// (turno noturno), intervalo mínimo e uso de banco de horas.
  Future<void> salvarRegrasHorario(
      int id, String tipoEscala, DateTime? escalaInicio, String viradaDia, int intervaloMin, bool bancoHoras) => exec(
      'UPDATE TB_PONTO_HORARIO SET HOR_TIPO_ESCALA = ?, HOR_ESCALA_INICIO = ?, HOR_VIRADA_DIA = ?, '
      'HOR_INTERVALO_MIN = ?, HOR_BANCO_HORAS = ? WHERE HOR_ID = ?',
      [tipoEscala, escalaInicio == null ? null : soData(escalaInicio), viradaDia.trim().isEmpty ? '00:00' : viradaDia.trim(),
       intervaloMin, bancoHoras ? 'S' : 'N', id]);

  // ======================= Feriados =======================

  Future<List<DbRow>> getFeriados() => query(
      "SELECT FER_ID, FER_DATA, FER_DESCRICAO, COALESCE(FER_RECORRENTE, 'S') AS FER_RECORRENTE, "
      "COALESCE(FER_ABRANGENCIA, 'NACIONAL') AS FER_ABRANGENCIA FROM TB_PONTO_FERIADO "
      'ORDER BY EXTRACT(MONTH FROM FER_DATA), EXTRACT(DAY FROM FER_DATA), FER_DATA');

  Future<int> salvarFeriado(int id, DateTime data, String descricao, bool recorrente, String abrangencia) async {
    final p = [soData(data), descricao.trim(), recorrente ? 'S' : 'N', abrangencia];
    if (id <= 0) {
      final r = await execReturning(
          'INSERT INTO TB_PONTO_FERIADO (FER_DATA, FER_DESCRICAO, FER_RECORRENTE, FER_ABRANGENCIA) VALUES (?, ?, ?, ?) '
          'RETURNING FER_ID',
          p);
      return asInt(r?['FER_ID']);
    }
    await exec(
        'UPDATE TB_PONTO_FERIADO SET FER_DATA = ?, FER_DESCRICAO = ?, FER_RECORRENTE = ?, FER_ABRANGENCIA = ? WHERE FER_ID = ?',
        [...p, id]);
    return id;
  }

  Future<void> excluirFeriado(int id) => exec('DELETE FROM TB_PONTO_FERIADO WHERE FER_ID = ?', [id]);

  /// Feriados (data -> descrição) que caem no período, expandindo os recorrentes ano a ano.
  Future<Map<DateTime, String>> feriadosNoPeriodo(DateTime ini, DateTime fim) async {
    final mapa = <DateTime, String>{};
    for (final f in await getFeriados()) {
      final d = asDate(f['FER_DATA']);
      if (d == null) continue;
      if (asStr(f['FER_RECORRENTE']) == 'S') {
        for (var ano = ini.year; ano <= fim.year; ano++) {
          final x = DateTime(ano, d.month, d.day);
          if (!x.isBefore(soData(ini)) && !x.isAfter(soData(fim))) mapa[x] = asStr(f['FER_DESCRICAO']);
        }
      } else if (!soData(d).isBefore(soData(ini)) && !soData(d).isAfter(soData(fim))) {
        mapa[soData(d)] = asStr(f['FER_DESCRICAO']);
      }
    }
    // Sexta-feira Santa: feriado nacional móvel (Lei 9.093/95), calculado pela Páscoa
    for (var ano = ini.year; ano <= fim.year; ano++) {
      final s = pascoa(ano).subtract(const Duration(days: 2));
      if (!s.isBefore(soData(ini)) && !s.isAfter(soData(fim))) mapa.putIfAbsent(s, () => 'Sexta-feira Santa');
    }
    return mapa;
  }

  /// Domingo de Páscoa (algoritmo de Meeus/Jones/Butcher).
  static DateTime pascoa(int ano) {
    final a = ano % 19, b = ano ~/ 100, c = ano % 100, d = b ~/ 4, e = b % 4;
    final f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3, h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31, dia = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(ano, mes, dia);
  }

  Future<void> _semearFeriados() async {
    if (asInt((await queryOne('SELECT COUNT(*) AS QTD FROM TB_PONTO_FERIADO'))?['QTD']) > 0) return;
    // Feriados nacionais fixos (Lei 662/49, Lei 6.802/80, Lei 14.759/23)
    const fixos = [
      [1, 1, 'Confraternização Universal'],
      [4, 21, 'Tiradentes'],
      [5, 1, 'Dia do Trabalho'],
      [9, 7, 'Independência do Brasil'],
      [10, 12, 'Nossa Senhora Aparecida'],
      [11, 2, 'Finados'],
      [11, 15, 'Proclamação da República'],
      [11, 20, 'Dia Nacional de Zumbi e da Consciência Negra'],
      [12, 25, 'Natal'],
    ];
    for (final f in fixos) {
      await salvarFeriado(0, DateTime(2000, f[0] as int, f[1] as int), f[2] as String, true, 'NACIONAL');
    }
  }

  // ======================= Banco de horas =======================

  /// Tipos: C = crédito apurado, D = débito apurado, P = pagamento em folha, F = folga compensada, A = ajuste.
  Future<int> lancarBancoHoras(int pessoaId, DateTime data, int minutos, String tipo, String descricao,
      [String competencia = '']) async {
    final r = await execReturning(
        'INSERT INTO TB_PONTO_BANCO_HORAS (BH_PESSOA, BH_DATA, BH_MINUTOS, BH_TIPO, BH_DESCRICAO, BH_COMPETENCIA) '
        'VALUES (?, ?, ?, ?, ?, ?) RETURNING BH_ID',
        [pessoaId, soData(data), minutos, tipo, _limite(descricao, 200), competencia]);
    return asInt(r?['BH_ID']);
  }

  Future<void> excluirLancamentoBancoHoras(int id) => exec('DELETE FROM TB_PONTO_BANCO_HORAS WHERE BH_ID = ?', [id]);

  Future<List<DbRow>> getBancoHoras({int pessoaId = 0, DateTime? ate}) {
    final p = <dynamic>[];
    var sql = 'SELECT B.BH_ID, B.BH_PESSOA, B.BH_DATA, B.BH_MINUTOS, B.BH_TIPO, B.BH_DESCRICAO, B.BH_COMPETENCIA, '
        'P.PES_RSOCIAL_NOME FROM TB_PONTO_BANCO_HORAS B LEFT JOIN TB_PESSOA P ON P.PES_ID = B.BH_PESSOA WHERE 1 = 1 ';
    if (pessoaId > 0) {
      sql += 'AND B.BH_PESSOA = ? ';
      p.add(pessoaId);
    }
    if (ate != null) {
      sql += 'AND B.BH_DATA <= ? ';
      p.add(soData(ate));
    }
    return query('${sql}ORDER BY B.BH_DATA, B.BH_ID', p);
  }

  /// Saldo acumulado (minutos) de cada colaborador.
  Future<Map<int, int>> saldosBancoHoras() async => {
        for (final r in await query(
            'SELECT BH_PESSOA, SUM(BH_MINUTOS) AS SALDO FROM TB_PONTO_BANCO_HORAS GROUP BY BH_PESSOA'))
          asInt(r['BH_PESSOA']): asInt(r['SALDO'])
      };

  /// Já existe fechamento da competência para o colaborador?
  Future<bool> competenciaFechada(int pessoaId, String competencia) async =>
      await queryOne("SELECT FIRST 1 BH_ID FROM TB_PONTO_BANCO_HORAS WHERE BH_PESSOA = ? AND BH_COMPETENCIA = ? "
          "AND BH_TIPO IN ('C', 'D')", [pessoaId, competencia]) !=
      null;

  Future<void> estornarCompetencia(int pessoaId, String competencia) => exec(
      "DELETE FROM TB_PONTO_BANCO_HORAS WHERE BH_PESSOA = ? AND BH_COMPETENCIA = ? AND BH_TIPO IN ('C', 'D')",
      [pessoaId, competencia]);

  // ======================= Contrato e dados do relógio do colaborador =======================

  Future<void> salvarContratoColaborador(int pessoaId,
          {DateTime? admissao, DateTime? demissao, String senhaRelogio = '', int rfid = 0, bool adminRelogio = false}) =>
      exec(
          'UPDATE TB_COLABORADOR SET COL_DATA_ADMISSAO = ?, COL_DATA_DEMISSAO = ?, COL_SENHA_RELOGIO = ?, COL_RFID = ?, '
          'COL_ADMIN_RELOGIO = ? WHERE COL_PESSOA = ?',
          [
            admissao == null ? null : soData(admissao), demissao == null ? null : soData(demissao), senhaRelogio.trim(),
            rfid > 0 ? rfid : null, adminRelogio ? 'S' : 'N', pessoaId
          ]);

  /// Digitais lidas do relógio Control iD (JSON com a lista de templates).
  Future<void> salvarBiometriaControlId(int pessoaId, String templatesJson) => exec(
      'UPDATE TB_COLABORADOR SET COL_BIOMETRIA_CONTROLID = ? WHERE COL_PESSOA = ?', [templatesJson, pessoaId]);

  Future<String> getBiometriaControlId(int pessoaId) async =>
      asStr((await queryOne('SELECT COL_BIOMETRIA_CONTROLID AS T FROM TB_COLABORADOR WHERE COL_PESSOA = ?', [pessoaId]))?['T']);

  // ======================= Afastamentos (férias, licenças, INSS) =======================

  static const tiposAfastamento = [
    'Férias', 'Licença médica (atestado)', 'Afastamento INSS', 'Licença maternidade', 'Licença paternidade',
    'Licença casamento', 'Licença nojo (falecimento)', 'Folga compensatória', 'Suspensão', 'Outros',
  ];

  Future<List<DbRow>> getAfastamentos({int pessoaId = 0, DateTime? ini, DateTime? fim}) {
    final p = <dynamic>[];
    var sql = 'SELECT A.AFA_ID, A.AFA_PESSOA, A.AFA_INICIO, A.AFA_FIM, A.AFA_TIPO, A.AFA_MOTIVO, A.AFA_USUARIO, '
        'P.PES_RSOCIAL_NOME FROM TB_PONTO_AFASTAMENTO A LEFT JOIN TB_PESSOA P ON P.PES_ID = A.AFA_PESSOA WHERE 1 = 1 ';
    if (pessoaId > 0) {
      sql += 'AND A.AFA_PESSOA = ? ';
      p.add(pessoaId);
    }
    if (ini != null && fim != null) {
      sql += 'AND A.AFA_FIM >= ? AND A.AFA_INICIO <= ? ';
      p.addAll([soData(ini), soData(fim)]);
    }
    return query('${sql}ORDER BY A.AFA_INICIO DESC', p);
  }

  Future<int> salvarAfastamento(int id, int pessoaId, DateTime ini, DateTime fim, String tipo, String motivo) async {
    final p = [pessoaId, soData(ini), soData(fim), tipo, _limite(motivo), usuarioLogado];
    if (id <= 0) {
      final r = await execReturning(
          'INSERT INTO TB_PONTO_AFASTAMENTO (AFA_PESSOA, AFA_INICIO, AFA_FIM, AFA_TIPO, AFA_MOTIVO, AFA_USUARIO) '
          'VALUES (?, ?, ?, ?, ?, ?) RETURNING AFA_ID',
          p);
      return asInt(r?['AFA_ID']);
    }
    await exec(
        'UPDATE TB_PONTO_AFASTAMENTO SET AFA_PESSOA = ?, AFA_INICIO = ?, AFA_FIM = ?, AFA_TIPO = ?, AFA_MOTIVO = ?, '
        'AFA_USUARIO = ? WHERE AFA_ID = ?',
        [...p, id]);
    return id;
  }

  Future<void> excluirAfastamento(int id) => exec('DELETE FROM TB_PONTO_AFASTAMENTO WHERE AFA_ID = ?', [id]);

  /// Justificativas de todos (ou de um colaborador) no período, com o nome.
  Future<List<DbRow>> getJustificativas({int pessoaId = 0, required DateTime ini, required DateTime fim}) {
    final p = <dynamic>[soData(ini), soData(fim)];
    var sql = 'SELECT J.JUS_ID, J.JUS_PESSOA, J.JUS_DATA, J.JUS_TIPO, J.JUS_MOTIVO, J.JUS_ABONO_MINUTOS, J.JUS_USUARIO, '
        'J.JUS_CRIADO_EM, P.PES_RSOCIAL_NOME FROM TB_PONTO_JUSTIFICATIVA J LEFT JOIN TB_PESSOA P ON P.PES_ID = J.JUS_PESSOA '
        'WHERE J.JUS_DATA BETWEEN ? AND ? ';
    if (pessoaId > 0) {
      sql += 'AND J.JUS_PESSOA = ? ';
      p.add(pessoaId);
    }
    return query('${sql}ORDER BY J.JUS_DATA DESC', p);
  }

  // ======================= Usuários =======================

  static String _hash(String salt, String senha) => sha256.convert(utf8.encode('$salt|$senha')).toString();

  static String _novoSalt() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<List<DbRow>> getUsuarios() => query('SELECT USU_ID, USU_LOGIN, USU_NOME, USU_PERFIL, USU_ATIVO, '
      'USU_TROCAR_SENHA, USU_ULTIMO_ACESSO FROM TB_PONTO_USUARIO ORDER BY USU_LOGIN');

  Future<int> salvarUsuario(int id, String login, String nome, String perfil, bool ativo,
      {String? senha, bool trocarSenha = false}) async {
    final l = login.trim().toLowerCase();
    if (id <= 0) {
      final salt = _novoSalt();
      final r = await execReturning(
          'INSERT INTO TB_PONTO_USUARIO (USU_LOGIN, USU_NOME, USU_SENHA_HASH, USU_SALT, USU_PERFIL, USU_ATIVO, '
          'USU_TROCAR_SENHA) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING USU_ID',
          [l, nome.trim(), _hash(salt, senha ?? ''), salt, perfil, ativo ? 'S' : 'N', trocarSenha ? 'S' : 'N']);
      return asInt(r?['USU_ID']);
    }
    await exec('UPDATE TB_PONTO_USUARIO SET USU_LOGIN = ?, USU_NOME = ?, USU_PERFIL = ?, USU_ATIVO = ? WHERE USU_ID = ?',
        [l, nome.trim(), perfil, ativo ? 'S' : 'N', id]);
    if (senha != null) await alterarSenha(id, senha, trocarNoProximoAcesso: trocarSenha);
    return id;
  }

  Future<void> alterarSenha(int id, String senha, {bool trocarNoProximoAcesso = false}) {
    final salt = _novoSalt();
    return exec('UPDATE TB_PONTO_USUARIO SET USU_SENHA_HASH = ?, USU_SALT = ?, USU_TROCAR_SENHA = ? WHERE USU_ID = ?',
        [_hash(salt, senha), salt, trocarNoProximoAcesso ? 'S' : 'N', id]);
  }

  /// Cria o administrador inicial (admin / admin, com troca obrigatória da senha no primeiro acesso).
  Future<void> garantirUsuarioAdmin() async {
    if (asInt((await queryOne('SELECT COUNT(*) AS QTD FROM TB_PONTO_USUARIO'))?['QTD']) > 0) return;
    await salvarUsuario(0, 'admin', 'Administrador', 'ADMIN', true, senha: 'admin', trocarSenha: true);
  }

  /// Retorna o usuário autenticado ou null.
  Future<DbRow?> autenticar(String login, String senha) async {
    final u = await queryOne(
        'SELECT USU_ID, USU_LOGIN, USU_NOME, USU_PERFIL, USU_SENHA_HASH, USU_SALT, USU_TROCAR_SENHA FROM TB_PONTO_USUARIO '
        "WHERE USU_LOGIN = ? AND COALESCE(USU_ATIVO, 'S') = 'S'",
        [login.trim().toLowerCase()]);
    if (u == null || _hash(asStr(u['USU_SALT']), senha) != asStr(u['USU_SENHA_HASH'])) return null;
    await exec('UPDATE TB_PONTO_USUARIO SET USU_ULTIMO_ACESSO = CURRENT_TIMESTAMP WHERE USU_ID = ?', [u['USU_ID']]);
    usuarioLogado = asStr(u['USU_LOGIN']);
    return u;
  }

  // ======================= Jornada por dia da semana e ciclos =======================

  /// Dias configurados (1 = segunda ... 7 = domingo). Vazio = usa os horários gerais da jornada.
  Future<Map<int, DbRow>> getHorarioDias(int horarioId) async => {
        for (final r in await query('SELECT * FROM TB_PONTO_HORARIO_DIA WHERE HDI_HORARIO = ?', [horarioId]))
          asInt(r['HDI_DIA_SEMANA']): r
      };

  Future<void> salvarHorarioDias(
      int horarioId, Map<int, ({String e1, String s1, String e2, String s2, int carga, bool folga})> dias) async {
    await exec('DELETE FROM TB_PONTO_HORARIO_DIA WHERE HDI_HORARIO = ?', [horarioId]);
    for (final e in dias.entries) {
      final d = e.value;
      await exec(
          'INSERT INTO TB_PONTO_HORARIO_DIA (HDI_HORARIO, HDI_DIA_SEMANA, HDI_ENTRADA_1, HDI_SAIDA_1, HDI_ENTRADA_2, '
          'HDI_SAIDA_2, HDI_CARGA_MIN, HDI_FOLGA) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [horarioId, e.key, d.e1.trim(), d.s1.trim(), d.e2.trim(), d.s2.trim(), d.carga, d.folga ? 'S' : 'N']);
    }
  }

  /// Escala em ciclo (ex.: 6x1 = 6 dias de trabalho e 1 de folga), a partir de HOR_ESCALA_INICIO.
  Future<void> salvarCicloHorario(int id, int trabalho, int folga) => exec(
      'UPDATE TB_PONTO_HORARIO SET HOR_CICLO_TRABALHO = ?, HOR_CICLO_FOLGA = ? WHERE HOR_ID = ?',
      [trabalho > 0 ? trabalho : null, folga > 0 ? folga : null, id]);

  // ======================= Justificativas =======================

  Future<void> salvarJustificativa(int pessoaId, DateTime data, String tipo, String motivo, int abonoMin) async {
    final d = soData(data);
    await exec('DELETE FROM TB_PONTO_JUSTIFICATIVA WHERE JUS_PESSOA = ? AND JUS_DATA = ?', [pessoaId, d]);
    await exec(
        'INSERT INTO TB_PONTO_JUSTIFICATIVA (JUS_PESSOA, JUS_DATA, JUS_TIPO, JUS_MOTIVO, JUS_ABONO_MINUTOS, JUS_USUARIO) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [pessoaId, d, tipo.trim(), motivo.trim(), abonoMin, usuarioLogado]);
  }

  Future<void> excluirJustificativa(int id) => exec('DELETE FROM TB_PONTO_JUSTIFICATIVA WHERE JUS_ID = ?', [id]);

  Future<List<DbRow>> getJustificativasPeriodo(int pessoaId, DateTime ini, DateTime fim) => query(
      'SELECT JUS_ID, JUS_PESSOA, JUS_DATA, JUS_TIPO, JUS_MOTIVO, JUS_ABONO_MINUTOS, JUS_CRIADO_EM '
      'FROM TB_PONTO_JUSTIFICATIVA WHERE JUS_PESSOA = ? AND JUS_DATA >= ? AND JUS_DATA <= ? ORDER BY JUS_DATA',
      [pessoaId, soData(ini), soData(fim)]);

  // ======================= Empresa =======================

  Future<EmpresaInfo?> getEmpresaPrincipal() async {
    final r = await queryOne(_first1('EMP_RAZAO_SOCIAL, EMP_CNPJ, EMP_ENDERECO, EMP_NUMERO, EMP_BAIRRO '
        "FROM TB_EMPRESA WHERE EMP_STATUS = 'A' OR EMP_STATUS IS NULL ORDER BY EMP_ID"));
    if (r == null) return null;
    var end = asStr(r['EMP_ENDERECO']).trim();
    final num = asStr(r['EMP_NUMERO']).trim();
    final bairro = asStr(r['EMP_BAIRRO']).trim();
    if (num.isNotEmpty) end += ', $num';
    if (bairro.isNotEmpty) end += ' - $bairro';
    return EmpresaInfo()
      ..razao = asStr(r['EMP_RAZAO_SOCIAL']).trim()
      ..cnpj = asStr(r['EMP_CNPJ']).trim()
      ..endereco = end;
  }

  Future<bool> salvarEmpresaPrincipal(String razao, String cnpj, String endereco) async =>
      await exec(
          'UPDATE TB_EMPRESA SET EMP_RAZAO_SOCIAL = ?, EMP_CNPJ = ?, EMP_ENDERECO = ? '
          'WHERE EMP_ID = (SELECT FIRST 1 EMP_ID FROM TB_EMPRESA)',
          [razao, cnpj, endereco]) >
      0;

  // ======================= Marcações =======================

  Future<bool> gravarMarcacao(int pessoaId, int relogioId, DateTime dataHora, int evento, int controlIdLogId,
      String origem, int nsr, String pis, String cpf, String tipoBatida, String tipoIdent) async {
    try {
      final r = await queryOne(
          'SELECT PMA_ID FROM TB_PONTO_MARCACAO WHERE PMA_RELOGIO = ? AND PMA_CONTROLID_LOG_ID = ?',
          [relogioId, controlIdLogId]);
      if (r != null) return true; // já gravado
      await exec(
          'INSERT INTO TB_PONTO_MARCACAO (PMA_PESSOA, PMA_RELOGIO, PMA_DATA_HORA, PMA_EVENTO, PMA_CONTROLID_LOG_ID, '
          'PMA_ORIGEM, PMA_NSR, PMA_PIS, PMA_CPF, PMA_TIPO_BATIDA, PMA_TIPO_IDENTIFICACAO, PMA_EXPORTADO) '
          "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'N')",
          [
            pessoaId > 0 ? pessoaId : null, relogioId, dataHora, evento, controlIdLogId,
            origem.isEmpty ? 'C' : origem.substring(0, 1), nsr, pis, cpf, tipoBatida, tipoIdent
          ]);
      return true;
    } catch (e) {
      lastError = 'Erro ao gravar marcação: $e';
      return false;
    }
  }

  /// Condição SQL das batidas válidas (as desconsideradas ficam guardadas, mas não contam).
  static const validas = "COALESCE(PMA_DESCONSIDERADA, 'N') = 'N'";

  Future<List<DbRow>> getMarcacoes(DateTime ini, DateTime fim,
      {int relogioId = 0, int pessoaId = 0, bool incluirDesconsideradas = false}) {
    final params = <dynamic>[inicioDoDia(ini), fimDoDia(fim)];
    var sql = 'SELECT M.PMA_ID, M.PMA_PESSOA, M.PMA_RELOGIO, M.PMA_DATA_HORA, M.PMA_EVENTO, M.PMA_CONTROLID_LOG_ID, '
        'M.PMA_NSR, M.PMA_PIS, M.PMA_CPF, M.PMA_TIPO_BATIDA, M.PMA_TIPO_IDENTIFICACAO, '
        'M.PMA_ORIGEM, M.PMA_EXPORTADO, M.PMA_MOTIVO_AJUSTE, M.PMA_ID_ORIGINAL, '
        "COALESCE(M.PMA_DESCONSIDERADA, 'N') AS PMA_DESCONSIDERADA, M.PMA_MOTIVO_DESCONSIDERACAO, "
        'R.PRE_NOME AS RELOGIO_NOME, '
        "COALESCE(P.PES_RSOCIAL_NOME, 'NÃO IDENTIFICADO') AS PESSOA_NOME "
        'FROM TB_PONTO_MARCACAO M '
        'LEFT JOIN TB_PONTO_RELOGIO R ON R.PRE_ID = M.PMA_RELOGIO '
        'LEFT JOIN TB_PESSOA P ON P.PES_ID = M.PMA_PESSOA '
        'WHERE M.PMA_DATA_HORA BETWEEN ? AND ? ';
    if (!incluirDesconsideradas) sql += "AND COALESCE(M.PMA_DESCONSIDERADA, 'N') = 'N' ";
    if (relogioId > 0) {
      sql += 'AND M.PMA_RELOGIO = ? ';
      params.add(relogioId);
    }
    if (pessoaId > 0) {
      sql += 'AND M.PMA_PESSOA = ? ';
      params.add(pessoaId);
    }
    return query('${sql}ORDER BY M.PMA_DATA_HORA DESC, M.PMA_ID DESC', params);
  }

  static String _limite(String s, [int n = 250]) {
    final t = s.trim();
    return t.length > n ? t.substring(0, n) : t;
  }

  /// Portaria 671: a batida não é apagada; fica desconsiderada, com motivo e data.
  Future<bool> desconsiderarMarcacao(int id, String motivo) async =>
      await exec(
          "UPDATE TB_PONTO_MARCACAO SET PMA_DESCONSIDERADA = 'S', PMA_MOTIVO_DESCONSIDERACAO = ?, "
          'PMA_DATA_DESCONSIDERACAO = CURRENT_TIMESTAMP, PMA_USUARIO_ALTERACAO = ? WHERE PMA_ID = ?',
          [_limite(motivo), usuarioLogado, id]) >
      0;

  /// Volta a considerar uma batida desconsiderada por engano.
  Future<bool> restaurarMarcacao(int id) async =>
      await exec(
          "UPDATE TB_PONTO_MARCACAO SET PMA_DESCONSIDERADA = 'N', PMA_MOTIVO_DESCONSIDERACAO = NULL, "
          'PMA_DATA_DESCONSIDERACAO = NULL, PMA_USUARIO_ALTERACAO = ? WHERE PMA_ID = ?',
          [usuarioLogado, id]) >
      0;

  /// Correção conforme a Portaria 671: a original fica desconsiderada e uma nova batida
  /// (origem "M" - incluída) é gravada com o motivo e o vínculo com a original. Retorna o novo ID.
  Future<int> corrigirMarcacao(int id, DateTime dataHora, String tipo, String motivo) async {
    final o = await queryOne('SELECT PMA_PESSOA, PMA_RELOGIO FROM TB_PONTO_MARCACAO WHERE PMA_ID = ?', [id]);
    if (o == null) return 0;
    final r = await execReturning(
        'INSERT INTO TB_PONTO_MARCACAO (PMA_PESSOA, PMA_RELOGIO, PMA_DATA_HORA, PMA_TIPO_BATIDA, PMA_ORIGEM, '
        "PMA_EVENTO, PMA_EXPORTADO, PMA_MOTIVO_AJUSTE, PMA_ID_ORIGINAL, PMA_USUARIO_ALTERACAO, PMA_DATA_ALTERACAO) "
        "VALUES (?, ?, ?, ?, 'M', 7, 'N', ?, ?, ?, CURRENT_TIMESTAMP) RETURNING PMA_ID",
        [o['PMA_PESSOA'], o['PMA_RELOGIO'], dataHora, tipo.trim().toUpperCase(), _limite(motivo), id, usuarioLogado]);
    final novo = asInt(r?['PMA_ID']);
    if (novo > 0) await desconsiderarMarcacao(id, 'Corrigida pela batida #$novo: ${motivo.trim()}');
    return novo;
  }

  Future<int> inserirMarcacaoManual(int pessoaId, int relogioId, DateTime dataHora, String tipo,
      [String motivo = '']) async {
    final m = motivo.trim();
    final r = await execReturning(
        'INSERT INTO TB_PONTO_MARCACAO (PMA_PESSOA, PMA_RELOGIO, PMA_DATA_HORA, PMA_TIPO_BATIDA, PMA_ORIGEM, '
        "PMA_EVENTO, PMA_EXPORTADO, PMA_MOTIVO_AJUSTE, PMA_USUARIO_ALTERACAO, PMA_DATA_ALTERACAO) "
        "VALUES (?, ?, ?, ?, 'M', 7, 'N', ?, ?, CURRENT_TIMESTAMP) RETURNING PMA_ID",
        [
          pessoaId, relogioId > 0 ? relogioId : null, dataHora, tipo.trim().toUpperCase(),
          m.length > 250 ? m.substring(0, 250) : m, usuarioLogado
        ]);
    return asInt(r?['PMA_ID']);
  }

  // ======================= Dashboard =======================

  Future<int> _count(String sql, [List<dynamic> p = const []]) async {
    try {
      return asInt((await queryOne(sql, p))?['TOTAL']);
    } catch (e) {
      lastError = e.toString();
      return 0;
    }
  }

  Future<int> getTotalMarcacoesHoje() => _count(
      'SELECT COUNT(*) AS TOTAL FROM TB_PONTO_MARCACAO WHERE PMA_DATA_HORA >= ? AND $validas', [inicioDoDia(DateTime.now())]);

  Future<int> getTotalColaboradores() => _count('SELECT COUNT(*) AS TOTAL FROM TB_PESSOA P '
      "LEFT JOIN TB_COLABORADOR C ON C.COL_PESSOA = P.PES_ID WHERE P.PES_COLABORADOR = 'S' OR C.COL_PESSOA IS NOT NULL");

  Future<int> getTotalRelogiosAtivos() =>
      _count("SELECT COUNT(*) AS TOTAL FROM TB_PONTO_RELOGIO WHERE PRE_ATIVO = 'S' AND PRE_STATUS = 'A'");

  // ======================= Estrutura / Migração =======================

  Future<bool> tabelaExiste(String t) async =>
      await queryOne('SELECT 1 AS X FROM RDB\$RELATIONS WHERE UPPER(TRIM(RDB\$RELATION_NAME)) = UPPER(TRIM(?))', [t]) !=
      null;

  Future<bool> campoExiste(String t, String c) async =>
      await queryOne(
          'SELECT 1 AS X FROM RDB\$RELATION_FIELDS WHERE UPPER(TRIM(RDB\$RELATION_NAME)) = UPPER(TRIM(?)) '
          'AND UPPER(TRIM(RDB\$FIELD_NAME)) = UPPER(TRIM(?))',
          [t, c]) !=
      null;

  Future<bool> generatorExiste(String g) async =>
      await queryOne(
          'SELECT 1 AS X FROM RDB\$GENERATORS WHERE UPPER(TRIM(RDB\$GENERATOR_NAME)) = UPPER(TRIM(?))', [g]) !=
      null;

  Future<void> _addCampo(String tabela, String campo, String tipo) async {
    if (!await campoExiste(tabela, campo)) await execDdl('ALTER TABLE $tabela ADD $campo $tipo');
  }

  Future<void> _garantirGenerator(String g) async {
    if (!await generatorExiste(g)) await execDdl('CREATE GENERATOR $g');
  }

  Future<int> obterProximoIdPessoa() async {
    // TB_PESSOA pode não ter trigger de auto-incremento: gera o ID aqui.
    final maxId = asInt((await queryOne('SELECT COALESCE(MAX(PES_ID), 0) AS M FROM TB_PESSOA'))?['M']);
    final g = await queryOne('SELECT FIRST 1 TRIM(RDB\$GENERATOR_NAME) AS NOME FROM RDB\$GENERATORS '
        "WHERE COALESCE(RDB\$SYSTEM_FLAG, 0) = 0 AND UPPER(RDB\$GENERATOR_NAME) LIKE '%PESSOA%' "
        'ORDER BY CHAR_LENGTH(TRIM(RDB\$GENERATOR_NAME))');
    final nome = asStr(g?['NOME']).trim();
    if (nome.isEmpty) return maxId + 1;
    var valor = asInt((await queryOne('SELECT GEN_ID("$nome", 1) AS V FROM RDB\$DATABASE'))?['V']);
    if (valor <= maxId) {
      valor = asInt((await queryOne('SELECT GEN_ID("$nome", ${maxId + 1 - valor}) AS V FROM RDB\$DATABASE'))?['V']);
    }
    return valor;
  }

  Future<void> garantirAutoIncremento(String tabela, String campo, String generator) async {
    if (!await tabelaExiste(tabela)) return;
    await _garantirGenerator(generator);
    final trigger = 'TRG_${tabela.substring(3)}_BI'; // TB_PONTO_X -> TRG_PONTO_X_BI

    // Generator nunca abaixo do maior ID já gravado
    final maxId = asInt((await queryOne('SELECT COALESCE(MAX($campo), 0) AS M FROM $tabela'))?['M']);
    final valor = asInt((await queryOne('SELECT GEN_ID($generator, 0) AS V FROM RDB\$DATABASE'))?['V']);
    if (valor < maxId) await queryOne('SELECT GEN_ID($generator, ${maxId - valor}) AS V FROM RDB\$DATABASE');

    final existeNosso = await queryOne(
            'SELECT 1 AS X FROM RDB\$TRIGGERS WHERE UPPER(TRIM(RDB\$TRIGGER_NAME)) = ?', [trigger.toUpperCase()]) !=
        null;
    // Outro trigger BEFORE INSERT já gera o ID: não duplica
    final existeOutro = await queryOne(
            'SELECT 1 AS X FROM RDB\$TRIGGERS WHERE UPPER(TRIM(RDB\$RELATION_NAME)) = ? '
            'AND RDB\$TRIGGER_TYPE = 1 AND UPPER(TRIM(RDB\$TRIGGER_NAME)) <> ?',
            [tabela.toUpperCase(), trigger.toUpperCase()]) !=
        null;
    if (existeOutro) {
      if (existeNosso) await execDdl('DROP TRIGGER $trigger');
      return;
    }
    if (existeNosso) return;
    await execDdl('CREATE TRIGGER $trigger FOR $tabela ACTIVE BEFORE INSERT POSITION 0 AS '
        'BEGIN IF (NEW.$campo IS NULL) THEN NEW.$campo = GEN_ID($generator, 1); END');
  }

  Future<void> garantirCampoOpcional(String tabela, String campo) async {
    final r = await queryOne(
        'SELECT 1 AS X FROM RDB\$RELATION_FIELDS WHERE UPPER(TRIM(RDB\$RELATION_NAME)) = ? '
        'AND UPPER(TRIM(RDB\$FIELD_NAME)) = ? AND COALESCE(RDB\$NULL_FLAG, 0) = 1',
        [tabela.toUpperCase(), campo.toUpperCase()]);
    if (r == null) return;
    // Firebird 3+: DROP NOT NULL. Firebird 2.5: limpa o flag direto no catálogo.
    if (!await execDdl('ALTER TABLE $tabela ALTER $campo DROP NOT NULL')) {
      await execDdl("UPDATE RDB\$RELATION_FIELDS SET RDB\$NULL_FLAG = NULL "
          "WHERE RDB\$RELATION_NAME = '${tabela.toUpperCase()}' AND RDB\$FIELD_NAME = '${campo.toUpperCase()}'");
    }
  }

  Future<int> obterVersaoBanco() async {
    if (!await tabelaExiste('TB_PONTO_VERSAO_BD')) return 0;
    return asInt((await queryOne('SELECT COALESCE(MAX(VER_NUMERO), 0) AS ATUAL FROM TB_PONTO_VERSAO_BD'))?['ATUAL']);
  }

  Future<String> verificarEAtualizarEstruturaBanco() async {
    await _garantirTabelasBase();
    // 1. Tabela de controle de versão
    if (!await tabelaExiste('TB_PONTO_VERSAO_BD')) {
      await execDdl('CREATE TABLE TB_PONTO_VERSAO_BD (VER_ID INTEGER NOT NULL PRIMARY KEY, '
          'VER_NUMERO INTEGER NOT NULL, VER_SISTEMA VARCHAR(20), '
          'VER_DATA_HORA TIMESTAMP DEFAULT CURRENT_TIMESTAMP, VER_DESCRICAO VARCHAR(250))');
    }
    await _garantirGenerator('GEN_PONTO_VERSAO_BD');
    await _addCampo('TB_PONTO_VERSAO_BD', 'VER_ACAO', 'VARCHAR(40)');
    await _addCampo('TB_PONTO_VERSAO_BD', 'VER_STATUS', "CHAR(1) DEFAULT 'A'");
    await _addCampo('TB_PONTO_VERSAO_BD', 'VER_SCRIPT', 'BLOB SUB_TYPE TEXT');
    await _addCampo('TB_PONTO_VERSAO_BD', 'VER_PROGRESSO', 'BLOB SUB_TYPE TEXT');
    await _addCampo('TB_PONTO_VERSAO_BD', 'VER_ERROS', 'BLOB SUB_TYPE TEXT');

    // 2. TB_PONTO_RELOGIO
    if (!await tabelaExiste('TB_PONTO_RELOGIO')) {
      await execDdl('CREATE TABLE TB_PONTO_RELOGIO (PRE_ID INTEGER NOT NULL PRIMARY KEY, '
          'PRE_NOME VARCHAR(60) NOT NULL, PRE_IP VARCHAR(45) NOT NULL, PRE_PORTA INTEGER DEFAULT 80, '
          "PRE_USAR_SSL CHAR(1) DEFAULT 'N', PRE_USUARIO VARCHAR(40), PRE_SENHA VARCHAR(40), "
          "PRE_MODELO VARCHAR(40) DEFAULT 'IDCLASS', PRE_MODO_COLETA VARCHAR(20) DEFAULT 'API', "
          "PRE_ULTIMO_LOG_ID BIGINT DEFAULT 0, PRE_STATUS CHAR(1) DEFAULT 'A', PRE_ATIVO CHAR(1) DEFAULT 'S', "
          'PRE_DEVICE_ID VARCHAR(50), PRE_SERIAL VARCHAR(50), PRE_VERSAO_FW VARCHAR(50), '
          'PRE_ULTIMA_COLETA TIMESTAMP, PRE_DATA_HORA_SYNC TIMESTAMP)');
    }
    for (final c in const [
      ['PRE_PORTA', 'INTEGER DEFAULT 80'],
      ['PRE_USAR_SSL', "CHAR(1) DEFAULT 'N'"],
      ['PRE_MODELO', "VARCHAR(40) DEFAULT 'IDCLASS'"],
      ['PRE_MODO_COLETA', "VARCHAR(20) DEFAULT 'API'"],
      ['PRE_ULTIMA_COLETA', 'TIMESTAMP'],
      ['PRE_SERIAL', 'VARCHAR(50)'],
      ['PRE_VERSAO_FW', 'VARCHAR(50)'],
      ['PRE_ATIVO', "CHAR(1) DEFAULT 'S'"],
      ['PRE_DATA_HORA_SYNC', 'TIMESTAMP'],
      ['PRE_LOCALIZACAO', 'VARCHAR(60)'],
      ['PRE_MAC', 'VARCHAR(20)'],
      ['PRE_TIMEZONE', 'VARCHAR(30)'],
    ]) {
      await _addCampo('TB_PONTO_RELOGIO', c[0], c[1]);
    }
    await _garantirGenerator('GEN_PONTO_RELOGIO');

    // 3. TB_PONTO_MARCACAO
    if (!await tabelaExiste('TB_PONTO_MARCACAO')) {
      await execDdl('CREATE TABLE TB_PONTO_MARCACAO (PMA_ID BIGINT NOT NULL PRIMARY KEY, PMA_RELOGIO INTEGER, '
          'PMA_PESSOA INTEGER, PMA_NSR BIGINT, PMA_DATA_HORA TIMESTAMP NOT NULL, PMA_TIPO_BATIDA VARCHAR(20), '
          'PMA_TIPO_IDENTIFICACAO VARCHAR(30), PMA_CPF VARCHAR(14), PMA_PIS VARCHAR(15), '
          "PMA_ORIGEM CHAR(1) DEFAULT 'C', PMA_EXPORTADO CHAR(1) DEFAULT 'N', PMA_EVENTO INTEGER DEFAULT 7, "
          'PMA_MOTIVO_AJUSTE VARCHAR(250))');
    }
    for (final c in const [
      ['PMA_NSR', 'BIGINT'],
      ['PMA_PIS', 'VARCHAR(15)'],
      ['PMA_CPF', 'VARCHAR(14)'],
      ['PMA_TIPO_BATIDA', 'VARCHAR(20)'],
      ['PMA_TIPO_IDENTIFICACAO', 'VARCHAR(30)'],
      ['PMA_ORIGEM', "CHAR(1) DEFAULT 'C'"],
      ['PMA_EXPORTADO', "CHAR(1) DEFAULT 'N'"],
      ['PMA_EVENTO', 'INTEGER DEFAULT 7'],
      ['PMA_MOTIVO_AJUSTE', 'VARCHAR(250)'],
      ['PMA_DATA_ALTERACAO', 'TIMESTAMP'],
      ['PMA_USUARIO_ALTERACAO', 'VARCHAR(40)'],
      ['PMA_JUSTIFICATIVA_ID', 'INTEGER'],
      ['PMA_CONTROLID_LOG_ID', 'BIGINT'],
    ]) {
      await _addCampo('TB_PONTO_MARCACAO', c[0], c[1]);
    }
    await _garantirGenerator('GEN_PONTO_MARCACAO');
    await execDdl('CREATE INDEX IDX_PMA_DATA_HORA ON TB_PONTO_MARCACAO (PMA_DATA_HORA)');
    await execDdl('CREATE INDEX IDX_PMA_PESSOA ON TB_PONTO_MARCACAO (PMA_PESSOA)');

    // 4. TB_COLABORADOR - campos complementares
    if (await tabelaExiste('TB_COLABORADOR')) {
      for (final c in const [
        ['COL_SINCRONIZADO_RELOGIO', "CHAR(1) DEFAULT 'N'"],
        ['COL_ULTIMA_SINCRONIZACAO', 'TIMESTAMP'],
        ['COL_HORARIO', 'INTEGER'],
        ['COL_SENHA_RELOGIO', 'VARCHAR(20)'],
        ['COL_RFID', 'BIGINT'],
        ['COL_ADMIN_RELOGIO', "CHAR(1) DEFAULT 'N'"],
        ['COL_BARRAS', 'VARCHAR(30)'],
        ['COL_MATRICULA', 'VARCHAR(20)'],
        ['COL_DEPARTAMENTO', 'VARCHAR(50)'],
        ['COL_BIOMETRIA_CADASTRADA', "CHAR(1) DEFAULT 'N'"],
        ['COL_BIOMETRIA', 'BLOB SUB_TYPE TEXT'],
        ['COL_BIOMETRIA_DATA', 'TIMESTAMP'],
      ]) {
        await _addCampo('TB_COLABORADOR', c[0], c[1]);
      }
    }

    // 5. TB_PONTO_HORARIO
    if (!await tabelaExiste('TB_PONTO_HORARIO')) {
      await execDdl('CREATE TABLE TB_PONTO_HORARIO (HOR_ID INTEGER NOT NULL PRIMARY KEY, '
          'HOR_DESCRICAO VARCHAR(60) NOT NULL, HOR_ENTRADA_1 TIME, HOR_SAIDA_1 TIME, HOR_ENTRADA_2 TIME, '
          'HOR_SAIDA_2 TIME, HOR_TOLERANCIA_MIN INTEGER DEFAULT 10, HOR_CARGA_DIARIA_MIN INTEGER DEFAULT 528, '
          "HOR_COMPENSA_SABADO CHAR(1) DEFAULT 'S', HOR_TRABALHA_SABADO CHAR(1) DEFAULT 'N', "
          "HOR_SAB_ENTRADA_1 TIME, HOR_SAB_SAIDA_1 TIME, HOR_ATIVO CHAR(1) DEFAULT 'S')");
    }
    await _addCampo('TB_PONTO_HORARIO', 'HOR_SAB_ENTRADA_1', 'TIME');
    await _addCampo('TB_PONTO_HORARIO', 'HOR_SAB_SAIDA_1', 'TIME');
    await _addCampo('TB_PONTO_HORARIO', 'HOR_COMPENSA_SABADO', "CHAR(1) DEFAULT 'S'");
    await _addCampo('TB_PONTO_HORARIO', 'HOR_TRABALHA_SABADO', "CHAR(1) DEFAULT 'N'");
    await _addCampo('TB_PONTO_HORARIO', 'HOR_ATIVO', "CHAR(1) DEFAULT 'S'");
    await _garantirGenerator('GEN_PONTO_HORARIO');

    // Horários padrão caso não existam
    if (await tabelaExiste('TB_PONTO_HORARIO') &&
        asInt((await queryOne('SELECT COUNT(*) AS QTD FROM TB_PONTO_HORARIO'))?['QTD']) == 0) {
      await execDdl('INSERT INTO TB_PONTO_HORARIO (HOR_ID, HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, '
          'HOR_SAIDA_2, HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, HOR_ATIVO) '
          "VALUES (1, 'Comercial 44h (08:00 - 12:00 / 13:12 - 18:00)', '08:00:00', '12:00:00', '13:12:00', "
          "'18:00:00', 10, 528, 'S', 'N', 'S')");
      await execDdl('INSERT INTO TB_PONTO_HORARIO (HOR_ID, HOR_DESCRICAO, HOR_ENTRADA_1, HOR_SAIDA_1, HOR_ENTRADA_2, '
          'HOR_SAIDA_2, HOR_TOLERANCIA_MIN, HOR_CARGA_DIARIA_MIN, HOR_COMPENSA_SABADO, HOR_TRABALHA_SABADO, '
          'HOR_SAB_ENTRADA_1, HOR_SAB_SAIDA_1, HOR_ATIVO) '
          // Descrição cabe em HOR_DESCRICAO VARCHAR(60)
          "VALUES (2, 'Comercial 44h c/ Sabado (08-12 / 14-18 + Sab 08-12)', "
          "'08:00:00', '12:00:00', '14:00:00', '18:00:00', 10, 480, 'N', 'S', '08:00:00', '12:00:00', 'S')");
    }

    // 6. TB_PONTO_JUSTIFICATIVA
    if (!await tabelaExiste('TB_PONTO_JUSTIFICATIVA')) {
      await execDdl('CREATE TABLE TB_PONTO_JUSTIFICATIVA (JUS_ID INTEGER NOT NULL PRIMARY KEY, '
          'JUS_PESSOA INTEGER NOT NULL, JUS_DATA DATE NOT NULL, JUS_TIPO VARCHAR(30) NOT NULL, '
          'JUS_MOTIVO VARCHAR(250), JUS_ABONO_MINUTOS INTEGER DEFAULT 0, '
          'JUS_CRIADO_EM TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    }
    await _addCampo('TB_PONTO_JUSTIFICATIVA', 'JUS_DOCUMENTO', 'VARCHAR(100)');
    await _addCampo('TB_PONTO_JUSTIFICATIVA', 'JUS_STATUS', "CHAR(1) DEFAULT 'A'");
    await _garantirGenerator('GEN_PONTO_JUSTIFICATIVA');

    // Auto-incremento das chaves
    // 7. Regras CLT / Portaria 671 (versão 9)
    // Batidas originais nunca são alteradas nem apagadas: ficam "desconsideradas" com motivo
    await _addCampo('TB_PONTO_MARCACAO', 'PMA_DESCONSIDERADA', "CHAR(1) DEFAULT 'N'");
    await _addCampo('TB_PONTO_MARCACAO', 'PMA_ID_ORIGINAL', 'BIGINT');
    await _addCampo('TB_PONTO_MARCACAO', 'PMA_MOTIVO_DESCONSIDERACAO', 'VARCHAR(250)');
    await _addCampo('TB_PONTO_MARCACAO', 'PMA_DATA_DESCONSIDERACAO', 'TIMESTAMP');
    // Escalas: semanal ou 12x36, virada do dia para turnos noturnos, intervalo mínimo e banco de horas
    await _addCampo('TB_PONTO_HORARIO', 'HOR_TIPO_ESCALA', "VARCHAR(10) DEFAULT 'SEMANAL'");
    await _addCampo('TB_PONTO_HORARIO', 'HOR_ESCALA_INICIO', 'DATE');
    await _addCampo('TB_PONTO_HORARIO', 'HOR_VIRADA_DIA', "VARCHAR(5) DEFAULT '00:00'");
    await _addCampo('TB_PONTO_HORARIO', 'HOR_INTERVALO_MIN', 'INTEGER DEFAULT 60');
    await _addCampo('TB_PONTO_HORARIO', 'HOR_BANCO_HORAS', "CHAR(1) DEFAULT 'N'");

    if (!await tabelaExiste('TB_PONTO_FERIADO')) {
      await execDdl('CREATE TABLE TB_PONTO_FERIADO (FER_ID INTEGER NOT NULL PRIMARY KEY, FER_DATA DATE NOT NULL, '
          "FER_DESCRICAO VARCHAR(80) NOT NULL, FER_RECORRENTE CHAR(1) DEFAULT 'S', FER_ABRANGENCIA VARCHAR(20) DEFAULT 'NACIONAL')");
    }
    await _garantirGenerator('GEN_PONTO_FERIADO');
    if (!await tabelaExiste('TB_PONTO_BANCO_HORAS')) {
      await execDdl('CREATE TABLE TB_PONTO_BANCO_HORAS (BH_ID INTEGER NOT NULL PRIMARY KEY, BH_PESSOA INTEGER NOT NULL, '
          "BH_DATA DATE NOT NULL, BH_MINUTOS INTEGER NOT NULL, BH_TIPO CHAR(1) DEFAULT 'C', BH_DESCRICAO VARCHAR(200), "
          'BH_COMPETENCIA VARCHAR(7), BH_CRIADO_EM TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
      await execDdl('CREATE INDEX IDX_BH_PESSOA ON TB_PONTO_BANCO_HORAS (BH_PESSOA, BH_DATA)');
    }
    await _garantirGenerator('GEN_PONTO_BANCO_HORAS');

    // 8. Versão 10: contrato, afastamentos, usuários, jornada por dia, ciclos e biometria do REP
    await _addCampo('TB_COLABORADOR', 'COL_DATA_ADMISSAO', 'DATE');
    await _addCampo('TB_COLABORADOR', 'COL_DATA_DEMISSAO', 'DATE');
    await _addCampo('TB_COLABORADOR', 'COL_BIOMETRIA_CONTROLID', 'BLOB SUB_TYPE TEXT');
    await _addCampo('TB_PONTO_JUSTIFICATIVA', 'JUS_USUARIO', 'VARCHAR(40)');
    await _addCampo('TB_PONTO_HORARIO', 'HOR_CICLO_TRABALHO', 'INTEGER');
    await _addCampo('TB_PONTO_HORARIO', 'HOR_CICLO_FOLGA', 'INTEGER');
    if (!await tabelaExiste('TB_PONTO_AFASTAMENTO')) {
      await execDdl('CREATE TABLE TB_PONTO_AFASTAMENTO (AFA_ID INTEGER NOT NULL PRIMARY KEY, AFA_PESSOA INTEGER NOT NULL, '
          'AFA_INICIO DATE NOT NULL, AFA_FIM DATE NOT NULL, AFA_TIPO VARCHAR(40) NOT NULL, AFA_MOTIVO VARCHAR(250), '
          'AFA_USUARIO VARCHAR(40), AFA_CRIADO_EM TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    }
    await _garantirGenerator('GEN_PONTO_AFASTAMENTO');
    if (!await tabelaExiste('TB_PONTO_USUARIO')) {
      await execDdl('CREATE TABLE TB_PONTO_USUARIO (USU_ID INTEGER NOT NULL PRIMARY KEY, USU_LOGIN VARCHAR(40) NOT NULL, '
          "USU_NOME VARCHAR(100), USU_SENHA_HASH VARCHAR(64), USU_SALT VARCHAR(32), USU_PERFIL VARCHAR(10) DEFAULT 'OPERADOR', "
          "USU_ATIVO CHAR(1) DEFAULT 'S', USU_TROCAR_SENHA CHAR(1) DEFAULT 'N', USU_ULTIMO_ACESSO TIMESTAMP)");
      await execDdl('CREATE UNIQUE INDEX IDX_USU_LOGIN ON TB_PONTO_USUARIO (USU_LOGIN)');
    }
    await _garantirGenerator('GEN_PONTO_USUARIO');
    if (!await tabelaExiste('TB_PONTO_HORARIO_DIA')) {
      await execDdl('CREATE TABLE TB_PONTO_HORARIO_DIA (HDI_HORARIO INTEGER NOT NULL, HDI_DIA_SEMANA INTEGER NOT NULL, '
          'HDI_ENTRADA_1 VARCHAR(5), HDI_SAIDA_1 VARCHAR(5), HDI_ENTRADA_2 VARCHAR(5), HDI_SAIDA_2 VARCHAR(5), '
          "HDI_CARGA_MIN INTEGER DEFAULT 0, HDI_FOLGA CHAR(1) DEFAULT 'N', PRIMARY KEY (HDI_HORARIO, HDI_DIA_SEMANA))");
    }

    await garantirAutoIncremento('TB_PONTO_RELOGIO', 'PRE_ID', 'GEN_PONTO_RELOGIO');
    await garantirAutoIncremento('TB_PONTO_MARCACAO', 'PMA_ID', 'GEN_PONTO_MARCACAO');
    await garantirAutoIncremento('TB_PONTO_HORARIO', 'HOR_ID', 'GEN_PONTO_HORARIO');
    await garantirAutoIncremento('TB_PONTO_JUSTIFICATIVA', 'JUS_ID', 'GEN_PONTO_JUSTIFICATIVA');
    await garantirAutoIncremento('TB_PONTO_FERIADO', 'FER_ID', 'GEN_PONTO_FERIADO');
    await garantirAutoIncremento('TB_PONTO_BANCO_HORAS', 'BH_ID', 'GEN_PONTO_BANCO_HORAS');
    await garantirAutoIncremento('TB_PONTO_AFASTAMENTO', 'AFA_ID', 'GEN_PONTO_AFASTAMENTO');
    await garantirAutoIncremento('TB_PONTO_USUARIO', 'USU_ID', 'GEN_PONTO_USUARIO');
    await _semearFeriados();

    // Batidas do leitor USB e lançamentos manuais não têm relógio
    await garantirCampoOpcional('TB_PONTO_MARCACAO', 'PMA_RELOGIO');
    await garantirCampoOpcional('TB_PONTO_MARCACAO', 'PMA_CONTROLID_LOG_ID');

    // 7. Histórico e scripts de cada versão
    for (final v in versoesBd) {
      await _sincronizarRegistroVersao(v);
    }
    await _sincronizarRegistroVersao(versaoBaseSeparada);
    await _sincronizarRegistroVersao(versaoRegrasClt);
    await _sincronizarRegistroVersao(versaoContratos);
    return 'Base de dados atualizada com sucesso para a versão de schema ${versaoContratos.numero}.';
  }

  Future<void> _sincronizarRegistroVersao(VersaoBdDef v) async {
    try {
      final r = await queryOne('SELECT VER_ID FROM TB_PONTO_VERSAO_BD WHERE VER_NUMERO = ?', [v.numero]);
      if (r == null) {
        await exec(
            'INSERT INTO TB_PONTO_VERSAO_BD (VER_ID, VER_NUMERO, VER_SISTEMA, VER_DATA_HORA, VER_DESCRICAO, '
            'VER_ACAO, VER_STATUS, VER_SCRIPT, VER_PROGRESSO, VER_ERROS) VALUES ('
            '(SELECT COALESCE(MAX(VER_ID), 0) + 1 FROM TB_PONTO_VERSAO_BD), ?, ?, CURRENT_TIMESTAMP, ?, ?, '
            "'A', ?, ?, 'Nenhum erro registrado')",
            [v.numero, v.sistema, v.descricao, v.acao, v.script, v.progresso]);
      } else {
        await exec(
            "UPDATE TB_PONTO_VERSAO_BD SET VER_SISTEMA = ?, VER_DESCRICAO = ?, VER_ACAO = ?, VER_STATUS = 'A', "
            "VER_SCRIPT = ?, VER_PROGRESSO = ?, VER_ERROS = 'Nenhum erro registrado' WHERE VER_NUMERO = ?",
            [v.sistema, v.descricao, v.acao, v.script, v.progresso, v.numero]);
      }
    } catch (e) {
      lastError = e.toString();
    }
  }

  // ======================= Base exclusiva do ponto =======================

  /// Tabelas de cadastro (empresa, pessoas e colaboradores) da base exclusiva do ponto.
  static const _ddlBaseSeparada = <String, String>{
    'TB_EMPRESA': 'CREATE TABLE TB_EMPRESA (EMP_ID INTEGER NOT NULL PRIMARY KEY, EMP_RAZAO_SOCIAL VARCHAR(100), '
        "EMP_CNPJ VARCHAR(20), EMP_ENDERECO VARCHAR(100), EMP_NUMERO VARCHAR(10), EMP_BAIRRO VARCHAR(50), "
        "EMP_STATUS CHAR(1) DEFAULT 'A')",
    'TB_PESSOA': 'CREATE TABLE TB_PESSOA (PES_ID INTEGER NOT NULL PRIMARY KEY, PES_RSOCIAL_NOME VARCHAR(100), '
        "PES_CNPJ_CPF VARCHAR(20), PES_STATUS CHAR(1) DEFAULT 'A', PES_COLABORADOR CHAR(1) DEFAULT 'S', "
        'PES_CODIGO_ACESSO VARCHAR(20), PES_DT_CADASTRO TIMESTAMP)',
    'TB_COLABORADOR': 'CREATE TABLE TB_COLABORADOR (COL_PESSOA INTEGER NOT NULL PRIMARY KEY, COL_EMPRESA INTEGER DEFAULT 1, '
        'COL_CPF VARCHAR(14), COL_PIS VARCHAR(15), COL_CARTAO_PONTO VARCHAR(20), COL_FUNCAO VARCHAR(50), '
        "COL_STATUS CHAR(1) DEFAULT 'A', COL_DT_CADASTRO TIMESTAMP)",
  };

  Future<void> _garantirTabelasBase() async {
    for (final e in _ddlBaseSeparada.entries) {
      if (!await tabelaExiste(e.key)) await execDdl(e.value);
    }
    await execDdl('CREATE INDEX IDX_PES_CPF ON TB_PESSOA (PES_CNPJ_CPF)');
    if (asInt((await queryOne('SELECT COUNT(*) AS QTD FROM TB_EMPRESA'))?['QTD']) == 0) {
      await execDdl("INSERT INTO TB_EMPRESA (EMP_ID, EMP_RAZAO_SOCIAL, EMP_CNPJ, EMP_STATUS) VALUES (1, 'MINHA EMPRESA', '', 'A')");
    }
  }


  Future<List<VersaoBdItem>> obterHistoricoVersoes() async {
    if (!await tabelaExiste('TB_PONTO_VERSAO_BD')) return [];
    final rows = await query('SELECT VER_ID, VER_NUMERO, VER_SISTEMA, VER_DATA_HORA, VER_DESCRICAO, '
        "COALESCE(VER_ACAO, 'actVersao' || VER_NUMERO) AS VER_ACAO, COALESCE(VER_STATUS, 'A') AS VER_STATUS, "
        'VER_SCRIPT, VER_PROGRESSO, VER_ERROS FROM TB_PONTO_VERSAO_BD ORDER BY VER_NUMERO DESC, VER_ID DESC');
    return [
      for (final r in rows)
        VersaoBdItem()
          ..id = asInt(r['VER_ID'])
          ..numero = asInt(r['VER_NUMERO'])
          ..sistema = asStr(r['VER_SISTEMA'])
          ..dataHora = asDate(r['VER_DATA_HORA'])
          ..descricao = asStr(r['VER_DESCRICAO'])
          ..acao = asStr(r['VER_ACAO'])
          ..status = asStr(r['VER_STATUS']).isEmpty ? 'A' : asStr(r['VER_STATUS']).substring(0, 1)
          ..script = asStr(r['VER_SCRIPT'])
          ..progresso = asStr(r['VER_PROGRESSO'])
          ..erros = asStr(r['VER_ERROS'])
    ];
  }
}
