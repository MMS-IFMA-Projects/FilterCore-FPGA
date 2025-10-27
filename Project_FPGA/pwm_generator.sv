module pwm_generator #(
    parameter int WIDTH = 8
) (
    input wire clk, 
    input wire reset, 
    input wire [WIDTH-1:0] duty_cycle,
    output logic pwm_signal
);
    logic [WIDTH-1:0] pwm_counter = '0;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) pwm_counter <= '0;
        else pwm_counter <= pwm_counter + 1;
    end

    assign pwm_signal = (pwm_counter < duty_cycle);
endmodule