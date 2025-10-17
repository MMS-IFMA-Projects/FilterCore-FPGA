/**
 * @file pwm_generator.sv
 * @brief Módulo gerador de PWM (Pulse Width Modulation).
 *
 * Gera um sinal de saída com um ciclo de trabalho (duty cycle)
 * definido pelo valor de entrada `i_duty_cycle`.
 */
module pwm_generator #(
    parameter int WIDTH = 8
) (
    input  wire             clk_fpga,
    input  wire             reset,
    input  wire [WIDTH-1:0] i_duty_cycle,
    output logic            o_pwm_out
);
    logic [WIDTH-1:0] counter;

    always_ff @(posedge clk_fpga or posedge reset) begin
        if (reset) begin
            counter   <= '0;
            o_pwm_out <= 1'b0;
        end else begin
            counter <= counter + 1; // O contador incrementa a cada ciclo de clock
            // A saída é alta enquanto o contador for menor que o duty cycle
            o_pwm_out <= (counter < i_duty_cycle);
        end
    end
endmodule