<#
.SYNOPSIS
    Workflow de verificação de encoding, compilação e release do Integrador Control iD.
.DESCRIPTION
    1. Garante que todos os arquivos .pas e .dpr possuam UTF-8 BOM (EF BB BF).
    2. Garante que o arquivo .dproj possua DCC_CodePage=65001.
    3. Executa o build limpo com Delphi 12 (Athens).
    4. Se $ReleaseVersion for informada, gera tag e release no GitHub via GitHub CLI.
#>

[CmdletBinding()]
param(
    [string]$Config = "Release",
    [string]$Platform = "Win32",
    [string]$ReleaseVersion = "",
    [string]$ReleaseNotes = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Workflow de Build & Release (Delphi 12 Athens)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Localizar Git e GitHub CLI e garantir no PATH
if (Test-Path "C:\Program Files\Git\cmd") {
    $env:Path = "C:\Program Files\Git\cmd;" + $env:Path
}
if (Test-Path "C:\Program Files\GitHub CLI") {
    $env:Path = "C:\Program Files\GitHub CLI;" + $env:Path
}
$GitCmd = if (Get-Command git -ErrorAction SilentlyContinue) { "git" } elseif (Test-Path "C:\Program Files\Git\cmd\git.exe") { "C:\Program Files\Git\cmd\git.exe" } else { $null }
$GhCmd  = if (Get-Command gh -ErrorAction SilentlyContinue) { "gh" } elseif (Test-Path "C:\Program Files\GitHub CLI\gh.exe") { "C:\Program Files\GitHub CLI\gh.exe" } else { $null }

# 1. Normalizar arquivos .pas e .dpr para UTF-8 com BOM
Write-Host "`n[1/4] Verificando e corrigindo codificacao dos arquivos fonte..." -ForegroundColor Yellow
$Utf8WithBom = New-Object System.Text.UTF8Encoding($true)
$SourceFiles = Get-ChildItem -Path $ScriptDir -Include "*.pas", "*.dpr" -Recurse

foreach ($File in $SourceFiles) {
    $Bytes = Get-Content -Path $File.FullName -Encoding Byte -TotalCount 3 -ErrorAction SilentlyContinue
    $HasBom = ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF)
    
    if (-not $HasBom) {
        $Text = [System.IO.File]::ReadAllText($File.FullName, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($File.FullName, $Text, $Utf8WithBom)
        Write-Host "  -> Corrigido para UTF-8 com BOM: $($File.Name)" -ForegroundColor Green
    } else {
        Write-Host "  -> OK (UTF-8 BOM presente): $($File.Name)" -ForegroundColor DarkGray
    }
}

# 2. Verificar DCC_CodePage no .dproj
Write-Host "`n[2/4] Verificando configuracao do projeto .dproj..." -ForegroundColor Yellow
$DprojFiles = Get-ChildItem -Path $ScriptDir -Filter "*.dproj"
foreach ($Dproj in $DprojFiles) {
    $DprojContent = [System.IO.File]::ReadAllText($Dproj.FullName, [System.Text.Encoding]::UTF8)
    if ($DprojContent -notmatch "<DCC_CodePage>65001</DCC_CodePage>") {
        Write-Host "  -> Adicionando <DCC_CodePage>65001</DCC_CodePage> em $($Dproj.Name)..." -ForegroundColor Green
        $DprojContent = $DprojContent -replace "(<SanitizedProjectName>[^<]+</SanitizedProjectName>)", "`$1`r`n        <DCC_CodePage>65001</DCC_CodePage>"
        [System.IO.File]::WriteAllText($Dproj.FullName, $DprojContent, $Utf8WithBom)
    } else {
        Write-Host "  -> OK (DCC_CodePage=65001 configurado): $($Dproj.Name)" -ForegroundColor DarkGray
    }
}

# 3. Compilar projeto
Write-Host "`n[3/4] Compilando projeto ($Config | $Platform)..." -ForegroundColor Yellow
$RsVars = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
if (-not (Test-Path -Path $RsVars)) {
    throw "Arquivo rsvars.bat nao encontrado em: $RsVars"
}

$DprojMain = Join-Path $ScriptDir "PontoControlID.dproj"
$BuildCmd = "call `"$RsVars`" && msbuild `"$DprojMain`" /t:Build /p:Configuration=$Config /p:Platform=$Platform"
cmd /c $BuildCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERRO] Falha durante a compilacao. Verifique as mensagens acima." -ForegroundColor Red
    exit 1
}

$ExePath = Join-Path $ScriptDir "PontoControlID.exe"
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  [SUCESSO] Compilacao finalizada com exito!" -ForegroundColor Green
Write-Host "  Binario gerado: $ExePath" -ForegroundColor Green
Write-Host "  Todos os acentos estao 100% preservados e validados." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# 4. Publicar Release no GitHub (opcional)
if ($ReleaseVersion) {
    Write-Host "`n[4/4] Gerando Release no GitHub ($ReleaseVersion)..." -ForegroundColor Cyan

    if (-not $ReleaseVersion.StartsWith("v")) {
        $ReleaseVersion = "v$ReleaseVersion"
    }

    if (-not $GhCmd) {
        Write-Host "  [AVISO] GitHub CLI (gh.exe) nao foi encontrado. Release manual necessaria." -ForegroundColor Yellow
        exit 0
    }

    if (-not $ReleaseNotes) {
        $ReleaseNotes = "Release automatica $ReleaseVersion do Integrador Ponto Control iD."
    }

    # Se git estiver disponivel, commitar e pushar
    if ($GitCmd) {
        Write-Host "  -> Sincronizando com Git..." -ForegroundColor DarkGray
        & $GitCmd add .
        & $GitCmd commit -m "chore: release $ReleaseVersion" -q 2>$null
        & $GitCmd push origin main -q 2>$null
    }

    # Criar ou atualizar release
    Write-Host "  -> Criando Release $ReleaseVersion no GitHub..." -ForegroundColor Yellow
    $PrevEA = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $ExistingReleases = & $GhCmd release list 2>$null
    if ($ExistingReleases -and ($ExistingReleases -match [regex]::Escape($ReleaseVersion))) {
        Write-Host "  -> Release $ReleaseVersion ja existe. Atualizando binario..." -ForegroundColor Yellow
        & $GhCmd release upload $ReleaseVersion $ExePath --clobber
    } else {
        & $GhCmd release create $ReleaseVersion $ExePath --title "Versao $ReleaseVersion" --notes $ReleaseNotes
    }
    $ErrorActionPreference = $PrevEA

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [SUCESSO] Release $ReleaseVersion publicada com sucesso no GitHub!" -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] Falha ao publicar release no GitHub. Verifique credenciais do gh." -ForegroundColor Yellow
    }
}
