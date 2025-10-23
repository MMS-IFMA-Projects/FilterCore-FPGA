#include "ds18b20.h"
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "pico/time.h"
#include "FreeRTOS.h"
#include "task.h"

#define DS18B20_PIN 16 // gpio pin where the DS18B20 is connected

static void init_procedure(){
    gpio_set_dir(DS18B20_PIN, GPIO_OUT);
    gpio_put(DS18B20_PIN, 0);
    busy_wait_us(490);

    gpio_put(DS18B20_PIN, 1);
    gpio_set_dir(DS18B20_PIN, GPIO_IN);
    busy_wait_us(60);

    busy_wait_us(430);
}

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

static uint8_t read_byte(){
    uint8_t byte_val = 0x00;

    for(int i=0; i<8; i++) byte_val |= (read_bit() << i);
    
    return byte_val;
}

static void send_byte(uint8_t cmd){
    for(int i=0; i<8; i++){
        send_bit((cmd >> i) & 1);
    }
    busy_wait_us(5);
}

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