import 'dart:io';

/// Assinatura eletrônica destacada (CMS/CAdES, SHA-256) com certificado digital A1 (.pfx).
/// Gera `arquivo.p7s` ao lado do arquivo original (AEJ / AFD da Portaria 671).
class AssinaturaService {
  static const _script = r'''
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Security
$flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($env:GOUP_PFX, $env:GOUP_PFX_SENHA, $flags)
if (-not $cert.HasPrivateKey) { throw 'O certificado informado não possui chave privada.' }
foreach ($arq in ($env:GOUP_ARQUIVOS -split '\|')) {
  if (-not $arq) { continue }
  $bytes = [System.IO.File]::ReadAllBytes($arq)
  $ci = New-Object System.Security.Cryptography.Pkcs.ContentInfo(,$bytes)
  $cms = New-Object System.Security.Cryptography.Pkcs.SignedCms($ci, $true)
  $signer = New-Object System.Security.Cryptography.Pkcs.CmsSigner($cert)
  $signer.DigestAlgorithm = New-Object System.Security.Cryptography.Oid('2.16.840.1.101.3.4.2.1')
  $signer.IncludeOption = [System.Security.Cryptography.X509Certificates.X509IncludeOption]::WholeChain
  [void]$signer.SignedAttributes.Add((New-Object System.Security.Cryptography.Pkcs.Pkcs9SigningTime))
  $cms.ComputeSignature($signer, $false)
  [System.IO.File]::WriteAllBytes($arq + '.p7s', $cms.Encode())
}
Write-Output ('OK|' + $cert.Subject + '|' + $cert.NotAfter.ToString('dd/MM/yyyy'))
''';

  /// Assina os [arquivos]; retorna (titular, validade) do certificado ou lança exceção com o motivo.
  static Future<({String titular, String validade})> assinar(List<String> arquivos, String pfx, String senha) async {
    if (!File(pfx).existsSync()) throw Exception('Certificado não encontrado: $pfx');
    final r = await Process.run(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', _script],
      // Senha e caminhos vão por variável de ambiente (não aparecem na linha de comando)
      environment: {'GOUP_PFX': pfx, 'GOUP_PFX_SENHA': senha, 'GOUP_ARQUIVOS': arquivos.join('|')},
    );
    final out = '${r.stdout}'.trim();
    if (r.exitCode != 0 || !out.contains('OK|')) {
      final erro = '${r.stderr}'.trim().split('\n').first;
      throw Exception(erro.contains('senha') || erro.toLowerCase().contains('password')
          ? 'Senha do certificado incorreta.'
          : 'Falha ao assinar: $erro');
    }
    final p = out.substring(out.indexOf('OK|')).split('|');
    return (titular: p.length > 1 ? p[1] : '', validade: p.length > 2 ? p[2].trim() : '');
  }
}
