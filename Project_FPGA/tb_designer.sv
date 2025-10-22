/**
 * @file tb_designer.sv
 * @brief Testbench final e corrigido para o módulo 'designer'.
 */
 `timescale 1ns / 1ps
module tb_designer;

    // --- Parâmetros e Constantes ---
    localparam  CLK_FPGA_PERIOD   = 20ns; // 50 MHz
    localparam  CLK_BITDOG_PERIOD = 40ns; // 25 MHz

    // --- Sinais para Conectar ao DUT (Device Under Test) ---
    logic clk_fpga;
    logic clk_bitdog;
    logic reset;
    logic [3:0] tb_dados;
    logic       tb_req;
    logic       tb_ack;
    logic       tb_boia_cheia;
    logic       tb_boia_vazia;
    logic       pwm_ba, pwm_bb;

    // --- Instanciação do Módulo de Design ---
    designer DUT (
        .clk_fpga(clk_fpga), .reset(reset),
        .i_dados(tb_dados), .i_req(tb_req), .o_ack(tb_ack),
        .i_boia_cheia(tb_boia_cheia), .i_boia_vazia(tb_boia_vazia),
        .o_pwm_bomba_a(pwm_ba), .o_pwm_bomba_b(pwm_bb)
    );

    // --- Geração dos Clocks ---
    initial clk_fpga = 0;
    always #(CLK_FPGA_PERIOD / 2) clk_fpga = ~clk_fpga;

    initial clk_bitdog = 0;
    always #(CLK_BITDOG_PERIOD / 2) clk_bitdog = ~clk_bitdog;

    // --- Tarefa para Simular o Transmissor da BitDogLab ---
    task transmit_handshake(input [3:0] data_to_send);
        @(posedge clk_bitdog);
        tb_req <= 1'b1; tb_dados <= data_to_send;
        wait (tb_ack == 1'b1);
        @(posedge clk_bitdog);
        tb_req <= 1'b0;
        wait (tb_ack == 1'b0);
        @(posedge clk_bitdog);
        $display("[%0t] BitDog: Status %b enviado.", $time, data_to_send);
    endtask

    // --- Sequência Principal de Testes ---
    initial begin
        $dumpfile("onda.vcd"); 
        $dumpvars(0, tb_designer); 
        
        reset = 1; tb_req = 0; tb_dados = '0;
        tb_boia_cheia = 0; tb_boia_vazia = 1;
        #100ns;
        reset = 0;

        #50ns;
        $display("[%0t] TESTE: Agua anomala! (pH anomalo -> 4'b0100)", $time);
        transmit_handshake(4'b0100);

        #4000ns;
        tb_boia_cheia = 1;
        $display("[%0t] SENSOR: Boia Cheia ativada.", $time);
        
        #4000ns;
        tb_boia_vazia = 1;
        $display("[%0t] SENSOR: Boia Vazia ativada.", $time);
        
        #4000ns;
        $display("[%0t] TESTE: Agua OK! (Status -> 4'b0000)", $time);
        transmit_handshake(4'b0000);

        #4000ns;
        tb_boia_vazia = 1;
        $display("[%0t] SENSOR: Boia Vazia ativada (para finalizar o STOPPING).", $time);

        #500ns;
        $display("[%0t] SIMULACAO: Fim do teste.", $time);
        $finish;
    end
endmodule