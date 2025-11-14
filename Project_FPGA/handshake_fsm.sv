/**
 * @brief FSM para o protocolo de handshake REQ/ACK.
 * @details Recebe um sinal 'req' e 'data' de um mestre (Pico).
 * Valida os dados, gera 'ack' em resposta, e
 * gera um pulso ('new_data_pulse') para
 * sinalizar a captura de novos dados.
 *
 * @param DATA_WIDTH Largura do barramento de dados.
 */
module handshake_fsm #(
    parameter int DATA_WIDTH = 4
) (
    input  wire clk,                    // Clock do sistema
    input  wire reset,                  // Reset síncrono (ativo alto)

    // Pico input signals
    input wire [DATA_WIDTH-1:0] data,   // Barramento de dados vindo do Pico
    input  wire req,                    // Sinal de Requisição (ativo alto)

    // Outputs for the protocol
    output logic ack,                   // Sinal de Reconhecimento (ativo alto)
    output logic new_data_pulse         // Pulso de 1 ciclo indicando novos dados
);

    // --- 2-pulse synchronisation ---
    // Sincronizador de 2 pulsos para o sinal 'req' assíncrono
    logic req_sync1, req_sync2;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) {req_sync1, req_sync2} <= 2'b0;
        else        {req_sync1, req_sync2} <= {req, req_sync1};
    end

    // --- FSM States ---
    /**
     * @brief Definição dos estados da FSM de Handshake. 
     */
    typedef enum logic [1:0] {
        IDLE,           // 0: Aguardando 'req' ir para alto
        LATCH_DATA,     // 1: 'req' detectado, trava dados, levanta 'ack'
        WAIT_REQ_LOW    // 2: Aguardando 'req' ir para baixo
    } state_t;

    state_t current_state, next_state;

    // --- Data verification ---
    // Verificação de corrupção de dados (X/Z)
    logic data_is_corrupt;
    always_comb begin
        data_is_corrupt = $isunknown(data);
    end

    // --- FSM State Transition Logic ---
    // Lógica de transição de estados
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:         if (req_sync2 && !data_is_corrupt) next_state = LATCH_DATA;
            LATCH_DATA:   next_state = WAIT_REQ_LOW;
            WAIT_REQ_LOW: if (!req_sync2) next_state = IDLE;
            default:      next_state = IDLE;
        endcase
    end

    // --- FSM State Register ---
    // Registrador de estado e lógica de saída
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state  <= IDLE;
            ack            <= 1'b0;
            new_data_pulse <= 1'b0;
        end else begin
            current_state <= next_state;

            // One clock cycle pulse when REQ is detected
            new_data_pulse <= (current_state == IDLE) && (next_state == LATCH_DATA);

            // ACK signal management
            if((current_state == IDLE) && (next_state == LATCH_DATA)) ack <= 1'b1;
            else if((current_state == WAIT_REQ_LOW) && (next_state == IDLE)) ack <= 1'b0;
        end
    end
endmodule