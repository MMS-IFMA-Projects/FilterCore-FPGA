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
    logic reset;
    logic [3:0] data;
    logic       req;
    logic       ack;
    logic       level_sensor;
    logic       pump_a_pwm;
    logic       pump_b_pwm;

    // --- DUT Instantiation ---
    designer DUT (
        .clk(clk),
        .reset(reset),
        .data_in(data),
        .req_in(req),
        .ack_out(ack),
        .level_sensor_in(level_sensor),
        .pwm_pump_a_out(pump_a_pwm),
        .pwm_pump_b_out(pump_b_pwm)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // --- Task to simulate Pico transmission ---
    task transmit_handshake(input [3:0] data_to_send);
        @(posedge clk);
        req <= 1'b1; data <= data_to_send;
        wait (ack == 1'b1);
        @(posedge clk);
        req <= 1'b0;
        wait (ack == 1'b0);
        @(posedge clk);
        $display("[%0t ns] TB: Pico sent status %b.", $time, data_to_send);
    endtask

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("onda.vcd"); 
        $dumpvars(0, tb_designer); 
        
        // Initialize signals and apply reset
        req = 0; data = '0;
        level_sensor = 1; // Start with filter empty
        reset = 1'b1;
        #(CLK_PERIOD * 5);
        reset = 1'b0;
        $display("[%0t ns] TB: System reset released.", $time);

        // --- Test Case 2: Anomalous water starts the cycle ---
        $display("[%0t ns] TB_INFO: Water quality is bad (pH anomaly). Starting cycle.", $time);
        transmit_handshake(4'b0100); // pH está ruim

        // Wait for the filter to fill
        #(CLK_PERIOD * 200);
        level_sensor = 0; // Sensor is WET
        $display("[%0t ns] TB_SENSOR: Float sensor FULL activated.", $time);
        
        // Wait in RETURNING state, then simulate water quality is OK
        #(CLK_PERIOD * 200);
        $display("[%0t ns] TB_INFO: Water quality is now OK. Stopping cycle.", $time);
        transmit_handshake(4'b0000); // Todos os sensores OK
        
        // Wait for the filter to drain
        #(CLK_PERIOD * 200);
        level_sensor = 1; // Sensor is EMPTY
        $display("[%0t ns] TB_SENSOR: Float sensor EMPTY activated. Cycle finished.", $time);

        #(CLK_PERIOD * 50);
        $display("[%0t ns] SIMULATION: Test finished.", $time);
        $finish;
    end
endmodule