module tb_designer;

    logic clk_fpga, clk_bitdog, reset;
    logic [7:0] tb_dados;
    logic tb_req, tb_ack;
    logic tb_boia_cheia, tb_boia_vazia;
    logic pwm_ma, pwm_mb, pwm_ba, pwm_bb;

    designer DUT (
        .clk_fpga(clk_fpga), .reset(reset),
        .i_dados(tb_dados), .i_req(tb_req), .o_ack(tb_ack),
        .i_boia_cheia(tb_boia_cheia), .i_boia_vazia(tb_boia_vazia),
        .o_pwm_motor_a(pwm_ma), .o_pwm_motor_b(pwm_mb),
        .o_pwm_bomba_a(pwm_ba), .o_pwm_bomba_b(pwm_bb)
    );

    initial clk_fpga = 0; always #10 clk_fpga = ~clk_fpga;
    initial clk_bitdog = 0; always #20 clk_bitdog = ~clk_bitdog;

    task transmit_handshake(input [7:0] data_to_send);
        @(posedge clk_bitdog);
        tb_req <= 1'b1; tb_dados <= data_to_send;
        wait (tb_ack == 1'b1);
        @(posedge clk_bitdog);
        tb_req <= 1'b0;
        wait (tb_ack == 1'b0);
        @(posedge clk_bitdog);
        $display("[%0t ns] Transmissao do dado %h finalizada.", $time, data_to_send);
    endtask

    initial begin
        reset = 1; tb_req = 0; tb_dados = '0;
        tb_boia_cheia = 0; tb_boia_vazia = 1; // Condição inicial: Filtro B vazio
        #100; reset = 0;

        // Inicia ciclo com PWM 90% (valor 230)
        $display("[%0t ns] BitDog: Agua anomala! Iniciando filtragem com 90%%.", $time);
        transmit_handshake(8'd230);

        // Simula o enchimento do filtro
        #1000; tb_boia_vazia = 0; // Água começou a encher
        #3000; tb_boia_cheia = 1; // Filtro encheu

        // Simula o esvaziamento do filtro
        #1000; tb_boia_cheia = 0; // Água começou a esvaziar
        #3000; tb_boia_vazia = 1; // Filtro esvaziou, deve voltar a encher

        // Simula o segundo ciclo de enchimento
        #1000; tb_boia_vazia = 0;
        #3000; tb_boia_cheia = 1;

        // BitDog detecta que a água está boa e manda parar
        $display("[%0t ns] BitDog: Agua OK! Finalizando filtragem.", $time);
        transmit_handshake(8'd0);

        // Simula o esvaziamento final
        #1000; tb_boia_cheia = 0;
        #3000; tb_boia_vazia = 1; // Ciclo de parada deve terminar aqui

        #500;
        $display("[%0t ns] Simulacao finalizada.", $time);
        $finish;
    end
endmodule