/**
 * @file handshake_fsm.sv
 * @brief Asynchronous handshake receiver module.
 */
module handshake_fsm #(
    parameter int DATA_WIDTH = 4
) (
    input  wire clk,
    input  wire reset,

    // Pico input signals
    input wire [DATA_WIDTH-1:0] data,
    input  wire req,

    // Outputs for the protocol
    output logic ack,
    output logic new_data_pulse,
);

    // --- 2-pulse synchronisation ---
    logic req_sync1, req_sync2;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) {req_sync1, req_sync2} <= 2'b0;
        else        {req_sync1, req_sync2} <= {req, req_sync1};
    end

    // --- FSM States ---
    typedef enum logic [1:0] {
        IDLE, 
        LATCH_DATA, 
        WAIT_REQ_LOW
    } state_t;

    state_t current_state, next_state;

    // --- Data verification ---
    logic data_is_corrupt;
    always_comb begin
        data_is_corrupt = $isunknown(data)
    end

    // --- FSM State Transition Logic ---
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