#include "i2c_configs.h"
#include "pico/stdlib.h"

/**
 * @brief Inicializa e configura o periférico I2C, definindo a velocidade de comunicação 
 * para 100 kHz e ajustando os pinos SDA e SCL para a função I2C com resistores de pull-up ativados.
 */
void i2c_configs(){
    i2c_init(I2C_PORT, 100 * 1000);
    gpio_set_function(I2C_SDA_PIN, GPIO_FUNC_I2C);
    gpio_set_function(I2C_SCL_PIN, GPIO_FUNC_I2C);
    gpio_pull_up(I2C_SDA_PIN);
    gpio_pull_up(I2C_SCL_PIN);
}
