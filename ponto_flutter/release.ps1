# Go Up Ponto - geração e publicação de versão
#
#   .\release.ps1                          -> incrementa o build, compila e gera build\GoUpPonto.zip
#   .\release.ps1 -Versao 2.5.0            -> muda a versão (o build volta para 1)
#   .\release.ps1 -Publicar                -> também publica a release no GitHub (requer gh autenticado)
#   .\release.ps1 -Publicar -Notas "..."   -> usa as notas informadas em vez de gerá-las
#
# Notas da versão: se -Notas não for informado, são geradas a partir dos commits desde a última release
# (feat -> Novidades, fix -> Correções, demais -> Melhorias; os tópicos "- ..." do corpo do commit são usados).
# Essas notas aparecem no rodapé do sistema ao haver atualização e, depois de atualizar, na tela "O que há de novo".
#
# O .zip contém a pasta Release completa (GoUpPonto.exe, GoUpPontoServico.exe, DLLs) e é o pacote baixado
# pela atualização automática (asset "GoUpPonto.zip"). O Config.ini do cliente nunca entra no pacote.
param(
  [string]$Versao = '',
  [string]$Notas = '',
  [switch]$Publicar
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Gerar-Notas {
  $ultima = (git describe --tags --abbrev=0 --match 'v*-b*' 2>$null)
  $faixa = if ($ultima) { "$ultima..HEAD" } else { 'HEAD' }
  $raw = git log $faixa --reverse --no-merges --pretty=format:'%x1e%s%x1f%b' -- . 2>$null
  $cat = [ordered]@{ 'Novidades' = @(); 'Melhorias' = @(); 'Correções' = @() }
  foreach ($c in ($raw -join "`n") -split [char]0x1e) {
    if (-not $c.Trim()) { continue }
    $partes = $c -split [char]0x1f, 2
    $assunto = $partes[0].Trim()
    $corpo = if ($partes.Count -gt 1) { $partes[1] } else { '' }
    if ($assunto -match '^chore: release') { continue }
    $tipo = if ($assunto -match '^feat') { 'Novidades' } elseif ($assunto -match '^fix') { 'Correções' } else { 'Melhorias' }
    $titulo = ($assunto -replace '^[a-z]+(\([^)]*\))?!?:\s*', '')
    # Tópicos "- ..." do corpo; linhas seguintes recuadas continuam o mesmo tópico
    $topicos = @()
    foreach ($linha in ($corpo -split "`n")) {
      $l = $linha.TrimEnd("`r")
      if ($l -match '^\s*-\s+\S') { $topicos += ($l -replace '^\s*-\s+', '').Trim() }
      elseif ($l -match '^\s{2,}\S' -and $topicos.Count -gt 0) { $topicos[$topicos.Count - 1] += ' ' + $l.Trim() }
    }
    if ($topicos.Count -gt 0) { $cat[$tipo] += $topicos } else { $cat[$tipo] += $titulo.Substring(0, 1).ToUpper() + $titulo.Substring(1) }
  }
  $md = foreach ($k in $cat.Keys) {
    if ($cat[$k].Count -gt 0) { "## $k"; $cat[$k] | Select-Object -Unique | ForEach-Object { "- $_" }; '' }
  }
  return ($md -join "`n").Trim()
}

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
Get-ChildItem $staging -Include 'Config.ini', '*.log', '*.fdb', '*.FDB', 'novidades_pendentes.json' -Recurse | Remove-Item -Force
$zip = 'build\GoUpPonto.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$staging\*" -DestinationPath $zip
Remove-Item $staging -Recurse -Force
$mb = '{0:N1}' -f ((Get-Item $zip).Length / 1MB)
Write-Host "Pacote gerado: $zip ($mb MB)" -ForegroundColor Green

# 4. Publicação no GitHub
if ($Publicar) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) não encontrado.' }
  if (-not $Notas) { $Notas = Gerar-Notas }
  if (-not $Notas) { $Notas = "Go Up Ponto v$ver (Build $build)" }
  Write-Host "`nNotas da versão:`n$Notas`n" -ForegroundColor Yellow

  # Registra a nova versão no repositório antes de criar a tag
  $branch = (git rev-parse --abbrev-ref HEAD).Trim()
  git add $info
  git commit -m "chore: release v$ver (Build $build)" | Out-Null
  git push origin $branch
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao enviar os commits para o GitHub.' }

  $arqNotas = Join-Path $env:TEMP "goup_notas_$build.md"
  [IO.File]::WriteAllText($arqNotas, "$Notas`n`nBuild $build", (New-Object Text.UTF8Encoding $false))
  gh release create "v$ver-b$build" $zip --target $branch --title "v$ver (Build $build)" --notes-file $arqNotas
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao publicar a release.' }
  Remove-Item $arqNotas -ErrorAction SilentlyContinue
  Write-Host "Release v$ver (Build $build) publicada no GitHub." -ForegroundColor Green
}
