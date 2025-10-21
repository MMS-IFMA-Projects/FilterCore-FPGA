#include "tds_screen.h"
#include "oled_prints.h"

void show_tds_screen(sensors_data_t latest_data) {
    oled_clear(&oled);

    char title[] = "TOTAL DISSOLVED SOLIDS";
    char unit[] = "(ppm)";
    char sensor_value[8];

    snprintf(sensor_value, sizeof(sensor_value), "%.2f", latest_data.tds);

    print_text_center(&oled, title, 1);
    print_large_text_center(&oled, sensor_value, 2); // Start at line 2, end at line 4
    print_text_center(&oled, unit, 5);

    oled_render(&oled);
}