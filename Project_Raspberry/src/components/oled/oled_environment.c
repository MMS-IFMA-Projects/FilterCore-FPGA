#include "oled_environment.h"

/**
 * @brief Instância global da estrutura do display OLED.
 * Contém o estado, buffer e configuração do SSD1306.
 */
ssd1306_t oled;

/**
 * @brief Mutex para proteger o acesso ao hardware OLED e ao ram_buffer.
 * Deve ser usado antes de qualquer operação de desenho (oled_clear, oled_render, print_...)
 * para garantir a segurança em ambiente multithread (FreeRTOS).
 */
SemaphoreHandle_t oled_mutex = NULL;

/**
 * @brief Variável volátil que controla qual tela está sendo exibida.
 * Usada para gerenciar a máquina de estados da interface do usuário.
 */
volatile oled_screen_t current_screen = DEFAULT_SCREEN;