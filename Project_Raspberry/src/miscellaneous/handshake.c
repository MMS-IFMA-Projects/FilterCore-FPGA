#include "handshake.h"
#include "notifications.h"

#define DATA_TEMPERATURE_PIN 18
#define DATA_PH_PIN 19
#define DATA_TDS_PIN 20
#define DATA_BUTTON_PIN 4
#define FPGA_RESET_PIN 16
#define FPGA_ALIVE_PIN 17

volatile uint32_t out_mask;
volatile int timeout_ms = 0;

void reset_fpga_setup(void){
    // Initializes the check pins
    gpio_init(FPGA_RESET_PIN); gpio_set_dir(FPGA_RESET_PIN, GPIO_OUT);
    gpio_init(FPGA_ALIVE_PIN); gpio_set_dir(FPGA_ALIVE_PIN, GPIO_IN);

    while(!gpio_get(FPGA_ALIVE_PIN)){
        gpio_put(FPGA_RESET_PIN, 0);
        vTaskDelay(pdMS_TO_TICKS(100));
    }

    gpio_put(FPGA_RESET_PIN, 1);
}

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

void handshake_request(normalized_sensors_data_t data){
    gpio_put(DATA_TEMPERATURE_PIN, data.temperature);
    gpio_put(DATA_PH_PIN, data.ph);
    gpio_put(DATA_TDS_PIN, data.tds);
    gpio_put(DATA_BUTTON_PIN, data.button_state);

    vTaskDelay(pdMS_TO_TICKS(1));
    gpio_put(REQ_PIN, 1);
}

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