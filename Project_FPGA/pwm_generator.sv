/**
 * @file pwm_generator.sv
 * @brief Module that generates a PWM waveform.
 */
module pwm_generator #(
    parameter int WIDTH = 8
) (
    input wire clk, // Renamed for consistency
    input wire reset, // Active-high reset
    input wire [WIDTH-1:0] duty_cycle_val,
    output logic pwm_signal
);
    logic [WIDTH-1:0] pwm_counter = '0;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pwm_counter <= '0;
        end else begin
            pwm_counter <= pwm_counter + 1;
        end
    end

    assign pwm_signal = (pwm_counter < duty_cycle_val);
endmodule