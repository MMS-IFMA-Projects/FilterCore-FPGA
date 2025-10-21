/**
 * @file tb_designer.sv
 * @brief Testbench completo para o módulo 'designer', configurado para Icarus Verilog.
 *
 * Este testbench verifica a arquitetura híbrida, simulando:
 * 1. O envio de comandos PWM da BitDogLab (domínio de clock de 25 MHz).
 * 2. A resposta da FSM tática do FPGA aos sensores de nível (boias).
 * 3. A correta alternância das bombas no ciclo de filtragem.
 */
`timescale 1ns / 1ps // Define a unidade de tempo (1ns) e a precisão (1ps)

module tb_designer;

    // --- Parâmetros e Constantes ---
    localparam  CLK_FPGA_PERIOD   = 20ns; // 50 MHz
    localparam  CLK_BITDOG_PERIOD = 40ns; // 25 MHz

    // --- Sinais para Conectar ao DUT (Device Under Test) ---
    logic clk_fpga;
    logic clk_bitdog;
    logic reset;
    logic [7:0] tb_dados;
    logic       tb_req;
    logic       tb_ack;
    logic       tb_boia_cheia;
    logic       tb_boia_vazia;

    // Sinais de saída do DUT para observação
    logic       pwm_ma, pwm_mb, pwm_ba, pwm_bb;

    // --- Instanciação do Módulo de Design ---
    // O nome 'designer' deve corresponder ao do seu arquivo de design.
    designer DUT (
        .clk_fpga(clk_fpga), .reset(reset),
        .i_dados(tb_dados), .i_req(tb_req), .o_ack(tb_ack),
        .i_boia_cheia(tb_boia_cheia), .i_boia_vazia(tb_boia_vazia),
        .o_pwm_motor_a(pwm_ma), .o_pwm_motor_b(pwm_mb),
        .o_pwm_bomba_a(pwm_ba), .o_pwm_bomba_b(pwm_bb)
    );

    // --- Geração dos Clocks Assíncronos ---
    initial clk_fpga = 0;
    always #(CLK_FPGA_PERIOD / 2) clk_fpga = ~clk_fpga;

    initial clk_bitdog = 0;
    always #(CLK_BITDOG_PERIOD / 2) clk_bitdog = ~clk_bitdog;

    // --- Tarefa para Simular o Transmissor da BitDogLab ---
    task transmit_handshake(input [7:0] data_to_send);
        @(posedge clk_bitdog);
        tb_req <= 1'b1;
        tb_dados <= data_to_send;
        
        wait (tb_ack == 1'b1);
        @(posedge clk_bitdog);
        
        tb_req <= 1'b0;

        wait (tb_ack == 1'b0);
        @(posedge clk_bitdog);
        $display("[%0t] BitDog: Transmissao do dado %h finalizada.", $time, data_to_send);
    endtask

    // --- Sequência Principal de Testes ---
    initial begin
        // --- Comandos para gerar a forma de onda (VCD) ---
        $dumpfile("onda.vcd"); // Define o nome do arquivo de onda
        $dumpvars(0, tb_designer);     // Grava todas as variáveis internas do módulo 'DUT'

        // Fase 1: Inicialização e Reset
        reset = 1; tb_req = 0; tb_dados = '0;
        tb_boia_cheia = 0; tb_boia_vazia = 1; // Condição inicial: Filtro B vazio
        $display("[%0t] SIMULACAO: Reset ativo.", $time);
        #100ns;
        reset = 0;
        $display("[%0t] SIMULACAO: Reset liberado. Sistema em STOP.", $time);

        // Fase 2: BitDog detecta água anômala e inicia o ciclo com 90% de PWM
        #50ns;
        $display("[%0t] TESTE: Agua anomala! Iniciando filtragem com 90%% (valor 230).", $time);
        transmit_handshake(8'd230); // Comando para RUNNING_FILLING

        // Fase 3: Simula o enchimento do filtro
        #1000ns;
        tb_boia_vazia = 0;
        $display("[%0t] SENSOR: Boia Vazia desativada (filtro comecou a encher).", $time);
        #3000ns;
        tb_boia_cheia = 1;
        $display("[%0t] SENSOR: Boia Cheia ativada (FPGA deve iniciar o retorno da agua).", $time);

        // Fase 4: Simula o esvaziamento do filtro
        #1000ns;
        tb_boia_cheia = 0;
        $display("[%0t] SENSOR: Boia Cheia desativada (filtro comecou a esvaziar).", $time);
        #3000ns;
        tb_boia_vazia = 1;
        $display("[%0t] SENSOR: Boia Vazia ativada (FPGA deve reiniciar o enchimento).", $time);

        // Fase 5: BitDog detecta que a água voltou ao normal e manda parar
        #4000ns;
        $display("[%0t] TESTE: Agua OK! Enviando comando de parada (valor 0).", $time);
        transmit_handshake(8'd0); // Comando para STOPPING

        // Fase 6: Simula o esvaziamento final durante o estado STOPPING
        #1000ns;
        tb_boia_cheia = 0;
        $display("[%0t] SENSOR: Boia Cheia desativada.", $time);
        #3000ns;
        tb_boia_vazia = 1;
        $display("[%0t] SENSOR: Boia Vazia ativada (FPGA deve ir para o estado final STOP).", $time);

        #500ns;
        $display("[%0t] SIMULACAO: Fim do teste.", $time);
        $finish;
    end
endmodule