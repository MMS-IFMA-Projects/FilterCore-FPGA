/**
 * @file handshake_receiver.sv
 * @brief Asynchronous handshake receiver module.
 */
module handshake_receiver #(
    parameter int DATA_WIDTH = 4
) (
    input  wire clk,
    input  wire rst_n, // Active-low reset
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire req_in,
    output logic ack_out,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic new_data_pulse,
    output logic invalid_data_pulse
);
    logic req_sync1, req_sync2;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) {req_sync1, req_sync2} <= 2'b0;
        else        {req_sync1, req_sync2} <= {req_in, req_sync1};
    end

    // Validation function: checks if the data is "useful and safe".
    // Example: '1111' is considered a forbidden/invalid state.
    function automatic bit is_data_valid(input [DATA_WIDTH-1:0] data);
        return (data != '1); // Returns '0' if all bits are '1', otherwise '1'.
    endfunction

    typedef enum logic [1:0] {IDLE, LATCH_DATA, WAIT_REQ_LOW} state_t;
    state_t current_state, next_state;

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:         if (req_sync2) next_state = LATCH_DATA;
            LATCH_DATA:   next_state = WAIT_REQ_LOW;
            WAIT_REQ_LOW: if (!req_sync2) next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state      <= IDLE;
            ack_out            <= 1'b0;
            data_out           <= '0;
            new_data_pulse     <= 1'b0;
            invalid_data_pulse <= 1'b0;
        end else begin
            current_state <= next_state;

            // On the transition to capture data...
            if ((current_state == IDLE) && (next_state == LATCH_DATA)) begin
                ack_out <= 1'b1; // Raise ACK to confirm reception
                if (is_data_valid(data_in)) begin
                    data_out           <= data_in; // Capture the valid data
                    new_data_pulse     <= 1'b1;    // Pulse to signal "new valid data"
                    invalid_data_pulse <= 1'b0;
                end else begin
                    // Data is invalid, do not propagate it and signal the error.
                    new_data_pulse     <= 1'b0;
                    invalid_data_pulse <= 1'b1;    // Pulse to signal "invalid data"
                end
            end else if ((current_state == WAIT_REQ_LOW) && (next_state == IDLE)) begin
                ack_out            <= 1'b0;    // Lower ACK
                new_data_pulse     <= 1'b0;    // Ensure both pulses are terminated
                invalid_data_pulse <= 1'b0;
            end
        end
    end
endmodule