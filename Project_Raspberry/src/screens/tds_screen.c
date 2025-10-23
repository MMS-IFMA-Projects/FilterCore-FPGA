#include "tds_screen.h"
#include "oled_prints.h"
#include "sensor_analyzer.h"

#define LINE_ONE 0
#define LINE_WITH_MARGIN 2

void show_tds_screen(sensors_data_t latest_data) {
    oled_clear(&oled);

    char title[] = "TDS LEVEL";
    char unit_and_state[16];
    char sensor_value[8];

    if(analyzer_is_tds_alert(latest_data)) 
        snprintf(unit_and_state, sizeof(unit_and_state), "(PPM) I ALERT");
    else snprintf(unit_and_state, sizeof(unit_and_state), "(PPM) I NORMAL");

    snprintf(sensor_value, sizeof(sensor_value), "%.2f", latest_data.tds);

    uint8_t line = LINE_ONE;

    print_text_center(&oled, title, line);
    line += LINE_WITH_MARGIN;

    print_text_center(&oled, unit_and_state, line);
    line += LINE_WITH_MARGIN;

    print_large_text_center(&oled, sensor_value,  line);
   
    oled_render(&oled);
}