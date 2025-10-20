#include "default_screen.h"
#include "oled_prints.h"

void show_default_screen(sensors_data_t latest_data) {
    oled_clear(&oled);

    char text[32];
    int line = 0;

    snprintf(text, sizeof(text), "Data Summary");
    print_text_center(&oled, text, line);
    line += SSD1306_CHAR_HEIGHT;
        
    snprintf(text, sizeof(text), "pH: %.2f", latest_data.ph);
    print_text_left(&oled, text, line);
    line += SSD1306_CHAR_HEIGHT;
        
    snprintf(text, sizeof(text), "PPM: %.2f", latest_data.ppm);
    print_text_left(&oled, text, line);
    line += SSD1306_CHAR_HEIGHT;

    snprintf(text, sizeof(text), "Temp: %.2f ºC", latest_data.temperature);
    print_text_left(&oled, text, line);
    
    oled_render(&oled);
}