# Gera instalador\GoUpPonto_Instalador_<versao>.exe com tudo que o sistema precisa.
# Uso (na pasta ponto_flutter):  .\instalador\gerar-instalador.ps1 [-SemCompilar]
param([switch]$SemCompilar)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not $SemCompilar) {
  flutter build windows --release; if ($LASTEXITCODE) { throw 'Falha na compilação.' }
  dart build cli -t bin/servico.dart -o build\servico; if ($LASTEXITCODE) { throw 'Falha no serviço.' }
}
$rel = 'build\windows\x64\runner\Release'
Copy-Item build\servico\bundle\bin\servico.exe "$rel\GoUpPontoServico.exe" -Force
if (Test-Path build\servico\bundle\lib) { Copy-Item build\servico\bundle\lib\* $rel -Force -Recurse }

$arq = 'instalador\arquivos'
if (Test-Path $arq) { Remove-Item $arq -Recurse -Force }
Copy-Item $rel $arq -Recurse
Get-ChildItem $arq -Include 'Config.ini','*.log','*.fdb' -Recurse | Remove-Item -Force

# Cliente Firebird 64 bits (fbclient.dll) e runtime do Visual C++, para rodar sem instalar nada além do servidor Firebird
$fb = 'C:\Program Files\Firebird\Firebird_5_0'
foreach ($f in 'fbclient.dll','firebird.msg','ib_util.dll','icudt63.dll','icuin63.dll','icuuc63.dll','icudt63l.dat','msvcp140.dll','msvcp140_1.dll') {
  if (Test-Path "$fb\$f") { Copy-Item "$fb\$f" $arq -Force } else { Write-Warning "Não encontrado: $fb\$f" }
}
foreach ($f in 'vcruntime140.dll','vcruntime140_1.dll','msvcp140.dll') { Copy-Item "$env:SystemRoot\System32\$f" $arq -Force }

$ver = (Select-String -Path lib\core\build_info.dart -Pattern "buildVersion = '([^']+)'").Matches[0].Groups[1].Value
$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe","${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe","$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 não encontrado.' }
& $iscc "/DAppVersao=$ver" instalador\GoUpPonto.iss; if ($LASTEXITCODE) { throw 'Falha ao gerar o instalador.' }
Remove-Item $arq -Recurse -Force
Get-ChildItem instalador\*.exe | ForEach-Object { Write-Host ('Instalador: {0} ({1:N1} MB)' -f $_.FullName, ($_.Length/1MB)) -ForegroundColor Green }
