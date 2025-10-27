`timescale 1ns / 1ps
module tb_design;

    // --- Simulation Parameters ---
    localparam CLK_PERIOD = 20ns; // 50 MHz
    
    // Short timers for fast simulation
    localparam SIM_FILL_TIME_CYCLES = 500; // 500 cycles
    localparam SIM_PUMP_B_TIMER_CYCLES = 200; // 200 cycles
    localparam SIM_DEBOUNCE_CLK_FREQ = 5000; 

    // --- Signals ---
    logic clk;
    logic reset;
    logic [3:0] data;
    logic       req;
    logic       ack;
    logic       level_sensor; // '1' = EMPTY, '0' = WET
    logic       pump_a_pwm;
    logic       pump_b_pwm;

    // --- DUT Instantiation ---
    filter_core_design DUT (
        .clk(clk),
        .reset(reset),
        .data(data),
        .req(req),
        .ack(ack),
        .level_sensor(level_sensor),
        .pwm_pump_a(pump_a_pwm),
        .pwm_pump_b(pump_b_pwm)
    );

    // --- Override FSM parameters for fast simulation ---
    defparam DUT.inst_filter.PUMP_A_FILL_TIME_CYCLES = SIM_FILL_TIME_CYCLES;
    defparam DUT.inst_filter.PUMP_B_TIMER_CYCLES = SIM_PUMP_B_TIMER_CYCLES;
    defparam DUT.inst_water_level.CLK_FREQ = SIM_DEBOUNCE_CLK_FREQ;

    // --- Clock Generation ---
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // --- Handshake Task (Success) ---
    task transmit_handshake(input [3:0] data_to_send);
        @(posedge clk);
        req <= 1'b1;
        data <= data_to_send;
        wait (ack == 1'b1);
        @(posedge clk);
        req <= 1'b0;
        wait (ack == 1'b0);
        @(posedge clk);
        $display("[%0t ns] TB_SUCCESS: Pico sent status %b.", $time, data_to_send);
    endtask
    
    // --- Handshake Task (Failure) ---
    task transmit_corrupt_handshake;
        logic timeout;
        timeout = 0;
        @(posedge clk);
        req <= 1'b1;
        data <= 4'bxxxx; // Send corrupt data (X)
        
        fork
            begin @(posedge ack); end
            begin #(CLK_PERIOD * 10) timeout = 1; end
        join_any
        
        if (ack == 1'b1) $error("TB_FAIL: ACK received for corrupt data!");
        else if (timeout) $display("[%0t ns] TB_SUCCESS: ACK correctly NOT received for corrupt data.", $time);
        
        req <= 1'b0;
        @(posedge clk);
    endtask

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("design.vcd");
        $dumpvars(0, tb_design);
        
        // 1. Initialize and Reset
        req = 0; data = '0; level_sensor = 1; // Start EMPTY
        reset = 1'b1;
        #(CLK_PERIOD * 5);
        reset = 1'b0;
        $display("[%0t ns] TB: System reset released. (State: STOP)", $time);

        // --- 2. Test Failed Handshake ---
        $display("[%0t ns] TB: Testing FAILED handshake (sending X)...", $time);
        transmit_corrupt_handshake();
        if (pump_a_pwm || pump_b_pwm) $error("TB_FAIL: Pumps activated on corrupt data!");

        #(CLK_PERIOD * 50);

        // --- 3. Test Success & Pump Execution ---
        $display("[%0t ns] TB: Testing SUCCESSFUL handshake (sending 0100)...", $time);
        transmit_handshake(4'b0100); // Water is critical
        
        #(CLK_PERIOD * 5);
        if (!pump_a_pwm) $error("TB_FAIL: Pump A did not start! (State: FILLING)");
        else $display("[%0t ns] TB_CHECK: Pump A is ON. (State: FILLING)", $time);

        // Simulate sensor getting WET
        #(CLK_PERIOD * 100);
        level_sensor = 0; // Sensor is WET
        $display("[%0t ns] TB_SENSOR: Level sensor WET (level > 5cm).", $time);
        
        // Wait for Fill Timer (500) to expire
        // O debouncer (100) deve disparar antes do timer (500)
        #(CLK_PERIOD * (SIM_FILL_TIME_CYCLES - 100 + 10)); // Wait remaining time
        
        if (pump_a_pwm) $error("TB_FAIL: Pump A did not stop after fill timer!");
        if (!pump_b_pwm) $error("TB_FAIL: Pump B (MIN) did not start!");
        else $display("[%0t ns] TB_CHECK: Pump A OFF, Pump B (MIN) is ON. (State: DRAINING_MIN)", $time);

        // Wait for Pump B Timer (200) to expire
        #(CLK_PERIOD * (SIM_PUMP_B_TIMER_CYCLES + 10));
        $display("[%0t ns] TB_CHECK: Pump B Timer expired. (State: DRAINING_MAX)", $time);
        if (!pump_b_pwm) $error("TB_FAIL: Pump B (MAX) did not stay on!");
        
        #(CLK_PERIOD * 100);
        
        // --- 4. Test Pump Stop ---
        $display("[%0t ns] TB: Testing STOP sequence (sending 0000)...", $time);
        transmit_handshake(4'b0000); // Water is OK

        #(CLK_PERIOD * 5);
        if (pump_a_pwm) $error("TB_FAIL: Pump A turned on during STOPPING!");
        if (!pump_b_pwm) $error("TB_FAIL: Pump B (MAX) did not stay on for STOPPING!");
        else $display("[%0t ns] TB_CHECK: Pump A OFF, Pump B (MAX) is ON. (State: STOPPING)", $time);
        
        // Simulate filter draining
        #(CLK_PERIOD * 100);
        level_sensor = 1; // Sensor is EMPTY
        $display("[%0t ns] TB_SENSOR: Filter is now EMPTY.", $time);
        
        #(CLK_PERIOD * (100 + 10));
        
        if (pump_a_pwm || pump_b_pwm) $error("TB_FAIL: Pumps did not turn OFF. (State: STOP)");
        else $display("[%0t ns] TB_CHECK: All pumps OFF. (State: STOP)", $time);

        #(CLK_PERIOD * 50);
        $display("[%0t ns] SIMULATION: All tests passed.", $time);
        $finish;
    end
endmodule