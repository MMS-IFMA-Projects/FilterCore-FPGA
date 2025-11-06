`timescale 1ns / 1ps
module tb_design;

    // --- Simulation Parameters ---
    localparam CLK_PERIOD = 20ns; // 50 MHz clock
    // Shortened timers for faster simulation
    localparam SIM_PUMP_B_TIMER_CYCLES = 500; 
    localparam SIM_DEBOUNCE_CLK_FREQ = 2000; 

    // --- Signals ---
    logic clk;
    logic reset;
    logic [3:0] data;
    logic       req;
    logic       ack;
    
    // Sensors: '1' = DRY (Open/Pull-Up), '0' = WET (Closed to GND)
    logic       level_sensor_a; // Top Sensor (Full detection)
    logic       level_sensor_b; // Bottom Sensor (Empty detection)
    
    logic       pump_a_pwm;
    logic       pump_b_pwm;

    // --- DUT (Device Under Test) Instantiation ---
    filter_core_design DUT (
        .clk(clk),
        .reset(reset),
        .data(data),
        .req(req),
        .ack(ack),
        .level_sensor_a(level_sensor_a),
        .level_sensor_b(level_sensor_b),
        .pwm_pump_a(pump_a_pwm),
        .pwm_pump_b(pump_b_pwm)
    );

    // --- Parameter Overrides for Simulation ---
    defparam DUT.inst_filter.PUMP_B_TIMER_CYCLES = SIM_PUMP_B_TIMER_CYCLES;
    defparam DUT.inst_water_level_a.CLK_FREQ = SIM_DEBOUNCE_CLK_FREQ;
    defparam DUT.inst_water_level_b.CLK_FREQ = SIM_DEBOUNCE_CLK_FREQ;

    // --- Clock Generation ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // --- Helper Task: Wait for Debounce Time ---
    task wait_debounce;
        #(CLK_PERIOD * (SIM_DEBOUNCE_CLK_FREQ + 100));
    endtask

    // --- Helper Task: Successful Handshake ---
    task transmit_handshake(input [3:0] data_to_send);
        @(posedge clk);
        req <= 1'b1;
        data <= data_to_send;
        wait (ack == 1'b1);
        @(posedge clk);
        req <= 1'b0;
        wait (ack == 1'b0);
        @(posedge clk);
        $display("[%0t ns] HANDSHAKE: Sent successfully: %b", $time, data_to_send);
    endtask

    // --- Helper Task: Malformed/Corrupt Handshake ---
    task transmit_bad_handshake;
        @(posedge clk);
        $display("[%0t ns] HANDSHAKE: Attempting to send CORRUPT data (xxxx)...", $time);
        req <= 1'b1;
        data <= 4'bxxxx; // Sending invalid data
        repeat(50) @(posedge clk);
        if (ack) $display("[%0t ns] WARNING: DUT acknowledged corrupt data.", $time);
        else $display("[%0t ns] SUCCESS: DUT ignored corrupt data (no ACK).", $time);
        req <= 1'b0;
        @(posedge clk);
    endtask

    // ========================================================================
    // MAIN TEST SEQUENCE
    // ========================================================================
    initial begin
        $dumpfile("design.vcd");
        $dumpvars(0, tb_design);
        
        // 1. Initialization
        req = 0; data = '0;
        level_sensor_a = 1; // DRY
        level_sensor_b = 1; // DRY
        reset = 1'b1;
        #(CLK_PERIOD * 10);
        reset = 1'b0;
        $display("[%0t ns] INIT: System reset complete. State should be STOP.", $time);
        #(CLK_PERIOD * 50);

        // ============================================================
        // TEST CASE 1: Successful Full Filtering Cycle
        // ============================================================
        $display("\n--- START CASE 1: Good Signal & Full Cycle ---");
        transmit_handshake(4'b0100); // "Water Critical"
        wait_debounce();

        if (pump_a_pwm && !pump_b_pwm) 
            $display("[%0t ns] CHECK PASS: Filling started (A ON, B OFF - Dry).", $time);
        else $error("[%0t ns] CHECK FAIL: Incorrect pump state at start!", $time);

        // Simulate water reaching Bottom Sensor (B) -> Pump B starts
        #(CLK_PERIOD * 200);
        level_sensor_b = 0; // WET
        wait_debounce();
        if (pump_a_pwm && pump_b_pwm) 
            $display("[%0t ns] CHECK PASS: Simultaneous Operation (A ON, B ON).", $time);
        else $error("[%0t ns] CHECK FAIL: Simultaneous start failed!", $time);

        // Simulate water reaching Top Sensor (A) -> Pump A stops
        #(CLK_PERIOD * 400);
        level_sensor_a = 0; // WET (FULL)
        wait_debounce();
        if (!pump_a_pwm && pump_b_pwm) 
            $display("[%0t ns] CHECK PASS: Transition to Draining (A OFF, B ON).", $time);
        else $error("[%0t ns] CHECK FAIL: Draining transition failed!", $time);

        // Draining phase
        #(CLK_PERIOD * SIM_PUMP_B_TIMER_CYCLES * 2); // Wait for timer
        level_sensor_a = 1; // Top becomes DRY
        #(CLK_PERIOD * 200);
        level_sensor_b = 1; // Bottom becomes DRY (EMPTY)
        wait_debounce();

        // Cycle Restart Check (Status still 0100)
        if (pump_a_pwm) 
            $display("[%0t ns] CHECK PASS: Cycle automatically restarted.", $time);
        else $error("[%0t ns] CHECK FAIL: Cycle did not restart!", $time);

        // Clean STOP for next test
        transmit_handshake(4'b0000);
        wait_debounce();
        wait(!pump_a_pwm && !pump_b_pwm);
        $display("[%0t ns] INFO: System fully STOPPED for next test.", $time);
        #(CLK_PERIOD * 200);

        // ============================================================
        // TEST CASE 2: Bad Signal
        // ============================================================
        $display("\n--- START CASE 2: Bad Signal Ignored ---");
        transmit_bad_handshake();
        #(CLK_PERIOD * 100);
        if (!pump_a_pwm && !pump_b_pwm) 
            $display("[%0t ns] CHECK PASS: System remained STOPPED.", $time);
        else $error("[%0t ns] CHECK FAIL: Bad signal started pumps!", $time);

        // ============================================================
        // TEST CASE 3: Interrupting Active Cycle with STOP
        // ============================================================
        $display("\n--- START CASE 3: Interrupt Active Fill with STOP (0000) ---");
        // 3.1 Start filling again
        transmit_handshake(4'b0100);
        wait_debounce();
        level_sensor_b = 0; // Make B wet so both pumps run
        wait_debounce();
        if(pump_a_pwm && pump_b_pwm) $display("[%0t ns] INFO: Both pumps RUNNING (Active Fill).", $time);

        // 3.2 Send STOP (0000) immediately
        $display("[%0t ns] CMD: Sending STOP (0000) during ACTIVE FILL...", $time);
        transmit_handshake(4'b0000);
        wait_debounce(); // Allow FSM to react to new status

        // 3.3 Verify immediate stop of Pump A (filling), B continues to drain
        if(!pump_a_pwm && pump_b_pwm) 
            $display("[%0t ns] CHECK PASS: Pump A STOPPED immediately. Pump B draining (State: STOPPING).", $time);
        else $error("[%0t ns] CHECK FAIL: Immediate stop failed!", $time);

        // 3.4 Finish draining and verify complete stop
        level_sensor_b = 1; // EMPTY
        wait_debounce();
        if(!pump_a_pwm && !pump_b_pwm) 
            $display("[%0t ns] CHECK PASS: All pumps OFF after final drain.", $time);
        else $error("[%0t ns] CHECK FAIL: Pumps did not turn off finaly!", $time);

        // ============================================================
        #(CLK_PERIOD * 500);
        $display("\n[%0t ns] ALL TESTS COMPLETE.", $time);
        $finish;
    end
endmodule