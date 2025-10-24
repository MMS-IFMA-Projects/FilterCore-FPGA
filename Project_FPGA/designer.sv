/**
 * @file designer.sv
 * @brief Top-level module that implements the filtration control logic.
 */

 
module designer (
    // Clock and Reset
    input wire clk,
    input wire rst_n, // Active-low reset

    // Interface with Pico
    input wire [3:0] pico_data_in,
    input wire pico_req_in,
    output logic pico_ack_out,

    // Float Sensor Interface
    input wire float_full_in,
    input wire float_empty_in,

    // Pump PWM Outputs
    output logic pump_a_pwm_out,
    output logic pump_b_pwm_out,
    output logic comm_error_led_out // Optional: for the invalid data pulse
);
    typedef enum logic [1:0] {IDLE, FILLING, RETURNING, DRAINING} state_t;

    // Signals from the handshake_receiver
    logic [3:0] received_data;
    logic       new_data_received;
    logic       invalid_data_received;

    // Instantiate the communication module
    handshake_receiver #( .DATA_WIDTH(4) ) comm_inst (
        .clk(clk), 
        .rst_n(rst_n),
        .data_in(pico_data_in), 
        .req_in(pico_req_in), 
        .ack_out(pico_ack_out),
        .data_out(received_data), 
        .new_data_pulse(new_data_received),
        .invalid_data_pulse(invalid_data_received)
    );

    logic [3:0] strategic_status_reg = 4'b0;
    logic float_full_sync, float_empty_sync;
    state_t current_state, next_state;

    // Synchronize asynchronous float sensor inputs
    always_ff @(posedge clk) begin
        float_full_sync  <= float_full_in;
        float_empty_sync <= float_empty_in;
    end

    always_comb begin
        next_state = current_state;
        // Main transition logic based on received status OR float sensors
        case (current_state)
            IDLE:
                // If any status bit is '1' (anomaly or button), start the cycle
                if (|strategic_status_reg) next_state = FILLING;
            FILLING:
                if (float_full_sync) next_state = RETURNING;
            RETURNING:
                // If water quality returns to normal (all status bits = 0), stop.
                if (&(~strategic_status_reg)) next_state = DRAINING;
                // Otherwise, if the filter empties, continue the cycle
                else if (float_empty_sync) next_state = FILLING;
            DRAINING:
                if (float_empty_sync) next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            strategic_status_reg <= 4'b0;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Data capture logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            strategic_status_reg <= 4'b0;
        end else if (new_data_received) begin
            strategic_status_reg <= received_data;
        end
    end

    assign comm_error_led_out = invalid_data_received;

    logic [7:0] pump_a_duty_cycle, pump_b_duty_cycle;
    localparam PWM_HIGH_DUTY = 8'd230; // 90%

    always_comb begin
        pump_a_duty_cycle = 8'h00; pump_b_duty_cycle = 8'h00; // Default off
        case (current_state)
            FILLING:   pump_a_duty_cycle = PWM_HIGH_DUTY;
            RETURNING: pump_b_duty_cycle = PWM_HIGH_DUTY;
            DRAINING:  pump_b_duty_cycle = PWM_HIGH_DUTY; // Continues draining to stop
        endcase
    end

    pwm_generator pump_a_pwm_gen (.clk(clk), .rst_n(rst_n), .duty_cycle_val(pump_a_duty_cycle), .pwm_signal(pump_a_pwm_out));
    pwm_generator pump_b_pwm_gen (.clk(clk), .rst_n(rst_n), .duty_cycle_val(pump_b_duty_cycle), .pwm_signal(pump_b_pwm_out));

endmodule