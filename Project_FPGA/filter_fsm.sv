module filter_fsm #(
    parameter int PUMP_B_TIMER_CYCLES = 250_000_000 // 5 seconds @ 50 MHz
) (
    input wire clk,
    input wire reset,

    // Input from other modules
    input wire [3:0] status_data,
    input wire level_b_empty,
    input wire level_a_full,
    
    // Output to PWM generator
    output logic [7:0] pwm_duty_a,
    output logic [7:0] pwm_duty_b
);

    // --- Parameters ---
    localparam PWM_MAX = 8'd230;
    localparam PWM_MIN = 8'd77;

    // --- FSM States ---
    typedef enum logic [2:0] {
        STOP,
        FILLING,
        DRAINING_MIN,
        DRAINING_MAX,
        STOPPING
    } state_t;

    state_t current_state, next_state;

    // --- Timers ---
    logic [27:0] timer_pump_b;
    logic pump_b_timer_expired;

    // --- System criticality variable ---
    wire is_critical;
    assign is_critical = (|status_data);

    // --- Pump B Timer (Min/Max Timer) ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) timer_pump_b <= '0;
        else if (current_state == DRAINING_MIN) begin
            if(!pump_b_timer_expired) timer_pump_b <= timer_pump_b + 1;
        end
        else timer_pump_b <= '0;
    end

    assign pump_b_timer_expired = (timer_pump_b >= PUMP_B_TIMER_CYCLES);

    // --- FSM State Transition Logic ---
    always_comb begin
        next_state = current_state;

        case (current_state)
            STOP:
                if (is_critical) next_state = FILLING;
            FILLING:
                if(!is_critical) next_state = STOPPING;
                else if (!level_a_full) next_state = DRAINING_MIN;
            DRAINING_MIN:
                if (!is_critical) next_state = STOPPING;
                else if (level_b_empty && is_critical) next_state = FILLING;
                else if (pump_b_timer_expired) next_state = DRAINING_MAX;
            DRAINING_MAX:
                if (!is_critical) next_state = STOPPING;
                else if (level_b_empty && is_critical) next_state = FILLING;
            STOPPING:
                if (level_b_empty) next_state = STOP;
            default:
                next_state = STOP;
        endcase
    end

    // --- FSM Output (Pump Control) ---
    always_comb begin
        pwm_duty_a = 8'h00;
        pwm_duty_b = 8'h00;

        case (current_state)
            FILLING: begin
                pwm_duty_a = PWM_MAX;
                if(!level_b_empty) pwm_duty_b = PWM_MAX;
            end
            DRAINING_MIN: begin
                pwm_duty_b = PWM_MIN;
            end
            DRAINING_MAX: begin
                pwm_duty_b = PWM_MAX;
            end
            STOPPING: begin
                if(!level_b_empty) pwm_duty_b = PWM_MAX;
            end
            default: begin
                pwm_duty_a = 8'h00;
                pwm_duty_b = 8'h00;
            end
        endcase
    end

    // --- FSM State Register ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) current_state <= STOP;
        else current_state <= next_state;
    end
endmodule