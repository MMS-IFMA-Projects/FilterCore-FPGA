@echo off
REM Limpa a tela do terminal para uma visualização mais limpa
cls

echo [INFO] Iniciando a compilacao e simulacao do projeto SystemVerilog...

REM --- Etapa 1: Compila todos os arquivos SystemVerilog com Icarus Verilog ---
echo [PASSO 1/2] Compilando modulos de design e testbench...
REM Icarus Verilog compila todos os arquivos de uma vez para gerar um executavel de simulacao.
iverilog -g2012 -o tb_designer.vvp ^
    handshake_receiver.sv ^
    pwm_generator.sv ^
    designer.sv ^
    tb_designer.sv

IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha na compilacao.
    goto :eof
)

REM --- Etapa 2: Roda a simulação e gera a forma de onda ---
echo [PASSO 2/2] Rodando a simulacao e gerando arquivo VCD...
REM O simulador VVP executa o arquivo compilado e gera o arquivo de forma de onda.
vvp tb_designer.vvp -lxt2 onda.vcd

IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha na simulacao.
    goto :eof
)

echo [SUCESSO] Simulacao concluida! O arquivo onda.vcd foi gerado.

REM --- Etapa Opcional: Abrir o visualizador de formas de onda ---
echo [INFO] Abrindo o GTKWave para visualizar onda.vcd...
start gtkwave onda.vcd

echo.
echo Pressione qualquer tecla para fechar o terminal...
pause > nul