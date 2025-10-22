/**
 * @file designer.sv
 * @brief Módulo Top-Level que implementa a lógica de controle de filtragem final.
 */
module designer (
    // Clock e Reset
    input wire clk_fpga, input wire reset,
    // Interface com a BitDogLab (agora com 4 bits de dados)
    input wire [3:0] i_dados, input wire i_req, output logic o_ack,
    // Interface com os Sensores de Nível
    input wire i_boia_cheia, input wire i_boia_vazia,
    // Saídas para as Bombas
    output logic o_pwm_bomba_a, output logic o_pwm_bomba_b
);
    typedef enum logic [1:0] {STOP, RUNNING_FILLING, RUNNING_RETURNING, STOPPING} state_t;

    logic [3:0] dados_recebidos;
    logic       novo_dado_chegou;
    logic [3:0] reg_status_estrategico = 4'b0; // Armazena os 4 bits de status
    
    logic boia_cheia_sync, boia_vazia_sync;
    state_t estado_atual, proximo_estado;

    always_ff @(posedge clk_fpga) begin
        boia_cheia_sync <= i_boia_cheia;
        boia_vazia_sync <= i_boia_vazia;
    end

    handshake_receiver #( .DATA_WIDTH(4) ) FSM_comm (
        .clk_fpga(clk_fpga), .reset(reset), .i_dados(i_dados), .i_req(i_req), .o_ack(o_ack),
        .o_dados_validos(dados_recebidos), .o_novo_dado_pronto(novo_dado_chegou)
    );

    always_comb begin
        proximo_estado = estado_atual;
        // A lógica de transição principal é baseada no status recebido OU nas boias
        case (estado_atual)
            STOP:
                // Se algum bit de status for '1' (anomalia ou botão), inicia o ciclo
                if (|dados_recebidos) proximo_estado = RUNNING_FILLING;
            RUNNING_FILLING:
                if (boia_cheia_sync) proximo_estado = RUNNING_RETURNING;
            RUNNING_RETURNING:
                // Se a qualidade da água voltar ao normal (todos os bits de status = 0), para.
                if (&(~dados_recebidos)) proximo_estado = STOPPING;
                // Senão, se o filtro esvaziar, continua o ciclo
                else if (boia_vazia_sync) proximo_estado = RUNNING_FILLING;
            STOPPING:
                if (boia_vazia_sync) proximo_estado = STOP;
        endcase
    end

    always_ff @(posedge clk_fpga or posedge reset) begin
        if (reset) begin
            estado_atual <= STOP;
            reg_status_estrategico <= 4'b0;
        end else begin
            estado_atual <= proximo_estado;
            if (novo_dado_chegou) reg_status_estrategico <= dados_recebidos;
        end
    end

    logic [7:0] pwm_bomba_a, pwm_bomba_b;
    localparam PWM_HIGH = 8'd230; // 90%
    
    always_comb begin
        pwm_bomba_a = 8'h00; pwm_bomba_b = 8'h00; // Padrão
        case (estado_atual)
            RUNNING_FILLING:   pwm_bomba_a = PWM_HIGH;
            RUNNING_RETURNING: pwm_bomba_b = PWM_HIGH;
            STOPPING:          pwm_bomba_b = PWM_HIGH; // Continua esvaziando para parar
        endcase
    end

    pwm_generator PWM_BA (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_bomba_a), .o_pwm_out(o_pwm_bomba_a));
    pwm_generator PWM_BB (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_bomba_b), .o_pwm_out(o_pwm_bomba_b));

endmodule