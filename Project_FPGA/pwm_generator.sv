/**
 * @brief Gera um sinal PWM simples (Pulse Width Modulation).
 * @details Compara um contador de "free-running" com um valor de
 * ciclo de trabalho (duty cycle) de entrada.
 *
 * @param WIDTH A largura de bits (resolução) do contador e da entrada
 * do ciclo de trabalho.
 */
module pwm_generator #(
    parameter int WIDTH = 8
) (
    input wire clk,                     // Clock do sistema
    input wire reset,                   // Reset síncrono
    input wire [WIDTH-1:0] duty_cycle,  // Valor do ciclo de trabalho (0 a 2^WIDTH-1)
    output logic pwm_signal             // Sinal de saída PWM
);
    // Contador interno do PWM (incrementa livremente)
    logic [WIDTH-1:0] pwm_counter = '0;

    /**
     * @brief Lógica do contador (free-running).
     * Incrementa a cada ciclo de clock, zerando no reset.
     */
    always_ff @(posedge clk or posedge reset) begin
        if (reset) pwm_counter <= '0;
        else pwm_counter <= pwm_counter + 1;
    end

    // Lógica de saída: O sinal é '1' enquanto o contador for menor que o duty_cycle
    assign pwm_signal = (pwm_counter < duty_cycle);
endmodule