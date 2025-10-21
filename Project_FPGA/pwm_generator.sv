/**
 * @file pwm_generator.sv
 * @brief Módulo que gera uma forma de onda PWM.
 */
module pwm_generator #(
    parameter int WIDTH = 8
) (
    input wire clk_fpga,
    input wire reset,
    input wire [WIDTH-1:0] i_duty_cycle,
    output logic o_pwm_out
);
    logic [WIDTH-1:0] counter = '0;

    always_ff @(posedge clk_fpga or posedge reset) begin
        if (reset) begin
            counter <= '0;
        end else begin
            counter <= counter + 1;
        end
    end

    assign o_pwm_out = (counter < i_duty_cycle);
endmodule