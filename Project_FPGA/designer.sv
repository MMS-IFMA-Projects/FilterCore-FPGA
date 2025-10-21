/**
 * @file designer.sv
 * @brief Módulo Top-Level que implementa a lógica de controle de filtragem (versão simplificada).
 */
module designer (
    input wire clk_fpga, input wire reset,
    input wire [7:0] i_dados, input wire i_req, output logic o_ack,
    input wire i_boia_cheia, input wire i_boia_vazia,
    output logic o_pwm_motor_a, output logic o_pwm_motor_b,
    output logic o_pwm_bomba_a, output logic o_pwm_bomba_b
);
    // --- Definições Internas (eliminando a dependência do _pkg.sv) ---
    typedef enum logic [1:0] {STOP, RUNNING_FILLING, RUNNING_RETURNING, STOPPING} state_t;

    // --- Sinais da Comunicação ---
    logic [7:0] dados_recebidos;
    logic       novo_dado_chegou;
    logic [7:0] reg_pwm_estrategico = 8'h00;

    // --- Sincronização dos Sinais das Boias (Boa Prática) ---
    logic boia_cheia_sync, boia_vazia_sync;
    always_ff @(posedge clk_fpga) begin
        boia_cheia_sync <= i_boia_cheia;
        boia_vazia_sync <= i_boia_vazia;
    end

    // --- FSM de Controle Tático ---
    state_t estado_atual, proximo_estado;

    // --- Instancia o Módulo de Handshake ---
    handshake_receiver FSM_comm (
        .clk_fpga(clk_fpga), .reset(reset),
        .i_dados(i_dados), .i_req(i_req), .o_ack(o_ack),
        .o_dados_validos(dados_recebidos), .o_novo_dado_pronto(novo_dado_chegou)
    );

    // --- Lógica de Transição da FSM Tática (Combinacional) ---
    always_comb begin
        proximo_estado = estado_atual;
        if (novo_dado_chegou) begin
            if (dados_recebidos != 0) proximo_estado = RUNNING_FILLING;
            else proximo_estado = STOPPING;
        end else begin
            case (estado_atual)
                RUNNING_FILLING:   if (boia_cheia_sync) proximo_estado = RUNNING_RETURNING;
                RUNNING_RETURNING: if (boia_vazia_sync) proximo_estado = RUNNING_FILLING;
                STOPPING:          if (boia_vazia_sync) proximo_estado = STOP;
            endcase
        end
    end

    // --- Lógica de Estados (Sequencial) ---
    always_ff @(posedge clk_fpga or posedge reset) begin
        if (reset) begin
            estado_atual <= STOP;
            reg_pwm_estrategico <= 8'h00;
        end else begin
            estado_atual <= proximo_estado;
            if (novo_dado_chegou) begin
                reg_pwm_estrategico <= dados_recebidos;
            end
        end
    end

    // --- Lógica de Saídas (Combinacional) ---
    logic [7:0] pwm_motor_a, pwm_motor_b, pwm_bomba_a, pwm_bomba_b;
    always_comb begin
        // Padrão: tudo desligado
        pwm_motor_a = 8'h00; pwm_motor_b = 8'h00;
        pwm_bomba_a = 8'h00; pwm_bomba_b = 8'h00;
        
        case (estado_atual)
            RUNNING_FILLING: begin
                pwm_motor_a = 8'hFF; pwm_motor_b = 8'hFF;
                pwm_bomba_a = reg_pwm_estrategico;
            end
            RUNNING_RETURNING: begin
                pwm_motor_a = 8'hFF; pwm_motor_b = 8'hFF;
                pwm_bomba_b = reg_pwm_estrategico;
            end
            STOPPING: begin
                pwm_motor_a = 8'hFF; pwm_motor_b = 8'hFF;
                pwm_bomba_b = reg_pwm_estrategico;
            end
        endcase
    end

    // --- Instancia os Módulos Geradores de PWM ---
    pwm_generator PWM_MA (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_motor_a), .o_pwm_out(o_pwm_motor_a));
    pwm_generator PWM_MB (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_motor_b), .o_pwm_out(o_pwm_motor_b));
    pwm_generator PWM_BA (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_bomba_a), .o_pwm_out(o_pwm_bomba_a));
    pwm_generator PWM_BB (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_bomba_b), .o_pwm_out(o_pwm_bomba_b));

endmodule