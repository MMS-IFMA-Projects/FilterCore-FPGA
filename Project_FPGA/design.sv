/**
 * @brief Módulo de topo do design "Filter Core".
 * @details Este módulo integra todos os sub-módulos:
 * 1. Handshake FSM (para comunicação com o Pico)
 * 2. Debouncers de Nível de Água (para os sensores)
 * 3. FSM de Controle (a lógica principal)
 * 4. Geradores de PWM (para as bombas)
 */
module filter_core_design (
    input wire clk,             // Clock principal (esperado 25MHz)
    input wire reset,           // Reset global (ativo baixo, vindo do Pico)

    // Interface with Pico
    input wire [3:0] data,      // Entrada de dados de status (do Pico)
    input wire req,             // Sinal de Requisição (do Pico)
    output logic ack,           // Sinal de Reconhecimento (para o Pico)
    output logic alive,         // Sinal 'vivo' (para o Pico)

    // Float Sensor Interface
    input wire level_sensor_b,  // Sensor Nível B (1=VAZIO, 0=CHEIO)
    input wire level_sensor_a,  // Sensor Nível A (1=NÃO CHEIO, 0=CHEIO)

    // Pump PWM Outputs
    output logic pwm_pump_a,    // Sinal PWM para Bomba A
    output logic pwm_pump_b,    // Sinal PWM para Bomba B

    // Connection LED
    output logic led_connection // LED de conexão/status
);

    // Internal Reset
    // Inverte o reset (ativo baixo) para reset interno (ativo alto)
    logic internal_reset;
    assign internal_reset = ~reset;


    // --- Wires to connect modules ---
    logic       new_data_pulse;         // Pulso do Handshake -> Latch de Dados
    logic       level_b_is_empty;       // Saída estável do Sensor B -> FSM Principal
    logic       level_a_is_full;        // Saída estável do Sensor A -> FSM Principal
    logic [7:0] pwm_duty_a;             // Duty cycle da FSM Principal -> PWM A
    logic [7:0] pwm_duty_b;             // Duty cycle da FSM Principal -> PWM B
    logic [3:0] reg_strategic_status;   // Registrador local para os dados do Pico
    logic       data_is_critical;       // Saída de criticidade da FSM Principal

    // --- 1. Handshake Receiver ---
    /**
     * @brief 1. Receptor de Handshake
     * @details Gerencia REQ/ACK e gera pulso 'new_data_pulse'
     */
    handshake_fsm #( .DATA_WIDTH(4) ) inst_handshake (
        .clk(clk), 
        .reset(internal_reset),
        .data(data), 
        .req(req), 
        .ack(ack),
        .new_data_pulse(new_data_pulse)
    );

    // --- 2. Data Latch ---
    /**
     * @brief 2. Registrador de Dados (Latch)
     * @details Captura os dados de entrada usando o pulso do handshake.
     */
    always_ff @(posedge clk or posedge internal_reset) begin
        if (internal_reset) reg_strategic_status <= 4'b0;
         else if (new_data_pulse) reg_strategic_status <= data;
    end

    // --- 3. Water Level Sensor A ---
    /**
     * @brief 3. Estabilizador do Sensor de Nível A
     * @details Filtra o ruído do sensor mecânico A.
     */
    water_level #(
        .CLK_FREQ(25_000_000),
        .STABLE_MS(20)
    ) inst_water_level_a (
        .clk(clk),
        .reset(internal_reset),
        .signal_async(level_sensor_a),
        .signal_stable(level_a_is_full)
    );

    // --- 4. Water Level Sensor B ---
    /**
     * @brief 4. Estabilizador do Sensor de Nível B
     * @details Filtra o ruído do sensor mecânico B.
     */
    water_level #(
        .CLK_FREQ(25_000_000),
        .STABLE_MS(20)
    ) inst_water_level_b (
        .clk(clk),
        .reset(internal_reset),
        .signal_async(level_sensor_b),
        .signal_stable(level_b_is_empty)
    );

    // --- 5. Filter Control FSM ---
    /**
     * @brief 5. FSM de Controle da Filtragem
     * @details O cérebro principal do sistema, decide quando ligar
     * as bombas com base nos sensores e dados do Pico.
     */
    filter_fsm inst_filter (
        .clk(clk),
        .reset(internal_reset),
        .status_data(reg_strategic_status),
        .level_b_empty(level_b_is_empty),
        .level_a_full(level_a_is_full),
        .pwm_duty_a(pwm_duty_a),
        .pwm_duty_b(pwm_duty_b),
        .is_critical(data_is_critical)
    );

    // --- 6. PWM Generators ---
    /**
     * @brief 6. Geradores de PWM
     * @details Convertem os valores de duty cycle em sinais PWM
     * para acionar as bombas.
     */
    pwm_generator pump_a_pwm_gen (
        .clk(clk), 
        .reset(internal_reset), 
        .duty_cycle(pwm_duty_a), 
        .pwm_signal(pwm_pump_a)
    );
    
    pwm_generator pump_b_pwm_gen (
        .clk(clk), 
        .reset(internal_reset), 
        .duty_cycle(pwm_duty_b), 
        .pwm_signal(pwm_pump_b)
    );

    // --- 7. LED Connection and Alive---
    /**
     * @brief 7. Lógica de LED e Sinal 'Alive'
     * @details Gera um sinal 'alive' (baseado no reset) e um
     * LED piscante (a ~500ms) quando não está em reset.
     */
    localparam BLINK_COUNT_MAX = 24'd12_499_999; // (25MHz / 2) - 1 for 500ms
    logic [23:0] blink_count = '0;
    logic blink_toggle = 1'b0;

    always_ff @(posedge clk) begin
        if (reset == 1'b0) begin
            if (blink_count == BLINK_COUNT_MAX) begin
                blink_count <= '0;
                blink_toggle <= ~blink_toggle;
            end else begin
                blink_count <= blink_count + 1;
            end
        end else begin
            blink_count <= '0;
            blink_toggle <= 1'b0;
        end
    end

    // LED fica aceso durante o reset, pisca caso contrário
    assign led_connection = (reset == 1'b1) ? 1'b1 : blink_toggle;
    // Sinal 'alive' está alto enquanto o FPGA estiver fora de reset
    assign alive = ~reset;

endmodule