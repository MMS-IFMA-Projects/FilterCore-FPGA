@echo off

REM ============================================================

REM 🚀 Gravar bitstream com openFPGALoader no projeto blink_onboard_led

REM ============================================================



set OSSCAD=C:\oss-cad-suite

set PROJETO=C:\Users\Mayro\OneDrive\Embarca Tech\FilterCore-FPGA\Project_FPGA\build

set BIT=impl\filtercore_impl.bit

set BOARD=colorlight-i9



REM Ativa ambiente do OSS CAD Suite

call "%OSSCAD%\environment.bat"



REM Vai para a pasta do projeto

cd /d "%PROJETO%"



REM Executa a gravação

openFPGALoader.exe -b %BOARD% --unprotect-flash -f --verify "%BIT%"



echo ============================================================

echo ✅ Processo finalizado!

echo ============================================================

pause