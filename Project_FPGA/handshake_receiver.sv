/**
 * @file handshake_receiver.sv
 * @brief Módulo receptor com protocolo de handshake assíncrono.
 */
module handshake_receiver #(
    parameter int DATA_WIDTH = 8
) (
    input wire clk_fpga, input wire reset,
    input wire [DATA_WIDTH-1:0] i_dados, input wire i_req,
    output logic o_ack,
    output logic [DATA_WIDTH-1:0] o_dados_validos,
    output logic o_novo_dado_pronto
);
    logic req_sync1, req_sync2;
    always_ff @(posedge clk_fpga or posedge reset) begin
        if (reset) {req_sync1, req_sync2} <= 2'b0;
        else       {req_sync1, req_sync2} <= {i_req, req_sync1};
    end

    typedef enum logic [1:0] {IDLE, LATCH_DATA, WAIT_REQ_LOW} state_t;
    state_t estado_atual, proximo_estado;

    always_comb begin
        proximo_estado = estado_atual;
        case (estado_atual)
            IDLE:         if (req_sync2) proximo_estado = LATCH_DATA;
            LATCH_DATA:   proximo_estado = WAIT_REQ_LOW;
            WAIT_REQ_LOW: if (!req_sync2) proximo_estado = IDLE;
        endcase
    end

    always_ff @(posedge clk_fpga or posedge reset) begin
        if (reset) begin
            estado_atual     <= IDLE;
            o_ack            <= 1'b0;
            o_dados_validos  <= '0;
            o_novo_dado_pronto <= 1'b0;
        end else begin
            // Atualiza o estado no ciclo de clock
            estado_atual <= proximo_estado;

            // Lógica de saída baseada na transição de estado
            // O pulso o_novo_dado_pronto é gerado na transição de IDLE para LATCH_DATA
            o_novo_dado_pronto <= 1'b0; // Padrão é não ter novo dado

            case (proximo_estado)
                LATCH_DATA:
                    if (estado_atual == IDLE) begin // A transição acabou de acontecer
                        o_dados_validos    <= i_dados;
                        o_ack              <= 1'b1;
                        o_novo_dado_pronto <= 1'b1;
                    end
                IDLE: o_ack <= 1'b0; // Baixa o ack ao retornar para IDLE
            endcase
        end
    end
endmodule