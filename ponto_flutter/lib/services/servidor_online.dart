import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/util.dart';
import '../data/database.dart';

/// Servidor do MODO ONLINE da Control iD (port de uServidorOnline.pas).
///
/// No modo online o próprio equipamento (linha iDAccess / iDFace / iDFlex) faz um POST para este
/// servidor a cada identificação. A batida é gravada na hora e o servidor responde liberando
/// (event 7 + abrir porta) ou negando (event 6) o acesso.
class ServidorOnline {
  final int porta;
  final int portaFechadura;
  final void Function(String msg, bool erro)? onLog;
  HttpServer? _server;

  ServidorOnline({this.porta = 8080, this.portaFechadura = 1, this.onLog});

  bool get ativo => _server != null;

  static const _identificacao = {
    '/new_user_identified.fcgi', '/new_card.fcgi', '/new_qrcode.fcgi', '/new_uhf_tag.fcgi',
    '/new_user_id_and_password.fcgi', '/new_biometric_image.fcgi', '/new_biometric_template.fcgi', '/new_rex_log.fcgi',
  };

  void _log(String m, [bool erro = false]) => onLog?.call('[${fmtHoraSeg(DateTime.now())}] 🌐 $m', erro);

  Future<void> iniciar() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, porta);
    _log('Servidor online iniciado na porta $porta.');
    _server!.listen(_atender, onError: (e) => _log('Erro no servidor online: $e', true));
  }

  Future<void> parar() async {
    await _server?.close(force: true);
    if (_server != null) _log('Servidor online parado.');
    _server = null;
  }

  String _resposta(bool concede, int userId, String nome) => jsonEncode({
        'result': {
          'event': concede ? 7 : 6,
          'user_id': userId,
          'user_name': nome,
          'user_image': false,
          'portal_id': 1,
          'actions': [
            if (concede) {'action': 'door', 'parameters': 'door=$portaFechadura'}
          ],
        }
      });

  Future<void> _atender(HttpRequest req) async {
    final res = req.response;
    final doc = req.uri.path.toLowerCase();
    res.headers.contentType = ContentType.json;
    try {
      if (doc == '/device_is_alive.fcgi') {
        res.write('{}');
      } else if (doc == '/user_get_image.fcgi') {
        res.statusCode = 204;
      } else if (_identificacao.contains(doc)) {
        final corpo = await utf8.decoder.bind(req).join();
        Map<String, dynamic>? j;
        try {
          final v = jsonDecode(corpo);
          if (v is Map<String, dynamic>) j = v;
        } catch (_) {}
        if (j == null) {
          res.write('{}');
          _log('Corpo inválido recebido em $doc', true);
        } else {
          res.write(await _registrar(doc, j));
        }
      } else {
        res.write('{}');
      }
    } catch (e) {
      _log('Falha ao tratar $doc: $e', true);
      res.write('{}');
    } finally {
      await res.close();
    }
  }

  /// Grava a batida recebida do equipamento e decide o acesso.
  Future<String> _registrar(String doc, Map<String, dynamic> j) async {
    int n(String k) => j[k] is num ? (j[k] as num).toInt() : int.tryParse('${j[k] ?? ''}') ?? 0;
    final userId = n('user_id'), deviceId = n('device_id'), evento = n('event') == 0 ? 7 : n('event');
    var time = n('time');
    if (time <= 0) time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (userId <= 0) {
      _log('$doc: usuário não identificado (acesso negado).');
      return _resposta(false, 0, '');
    }
    final db = Db.instance;
    final p = await db.getPessoaPorId(userId);
    if (p == null || asStr(p['PES_STATUS']) == 'I') {
      _log('$doc: usuário $userId não cadastrado ou inativo (acesso negado).', true);
      return _resposta(false, userId, '');
    }
    // Relógio pelo device_id informado (PRE_DEVICE_ID); se não achar, grava sem relógio
    var relogioId = 0;
    for (final r in await db.getRelogios()) {
      if (asStr(r['PRE_DEVICE_ID']).trim() == '$deviceId') relogioId = asInt(r['PRE_ID']);
    }
    final dh = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    // Chave única por equipamento + horário + usuário (evita duplicar reenvios do relógio)
    final chave = time * 100000 + userId % 100000;
    final nome = asStr(p['PES_RSOCIAL_NOME']);
    final ok = await db.gravarMarcacao(userId, relogioId, dh, evento, chave, 'C', 0, asStr(p['COL_PIS']),
        asStr(p['PES_CNPJ_CPF']), 'Batida Ponto', 'Control iD Online');
    _log(ok
        ? '$nome: batida às ${fmtHoraSeg(dh)} registrada (dispositivo $deviceId).'
        : 'Falha ao gravar a batida de $nome: ${db.lastError}', !ok);
    return _resposta(ok, userId, nome);
  }
}
