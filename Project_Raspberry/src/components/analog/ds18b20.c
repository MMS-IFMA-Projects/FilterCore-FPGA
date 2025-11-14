#include "ds18b20.h"
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "pico/time.h"
#include "FreeRTOS.h"
#include "task.h"

#define DS18B20_PIN 2 // gpio pin where the DS18B20 is connected

/**
 * @brief Executa o procedimento de inicialização (reset e detecção de presença)
 * do barramento 1-Wire para o sensor DS18B20.
 */
static void init_procedure(){
    gpio_set_dir(DS18B20_PIN, GPIO_OUT);
    gpio_put(DS18B20_PIN, 0);
    busy_wait_us(490);

    gpio_put(DS18B20_PIN, 1);
    gpio_set_dir(DS18B20_PIN, GPIO_IN);
    busy_wait_us(60);

    busy_wait_us(430);
}

/**
 * @brief Lê um único bit do barramento 1-Wire.
 * * @return O valor booleano do bit lido (true para 1, false para 0).
 */
static bool read_bit(){
    bool bit_val = false;

    gpio_set_dir(DS18B20_PIN, GPIO_OUT);
    gpio_put(DS18B20_PIN, 0);
    busy_wait_us(2);

    gpio_set_dir(DS18B20_PIN, GPIO_IN);
    busy_wait_us(2);
    bit_val = gpio_get(DS18B20_PIN);
    busy_wait_us(80);

    return bit_val;
}

/**
 * @brief Envia um único bit (0 ou 1) para o barramento 1-Wire.
 * * @param bit_state O valor booleano do bit a ser enviado (true para 1, false para 0).
 */
static void send_bit(bool bit_state){
    gpio_set_dir(DS18B20_PIN, GPIO_OUT);
    gpio_put(DS18B20_PIN, 0);

    if(bit_state){
        busy_wait_us(5);
        gpio_put(DS18B20_PIN, 1);
        busy_wait_us(45);
    } else {
        busy_wait_us(90);
        gpio_put(DS18B20_PIN, 1);
        busy_wait_us(10);
    }
}

/**
 * @brief Lê um byte (8 bits) do barramento 1-Wire, bit a bit (LSB first).
 * * @return O byte (uint8_t) lido do barramento.
 */
static uint8_t read_byte(){
    uint8_t byte_val = 0x00;

    for(int i=0; i<8; i++) byte_val |= (read_bit() << i);
    
    return byte_val;
}

/**
 * @brief Envia um byte (8 bits) para o barramento 1-Wire, bit a bit (LSB first).
 * * @param cmd O byte (comando) a ser enviado.
 */
static void send_byte(uint8_t cmd){
    for(int i=0; i<8; i++){
        send_bit((cmd >> i) & 1);
    }
    busy_wait_us(5);
}

/**
 * @brief Realiza a leitura completa da temperatura do sensor DS18B20.
 * * Inicia a conversão, aguarda o tempo necessário (750ms), e
 * lê os bytes do "Scratchpad" para calcular a temperatura.
 * * @return A temperatura medida em graus Celsius (tipo celsius_t).
 */
celsius_t ds18b20_read_temperature(void){
    gpio_init(DS18B20_PIN);

    init_procedure();   // Initializes the sensor
    send_byte(0xCC);    // Send the command “Skip ROM”
    send_byte(0x44);    // Send the command to start the conversion
    vTaskDelay(pdMS_TO_TICKS(750)); // wait for conversion (max 750ms for 12-bit resolution)

    init_procedure();   // Reset to prepare for reading
    send_byte(0xCC);    // Send the “Skip ROM” command again
    send_byte(0xBE);    // Send the command to read the “Scratchpad”

    // Reads the 2 bytes of temperature
    uint8_t temp_LSB = read_byte();
    uint8_t temp_MSB = read_byte();

    // Combine the two bytes into a single 16-bit value
    int16_t raw_temp = (temp_MSB << 8) | temp_LSB;

    return (float)raw_temp * 0.0625f; // Convert to Celsius (each bit represents 0.0625 degrees)
}