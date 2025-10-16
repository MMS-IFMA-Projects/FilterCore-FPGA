#include "i2c_configs.h"
#include "pico/stdlib.h"

static void i2c_configs(i2c_inst_t *i2c_port, uint sda_pin, uint scl_pin, uint baudrate) {
    i2c_init(i2c_port, baudrate);
    gpio_set_function(sda_pin, GPIO_FUNC_I2C);
    gpio_set_function(scl_pin, GPIO_FUNC_I2C);
    gpio_pull_up(sda_pin);
    gpio_pull_up(scl_pin);
}

/**
 * @brief Inicializa e configura o periférico I2C0, definindo a velocidade de comunicação 
 * para 400 kHz e ajustando os pinos SDA e SCL para a função I2C com resistores de pull-up ativados.
 */
void i2c0_configs(uint baudrate){
    i2c_configs(I2C0_PORT, I2C0_SDA_PIN, I2C0_SCL_PIN, baudrate);
}

/**
 * @brief Inicializa e configura o periférico I2C1, definindo a velocidade de comunicação 
 * para 400 kHz e ajustando os pinos SDA e SCL para a função I2C com resistores de pull-up ativados.
 */
void i2c1_configs(uint baudrate){
    i2c_configs(I2C1_PORT, I2C1_SDA_PIN, I2C1_SCL_PIN, baudrate);
}
