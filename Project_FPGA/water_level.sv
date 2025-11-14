/**
 * @brief Estabilizador de sinal para sensor de nível (Debouncer).
 * @details Sincroniza um sinal de entrada assíncrono (provavelmente
 * de um sensor mecânico/bóia) e só atualiza a saída
 * após o sinal de entrada permanecer estável por
 * um tempo definido (STABLE_MS).
 *
 * @param CLK_FREQ Frequência do clock do sistema em Hz.
 * @param STABLE_MS Tempo (em ms) que o sinal deve
 * permanecer estável.
 */
module water_level #(
    parameter int CLK_FREQ = 50_000_000, //50MHz Clock
    parameter int STABLE_MS = 20        //20ms Stable Time
) (
    input wire clk,             // Clock do sistema
    input wire  reset,          // Reset síncrono (ativo alto)
    input wire signal_async,    // Sinal de entrada assíncrono do sensor
    output logic signal_stable  // Sinal de saída estável/debounced
);
    // --- Parameters ---
    // Limite do contador calculado com base nos parâmetros
    localparam int COUNTER_LIMIT = (CLK_FREQ / 1000) * STABLE_MS;
    
    // --- Counting and validation ---
    // Contador para o tempo de estabilização
    logic [19:0] counter = '0;

    // --- 2-stage synchronizer ---
    // Sincronizador de 2 estágios para a entrada assíncrona
    logic signal_sync1, signal_sync2;
    always_ff @(posedge clk) begin
        signal_sync1 <= signal_async;
        signal_sync2 <= signal_sync1;
    end

    /**
     * @brief Lógica principal do debouncer.
     * @details Compara a entrada sincronizada (sync2) com a saída
     * estável. Se forem diferentes, inicia um contador.
     * Se o contador atingir o limite, atualiza a saída.
     */
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            signal_stable <= 1'b1; // Default to 'empty'
            counter <= '0;
        end
        else begin
            if (signal_sync2 != signal_stable) begin
                if(counter < COUNTER_LIMIT) counter <= counter + 1;
                else begin
                    signal_stable <= signal_sync2;
                    counter <= '0;
                end
            end
            else counter <= '0;
        end
    end
endmodule