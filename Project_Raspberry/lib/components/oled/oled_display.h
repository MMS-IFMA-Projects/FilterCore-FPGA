#ifndef OLED_DISPLAY_H
#define OLED_DISPLAY_H

#include "i2c_configs.h"
#include <stdint.h>
#include <stddef.h>

// Display dimensions
#define OLED_WIDTH  128
#define OLED_HEIGHT 64
#define OLED_PAGES (OLED_HEIGHT / 8)
#define OLED_I2C_ADDRESS 0x3C
#define OLED_I2C_FREQ 400000


// Display structure
typedef struct {
    uint8_t width;
    uint8_t height;
    uint8_t pages;
    uint8_t address;
    i2c_inst_t* i2c_port;
    uint8_t *ram_buffer;
    size_t buffer_size;
    uint8_t port_buffer[2];
} ssd1306_t;

extern ssd1306_t oled;

bool oled_init(ssd1306_t* oled);

void oled_clear(ssd1306_t* oled);

void oled_render(ssd1306_t* oled);

void ssd1306_draw_string(uint8_t *buffer, int16_t x, int16_t y, const char *str, uint8_t width, uint8_t height);

#endif //OLED_DISPLAY_H