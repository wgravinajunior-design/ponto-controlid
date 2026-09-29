<#
.SYNOPSIS
    Workflow de versao/build, verificacao de encoding, compilacao e release do Integrador Control iD.
.DESCRIPTION
    0. Le version.json, incrementa o numero de build e gera uBuildInfo.pas + VerInfo do .dproj.
    1. Garante que todos os arquivos .pas e .dpr possuam UTF-8 BOM (EF BB BF).
    2. Garante que o arquivo .dproj possua DCC_CodePage=65001.
    3. Executa o build limpo com Delphi 12 (Athens).
    4. Se -ReleaseVersion for informada, faz commit/push e publica a release no GitHub
       (tag vX.Y.Z, titulo "vX.Y.Z (Build N)"), que o auto-update do sistema detecta.
.EXAMPLE
    .\build.ps1                                  # compila (build N+1) sem publicar
    .\build.ps1 -ReleaseVersion 1.0.1            # compila e publica v1.0.1 (Build N+1)
    .\build.ps1 -ReleaseVersion 1.0.2 -ReleaseNotes "Correcoes..."
#>

[CmdletBinding()]
param(
    [string]$Config = "Release",
    [string]$Platform = "Win32",
    [string]$ReleaseVersion = "",
    [string]$ReleaseNotes = "",
    [switch]$NoIncrement
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Utf8WithBom = New-Object System.Text.UTF8Encoding($true)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Workflow de Build & Release (Delphi 12 Athens)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Localizar Git e GitHub CLI e garantir no PATH
if (Test-Path "C:\Program Files\Git\cmd") {
    $env:Path = "C:\Program Files\Git\cmd;C:\Program Files\Git\bin;" + $env:Path
}
if (Test-Path "C:\Program Files\GitHub CLI") {
    $env:Path = "C:\Program Files\GitHub CLI;" + $env:Path
}
$GitCmd = if (Get-Command git -ErrorAction SilentlyContinue) { "git" } elseif (Test-Path "C:\Program Files\Git\cmd\git.exe") { "C:\Program Files\Git\cmd\git.exe" } else { $null }
$GhCmd  = if (Get-Command gh -ErrorAction SilentlyContinue) { "gh" } elseif (Test-Path "C:\Program Files\GitHub CLI\gh.exe") { "C:\Program Files\GitHub CLI\gh.exe" } else { $null }

# 0. Versao e numero de build
Write-Host "`n[0/4] Gerando versao e numero de build..." -ForegroundColor Yellow
$VersionFile = Join-Path $ScriptDir "version.json"
if (Test-Path $VersionFile) {
    $VerInfo = [System.IO.File]::ReadAllText($VersionFile) | ConvertFrom-Json
    $Version = [string]$VerInfo.version
    $Build = [int]$VerInfo.build
} else {
    $Version = "1.0.1"
    $Build = 0
}

if ($ReleaseVersion) {
    $Version = $ReleaseVersion.TrimStart("v", "V")
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Versao invalida '$Version'. Use o formato X.Y.Z (ex.: 1.0.1)."
}
if (-not $NoIncrement) {
    $Build++
}
$BuildDate = Get-Date -Format "dd/MM/yyyy HH:mm"
$FileVersion = "$Version.$Build"

$VersionJson = "{`r`n  `"version`": `"$Version`",`r`n  `"build`": $Build`r`n}`r`n"
[System.IO.File]::WriteAllText($VersionFile, $VersionJson, $Utf8NoBom)

$BuildInfoPas = @"
unit uBuildInfo;

// ARQUIVO GERADO AUTOMATICAMENTE PELO build.ps1 - NAO EDITAR MANUALMENTE.
// A versao e o numero de build ficam em version.json.

interface

const
  BUILD_VERSION = '$Version';
  BUILD_NUMBER = $Build;
  BUILD_DATE = '$BuildDate';

implementation

end.
"@
[System.IO.File]::WriteAllText((Join-Path $ScriptDir "uBuildInfo.pas"), ($BuildInfoPas -replace "`r?`n", "`r`n") + "`r`n", $Utf8WithBom)

$DprojMain = Join-Path $ScriptDir "PontoControlID.dproj"
$DprojText = [System.IO.File]::ReadAllText($DprojMain, [System.Text.Encoding]::UTF8)
$DprojText = $DprojText -replace 'FileVersion=[\d\.]+', "FileVersion=$FileVersion"
$DprojText = $DprojText -replace 'ProductVersion=[\d\.]+', "ProductVersion=$FileVersion"
[System.IO.File]::WriteAllText($DprojMain, $DprojText, $Utf8WithBom)

Write-Host "  -> Versao v$Version  |  Build $Build  |  $BuildDate" -ForegroundColor Green

# 1. Normalizar arquivos .pas e .dpr para UTF-8 com BOM
Write-Host "`n[1/4] Verificando e corrigindo codificacao dos arquivos fonte..." -ForegroundColor Yellow
$SourceFiles = Get-ChildItem -Path $ScriptDir -Include "*.pas", "*.dpr" -Recurse |
    Where-Object { $_.FullName -notmatch '\\(__history|__recovery|scratch)\\' }

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

$BuildCmd = "call `"$RsVars`" && msbuild `"$DprojMain`" /t:Rebuild /p:Configuration=$Config /p:Platform=$Platform /nologo /v:minimal"
cmd /c $BuildCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERRO] Falha durante a compilacao. Verifique as mensagens acima." -ForegroundColor Red
    exit 1
}

$ExePath = Join-Path $ScriptDir "PontoControlID.exe"
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  [SUCESSO] Compilacao finalizada com exito!" -ForegroundColor Green
Write-Host "  Versao : v$Version (Build $Build)" -ForegroundColor Green
Write-Host "  Binario: $ExePath" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# 4. Publicar Release no GitHub (opcional)
if ($ReleaseVersion) {
    $Tag = "v$Version"
    $Title = "$Tag (Build $Build)"
    Write-Host "`n[4/4] Publicando Release no GitHub ($Title)..." -ForegroundColor Cyan

    if (-not $GhCmd) {
        Write-Host "  [AVISO] GitHub CLI (gh.exe) nao foi encontrado. Release manual necessaria." -ForegroundColor Yellow
        exit 0
    }

    if (-not $ReleaseNotes) {
        $ReleaseNotes = "Release automatica $Tag do Integrador Ponto Control iD."
    }
    $ReleaseNotes = "$ReleaseNotes`n`nBuild: $Build ($BuildDate)"

    $PrevEA = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    if ($GitCmd) {
        Write-Host "  -> Sincronizando com Git..." -ForegroundColor DarkGray
        & $GitCmd add -A
        & $GitCmd commit -m "chore: release $Title" -q
        & $GitCmd push origin HEAD -q
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [ERRO] Falha no git push. Release nao publicada." -ForegroundColor Red
            exit 1
        }
    }

    & $GhCmd release view $Tag *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  -> Release $Tag ja existe. Atualizando binario e build..." -ForegroundColor Yellow
        & $GhCmd release upload $Tag $ExePath --clobber
        & $GhCmd release edit $Tag --title $Title --notes $ReleaseNotes --latest
    } else {
        & $GhCmd release create $Tag $ExePath --title $Title --notes $ReleaseNotes --latest
    }
    $Ok = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $PrevEA

    if ($Ok) {
        Write-Host "  [SUCESSO] Release $Title publicada no GitHub!" -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] Falha ao publicar release no GitHub. Verifique credenciais do gh." -ForegroundColor Yellow
        exit 1
    }
}
