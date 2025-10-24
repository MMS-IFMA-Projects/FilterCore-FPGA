module filter(
    input wire clk,
    input wire reset,

    // Input from other modules
    input wire [3:0] status_data,
    input wire is_empty,

    // Output to PWM generator
    output logic [7:0] pwm_duty_a,
    output logic [7:0] pwm_duty_b
);

// --- Parameters ---
localparam PWM_MAX = 8'd230;
localparam PWM_MIN = 8'd77;
localparam int PUMP_B_TIMER_CYCLES = 250_000_000; // 5 seconds @ 50 MHz
localparam int PUMP_A_FILL_TIME_CYCLES 6_000_000_000; // 2 minutes @ 50 MHz

// --- FSM States ---
typedef enum logic {
    STOP,
    FILLING,
    DRAINING_MIN,
    DRAINING_MAX,
    STOPPING
} state_t;

state_t current_state, next_state;

// --- Timers ---
logic [29:0] timer_pump_a;
logic [27:0] timer_pump_b;
logic pump_a_timer_expired;
logic pump_b_timer_expired;

// --- Pump A Timer (Fill Timer) ---
always_ff @(posedge clk or posedge reset) begin
    if (reset) timer_pump_a <= '0;
    else if (current_state == FILLING) begin
        if(!pump_a_timer_expired) timer_pump_a <= timer_pump_a + 1;
        else timer_pump_a <= '0;
    end
end

assign pump_a_timer_expired = (timer_pump_a >= PUMP_A_FILL_TIME_CYCLES);

// --- Pump B Timer (Min/Max Timer) ---
always_ff @(posedge clk or posedge reset) begin
    if (reset) timer_pump_b <= '0;
    else if (current_state == DRAINING_MIN && next_state != DRAINING_MIN) timer_pump_b <= '0;
    else if (current_state == DRAINING_MIN) begin
        if(!pump_b_timer_expired) timer_pump_b <= timer_pump_b + 1;
        else timer_pump_b <= '0;
    end
end

assign pump_b_timer_expired = (timer_pump_b >= PUMP_B_TIMER_CYCLES);

// --- FSM State Transition Logic ---
always_comb begin
    next_state = current_state;
    logic is_critical = (|status_data);

    case (current_state)
        STOP:
            if (is_critical) next_state = FILLING;
        FILLING:
            if (pump_a_timer_expired) next_state = DRAINING_MIN;
        DRAINING_MIN:
            if (!is_critical) next_state = STOPPING;
            else if (pump_b_timer_expired) next_state = DRAINING_MAX;
            else if (is_empty && is_critical) next_state = FILLING;
        DRAINING_MAX:
            if (!is_critical) next_state = STOPPING;
            else if (is_empty && !is_critical) next_state = FILLING;
        STOPPING:
            if (is_empty) next_state = STOP;
        default:
            next_state = STOP;

    endcase
   
end

endmodule