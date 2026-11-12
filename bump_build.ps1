<#
.SYNOPSIS
    Soma 1 ao numero de build (sem compilar nem publicar), para identificar a versao que o usuario esta rodando.
.DESCRIPTION
    Regra do projeto: toda alteracao de codigo muda o numero de build.
    -App Delphi  : version.json + uBuildInfo.pas + FileVersion/ProductVersion do PontoControlID.dproj
    -App Flutter : ponto_flutter/lib/core/build_info.dart
    -App Ambos   : os dois (padrao)
.EXAMPLE
    .\bump_build.ps1 -App Delphi
#>
[CmdletBinding()]
param([ValidateSet("Delphi", "Flutter", "Ambos")][string]$App = "Ambos")

$ErrorActionPreference = "Stop"
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Bom = New-Object System.Text.UTF8Encoding($true)
$NoBom = New-Object System.Text.UTF8Encoding($false)

if ($App -in @("Delphi", "Ambos")) {
    $VersionFile = Join-Path $Dir "version.json"
    $Info = [System.IO.File]::ReadAllText($VersionFile) | ConvertFrom-Json
    $Version = [string]$Info.version
    $Build = [int]$Info.build + 1
    $Date = Get-Date -Format "dd/MM/yyyy HH:mm"
    [System.IO.File]::WriteAllText($VersionFile, "{`r`n  `"version`": `"$Version`",`r`n  `"build`": $Build`r`n}`r`n", $NoBom)

    $Pas = "unit uBuildInfo;`r`n`r`n// ARQUIVO GERADO AUTOMATICAMENTE PELO build.ps1 / bump_build.ps1 - NAO EDITAR MANUALMENTE.`r`n" +
        "// A versao e o numero de build ficam em version.json.`r`n`r`ninterface`r`n`r`nconst`r`n" +
        "  BUILD_VERSION = '$Version';`r`n  BUILD_NUMBER = $Build;`r`n  BUILD_DATE = '$Date';`r`n`r`nimplementation`r`n`r`nend.`r`n"
    [System.IO.File]::WriteAllText((Join-Path $Dir "uBuildInfo.pas"), $Pas, $Bom)

    $Dproj = Join-Path $Dir "PontoControlID.dproj"
    $Txt = [System.IO.File]::ReadAllText($Dproj, [System.Text.Encoding]::UTF8)
    $Txt = $Txt -replace 'FileVersion=[\d\.]+', "FileVersion=$Version.$Build"
    $Txt = $Txt -replace 'ProductVersion=[\d\.]+', "ProductVersion=$Version.$Build"
    [System.IO.File]::WriteAllText($Dproj, $Txt, $Bom)
    Write-Host "Delphi : v$Version  Build $Build  ($Date)"
}

if ($App -in @("Flutter", "Ambos")) {
    $File = Join-Path $Dir "ponto_flutter\lib\core\build_info.dart"
    $Txt = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8)
    $N = [int]([regex]::Match($Txt, 'buildNumber = (\d+);').Groups[1].Value) + 1
    $Txt = $Txt -replace 'buildNumber = \d+;', "buildNumber = $N;"
    $Txt = $Txt -replace "buildDate = '[^']*';", ("buildDate = '" + (Get-Date -Format "yyyy-MM-dd") + "';")
    [System.IO.File]::WriteAllText($File, $Txt, $NoBom)
    Write-Host "Flutter: Build $N"
}
