import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../core/build_info.dart';

class UpdateInfo {
  bool hasUpdate = false;
  String latestVersion = '', releaseName = '', releaseNotes = '', downloadUrl = '', assetFileName = '', publishedAt = '';
  int latestBuild = 0, assetSize = 0;

  String get descricao => latestBuild > 0 ? 'v$latestVersion (Build $latestBuild)' : 'v$latestVersion';
}

/// Atualização automática pelo GitHub Releases (port de uFrmUpdate).
/// A release do Flutter publica um .zip com a pasta do executável (asset GoUpPonto.zip).
class UpdateService {
  static const nomeAssetRelease = 'GoUpPonto.zip';

  /// "v2.3.0-b4" -> "2.3.0" (o build vem do título "(Build N)").
  static String limparVersao(String tag) => tag.trim().replaceFirst(RegExp(r'^[vV]'), '').split('-').first;

  static int extrairBuild(String s) {
    final m = RegExp(r'Build\s*(\d+)', caseSensitive: false).firstMatch(s);
    return m == null ? 0 : int.parse(m[1]!);
  }

  static int compararVersoes(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 4; i++) {
      final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  static Future<UpdateInfo?> checarAtualizacao() async {
    try {
      final resp = await http.get(Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest'),
          headers: {'User-Agent': 'GoUpPonto-Updater', 'Accept': 'application/vnd.github.v3+json'}).timeout(
          const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final tag = '${j['tag_name'] ?? ''}';
      final info = UpdateInfo()
        ..latestVersion = limparVersao(tag)
        ..releaseName = '${j['name'] ?? tag}'
        ..releaseNotes = '${j['body'] ?? ''}'
        ..publishedAt = '${j['published_at'] ?? ''}';
      info.latestBuild = extrairBuild(info.releaseName);
      if (info.latestBuild == 0) info.latestBuild = extrairBuild(info.releaseNotes);

      for (final a in (j['assets'] as List? ?? []).whereType<Map>()) {
        final nome = '${a['name'] ?? ''}';
        if (!nome.toLowerCase().endsWith('.zip')) continue;
        if (info.downloadUrl.isEmpty || nome.toLowerCase() == nomeAssetRelease.toLowerCase()) {
          info
            ..assetFileName = nome
            ..downloadUrl = '${a['browser_download_url'] ?? ''}'
            ..assetSize = (a['size'] as num?)?.toInt() ?? 0;
          if (nome.toLowerCase() == nomeAssetRelease.toLowerCase()) break;
        }
      }
      if (info.latestVersion.isEmpty || info.downloadUrl.isEmpty) return null;
      final cmp = compararVersoes(info.latestVersion, buildVersion);
      info.hasUpdate = cmp > 0 || (cmp == 0 && info.latestBuild > buildNumber);
      return info.hasUpdate ? info : null;
    } catch (_) {
      return null;
    }
  }

  /// Baixa o pacote, valida e agenda a troca dos arquivos após o aplicativo fechar.
  static Future<void> baixarEInstalar(UpdateInfo info, void Function(double progresso) onProgresso) async {
    final tmp = Directory(p.join(Directory.systemTemp.path, 'ponto_flutter_update'));
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    tmp.createSync(recursive: true);
    final zip = File(p.join(tmp.path, info.assetFileName));

    final req = http.Request('GET', Uri.parse(info.downloadUrl))..headers['User-Agent'] = 'GoUpPonto-Updater';
    final resp = await http.Client().send(req);
    if (resp.statusCode != 200) throw Exception('Falha no download (HTTP ${resp.statusCode}).');
    final total = resp.contentLength ?? info.assetSize;
    var recebido = 0;
    final sink = zip.openWrite();
    await for (final chunk in resp.stream) {
      sink.add(chunk);
      recebido += chunk.length;
      if (total > 0) onProgresso(recebido / total);
    }
    await sink.close();

    // Validação: tamanho e assinatura ZIP ("PK")
    final bytes = await zip.openRead(0, 2).first;
    if ((info.assetSize > 0 && zip.lengthSync() != info.assetSize) || bytes.length < 2 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw Exception('Arquivo de atualização inválido ou corrompido.');
    }

    final exe = Platform.resolvedExecutable;
    final pasta = p.dirname(exe);
    final extraido = p.join(tmp.path, 'novo');
    final backup = p.join(Directory.systemTemp.path, 'ponto_flutter_backup');
    final bat = File(p.join(tmp.path, 'atualizar.bat'));
    await bat.writeAsString('@echo off\r\n'
        'timeout /t 2 /nobreak > nul\r\n'
        ':espera\r\n'
        'tasklist /FI "PID eq $pid" | find "$pid" > nul && (timeout /t 1 > nul & goto espera)\r\n'
        'powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force \'${zip.path}\' \'$extraido\'"\r\n'
        'if exist "$backup" rmdir /s /q "$backup"\r\n'
        'xcopy /e /i /y /q "$pasta" "$backup" > nul\r\n'
        'xcopy /e /i /y /q "$extraido\\*" "$pasta" > nul\r\n'
        'start "" "$exe"\r\n');
    await Process.start('cmd.exe', ['/c', bat.path], mode: ProcessStartMode.detached);
    exit(0);
  }
}
