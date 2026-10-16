# Go Up Ponto - geração de versão
#
#   .\release.ps1                         -> incrementa o build, compila e gera build\GoUpPonto.zip
#   .\release.ps1 -Versao 2.4.0           -> muda a versão (build volta para 1)
#   .\release.ps1 -Publicar -Notas "..."  -> também cria a release no GitHub (requer gh autenticado)
#
# O .zip contém a pasta Release completa (GoUpPonto.exe, GoUpPontoServico.exe, DLLs e dados) e é o pacote
# que a atualização automática baixa (asset "GoUpPonto.zip"). O Config.ini do cliente nunca entra no pacote.
param(
  [string]$Versao = '',
  [string]$Notas = '',
  [switch]$Publicar
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# 1. Versão e build (lib/core/build_info.dart)
$info = 'lib\core\build_info.dart'
$txt = Get-Content $info -Raw -Encoding UTF8
$verAtual = [regex]::Match($txt, "buildVersion = '([^']+)'").Groups[1].Value
$buildAtual = [int][regex]::Match($txt, 'buildNumber = (\d+)').Groups[1].Value
if ($Versao -and $Versao -ne $verAtual) { $ver = $Versao; $build = 1 } else { $ver = $verAtual; $build = $buildAtual + 1 }
$hoje = Get-Date -Format 'yyyy-MM-dd'
$txt = $txt -replace "buildVersion = '[^']+'", "buildVersion = '$ver'" `
            -replace 'buildNumber = \d+', "buildNumber = $build" `
            -replace "buildDate = '[^']+'", "buildDate = '$hoje'"
[IO.File]::WriteAllText((Resolve-Path $info), $txt, (New-Object Text.UTF8Encoding $false))
Write-Host "Versão $ver (Build $build)" -ForegroundColor Cyan

# 2. Análise e compilação
flutter analyze lib
if ($LASTEXITCODE -ne 0) { throw 'A análise encontrou problemas. Corrija antes de gerar a versão.' }
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'Falha na compilação do aplicativo.' }
dart build cli -t bin/servico.dart -o build\servico
if ($LASTEXITCODE -ne 0) { throw 'Falha na compilação do serviço.' }

$rel = 'build\windows\x64\runner\Release'
Copy-Item build\servico\bundle\bin\servico.exe "$rel\GoUpPontoServico.exe" -Force
if (Test-Path build\servico\bundle\lib) { Copy-Item build\servico\bundle\lib\* $rel -Force -Recurse }

# 3. Pacote (sem Config.ini e sem arquivos locais)
$staging = 'build\pacote'
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
Copy-Item $rel $staging -Recurse
Get-ChildItem $staging -Include 'Config.ini', '*.log', '*.fdb', '*.FDB' -Recurse | Remove-Item -Force
$zip = 'build\GoUpPonto.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$staging\*" -DestinationPath $zip
Remove-Item $staging -Recurse -Force
$mb = '{0:N1}' -f ((Get-Item $zip).Length / 1MB)
Write-Host "Pacote gerado: $zip ($mb MB)" -ForegroundColor Green

# 4. Publicação no GitHub
if ($Publicar) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) não encontrado.' }
  if (-not $Notas) { $Notas = "Go Up Ponto v$ver (Build $build)" }
  gh release create "v$ver-b$build" $zip --title "v$ver (Build $build)" --notes "$Notas`n`nBuild $build"
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao publicar a release.' }
  Write-Host "Release v$ver (Build $build) publicada." -ForegroundColor Green
}
