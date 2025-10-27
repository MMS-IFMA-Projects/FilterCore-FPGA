/**
 * @file design.sv
 * @brief Top-level module that instantiates and connects all sub-modules.
 */
module design (
    // Clock and Reset
    input wire clk,
    input wire reset, // Active-high reset

    // Interface with Pico
    input wire [3:0] data, 
    input wire req, 
    output logic ack,

    // Float Sensor Interface
    input wire level_sensor, // '1' = EMPTY, '0' = WET

    // Pump PWM Outputs
    output logic pwm_pump_a,
    output logic pwm_pump_b
);

    // --- Wires to connect modules ---
    logic       new_data_pulse;         // From handshake to FSM
    logic       level_is_empty;         // From water_level to FSM
    logic [7:0] pwm_duty_a;           // From FSM to PWM_A
    logic [7:0] pwm_duty_b;           // From FSM to PWM_B
    logic [3:0] reg_strategic_status;   // Local register for status

    // --- 1. Handshake Receiver ---
    // Manages REQ/ACK, validates data, and provides a pulse when new data arrives.
    handshake_receiver #( .DATA_WIDTH(4) ) inst_handshake (
        .clk(clk), 
        .reset(reset),
        .data(data), 
        .req(req), 
        .ack(ack),
        .new_data_pulse(new_data_pulse),
    );

    // --- 2. Data Latch ---
    // Uses the pulse from the handshake to latch the input data.
    always_ff @(posedge clk or posedge reset) begin
        if (reset) reg_strategic_status <= 4'b0;
         else if (new_data_pulse) reg_strategic_status <= data;
    end

    // --- 3. Water Level Sensor ---
    // Cleans the mechanical sensor signal.
    water_level #(
        .CLK_FREQ(50_000_000),
        .STABLE_MS(20)
    ) inst_water_level (
        .clk(clk),
        .reset(reset),
        .signal_async(level_sensor),
        .signal_stable(level_is_empty)
    )

    // --- 4. Filter Control FSM ---
    // The main brain of the system.
    filter_fsm fsm_inst (
        .clk(clk),
        .reset(reset),
        .status_data(reg_strategic_status),
        .is_empty(level_is_empty),
        .pwm_duty_a(pwm_duty_a),
        .pwm_duty_b(pwm_duty_b)
    );

    // --- 5. PWM Generators ---
    // Convert the duty cycle values from the FSM into PWM signals.
    pwm_generator pump_a_pwm_gen (
        .clk(clk), 
        .reset(reset), 
        .duty_cycle(pwm_duty_a), 
        .pwm_signal(pwm_pump_a)
    );
    
    pwm_generator pump_b_pwm_gen (
        .clk(clk), 
        .reset(reset), 
        .duty_cycle(pwm_duty_b), 
        .pwm_signal(pwm_pump_b)
    );

endmodule