#include "oled_prints.h"
#include "ssd1306_symbols_large.h"

static void print_large_symbol(ssd1306_t* oled, const uint8_t* bitmap, uint8_t x, uint8_t start_y) {
    for(uint8_t col = 0; col < SSD1306_CHAR_LARGE_WIDTH; col++) {
        for(uint8_t page = 0; page < SSD1306_CHAR_LARGE_PAGES; page++) {
            int index = col * SSD1306_BITMAP_LARGE_HEIGHT + (page + 5);
            int position = (page + start_y) * oled->width + (x + col);

            if(position < oled->buffer_size &&  (x + col) < oled->width && (page + start_y) < oled->pages) {
                if(position > 0) oled->ram_buffer[position] = bitmap[index];
            }
        }
    }
}

static void print_large_char(ssd1306_t* oled, char c, uint8_t x, uint8_t start_y) {
    const uint8_t *bitmap = NULL;

    if(c >= '0' && c <= '9') bitmap = large_numbers[c - '0'];
    else if(c == '+') bitmap = large_symbols[0];
    else if(c == '-') bitmap = large_symbols[1];
    else if(c == '.') bitmap = large_symbols[2];
    else if(c == ' ') bitmap = large_symbols[3];
    else return; // Character not supported

    if(bitmap) print_large_symbol(oled, bitmap, x, start_y);
}


void print_text_center(ssd1306_t* oled, const char* text, uint8_t line) {
    int text_length = strlen(text);
    int x = (oled->width - (text_length * SSD1306_CHAR_WIDTH)) / 2; // Each character is 8 pixels wide
    ssd1306_draw_utf8_multiline(oled->ram_buffer, x, line * SSD1306_CHAR_HEIGHT, text, oled->width, oled->height);
}

void print_text_left(ssd1306_t* oled, const char* text, uint8_t line) {
    ssd1306_draw_utf8_multiline(oled->ram_buffer, 0, line * SSD1306_CHAR_HEIGHT, text, oled->width, oled->height);
}

void print_large_text_center(ssd1306_t* oled, const char* text, uint8_t start_line) {
    int text_length = strlen(text);
    int total_text_width = text_length * SSD1306_CHAR_LARGE_WIDTH;
    uint8_t x = 0;

    if(total_text_width < oled->width) {
        x = (oled->width - total_text_width) / 2;
    }

    for(uint8_t i = 0; text[i] != '\0'; i++){
        print_large_char(oled, text[i], x, start_line);
        x += SSD1306_CHAR_LARGE_WIDTH;

        if(x >= oled->width) break;
    }
}

