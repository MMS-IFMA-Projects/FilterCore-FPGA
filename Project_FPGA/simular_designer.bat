@echo off
cls
echo [INFO] Iniciando a simulacao com Icarus Verilog...
echo.

REM --- Etapa 1: Compila todos os arquivos .sv e cria o executavel da simulacao ---
echo [PASSO 1/2] Compilando o projeto...
iverilog -g2012 -o designer.vvp handshake_receiver.sv pwm_generator.sv designer.sv tb_designer.sv

REM Verifica se a compilação falhou
IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha na compilacao. Verifique as mensagens de erro acima.
    pause
    goto :eof
)

REM --- Etapa 2: Executa a simulação ---
echo [PASSO 2/2] Rodando a simulacao...
vvp designer.vvp

echo.
echo --------------------------------------------------------------------
echo [SUCESSO] Simulacao concluida! O arquivo 'onda.vcd' foi gerado.
echo --------------------------------------------------------------------

pause