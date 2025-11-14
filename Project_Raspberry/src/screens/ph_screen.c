#include "ph_screen.h"
#include "oled_prints.h"
#include "sensor_analyzer.h"

#define LINE_ONE 0
#define LINE_WITH_MARGIN 2

/**
 * @brief Exibe a tela dedicada ao sensor de pH no OLED.
 * @note Limpa o display, mostra um título, o estado (NORMAL/ALERT)
 * e o valor numérico do pH em fonte grande.
 * * @param latest_data Estrutura (sensors_data_t) contendo os dados
 * mais recentes dos sensores (usará especificamente o valor de pH).
 */
void show_ph_screen(sensors_data_t latest_data) {
    oled_clear(&oled);

    char title[] = "PH LEVEL";
    char unit_and_state[16];
    char sensor_value[8];

    if(analyzer_is_ph_alert(latest_data.ph)) snprintf(unit_and_state, sizeof(unit_and_state), "(pH) I ALERT");
    else snprintf(unit_and_state, sizeof(unit_and_state), "(pH) I NORMAL");

    snprintf(sensor_value, sizeof(sensor_value), "%.2f", latest_data.ph);

    uint8_t line = LINE_ONE;

    print_text_center(&oled, title, line);
    line += LINE_WITH_MARGIN;

    print_text_center(&oled, unit_and_state, line);
    line += LINE_WITH_MARGIN;

    print_large_text_center(&oled, sensor_value,  line);
    line += SSD1306_CHAR_LARGE_PAGES;
    
    oled_render(&oled);
}