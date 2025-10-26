module water_level #(
    parameter int CLK_FREQ = 50_000_000, //50MHz Clock
    parameter int STABLE_MS = 20        //20ms Stable Time
) (
    input wire clk,
    input wire  reset,
    input wire signal_async,
    output logic signal_stable
);
    // --- Parameters ---
    localparam int COUNTER_LIMIT = (CLK_FREQ / 1000) * STABLE_MS;
    
    // --- Counting and validation ---
    logic [19:0] counter = '0;
    logic signal_sync;

    // --- 2-stage synchronizer ---
    always_ff @(posedge clk) begin
        signal_sync <= signal_async;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            signal_stable <= 1'b1; // Default to 'empty'
            counter <= '0;
        end
        else begin
            if (signal_sync != signal_stable) begin
                if(counter < COUNTER_LIMIT) counter <= counter + 1;
                else begin
                    signal_stable <= signal_sync;
                    counter <= '0;
                end
            end
            else counter <= '0;
        end
    end
endmodule