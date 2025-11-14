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
    logic       new_data_pulse;         // From handshake to FSM
    logic       level_b_is_empty;         // From water_level to FSM
    logic       level_a_is_full;         // From water_level to FSM
    logic [7:0] pwm_duty_a;           // From FSM to PWM_A
    logic [7:0] pwm_duty_b;           // From FSM to PWM_B
    logic [3:0] reg_strategic_status;   // Local register for status
    logic       data_is_critical;

    // --- 1. Handshake Receiver ---
    // Manages REQ/ACK, validates data, and provides a pulse when new data arrives.
    handshake_fsm #( .DATA_WIDTH(4) ) inst_handshake (
        .clk(clk), 
        .reset(internal_reset),
        .data(data), 
        .req(req), 
        .ack(ack),
        .new_data_pulse(new_data_pulse)
    );

    // --- 2. Data Latch ---
    // Uses the pulse from the handshake to latch the input data.
    always_ff @(posedge clk or posedge internal_reset) begin
        if (internal_reset) reg_strategic_status <= 4'b0;
         else if (new_data_pulse) reg_strategic_status <= data;
    end

    // --- 3. Water Level Sensor A ---
    // Cleans the mechanical sensor signal.
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
    // Cleans the mechanical sensor signal.
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
    // The main brain of the system.
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
    // Convert the duty cycle values from the FSM into PWM signals.
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

    assign led_connection = (reset == 1'b1) ? 1'b1 : blink_toggle;
    assign alive = ~reset;

endmodule