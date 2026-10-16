import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../core/build_info.dart';
import '../core/config.dart';

class UpdateInfo {
  bool hasUpdate = false;
  String latestVersion = '', releaseName = '', releaseNotes = '', downloadUrl = '', assetFileName = '', publishedAt = '';
  int latestBuild = 0, assetSize = 0;

  String get descricao => latestBuild > 0 ? 'v$latestVersion (Build $latestBuild)' : 'v$latestVersion';

  Map<String, dynamic> toJson() => {
        'versao': latestVersion,
        'build': latestBuild,
        'titulo': releaseName,
        'notas': releaseNotes,
        'publicadoEm': publishedAt,
      };
}

/// Novidades de uma versão (notas da release publicada no GitHub).
class Novidades {
  final String versao, titulo, notas;
  final int build;
  Novidades(this.versao, this.build, this.titulo, this.notas);

  String get descricao => build > 0 ? 'v$versao (Build $build)' : 'v$versao';
}

/// Atualização automática pelo GitHub Releases.
/// A release publica um .zip com a pasta do executável (asset GoUpPonto.zip) e as notas da versão
/// (novidades, melhorias e correções) no corpo da release.
class UpdateService {
  static const nomeAssetRelease = 'GoUpPonto.zip';

  /// Permite apontar para um servidor de teste (variável de ambiente GOUP_UPDATE_API).
  static String get _api => Platform.environment['GOUP_UPDATE_API'] ?? 'https://api.github.com';

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

  static Map<String, String> get _headers => {'User-Agent': 'GoUpPonto-Updater', 'Accept': 'application/vnd.github.v3+json'};

  static UpdateInfo? _interpretar(Map<String, dynamic> j) {
    final tag = '${j['tag_name'] ?? ''}';
    final info = UpdateInfo()
      ..latestVersion = limparVersao(tag)
      ..releaseName = '${j['name'] ?? tag}'
      ..releaseNotes = '${j['body'] ?? ''}'
      ..publishedAt = '${j['published_at'] ?? ''}';
    info.latestBuild = extrairBuild(info.releaseName);
    if (info.latestBuild == 0) info.latestBuild = extrairBuild(info.releaseNotes);
    if (info.latestBuild == 0) info.latestBuild = extrairBuild(tag.replaceAll('-b', ' Build '));

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
    return info.latestVersion.isEmpty ? null : info;
  }

  /// Consulta a última release; devolve a atualização se houver versão (ou build) mais nova.
  static Future<UpdateInfo?> checarAtualizacao() async {
    try {
      final resp = await http
          .get(Uri.parse('$_api/repos/$githubOwner/$githubRepo/releases/latest'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final info = _interpretar(jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
      if (info == null || info.downloadUrl.isEmpty) return null;
      final cmp = compararVersoes(info.latestVersion, buildVersion);
      info.hasUpdate = cmp > 0 || (cmp == 0 && info.latestBuild > buildNumber);
      return info.hasUpdate ? info : null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Novidades: mostradas depois da atualização
  // ---------------------------------------------------------------------------------------------

  static File get _arqNovidades => File(p.join(AppConfig.pastaExe, 'novidades_pendentes.json'));

  /// Guarda as notas da versão que vai ser instalada (sobrevive à troca dos arquivos).
  static void _guardarNovidades(UpdateInfo info) {
    try {
      _arqNovidades.writeAsStringSync(jsonEncode(info.toJson()));
    } catch (_) {}
  }

  /// Notas guardadas antes da atualização, se forem da versão que está rodando agora.
  static Novidades? _novidadesGuardadas() {
    try {
      if (!_arqNovidades.existsSync()) return null;
      final j = jsonDecode(_arqNovidades.readAsStringSync()) as Map<String, dynamic>;
      final n = Novidades('${j['versao']}', (j['build'] as num?)?.toInt() ?? 0, '${j['titulo'] ?? ''}', '${j['notas'] ?? ''}');
      if (n.versao == buildVersion && n.build == buildNumber) return n;
      // Atualização que não chegou a concluir: descarta o rascunho se for de versão antiga
      if (compararVersoes(n.versao, buildVersion) < 0) _arqNovidades.deleteSync();
    } catch (_) {}
    return null;
  }

  /// Notas da versão publicada (tag "vX.Y.Z-bN"), para quem atualizou manualmente ou sem o rascunho local.
  static Future<Novidades?> _buscarNotasPublicadas() async {
    try {
      final r = await http
          .get(Uri.parse('$_api/repos/$githubOwner/$githubRepo/releases/tags/v$buildVersion-b$buildNumber'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final i = _interpretar(jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
      return i == null ? null : Novidades(i.latestVersion, i.latestBuild, i.releaseName, i.releaseNotes);
    } catch (_) {
      return null;
    }
  }

  /// Retorna as novidades se este for o primeiro uso desta versão/build (e marca como vista).
  static Future<Novidades?> novidadesDaVersaoAtual() async {
    final chave = '$buildVersion.$buildNumber';
    final cfg = AppConfig.instance;
    if (cfg.atualizacao.ultimaVista == chave) return null;
    final primeiraVez = cfg.atualizacao.ultimaVista.isEmpty;
    cfg.atualizacao.ultimaVista = chave;
    cfg.save();
    final guardadas = _novidadesGuardadas();
    try {
      if (_arqNovidades.existsSync()) _arqNovidades.deleteSync();
    } catch (_) {}
    if (primeiraVez && guardadas == null) return null; // instalação nova: nada a mostrar
    final n = guardadas ?? await _buscarNotasPublicadas();
    if (n == null || n.notas.trim().isEmpty) {
      return Novidades(buildVersion, buildNumber, 'Go Up Ponto ${versaoCompleta()}',
          'Sistema atualizado para a versão $buildVersion (Build $buildNumber).');
    }
    return n;
  }

  // ---------------------------------------------------------------------------------------------
  // Download e instalação
  // ---------------------------------------------------------------------------------------------

  /// Gera o script que espera o programa fechar, faz cópia de segurança, troca os arquivos e reabre.
  /// (separado para poder ser testado sem encerrar o aplicativo).
  static String montarScript({
    required String zip,
    required String extraido,
    required String pasta,
    required String exe,
    required String backup,
    required int pid,
    required String log,
  }) =>
      '@echo off\r\n'
      'chcp 65001 > nul\r\n'
      'timeout /t 2 /nobreak > nul\r\n'
      ':espera\r\n'
      'tasklist /FI "PID eq $pid" 2>nul | find "$pid" > nul && (timeout /t 1 /nobreak > nul & goto espera)\r\n'
      'if exist "$extraido" rmdir /s /q "$extraido"\r\n'
      'powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force \'$zip\' \'$extraido\'"\r\n'
      'if not exist "$extraido\\$_exeNome" goto falhou\r\n'
      // O serviço em segundo plano (se instalado) trava o próprio executável: tenta parar e reiniciar depois
      'schtasks /End /TN GoUpPontoServico > nul 2>&1\r\n'
      'if exist "$backup" rmdir /s /q "$backup"\r\n'
      'robocopy "$pasta" "$backup" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP > nul\r\n'
      // Config.ini e bases locais nunca são sobrescritos
      'robocopy "$extraido" "$pasta" /E /IS /IT /R:3 /W:1 /NFL /NDL /NJH /NJS /NP /XF Config.ini *.fdb *.log > "$log"\r\n'
      'schtasks /Run /TN GoUpPontoServico > nul 2>&1\r\n'
      'start "" "$exe"\r\n'
      'goto fim\r\n'
      ':falhou\r\n'
      'echo Pacote de atualizacao invalido > "$log"\r\n'
      'start "" "$exe"\r\n'
      ':fim\r\n'
      'rmdir /s /q "$extraido" > nul 2>&1\r\n';

  static const _exeNome = 'GoUpPonto.exe';

  /// Baixa o pacote, valida e agenda a troca dos arquivos após o aplicativo fechar.
  static Future<void> baixarEInstalar(UpdateInfo info, void Function(double progresso) onProgresso) async {
    final tmp = Directory(p.join(Directory.systemTemp.path, 'goup_ponto_update'));
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

    _guardarNovidades(info);
    final exe = Platform.resolvedExecutable;
    final bat = File(p.join(tmp.path, 'atualizar.bat'));
    await bat.writeAsString(montarScript(
      zip: zip.path,
      extraido: p.join(tmp.path, 'novo'),
      pasta: p.dirname(exe),
      exe: exe,
      backup: p.join(Directory.systemTemp.path, 'goup_ponto_backup'),
      pid: pid,
      log: p.join(tmp.path, 'atualizacao.log'),
    ));
    await Process.start('cmd.exe', ['/c', bat.path], mode: ProcessStartMode.detached);
    exit(0);
  }
}
