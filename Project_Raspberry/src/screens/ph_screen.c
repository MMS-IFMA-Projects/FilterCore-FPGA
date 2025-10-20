#include "ph_screen.h"
#include "oled_prints.h"

void show_ph_screen(sensors_data_t latest_data) {
    oled_clear(&oled);

    char title[] = "PH LEVEL";
    char unit[] = "(pH)";
    char value_sensor[8];

    snprintf(value_sensor, sizeof(value_sensor), "%.2f", latest_data.ph);

    print_text_center(&oled, title, 1);
    print_large_text_center(&oled, value_sensor, 2); // Start at line 2, end at line 4
    print_text_center(&oled, unit, 5);

    oled_render(&oled);
}