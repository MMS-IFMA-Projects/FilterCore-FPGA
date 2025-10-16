#include "ads1115.h"
#include "FreeRTOS.h"
#include "task.h"

#define ADS1115_ADDR 0x48

/**
 * @brief Configura o ADS1115 para uma conversão em um canal específico, aguarda a conversão e lê o 
 * resultado bruto do ADC.
 * @param channel O canal de entrada analógica a ser lido (0 a 3).
 * @return O resultado da conversão ADC como um inteiro sinalizado de 16 bits.
 */
int16_t ads1115_read_adc(uint8_t channel) {
    uint8_t config_msb = 0;
    switch (channel) {
        case 0: config_msb = 0b11000001; break; // AIN0 vs GND
        case 1: config_msb = 0b11010001; break; // AIN1 vs GND
        case 2: config_msb = 0b11100001; break; // AIN2 vs GND
        case 3: config_msb = 0b11110001; break; // AIN3 vs GND
        default: return 0;
    }
    // Config: Iniciar uma conversão, canal X, ganho +/-4.096V, modo single-shot, 860 amostras/s
    uint8_t config_lsb = 0b10000011;

    uint8_t write_buf[3] = {0x01, config_msb, config_lsb}; // Aponta para o reg de config e escreve
    i2c_write_blocking(I2C0_PORT, ADS1115_ADDR, write_buf, 3, false);

    vTaskDelay(pdMS_TO_TICKS(2));

    // Aponta para o registrador de conversão (0x00) para ler
    uint8_t pointer_reg = 0x00;
    i2c_write_blocking(I2C0_PORT, ADS1115_ADDR, &pointer_reg, 1, false);

    uint8_t read_buf[2];
    i2c_read_blocking(I2C0_PORT, ADS1115_ADDR, read_buf, 2, false);

    return (int16_t)((read_buf[0] << 8) | read_buf[1]);
}