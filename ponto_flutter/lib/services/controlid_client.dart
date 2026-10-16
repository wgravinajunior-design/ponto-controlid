import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/util.dart';

class ControlIdUser {
  int id = 0;
  String name = '', cpf = '', pis = '', registration = '', bars = '', password = '';
  int rfid = 0, code = 0, userTypeId = 0;
  bool admin = false;
  List<String> templates = []; // digitais cadastradas no relógio
}

class ControlIdAccessLog {
  int id = 0, userId = 0, event = 0, deviceId = 0, portalId = 0, identificationRuleId = 0;
  DateTime? time;
}

class AfdRecord {
  int nsr = 0, tipo = 3;
  DateTime dataHora = DateTime.now();
  String pis = '', cpf = '', rawLine = '';
}

class ControlIdCompany {
  int docType = 1; // 1 = CNPJ, 2 = CPF
  String cpfCnpj = '', name = '', address = '', cei = '', cpfResp = '';
}

class SystemInfo {
  String serial = '', fwVersion = '', deviceId = '';
  DateTime? time;
}

class _Resp {
  final int code;
  final String body;
  _Resp(this.code, this.body);
}

/// Mensagens de erro amigáveis (port de FormatarErroAmigavel).
String formatarErroAmigavel(String raw) {
  final low = raw.toLowerCase();
  bool has(String s) => low.contains(s);
  if (has('cadastre empregador')) {
    return 'O relógio de ponto (REP) exige o cadastro prévio do Empregador (CNPJ e Razão Social) no equipamento antes de receber colaboradores.';
  }
  if (has('invalid command')) return 'O comando solicitado não é suportado pelo firmware deste modelo de equipamento.';
  if (has('failed host lookup') || has('no such host') || has('12007')) {
    return 'Endereço IP não localizado. Verifique se o IP informado está correto na rede local.';
  }
  if (has('connection refused') || has('12029') || has('network is unreachable') || has('semáforo') ||
      has('connection failed')) {
    return 'Não foi possível conectar ao relógio. Verifique se o equipamento está ligado e com o cabo de rede conectado.';
  }
  if (has('timeout') || has('timed out') || has('tempo limite')) {
    return 'Tempo limite de resposta esgotado. O relógio demorou para responder; tente novamente.';
  }
  if (has('handshake') || has('certificate') || has('certificado ssl')) {
    return 'Falha no certificado SSL/HTTPS. Desmarque a opção SSL se o equipamento estiver configurado para HTTP comum (porta 80).';
  }
  if (has('status http 401') || has('status 401') || has('unauthorized') || has('invalid credentials')) {
    return 'Usuário ou senha incorretos. Por favor, confira as credenciais de acesso cadastradas.';
  }
  if (has('duplicate key') || has('já existe')) return 'Já existe um cadastro com estes dados na memória do relógio.';
  if (has('user not found')) return 'Colaborador não localizado na memória do relógio.';
  if (has('status -1')) return 'O relógio não retornou resposta. Verifique se o endereço IP e a porta estão corretos.';
  if (has('status http 500')) return 'O relógio encontrou uma falha interna temporária ao processar a solicitação.';
  final m = RegExp(r'"error"\s*:\s*"([^"]*)"').firstMatch(raw);
  if (m != null) return 'O relógio informou: ${m[1]}';
  return raw;
}

/// Cliente da API HTTP dos equipamentos Control iD (port de TControlIDClient).
class ControlIdClient {
  String host;
  int port;
  bool useSsl;
  String user = 'admin';
  String password = 'admin';
  String sessionToken = '';
  String lastError = '';
  int timeoutSec = 5;

  /// REP da Portaria 671 (iDClass 671): usuários identificados pelo CPF e comandos com ?mode=671.
  bool portaria671 = false;
  String get _modo => portaria671 ? 'mode=671' : '';

  ControlIdClient({this.host = '192.168.1.200', this.port = 80, this.useSsl = false});

  String get baseUrl {
    final h = host.trim();
    final https = useSsl || port == 443;
    final proto = https ? 'https://' : 'http://';
    if ((port == 80 && !useSsl) || (port == 443 && https)) return '$proto$h';
    return '$proto$h:$port';
  }

  String buildUrl(String endpoint, {bool includeSession = true, String extra = ''}) {
    var url = baseUrl + (endpoint.startsWith('/') ? '' : '/') + endpoint;
    var sep = '?';
    if (includeSession && sessionToken.isNotEmpty) {
      url += '${sep}session=$sessionToken';
      sep = '&';
    }
    if (extra.isNotEmpty) url += '$sep$extra';
    return url;
  }

  Future<_Resp> _post(String url, String body) async {
    final client = HttpClient()
      ..connectionTimeout = Duration(seconds: timeoutSec)
      // Aceita certificado autoassinado do equipamento Control iD
      ..badCertificateCallback = (cert, host, port) => true;
    try {
      final req = await client.postUrl(Uri.parse(url)).timeout(Duration(seconds: timeoutSec));
      req.followRedirects = true;
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json, text/plain, */*');
      // O firmware Control iD exige Content-Length (não aceita corpo "chunked")
      final bytes = utf8.encode(body);
      req.contentLength = bytes.length;
      req.add(bytes);
      final resp = await req.close().timeout(Duration(seconds: timeoutSec));
      final text = await resp.transform(const Utf8Decoder(allowMalformed: true)).join().timeout(
          Duration(seconds: timeoutSec * 6));
      return _Resp(resp.statusCode, text);
    } catch (e) {
      lastError = 'Falha de comunicação ($url): $e | Verifique se o equipamento está ligado na rede e confirme o IP '
          'na tela do relógio (Menu > Configurações > Rede).';
      return _Resp(-1, '');
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic>? _json(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  static int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);
  static String _str(dynamic v) => v == null ? '' : '$v';
  static bool _ok(int c) => c == 200 || c == 204;

  Future<bool> login(String u, String p) async {
    user = u;
    password = p;
    sessionToken = '';
    lastError = '';
    final r = await _post(buildUrl('login.fcgi', includeSession: false), jsonEncode({'login': u, 'password': p}));
    if (r.code == 200) {
      final j = _json(r.body);
      if (j == null) {
        lastError = 'Falha ao interpretar JSON retornado no login: ${r.body}';
        return false;
      }
      if (j['session'] is String) {
        sessionToken = j['session'];
        return true;
      }
      lastError = 'Resposta de login não continha token de sessão: ${r.body}';
      return false;
    }
    if (!(r.code == -1 && lastError.isNotEmpty)) lastError = 'Falha no login (Status HTTP ${r.code}): ${r.body}';
    return false;
  }

  Future<bool> sessionIsValid() async {
    if (sessionToken.isEmpty) return false;
    final r = await _post(buildUrl('session_is_valid.fcgi'), '{}');
    return r.code == 200 && _json(r.body)?['session_is_valid'] == true;
  }

  Future<void> logout() async {
    if (sessionToken.isEmpty) return;
    try {
      await _post(buildUrl('logout.fcgi'), '{}');
    } finally {
      sessionToken = '';
    }
  }

  Future<bool> ensureSession() async =>
      (sessionToken.isNotEmpty && await sessionIsValid()) || await login(user, password);

  Future<SystemInfo?> getSystemInformation() async {
    if (!await ensureSession()) return null;
    // 1. get_about.fcgi (REP iDClass)
    var r = await _post(buildUrl('get_about.fcgi'), '{}');
    if (r.code == 200) {
      final j = _json(r.body);
      if (j != null) {
        final fw = j['versionFW'];
        return SystemInfo()
          ..serial = _str(j['nSerie'])
          ..fwVersion = fw is num ? 'v.${fw.toInt()}' : _str(fw)
          ..deviceId = _str(j['mac'])
          ..time = DateTime.now();
      }
    }
    // 2. system_information.fcgi (iDAccess/iDFace)
    r = await _post(buildUrl('system_information.fcgi'), '{}');
    if (r.code == 200) {
      final j = _json(r.body);
      if (j != null) {
        final t = _int(j['time']);
        return SystemInfo()
          ..serial = _str(j['serial'])
          ..fwVersion = _str(j['version'])
          ..deviceId = _str(j['device_id'])
          ..time = t > 0 ? DateTime.fromMillisecondsSinceEpoch(t * 1000) : DateTime.now();
      }
    }
    lastError = 'Erro ao obter informações do sistema (Status ${r.code}): ${r.body}';
    return null;
  }

  Future<bool> setSystemTime(DateTime dt) async {
    if (!await ensureSession()) return false;
    final off = dt.timeZoneOffset.inMinutes;
    final tz = '${off < 0 ? '-' : '+'}${(off.abs() ~/ 60).toString().padLeft(2, '0')}'
        '${(off.abs() % 60).toString().padLeft(2, '0')}';
    final base = {
      'day': dt.day, 'month': dt.month, 'year': dt.year,
      'hour': dt.hour, 'minute': dt.minute, 'second': dt.second,
    };
    final comTz = jsonEncode({...base, 'timezone': tz});
    final semTz = jsonEncode(base);
    final tentativas = [
      [buildUrl('set_system_date_time.fcgi', extra: 'mode=671'), comTz],
      [buildUrl('set_system_date_time.fcgi'), comTz],
      [buildUrl('set_system_date_time.fcgi', extra: 'mode=671'), semTz],
      [buildUrl('set_system_time.fcgi'), semTz],
    ];
    _Resp? r;
    for (final t in tentativas) {
      r = await _post(t[0], t[1]);
      if (_ok(r.code)) return true;
    }
    lastError = 'Erro ao ajustar data/hora (Status ${r!.code}): ${r.body}';
    return false;
  }

  Future<ControlIdCompany?> getCompany() async {
    if (!await ensureSession()) return null;
    final r = await _post(buildUrl('load_company.fcgi'), '{}');
    if (r.code == 200) {
      final c = _json(r.body)?['company'];
      if (c is Map) {
        String numStr(dynamic v) => (v is num && v > 0) ? '${v.toInt()}' : _str(v);
        return ControlIdCompany()
          ..docType = _int(c['tipo_doc']) == 0 ? 1 : _int(c['tipo_doc'])
          ..cpfCnpj = numStr(c['cpf_cnpj'])
          ..name = _str(c['name'])
          ..address = _str(c['address'])
          ..cei = numStr(c['cei'])
          ..cpfResp = numStr(c['cpf']);
      }
    }
    lastError = 'Erro ao carregar dados do empregador no relógio (Status ${r.code}): ${r.body}';
    return null;
  }

  Future<bool> setCompany(ControlIdCompany c) async {
    if (!await ensureSession()) return false;
    final doc = onlyDigits(c.cpfCnpj);
    final docNum = int.tryParse(doc) ?? 0;
    var cpfNum = int.tryParse(onlyDigits(c.cpfResp)) ?? 0;
    if (c.docType == 1 && cpfNum == 0 && doc.length == 11) cpfNum = docNum;
    final body = jsonEncode({
      'company': {
        'tipo_doc': c.docType, 'cpf_cnpj': docNum, 'name': c.name, 'address': c.address,
        'cei': int.tryParse(onlyDigits(c.cei)) ?? 0, 'cpf': cpfNum,
      }
    });
    final r = await _post(buildUrl('edit_company.fcgi'), body);
    if (_ok(r.code)) return true;
    lastError = 'Erro ao salvar dados do empregador no relógio (Status ${r.code}): ${r.body}';
    return false;
  }

  Future<List<ControlIdUser>?> getUsers() async {
    if (!await ensureSession()) return null;
    // 1. load_users.fcgi (REP iDClass)
    var r = await _post(buildUrl('load_users.fcgi', extra: _modo),
        portaria671 ? '{"limit":1000,"offset":0,"templates":true}' : '{"limit":1000,"offset":0}');
    if (r.code == 200) {
      final arr = _json(r.body)?['users'];
      if (arr is List) {
        return [
          for (final u in arr.whereType<Map>())
            () {
              final it = ControlIdUser()..name = _str(u['name']);
              final cpf = _int(u['cpf']);
              if (cpf > 0) {
                it.cpf = cpf.toString().padLeft(11, '0');
                it.id = cpf;
              }
              final tpl = u['templates'];
              if (tpl is List) {
                for (final t in tpl) {
                  if (t is String && t.isNotEmpty) {
                    it.templates.add(t);
                  } else if (t is Map) {
                    final s = t.values.whereType<String>().fold<String>('', (a, b) => b.length > a.length ? b : a);
                    if (s.isNotEmpty) it.templates.add(s);
                  }
                }
              }
              final pis = _int(u['pis']);
              if (pis > 0) {
                it.pis = pis.toString().padLeft(11, '0');
                if (it.cpf.isEmpty) it.cpf = it.pis;
                if (it.id == 0) it.id = pis;
              }
              final reg = _int(u['registration']);
              if (reg > 0) {
                it.registration = '$reg';
                if (it.id == 0) it.id = reg;
              } else {
                it.registration = _str(u['registration']);
              }
              it
                ..bars = _str(u['bars'])
                ..rfid = _int(u['rfid'])
                ..code = _int(u['code'])
                ..password = _str(u['password'])
                ..admin = u['admin'] == true;
              return it;
            }()
        ];
      }
    }
    // 2. load_objects.fcgi (iDFace / iDAccess)
    r = await _post(buildUrl('load_objects.fcgi'), '{"object":"users"}');
    if (r.code == 200) {
      final arr = _json(r.body)?['users'];
      if (arr is List) {
        return [
          for (final u in arr.whereType<Map>())
            ControlIdUser()
              ..id = _int(u['id'])
              ..name = _str(u['name'])
              ..registration = _str(u['registration'])
              ..password = _str(u['password'])
              ..userTypeId = _int(u['user_type_id'])
        ];
      }
    }
    lastError = 'Erro ao carregar usuários do relógio (Status ${r.code}): ${r.body}';
    return null;
  }

  ({int pis, int reg, int code}) _ids(ControlIdUser u) {
    final pis = int.tryParse(onlyDigits(u.pis)) ?? int.tryParse(onlyDigits(u.cpf)) ?? 0;
    final reg = int.tryParse(onlyDigits(u.registration)) ?? u.id;
    return (pis: pis, reg: reg, code: u.code > 0 ? u.code : reg);
  }

  String _repUserBody(ControlIdUser u, {bool comTemplates = true}) {
    final i = _ids(u);
    final cpf = int.tryParse(onlyDigits(u.cpf)) ?? 0;
    return jsonEncode({
      'users': [
        {
          'name': u.name,
          // Portaria 671: o trabalhador é identificado pelo CPF; Portaria 1510: pelo PIS
          if (portaria671) 'cpf': cpf > 0 ? cpf : i.pis else 'pis': i.pis,
          'registration': i.reg, 'bars': u.bars, 'rfid': u.rfid,
          'code': i.code, 'password': u.password, 'admin': u.admin,
          if (comTemplates && u.templates.isNotEmpty) 'templates': u.templates,
        }
      ]
    });
  }

  /// Contadores do equipamento (usuários, digitais, senhas, cartões...).
  Future<Map<String, dynamic>?> getInfo() async {
    if (!await ensureSession()) return null;
    final r = await _post(buildUrl('get_info.fcgi', extra: _modo), '{}');
    return r.code == 200 ? _json(r.body) : null;
  }

  /// Retorna o novo ID (> 0) ou null em caso de falha.
  Future<int?> addUser(ControlIdUser u) async {
    if (!await ensureSession()) return null;
    final i = _ids(u);
    final body = _repUserBody(u);
    var r = await _post(buildUrl('add_users.fcgi', extra: _modo), body);
    // Firmware que não aceita as digitais junto do cadastro: envia só os dados
    if (!_ok(r.code) && u.templates.isNotEmpty) r = await _post(buildUrl('add_users.fcgi', extra: _modo), _repUserBody(u, comTemplates: false));
    if (_ok(r.code)) return i.reg > 0 ? i.reg : i.pis;

    final low = r.body.toLowerCase();
    if (r.code == 400 && (low.contains('já existe') || low.contains('duplicate'))) {
      r = await _post(buildUrl('update_users.fcgi', extra: _modo), body);
      if (_ok(r.code)) return i.reg;
    }

    if (r.code == 400 && r.body.toLowerCase().contains('invalid command')) {
      final values = <String, dynamic>{'name': u.name, 'registration': u.registration, 'password': u.password};
      if (u.id > 0) values['id'] = u.id;
      r = await _post(buildUrl('create_objects.fcgi'), jsonEncode({'object': 'users', 'values': [values]}));
      if (r.code == 200) {
        final ids = _json(r.body)?['ids'];
        final newId = (ids is List && ids.isNotEmpty) ? _int(ids.first) : u.id;
        if (u.rfid > 0 && newId > 0) {
          await _post(buildUrl('create_objects.fcgi'), jsonEncode({
            'object': 'cards',
            'values': [{'value': u.rfid, 'user_id': newId}]
          }));
        }
        return newId;
      }
    }
    lastError = 'Erro ao cadastrar colaborador no relógio (Status ${r.code}): ${r.body}';
    return null;
  }

  Future<bool> modifyUser(ControlIdUser u) async {
    if (!await ensureSession()) return false;
    var r = await _post(buildUrl('update_users.fcgi', extra: _modo), _repUserBody(u));
    if (!_ok(r.code) && u.templates.isNotEmpty) {
      r = await _post(buildUrl('update_users.fcgi', extra: _modo), _repUserBody(u, comTemplates: false));
    }
    if (_ok(r.code)) return true;
    if (r.code == 400 && r.body.toLowerCase().contains('invalid command')) {
      r = await _post(buildUrl('modify_objects.fcgi'), jsonEncode({
        'object': 'users',
        'values': {'name': u.name, 'registration': u.registration, 'password': u.password},
        'where': {'users': {'id': u.id}}
      }));
      if (_ok(r.code)) return true;
    }
    lastError = 'Erro ao atualizar colaborador no relógio (Status ${r.code}): ${r.body}';
    return false;
  }

  Future<bool> destroyUser(int id) async {
    if (!await ensureSession()) return false;
    var r = await _post(buildUrl('remove_users.fcgi', extra: _modo), jsonEncode({'users': [id]}));
    if (_ok(r.code)) return true;
    if (r.code == 400 && r.body.toLowerCase().contains('invalid command')) {
      r = await _post(buildUrl('destroy_objects.fcgi'), jsonEncode({
        'object': 'users',
        'where': {'users': {'id': id}}
      }));
      if (_ok(r.code)) return true;
    }
    lastError = 'Erro ao remover colaborador do relógio (Status ${r.code}): ${r.body}';
    return false;
  }

  /// Retorna a quantidade removida, ou null se não conseguiu ler os usuários.
  Future<int?> clearAllUsers() async {
    final users = await getUsers();
    if (users == null) return null;
    var n = 0;
    for (final u in users) {
      if (await destroyUser(u.id)) n++;
    }
    return n;
  }

  Future<List<ControlIdAccessLog>?> getAccessLogs(int fromLogId) async {
    if (!await ensureSession()) return null;
    final body = fromLogId > 0
        ? jsonEncode({
            'object': 'access_logs',
            'where': [
              {'object': 'access_logs', 'field': 'id', 'operator': '>', 'value': fromLogId}
            ],
            'order': ['ascending', 'id']
          })
        : '{"object":"access_logs","order":["ascending","id"]}';
    final r = await _post(buildUrl('load_objects.fcgi'), body);
    if (r.code == 200) {
      final arr = _json(r.body)?['access_logs'];
      if (arr is List) {
        return [
          for (final l in arr.whereType<Map>())
            ControlIdAccessLog()
              ..id = _int(l['id'])
              ..time = _int(l['time']) > 0 ? DateTime.fromMillisecondsSinceEpoch(_int(l['time']) * 1000) : null
              ..userId = _int(l['user_id'])
              ..event = _int(l['event'])
              ..deviceId = _int(l['device_id'])
              ..portalId = _int(l['portal_id'])
              ..identificationRuleId = _int(l['identification_rule_id'])
        ];
      }
    }
    lastError = 'Erro ao carregar logs de acesso (Status ${r.code}): ${r.body}';
    return null;
  }

  Future<String?> getAfd(int initialNsr, bool portaria671) async {
    if (!await ensureSession()) return null;
    final body = initialNsr > 0 ? jsonEncode({'initial_nsr': initialNsr}) : '{}';
    final extra = portaria671 ? 'mode=671' : '';
    // REP iDClass: get_afd.fcgi; export_afd.fcgi fica como alternativa para firmwares antigos
    var r = await _post(buildUrl('get_afd.fcgi', extra: extra), body);
    if (r.code != 200) r = await _post(buildUrl('export_afd.fcgi', extra: extra), body);
    if (r.code == 200) return r.body;
    lastError = 'Erro ao exportar AFD (Status ${r.code}): ${r.body}';
    return null;
  }

  /// Lê as marcações do AFD: tipo 3 (REP-C) e tipo 7 (REP-P), nos layouts da Portaria 1510 e da 671.
  static List<AfdRecord> parseAfd(String content) {
    final result = <AfdRecord>[];
    for (final raw in const LineSplitter().convert(content)) {
      final line = raw.trim();
      if (line.length < 22 || (line[9] != '3' && line[9] != '7')) continue;
      int n(int start, int len, int def) =>
          start + len <= line.length ? int.tryParse(line.substring(start, start + len)) ?? def : def;
      final rec = AfdRecord()
        ..rawLine = line
        ..tipo = int.parse(line[9])
        ..nsr = n(0, 9, 0);
      final layout671 = line.length >= 34 && line[14] == '-' && line[20] == 'T';
      if (layout671) {
        // NSR(9) tipo(1) AAAA-MM-DDThh:mm:00-0300(24) CPF(12) ...
        final dh = DateTime.tryParse('${line.substring(10, 29)}${line.substring(29, 32)}:${line.substring(32, 34)}');
        if (dh == null) continue;
        rec.dataHora = dh.toLocal();
        final cpf = line.length >= 46 ? line.substring(34, 46).trim() : '';
        rec.cpf = cpf.length > 11 ? cpf.substring(cpf.length - 11) : cpf;
        rec.pis = cpf;
      } else {
        if (line.length < 33 || line[9] != '3') continue;
        // Portaria 1510: NSR(9) 3 DDMMAAAA(8) HHMM(4) PIS(12)
        try {
          rec.dataHora = DateTime(n(14, 4, 2000), n(12, 2, 1), n(10, 2, 1), n(18, 2, 0), n(20, 2, 0));
        } catch (_) {}
        if (line.length >= 34) rec.pis = line.substring(22, 34).trim();
        rec.cpf = line.substring(22, 33).trim();
      }
      result.add(rec);
    }
    return result;
  }

  Future<bool> syncTimeZone(int id, String name, String e1, String s1, String e2, String s2) async {
    if (!await ensureSession()) return false;
    int sec(String t) {
      final v = t.trim();
      if (v.length < 5) return 0;
      return (int.tryParse(v.substring(0, 2)) ?? 0) * 3600 + (int.tryParse(v.substring(3, 5)) ?? 0) * 60;
    }

    await _post(buildUrl('create_objects.fcgi', extra: 'object=time_zones'), jsonEncode({
      'values': [{'id': id, 'name': name}]
    }));
    final spans = <Map<String, int>>[];
    if (sec(s1) > sec(e1)) spans.add({'time_zone_id': id, 'start': sec(e1), 'end': sec(s1)});
    if (sec(s2) > sec(e2)) spans.add({'time_zone_id': id, 'start': sec(e2), 'end': sec(s2)});
    if (spans.isNotEmpty) {
      await _post(buildUrl('create_objects.fcgi', extra: 'object=time_spans'), jsonEncode({'values': spans}));
    }
    return true;
  }
}
