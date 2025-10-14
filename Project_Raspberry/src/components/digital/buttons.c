#include "buttons.h"
#include "FreeRTOS.h"
#include "task.h"

#define PIN_BUTTON_A 5
#define PIN_BUTTON_B 6
#define PIN_BUTTON_SW 22
#define DEBOUNCE_DELAY 10

/**
 * @brief Configura um pino GPIO especificado como uma entrada com um resistor de pull-up.
 * @param button O número do pino GPIO a ser inicializado.
 */
static void init_button(uint8_t button){
    gpio_init(button); gpio_set_dir(button, GPIO_IN); gpio_pull_up(button);
}

/**
 * @brief Lê o estado de um botão, implementando um simples debounce de software ao esperar que o botão seja liberado.
 * @param button O número do pino GPIO do botão a ser lido.
 * @return Retorna true no momento em que o botão é pressionado.
 */
static bool get_button(uint8_t button){
    bool state = !gpio_get(button);
    while(!gpio_get(button)) vTaskDelay(pdMS_TO_TICKS(DEBOUNCE_DELAY));
    return state;
}

/**
 * @brief Função de inicialização do botão A, utilizando função init_button.
 */
void init_button_a(){
    init_button(PIN_BUTTON_A);
}

/**
 * @brief Função de inicialização do botão B, utilizando função init_button.
 */
void init_button_b(){
    init_button(PIN_BUTTON_B);
}

/**
 * @brief Função de inicialização do botão SW, utilizando função init_button.
 */
void init_button_sw(){
    init_button(PIN_BUTTON_SW);
}

/**
 * Função leitura do botão A.
 */
bool get_button_a(){
    return get_button(PIN_BUTTON_A);
}

/**
 * Função leitura do botão B.
 */
bool get_button_b(){
    return get_button(PIN_BUTTON_B);
}

/**
 * Função leitura do botão SW.
 */
bool get_button_sw(){
    return get_button(PIN_BUTTON_SW);
}
