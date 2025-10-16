#include "oled_display.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "ssd1306_text.h"
#include "hardware/gpio.h"

static void ssd1306_send_command(ssd1306_t* oled, uint8_t command) {
    oled->port_buffer[0] = 0x80; // Control byte for command
    oled->port_buffer[1] = command;
    i2c_write_blocking(oled->i2c_port, oled->address, oled->port_buffer, 2, false);
}

static void ssd1306_send_command_list(ssd1306_t* oled, const uint8_t* commands, size_t len) {
    for (size_t i = 0; i < len; i++) {
        ssd1306_send_command(oled, commands[i]);
    }
}

bool oled_init(ssd1306_t* oled) {
    if(!oled) return false;

    oled->width = OLED_WIDTH;
    oled->height = OLED_HEIGHT;
    oled->pages = OLED_PAGES;
    oled->address = OLED_I2C_ADDRESS;
    oled->i2c_port = I2C1_PORT;
    oled->buffer_size = oled->width * oled->pages;
    oled->ram_buffer = calloc(oled->buffer_size, sizeof(uint8_t));

    if(!oled->ram_buffer) return false;

    oled->ram_buffer[0] = 0x40; // Control byte for data

    // Pins setup
    i2c1_configs(OLED_I2C_FREQ);

    // Initialization sequence
    const uint8_t init_commands[] = {
        0xAE, // Display off
        0x20, 0x00, // Memory addressing mode (horizontal addressing mode)
        0x40, // Set start line address
        0xA1, // Set segment re-map (column address 127 is mapped to SEG0)
        0xC8, // Set COM output scan direction (remapped mode)
        0xDA, 0x12, // Set COM pins hardware configuration
        0x81, 0x7F, // Set contrast control
        0xA4, // Entire display ON (resume to RAM content display)
        0XA6, // Set normal display (not inverted)
        0xD5, 0x80, // Set display clock divide ratio/oscillator frequency
        0x8D, 0x14, // Charge pump setting (enable)
        0xAF // Display ON
    };

    ssd1306_send_command_list(oled, init_commands, sizeof(init_commands));

    return true;
}

void oled_clear(ssd1306_t* oled) {
    if(!oled || !oled->ram_buffer) return;
    memset(oled->ram_buffer[1], 0x00, oled->buffer_size - 1);
}

void oled_render(ssd1306_t* oled) {
    if(!oled || !oled->ram_buffer) return;

    ssd1306_send_command(oled, 0x21); // Set column address
    ssd1306_send_command(oled, 0);    // Column start address
    ssd1306_send_command(oled, oled->width - 1); // Column end address

    ssd1306_send_command(oled, 0x22); // Set page address
    ssd1306_send_command(oled, 0);    // Page start address
    ssd1306_send_command(oled, oled->pages - 1); // Page end address

    i2c_write_blocking(oled->i2c_port, oled->address, oled->ram_buffer, oled->buffer_size, false);
}
