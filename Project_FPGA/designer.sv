/**
 * @file designer.sv
 * @brief Top-level module that instantiates and connects all sub-modules.
 */
module designer (
    // Clock and Reset
    input wire clk,
    input wire reset, // Active-high reset

    // Interface with Pico
    input wire [3:0] data_in, 
    input wire req_in, 
    output logic ack_out,

    // Float Sensor Interface
    input wire level_sensor_in, // '1' = EMPTY, '0' = WET

    // Pump PWM Outputs
    output logic pwm_pump_a_out,
    output logic pwm_pump_b_out
);

    // --- Wires to connect modules ---
    logic [3:0] valid_data_from_comm;
    logic       new_data_pulse;
    logic       invalid_data_pulse;
    logic       level_is_empty; // From debouncer
    logic       level_is_full;  // Inverted from debouncer
    logic [7:0] w_pwm_duty_a;
    logic [7:0] w_pwm_duty_b;
    logic [3:0] strategic_status_reg;

    // --- 1. Handshake Receiver ---
    // Manages REQ/ACK, validates data, and provides a pulse when new data arrives.
    handshake_receiver #( .DATA_WIDTH(4) ) comm_inst (
        .clk(clk), 
        .reset(reset),
        .data_in(data_in), 
        .req_in(req_in), 
        .ack_out(ack_out),
        .data_out(valid_data_from_comm), 
        .new_data_pulse(new_data_pulse),
        .invalid_data_pulse(invalid_data_pulse)
    );

    // --- 2. Data Latch ---
    // Uses the pulse from the handshake to latch the validated input data.
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            strategic_status_reg <= 4'b0;
        end else if (new_data_pulse) begin
            strategic_status_reg <= valid_data_from_comm;
        end
    end

    // --- 3. Sensor Debouncer (or simple synchronizer) ---
    // Cleans the mechanical sensor signal. '1' means stable and empty.
    // For now, we use a simple synchronizer. A full debouncer module is recommended.
    always_ff @(posedge clk) level_is_empty <= level_sensor_in;
    assign level_is_full = ~level_is_empty;

    // --- 4. Filter Control FSM ---
    // The main brain of the system.
    // (This logic would be moved to a separate 'filter_fsm.sv' module)
    filter_fsm fsm_inst (
        .clk(clk),
        .reset(reset),
        .status_data(strategic_status_reg),
        .is_full(level_is_full),
        .is_empty(level_is_empty),
        .pump_a_duty_cycle(w_pwm_duty_a),
        .pump_b_duty_cycle(w_pwm_duty_b)
    );

    // --- 5. PWM Generators ---
    // Convert the duty cycle values from the FSM into PWM signals.
    pwm_generator pump_a_pwm_gen (
        .clk(clk), .reset(reset), 
        .duty_cycle_val(w_pwm_duty_a), .pwm_signal(pwm_pump_a_out)
    );
    
    pwm_generator pump_b_pwm_gen (
        .clk(clk), .reset(reset), 
        .duty_cycle_val(w_pwm_duty_b), .pwm_signal(pwm_pump_b_out)
    );

endmodule

// NOTE: This refactoring implies the creation of two new files:
// 1. 'filter_fsm.sv' to contain the main state machine logic.
// 2. 'debouncer.sv' if a more robust sensor input is desired.