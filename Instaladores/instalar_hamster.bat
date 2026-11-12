@echo off
rem ==================================================================
rem  Instala driver do leitor Nitgen Hamster DX e runtime do SDK eNBSP
rem  (NBioBSP) sem precisar baixar nada. Executar como Administrador.
rem ==================================================================
net session >nul 2>&1
if errorlevel 1 (
  echo Execute este arquivo como Administrador.
  pause
  exit /b 1
)

set "BASE=%~dp0"

echo [1/2] Instalando driver do Hamster DX...
rem Pasta driver\ = pacote 64 bits; Windows 32 bits usa o instalador original x86
if exist "%SystemRoot%\SysWOW64" (
  pnputil /add-driver "%BASE%driver\*.inf" /install
) else (
  "%BASE%UBio_Hamster_X_Driver_Setup_x86\UBio_Hamster_X_Driver_Setup_x86.exe" -s -f1"%BASE%UBio_Hamster_X_Driver_Setup_x86\install_UBio_Hamster_X_Driver.iss"
)

echo [2/2] Instalando SDK eNBSP (NBioBSP)...
rem O sistema e 32 bits: DLLs vao para SysWOW64 (Windows 64) ou System32 (Windows 32)
if exist "%SystemRoot%\SysWOW64" (
  set "DEST=%SystemRoot%\SysWOW64"
) else (
  set "DEST=%SystemRoot%\System32"
)
copy /Y "%BASE%sdk\NBioBSP.dll" "%DEST%\" >nul
copy /Y "%BASE%sdk\NBioBSPCOM.dll" "%DEST%\" >nul
"%DEST%\regsvr32.exe" /s "%DEST%\NBioBSPCOM.dll"
if errorlevel 1 (
  echo Falha ao registrar NBioBSPCOM.dll
  exit /b 2
)

echo.
echo Concluido. Desconecte e reconecte o leitor na USB.
exit /b 0
