import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'controlid_client.dart';

/// Equipamento Control iD encontrado na rede.
class RelogioEncontrado {
  final String ip;
  final int porta;
  final bool ssl;
  String serial = '', firmware = '', mac = '', modelo = '';
  bool autenticado = false; // login com o usuário/senha testados funcionou
  RelogioEncontrado(this.ip, this.porta, this.ssl);

  String get descricao => [
        if (modelo.isNotEmpty) modelo,
        if (serial.isNotEmpty) 'Nº série $serial',
        if (firmware.isNotEmpty) 'FW $firmware',
      ].join('  •  ');
}

/// Procura relógios Control iD nas redes locais do computador.
///
/// Para cada endereço da sub-rede (/24) testa as portas 80 e 443; quem responde ao
/// `login.fcgi` com o formato JSON da API Control iD é considerado um relógio.
class DescobertaService {
  static const _portas = [(80, false), (443, true)];

  /// Prefixos /24 das placas de rede ativas (ex.: "192.168.10").
  static Future<List<String>> redesLocais() async {
    final redes = <String>{};
    for (final nic in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final a in nic.addresses) {
        final ip = a.address;
        if (a.isLoopback || ip.startsWith('169.254.')) continue;
        redes.add(ip.substring(0, ip.lastIndexOf('.')));
      }
    }
    return redes.toList()..sort();
  }

  static Future<bool> _portaAberta(String ip, int porta, Duration timeout) async {
    try {
      final s = await Socket.connect(ip, porta, timeout: timeout);
      s.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Confirma se o endereço é um equipamento Control iD e lê os dados do aparelho.
  static Future<RelogioEncontrado?> identificar(String ip, int porta, bool ssl,
      {String usuario = 'admin', String senha = 'admin'}) async {
    final c = ControlIdClient(host: ip, port: porta, useSsl: ssl)..timeoutSec = 3;
    final ok = await c.login(usuario, senha);
    if (!ok) {
      // Credencial diferente: ainda é Control iD se o login.fcgi respondeu no formato da API
      final erro = c.lastError.toLowerCase();
      // A API Control iD responde credencial inválida com JSON {"error": ...}
      final ehControlId = erro.contains('falha no login (status http') && erro.contains('"error"');
      if (!ehControlId) return null;
      return RelogioEncontrado(ip, porta, ssl)..modelo = 'Control iD (senha diferente de $usuario/$senha)';
    }
    final r = RelogioEncontrado(ip, porta, ssl)..autenticado = true;
    final info = await c.getSystemInformation();
    if (info != null) {
      r
        ..serial = info.serial
        ..firmware = info.fwVersion
        ..mac = info.deviceId;
    }
    r.modelo = await _modelo(ip, porta, ssl, c.sessionToken) ?? 'Control iD';
    await c.logout();
    return r;
  }

  /// O get_about.fcgi só existe nos REP (iDClass / iDX); os demais são linha de acesso.
  static Future<String?> _modelo(String ip, int porta, bool ssl, String sessao) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 3)
      ..badCertificateCallback = (_, _, _) => true;
    try {
      final base = '${ssl ? 'https' : 'http'}://$ip${(porta == 80 && !ssl) || (porta == 443 && ssl) ? '' : ':$porta'}';
      final req = await client.postUrl(Uri.parse('$base/get_about.fcgi?session=$sessao'));
      req.headers.contentType = ContentType.json;
      req.contentLength = 2;
      req.write('{}');
      final resp = await req.close().timeout(const Duration(seconds: 3));
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode == 200 && body.contains('nSerie')) return 'REP iDClass / iDX';
      return 'iDAccess / iDFace';
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Varre as redes; [onProgresso] recebe (testados, total) e [onEncontrado] cada relógio achado.
  static Future<List<RelogioEncontrado>> procurar({
    List<String>? redes,
    String usuario = 'admin',
    String senha = 'admin',
    void Function(int testados, int total)? onProgresso,
    void Function(RelogioEncontrado)? onEncontrado,
    bool Function()? cancelado,
  }) async {
    final prefixos = redes ?? await redesLocais();
    final alvos = [for (final p in prefixos) for (var i = 1; i < 255; i++) '$p.$i'];
    final achados = <RelogioEncontrado>[];
    var testados = 0;
    const paralelo = 64;
    const timeout = Duration(milliseconds: 600);

    for (var i = 0; i < alvos.length; i += paralelo) {
      if (cancelado?.call() == true) break;
      final lote = alvos.sublist(i, i + paralelo > alvos.length ? alvos.length : i + paralelo);
      await Future.wait(lote.map((ip) async {
        for (final (porta, ssl) in _portas) {
          if (!await _portaAberta(ip, porta, timeout)) continue;
          final r = await identificar(ip, porta, ssl, usuario: usuario, senha: senha);
          if (r != null) {
            achados.add(r);
            onEncontrado?.call(r);
            break; // mesma máquina nas duas portas: basta uma
          }
        }
        testados++;
        onProgresso?.call(testados, alvos.length);
      }));
    }
    achados.sort((a, b) => _ipNum(a.ip).compareTo(_ipNum(b.ip)));
    return achados;
  }

  static int _ipNum(String ip) => ip.split('.').fold(0, (v, p) => v * 256 + (int.tryParse(p) ?? 0));
}
