/**
 * @file tb_designer.sv
 * @brief Testbench for the 'designer' module.
 */
 `timescale 1ns / 1ps
module tb_designer;

    // --- Parameters ---
    localparam CLK_PERIOD = 20ns; // 50 MHz clock

    // --- Signals to connect to DUT ---
    logic clk;
    logic rst_n;
    logic [3:0] pico_data;
    logic       pico_req;
    logic       pico_ack;
    logic       float_full;
    logic       float_empty;
    logic       pump_a_pwm;
    logic       pump_b_pwm;
    logic       comm_error_led;

    // --- DUT Instantiation ---
    designer DUT (
        .clk(clk),
        .rst_n(rst_n),
        .pico_data_in(pico_data),
        .pico_req_in(pico_req),
        .pico_ack_out(pico_ack),
        .float_full_in(float_full),
        .float_empty_in(float_empty),
        .pump_a_pwm_out(pump_a_pwm),
        .pump_b_pwm_out(pump_b_pwm),
        .comm_error_led_out(comm_error_led)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // --- Task to simulate Pico transmission ---
    task transmit_handshake(input [3:0] data_to_send);
        @(posedge clk);
        pico_req <= 1'b1; pico_data <= data_to_send;
        wait (pico_ack == 1'b1);
        @(posedge clk);
        pico_req <= 1'b0;
        wait (pico_ack == 1'b0);
        @(posedge clk);
        $display("[%0t ns] TB: Pico sent status %b.", $time, data_to_send);
    endtask

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("onda.vcd"); 
        $dumpvars(0, tb_designer); 
        
        // Initialize signals and apply reset
        pico_req = 0; pico_data = '0;
        float_full = 0; float_empty = 1; // Start with filter empty
        rst_n = 1'b0;
        #(CLK_PERIOD * 5);
        rst_n = 1'b1;
        $display("[%0t ns] TB: System reset released.", $time);

        // --- Test Case 1: Invalid data ---
        $display("[%0t ns] TB_INFO: Sending invalid data '1111'.", $time);
        transmit_handshake(4'b1111);
        #(CLK_PERIOD * 10);

        // --- Test Case 2: Anomalous water starts the cycle ---
        $display("[%0t ns] TB_INFO: Water quality is bad (pH anomaly). Starting cycle.", $time);
        transmit_handshake(4'b0100); // pH está ruim

        // Wait for the filter to fill
        #(CLK_PERIOD * 200);
        float_full = 1'b1;
        $display("[%0t ns] TB_SENSOR: Float sensor FULL activated.", $time);
        
        // Wait in RETURNING state, then simulate water quality is OK
        #(CLK_PERIOD * 200);
        $display("[%0t ns] TB_INFO: Water quality is now OK. Stopping cycle.", $time);
        transmit_handshake(4'b0000); // Todos os sensores OK
        
        // Wait for the filter to drain
        #(CLK_PERIOD * 200);
        float_empty = 1'b1;
        $display("[%0t ns] TB_SENSOR: Float sensor EMPTY activated. Cycle finished.", $time);

        #(CLK_PERIOD * 50);
        $display("[%0t ns] SIMULATION: Test finished.", $time);
        $finish;
    end
endmodule