#include "oled_prints.h"

void print_text_center(ssd1306_t* oled, const char* text, uint8_t line) {
    int text_length = strlen(text);
    int x = (oled->width - (text_length * SSD1306_CHAR_WIDTH)) / 2; // Each character is 8 pixels wide
    ssd1306_draw_utf8_multiline(oled->ram_buffer, x, line * SSD1306_CHAR_HEIGHT, text, oled->width, oled->height);
}

void print_text_left(ssd1306_t* oled, const char* text, uint8_t line) {
    ssd1306_draw_utf8_multiline(oled->ram_buffer, 0, line, text, oled->width, oled->height);
}