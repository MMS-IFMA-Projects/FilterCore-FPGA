/**
 * @brief Máquina de estados finitos (FSM) para o controle da filtragem.
 * @details Gerencia a lógica de enchimento e drenagem dos tanques
 * controlando duas bombas (A e B) com base nos níveis
 * dos sensores e no status de criticidade do sistema.
 *
 * @param PUMP_B_TIMER_CYCLES Duração (em ciclos de clock) que a bomba B
 * opera no modo 'DRAINING_MIN' antes de
 * passar para 'DRAINING_MAX'.
 */
module filter_fsm #(
    parameter int PUMP_B_TIMER_CYCLES = 250_000_000 // 5 seconds @ 50 MHz
) (
    input wire clk,                 // Clock do sistema
    input wire reset,               // Reset síncrono (ativo alto)

    // Input from other modules
    input wire [3:0] status_data,   // Dados de status (criticidade) vindos do Pico
    input wire level_b_empty,       // Sensor de nível B (1 = Vazio)
    input wire level_a_full,        // Sensor de nível A (1 = Não cheio)
    
    // Output to PWM generator
    output logic [7:0] pwm_duty_a,  // Ciclo de trabalho para a Bomba A
    output logic [7:0] pwm_duty_b,  // Ciclo de trabalho para a Bomba B

    output logic is_critical        // Flag (1 bit) indicando criticidade
);

    // --- Parameters ---
    localparam PWM_MAX = 8'd230;    // Valor de duty cycle para potência máxima
    localparam PWM_MIN = 8'd77;     // Valor de duty cycle para potência mínima


    // --- FSM States ---
    /**
     * @brief Definição dos estados da FSM de controle.
     */
    typedef enum logic [2:0] {
        STOP,           // 0: Ambas as bombas paradas
        FILLING,        // 1: Enchendo tanque A, esvaziando B (se não vazio)
        DRAINING_MIN,   // 2: Drenando B com potência mínima (modo timer)
        DRAINING_MAX,   // 3: Drenando B com potência máxima (timer expirou)
        STOPPING        // 4: Esvaziando B antes de parar totalmente
    } state_t;

    state_t current_state, next_state;

    // --- Timers ---
    logic [27:0] timer_pump_b;  // Contador para o estado DRAINING_MIN
    logic pump_b_timer_expired; // Flag de expiração do timer

    // --- System criticality variable ---
    // O sistema é considerado crítico se qualquer bit de status estiver ativo
    assign is_critical = (|status_data);

    // --- Pump B Timer (Min/Max Timer) ---
    /**
     * @brief Temporizador para a Bomba B (estados de drenagem).
     * @details Conta apenas durante o estado DRAINING_MIN.
     */
    always_ff @(posedge clk or posedge reset) begin
        if (reset) timer_pump_b <= '0;
        else if (current_state == DRAINING_MIN) begin
            if(!pump_b_timer_expired) timer_pump_b <= timer_pump_b + 1;
        end
        else timer_pump_b <= '0;
    end

    // Sinal de expiração do temporizador
    assign pump_b_timer_expired = (timer_pump_b >= PUMP_B_TIMER_CYCLES);

    // --- FSM State Transition Logic ---
    /**
     * @brief Lógica de transição de estados (Combinacional). 
     */
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
    /**
     * @brief Lógica de saída (Controle das Bombas).
     */
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
    /**
     * @brief Registrador de estado (Sequencial).
     */
    always_ff @(posedge clk or posedge reset) begin
        if (reset) current_state <= STOP;
        else current_state <= next_state;
    end
endmodule