/**
 * @file designer.sv
 * @brief Módulo Top-Level que implementa a lógica de controle de filtragem.
 */
module designer (
    // Clock e Reset
    input wire clk_fpga,
    input wire reset,

    // Interface de Comunicação com a BitDogLab
    input wire [7:0] i_dados,
    input wire       i_req,
    output logic     o_ack,

    // Interface com os Sensores de Nível (Boias)
    input wire i_boia_cheia,
    input wire i_boia_vazia,

    // Saídas para os Atuadores
    output logic o_pwm_motor_a,
    output logic o_pwm_motor_b,
    output logic o_pwm_bomba_a,
    output logic o_pwm_bomba_b
);

    // --- Sinais da Comunicação ---
    logic [7:0] dados_recebidos;
    logic       novo_dado_chegou;
    logic [7:0] reg_pwm_estrategico = 8'h00; // Armazena o PWM estratégico vindo da BitDog

    // --- FSM de Controle Tático ---
    typedef enum logic [1:0] {STOP, RUNNING_FILLING, RUNNING_RETURNING, STOPPING} state_t;
    state_t estado_atual, proximo_estado;

    // --- Instancia o Módulo de Handshake (FSM 1) ---
    handshake_receiver FSM_comm (
        .clk_fpga(clk_fpga), .reset(reset),
        .i_dados(i_dados), .i_req(i_req), .o_ack(o_ack),
        .o_dados_validos(dados_recebidos), .o_novo_dado_pronto(novo_dado_chegou)
    );

    // --- Lógica de Transição da FSM Tática (Combinacional) ---
    always_comb begin
        proximo_estado = estado_atual;
        if (novo_dado_chegou) begin
             // A BitDogLab tem prioridade: se ela mandar um novo comando, a FSM reavalia
            if (dados_recebidos != 0) begin // Comando para iniciar/continuar
                proximo_estado = RUNNING_FILLING; // Sempre começa enchendo
            end else begin // Comando 0 significa PARAR
                proximo_estado = STOPPING;
            end
        end else begin
            // Lógica de alternância baseada nas boias
            case (estado_atual)
                RUNNING_FILLING:
                    if (i_boia_cheia) proximo_estado = RUNNING_RETURNING; 
                RUNNING_RETURNING:
                    if (i_boia_vazia) proximo_estado = RUNNING_FILLING;
                STOPPING:
                    if (i_boia_vazia) proximo_estado = STOP; // Termina a parada quando o filtro esvazia
                default: // STOP ou qualquer outro estado
                    proximo_estado = estado_atual; // Mantém o estado atual
            endcase
        end
    end

    // --- Lógica de Estados e Saídas (Sequencial) ---
    logic [7:0] pwm_motor_a, pwm_motor_b, pwm_bomba_a, pwm_bomba_b;
    
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

    // --- Define as saídas de PWM com base no estado atual ---
    always_comb begin
        // Padrão: tudo desligado
        pwm_motor_a = 8'h00; pwm_motor_b = 8'h00;
        pwm_bomba_a = 8'h00; pwm_bomba_b = 8'h00;
        
        case (estado_atual)
            RUNNING_FILLING: begin
                // Comportas abertas, Bomba A ligada com PWM estratégico
                pwm_motor_a = 8'hFF; // 100% para abrir/manter aberta
                pwm_motor_b = 8'hFF;
                pwm_bomba_a = reg_pwm_estrategico;
                pwm_bomba_b = 8'h00;
            end

            RUNNING_RETURNING: begin
                // Comportas abertas, Bomba B ligada com PWM estratégico
                pwm_motor_a = 8'hFF;
                pwm_motor_b = 8'hFF;
                pwm_bomba_a = 8'h00;
                pwm_bomba_b = reg_pwm_estrategico;
            end

            STOPPING: begin
                // Comportas abertas, esvaziando o filtro B para parar
                pwm_motor_a = 8'hFF;
                pwm_motor_b = 8'hFF;
                pwm_bomba_a = 8'h00;
                pwm_bomba_b = reg_pwm_estrategico; // Esvazia com a última intensidade
            end
        endcase
    end

    // --- Instancia os Módulos Geradores de PWM ---
    pwm_generator #( .WIDTH(8) ) PWM_MA (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_motor_a), .o_pwm_out(o_pwm_motor_a));
    pwm_generator #( .WIDTH(8) ) PWM_MB (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_motor_b), .o_pwm_out(o_pwm_motor_b));
    pwm_generator #( .WIDTH(8) ) PWM_BA (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_bomba_a), .o_pwm_out(o_pwm_bomba_a));
    pwm_generator #( .WIDTH(8) ) PWM_BB (.clk_fpga(clk_fpga), .reset(reset), .i_duty_cycle(pwm_bomba_b), .o_pwm_out(o_pwm_bomba_b));

endmodule