#ifndef OLED_PRINTS_H
#define OLED_PRINTS_H

#include "oled_environment.h"
#include <string.h>
#include <stdio.h>

#define SSD1306_CHAR_LARGE_WIDTH 16
#define SSD1306_BITMAP_LARGE_HEIGHT 8
#define SSD1306_CHAR_LARGE_PAGES 3
#define DEFAULT_MARGIN 8

void print_text_center(ssd1306_t* oled, const char* text, uint8_t line);

void print_text_left(ssd1306_t* oled, const char* text, uint8_t line);

void print_large_text_center(ssd1306_t* oled, const char* text, uint8_t start_line);

#endif //OLED_PRINTS_H