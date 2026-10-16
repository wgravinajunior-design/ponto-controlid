@echo off
chcp 65001 > nul
setlocal
cd /d "%~dp0"
set "REL=%~dp0build\windows\x64\runner\Release"

echo ==========================================
echo   Go Up Ponto - teste
echo ==========================================

rem Compila se o executavel ainda nao existe ou se chamado com "testar.bat build"
if /i "%~1"=="build" goto compilar
if not exist "%REL%\GoUpPonto.exe" goto compilar
goto config

:compilar
echo Compilando versao Release (pode levar alguns minutos)...
call flutter build windows --release
if errorlevel 1 goto erro
call dart build cli -t bin/servico.dart -o build\servico
if exist "build\servico\bundle\bin\servico.exe" copy /y "build\servico\bundle\bin\servico.exe" "%REL%\GoUpPontoServico.exe" > nul
:erro
if errorlevel 1 (
  echo.
  echo ERRO na compilacao. Verifique as mensagens acima.
  pause
  exit /b 1
)

:config
rem Primeira execucao: reaproveita o Config.ini do sistema Delphi
if not exist "%REL%\Config.ini" (
  if exist "%~dp0..\Config.ini" (
    copy /y "%~dp0..\Config.ini" "%REL%\Config.ini" > nul
    echo Config.ini copiado do sistema Delphi.
  )
)

rem O app e 64 bits: avisa se o fbclient.dll 64 bits do Firebird 5 nao estiver instalado
if not exist "C:\Program Files\Firebird\Firebird_5_0\fbclient.dll" (
  echo AVISO: fbclient.dll 64 bits nao encontrado em C:\Program Files\Firebird\Firebird_5_0
  echo        Ajuste o caminho em Configuracoes ^> Banco de Dados.
)

rem Atalho "Go Up Ponto" na area de trabalho (usa o icone do executavel)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$d=[Environment]::GetFolderPath('Desktop'); $s=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $d 'Go Up Ponto.lnk'));" ^
  "$s.TargetPath='%REL%\GoUpPonto.exe'; $s.WorkingDirectory='%REL%'; $s.IconLocation='%REL%\GoUpPonto.exe,0';" ^
  "$s.Description='Go Up Ponto - Controle de ponto eletronico'; $s.Save()"
echo Atalho "Go Up Ponto" criado/atualizado na area de trabalho.

echo Iniciando o aplicativo...
start "" "%REL%\GoUpPonto.exe"
endlocal
