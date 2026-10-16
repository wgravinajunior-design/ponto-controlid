import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/database.dart';

/// Integração com o leitor biométrico Nitgen Hamster DX (port de uBiometriaHamster).
///
/// O SDK NBioBSP (eNBSP) é um servidor COM de 32 bits e o aplicativo Flutter Windows é de 64 bits,
/// portanto as chamadas ao SDK são feitas por um script executado no PowerShell de 32 bits
/// (SysWOW64), que devolve o resultado em JSON pela saída padrão.
class HamsterDx {
  static String get _powershell32 {
    final win = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    final wow = p.join(win, 'SysWOW64', 'WindowsPowerShell', 'v1.0', 'powershell.exe');
    return File(wow).existsSync() ? wow : 'powershell.exe';
  }

  // Pasta do executável: o script procura ali o NBSP2Por.dll (assistente em português)
  static Map<String, String> get _env => {'PONTO_EXE_DIR': p.dirname(Platform.resolvedExecutable)};

  static Future<String> _script() async {
    final dir = Directory(p.join(Directory.systemTemp.path, 'ponto_flutter'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final f = File(p.join(dir.path, 'hamster_bridge.ps1'));
    // BOM UTF-8 para o PowerShell 5.1 interpretar os acentos corretamente
    await f.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(_bridgeScript)]);
    return f.path;
  }

  static Future<List<String>> _args(String cmd, [List<String> extra = const []]) async =>
      ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', await _script(), cmd, ...extra];

  static Future<Map<String, dynamic>> _run(String cmd, [List<String> extra = const []]) async {
    try {
      final r = await Process.run(_powershell32, await _args(cmd, extra),
          environment: _env, stdoutEncoding: utf8, stderrEncoding: utf8);
      final out = (r.stdout as String).trim().split('\n').where((l) => l.trim().startsWith('{')).toList();
      if (out.isEmpty) {
        return {'ok': false, 'erro': 'Sem resposta do SDK NBioBSP. ${(r.stderr as String).trim()}'};
      }
      return jsonDecode(out.last) as Map<String, dynamic>;
    } catch (e) {
      return {'ok': false, 'erro': 'Falha ao executar a ponte do leitor biométrico: $e'};
    }
  }

  static Future<File> _tmp(String nome, String conteudo) async {
    final f = File(p.join(Directory.systemTemp.path, 'ponto_flutter', nome));
    await f.parent.create(recursive: true);
    await f.writeAsString(conteudo, encoding: utf8);
    return f;
  }

  /// SDK registrado (NBioBSPCOM) e driver instalado (serviço FPUSB).
  static Future<({bool sdk, bool driver})> verificarRequisitos() async {
    final r = await _run('check');
    return (sdk: r['sdk'] == true, driver: r['driver'] == true);
  }

  static Future<({String? template, String erro})> cadastrar() async {
    final r = await _run('enroll');
    return r['ok'] == true ? (template: r['template'] as String, erro: '') : (template: null, erro: '${r['erro']}');
  }

  static Future<({String? template, String erro})> capturar() async {
    final r = await _run('capture');
    return r['ok'] == true ? (template: r['template'] as String, erro: '') : (template: null, erro: '${r['erro']}');
  }

  static Future<({bool ok, bool igual, String erro})> comparar(String capturado, String armazenado) async {
    final a = await _tmp('cap.fir', capturado), b = await _tmp('sto.fir', armazenado);
    final r = await _run('verify', [a.path, b.path]);
    return (ok: r['ok'] == true, igual: r['match'] == true, erro: '${r['erro'] ?? ''}');
  }

  static Future<({bool ok, String erro})> testarLeitor() async {
    final r = await _run('open');
    return (ok: r['ok'] == true, erro: '${r['erro'] ?? ''}');
  }

  /// Inicia o modo terminal (captura contínua + identificação 1:N).
  static Future<HamsterTerminal> iniciarTerminal(List<DigitalCadastrada> digitais, int nivelSeguranca) async {
    final f = await _tmp('digitais.txt', digitais.map((d) => d.template.replaceAll('\n', '')).join('\n'));
    final proc =
        await Process.start(_powershell32, await _args('terminal', [f.path, '$nivelSeguranca']), environment: _env);
    return HamsterTerminal._(proc, digitais);
  }
}

class EventoLeitor {
  final String tipo; // ready | match | nomatch | error
  final DigitalCadastrada? digital;
  final String mensagem;
  EventoLeitor(this.tipo, {this.digital, this.mensagem = ''});
}

class HamsterTerminal {
  final Process _proc;
  final List<DigitalCadastrada> _digitais;
  final _ctrl = StreamController<EventoLeitor>.broadcast();

  HamsterTerminal._(this._proc, this._digitais) {
    _proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((linha) {
      final l = linha.trim();
      if (!l.startsWith('{')) return;
      try {
        final j = jsonDecode(l) as Map<String, dynamic>;
        final ev = '${j['event']}';
        if (ev == 'match') {
          final idx = (j['index'] as num).toInt() - 1;
          if (idx >= 0 && idx < _digitais.length) {
            _ctrl.add(EventoLeitor('match', digital: _digitais[idx]));
            return;
          }
          _ctrl.add(EventoLeitor('nomatch'));
        } else {
          _ctrl.add(EventoLeitor(ev, mensagem: '${j['erro'] ?? ''}'));
        }
      } catch (_) {}
    });
    _proc.stderr.transform(utf8.decoder).listen((e) {
      if (e.trim().isNotEmpty) _ctrl.add(EventoLeitor('error', mensagem: e.trim()));
    });
    _proc.exitCode.then((_) => _ctrl.close());
  }

  Stream<EventoLeitor> get eventos => _ctrl.stream;

  void parar() => _proc.kill();
}

const _bridgeScript = r'''
param([string]$Cmd = 'check', [string]$A1 = '', [string]$A2 = '')
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PROGID = 'NBioBSPCOM.NBioBSP'

function Out-Json($obj) { [Console]::Out.WriteLine(($obj | ConvertTo-Json -Compress)); [Console]::Out.Flush() }

function Erro-De($obj, $op) {
  $cod = [int]$obj.ErrorCode
  if ($cod -eq 0) { return $null }
  $desc = ''
  try { $desc = [string]$obj.ErrorDescription } catch {}
  if ($desc) { return "${op}: $desc (código $cod)" }
  return "${op}: código de erro NBioBSP $cod"
}

function Novo-BSP {
  try { $bsp = New-Object -ComObject $PROGID } catch {
    throw 'SDK Nitgen NBioBSP (eNBSP) não encontrado. Instale o driver do Hamster DX e o eNBSP SDK (NBioBSPCOM.dll registrado) nesta máquina.'
  }
  $skin = Join-Path $env:PONTO_EXE_DIR 'NBSP2Por.dll'
  if (Test-Path $skin) { try { $bsp.SetSkinResource($skin) | Out-Null } catch {} }
  return $bsp
}

function Abrir($bsp) {
  $dev = $bsp.Device
  $dev.Open(255)
  $e = Erro-De $dev 'Não foi possível abrir o leitor Hamster DX'
  if ($e) { throw $e }
  return $dev
}

try {
  switch ($Cmd) {
    'check' {
      $sdk = $false
      try { $null = [Type]::GetTypeFromProgID($PROGID, $true); $sdk = $true } catch {}
      $drv = Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\FPUSB'
      Out-Json @{ ok = $true; sdk = $sdk; driver = $drv }
    }
    'open' {
      $bsp = Novo-BSP; $dev = Abrir $bsp; $dev.Close(255)
      Out-Json @{ ok = $true }
    }
    'enroll' {
      $bsp = Novo-BSP; $dev = Abrir $bsp
      $ext = $bsp.Extraction
      try { $ext.WindowStyle = 0 } catch {}
      $ext.Enroll([System.DBNull]::Value, [System.DBNull]::Value)
      $e = Erro-De $ext 'Cadastro da digital não concluído'
      $dev.Close(255)
      if ($e) { throw $e }
      $t = [string]$ext.TextEncodeFIR
      if (-not $t) { throw 'O leitor não retornou o template da digital.' }
      Out-Json @{ ok = $true; template = $t }
    }
    'capture' {
      $bsp = Novo-BSP; $dev = Abrir $bsp
      $ext = $bsp.Extraction
      try { $ext.WindowStyle = 0 } catch {}
      $ext.Capture(1)
      $e = Erro-De $ext 'Leitura da digital'
      $dev.Close(255)
      if ($e) { throw $e }
      Out-Json @{ ok = $true; template = [string]$ext.TextEncodeFIR }
    }
    'verify' {
      $bsp = Novo-BSP
      $a = (Get-Content -Raw -Encoding UTF8 $A1).Trim(); $b = (Get-Content -Raw -Encoding UTF8 $A2).Trim()
      $m = $bsp.Matching
      $m.VerifyMatch($a, $b)
      $e = Erro-De $m 'Comparação de digitais'
      if ($e) { throw $e }
      Out-Json @{ ok = $true; match = ([int]$m.MatchingResult -ne 0) }
    }
    'terminal' {
      $nivel = [int]$A2
      $tpls = @(Get-Content -Encoding UTF8 $A1 | Where-Object { $_.Trim() -ne '' })
      $bsp = Novo-BSP; $dev = Abrir $bsp
      $ext = $bsp.Extraction
      try { $ext.WindowStyle = 1 } catch {}
      $idx = $null
      try {
        $idx = $bsp.IndexSearch; $idx.ClearDB()
        for ($i = 0; $i -lt $tpls.Count; $i++) { $idx.AddFIR($tpls[$i], $i + 1) }
      } catch { $idx = $null }
      Out-Json @{ event = 'ready'; total = $tpls.Count }
      while ($true) {
        try {
          $ext.Capture(1)
          if ([int]$ext.ErrorCode -ne 0) { Start-Sleep -Milliseconds 200; continue }
          $cap = [string]$ext.TextEncodeFIR
          $achou = 0
          if ($idx -ne $null) {
            $idx.IdentifyUser($cap, $nivel)
            if ([int]$idx.ErrorCode -eq 0) { $achou = [int]$idx.UserID }
          } else {
            $m = $bsp.Matching
            for ($i = 0; $i -lt $tpls.Count; $i++) {
              $m.VerifyMatch($cap, $tpls[$i])
              if ([int]$m.ErrorCode -eq 0 -and [int]$m.MatchingResult -ne 0) { $achou = $i + 1; break }
            }
          }
          if ($achou -gt 0) { Out-Json @{ event = 'match'; index = $achou } } else { Out-Json @{ event = 'nomatch' } }
        } catch {
          Out-Json @{ event = 'error'; erro = $_.Exception.Message }
          Start-Sleep -Seconds 1
        }
      }
    }
  }
} catch {
  Out-Json @{ ok = $false; erro = $_.Exception.Message }
}
''';
