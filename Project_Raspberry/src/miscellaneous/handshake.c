#include "handshake.h"
#include "notifications.h"

#define DATA_TEMPERATURE_PIN 18
#define DATA_PH_PIN 19
#define DATA_TDS_PIN 20
#define DATA_BUTTON_PIN 4
#define FPGA_RESET_PIN 16
#define FPGA_ALIVE_PIN 17

/**
 * @brief Máscara de bits para todos os pinos de GPIO de saída usados no handshake.
 */
volatile uint32_t out_mask;

/**
 * @brief Contador de timeout (em milissegundos) para as operações de handshake.
 */
volatile int timeout_ms = 0;

/**
 * @brief Realiza o setup inicial e o reset do FPGA.
 * @note Esta função inicializa os pinos de reset e 'alive' do FPGA.
 * Ela mantém o FPGA em reset (nível baixo) até que o pino 'alive' 
 * (controlado pelo FPGA) vá para nível alto, indicando que o FPGA 
 * está pronto. Após isso, libera o reset (nível alto).
 */
void reset_fpga_setup(void){
    // Initializes the check pins
    gpio_init(FPGA_RESET_PIN); gpio_set_dir(FPGA_RESET_PIN, GPIO_OUT);
    gpio_init(FPGA_ALIVE_PIN); gpio_set_dir(FPGA_ALIVE_PIN, GPIO_IN);

    while(!gpio_get(FPGA_ALIVE_PIN)){
        gpio_put(FPGA_RESET_PIN, 0);
        vTaskDelay(pdMS_TO_TICKS(100));
    }

    gpio_put(FPGA_RESET_PIN, 1);
    send_notification(INFO, "FP Connected");
}

/**
 * @brief Configura os pinos de GPIO para o protocolo de handshake.
 * @note Inicializa todos os pinos de dados, REQ (Request) e ACK (Acknowledge).
 * Define os pinos de saída (dados e REQ) e o pino de entrada (ACK) com pull-down.
 */
void handshake_setup(void){
    out_mask = (1 << DATA_TEMPERATURE_PIN) | (1 << DATA_PH_PIN) |
                        (1 << DATA_TDS_PIN) | (1 << DATA_BUTTON_PIN) |
                        (1 << REQ_PIN) | (1 << ACK_PIN);

    gpio_init_mask(out_mask);
    gpio_set_dir_out_masked(out_mask);

    gpio_init(ACK_PIN);
    gpio_set_dir(ACK_PIN, GPIO_IN);
    gpio_pull_down(ACK_PIN);

    gpio_put_masked(out_mask, 0);
}

/**
 * @brief Inicia uma requisição de handshake para o FPGA.
 * @note Coloca os dados normalizados (alertas) nos pinos de dados e,
 * em seguida, eleva o pino REQ para sinalizar ao FPGA que os dados estão prontos.
 * * @param data Estrutura (normalized_sensors_data_t) contendo os estados
 * boolianos (0 ou 1) dos sensores e do botão.
 */
void handshake_request(normalized_sensors_data_t data){
    gpio_put(DATA_TEMPERATURE_PIN, data.temperature);
    gpio_put(DATA_PH_PIN, data.ph);
    gpio_put(DATA_TDS_PIN, data.tds);
    gpio_put(DATA_BUTTON_PIN, data.button_state);

    vTaskDelay(pdMS_TO_TICKS(1));
    gpio_put(REQ_PIN, 1);
}

/**
 * @brief Aguarda pelo reconhecimento (ACK) do FPGA após uma requisição.
 * @note Monitora o pino ACK. Espera que o FPGA eleve o pino ACK para
 * sinalizar que recebeu os dados.
 * * @return true se o ACK foi recebido dentro do timeout (HANDSHAKE_TIMEOUT_MS),
 * false se ocorreu timeout.
 */
bool handshake_acknowledge(void){
    while(!gpio_get(ACK_PIN) && timeout_ms < HANDSHAKE_TIMEOUT_MS){
        vTaskDelay(pdMS_TO_TICKS(10));
        timeout_ms += 10;
    }

    if(timeout_ms >= HANDSHAKE_TIMEOUT_MS){
        send_notification(ERROR, "HS Retry...");
        gpio_put(ACK_PIN, 0);
        return false;
    }

    return true;
}

/**
 * @brief Aguarda o FPGA baixar o pino ACK.
 * @note Esta função é chamada após o Pico baixar o REQ, sinalizando ao
 * FPGA que o Pico viu o ACK. O FPGA então deve baixar o ACK.
 * Se o FPGA não baixar o ACK, ele é considerado travado.
 * * @return true se o ACK foi baixado dentro do timeout,
 * false se ocorreu timeout (indicando FPGA travado).
 */
bool handshake_await_ack_lower(void){
    timeout_ms = 0;
    // Wait for ACK to go low
    while(gpio_get(ACK_PIN) && timeout_ms < HANDSHAKE_TIMEOUT_MS){
        vTaskDelay(pdMS_TO_TICKS(10));
        timeout_ms += 10;
    }

    if(timeout_ms >= HANDSHAKE_TIMEOUT_MS){
        send_notification(ERROR, "FPGA Frozen!");
        return false;
    }

    return true;
}