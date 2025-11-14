#include "default_screen.h"
#include "oled_prints.h"

#define LINE_ONE 0
#define LINE_WITH_MARGIN 2

/**
 * @brief Exibe a tela de resumo padrão no OLED.
 * @note Esta tela limpa o display e mostra um resumo dos valores
 * de pH, PPM (TDS) e Temperatura.
 * * @param latest_data Estrutura (sensors_data_t) contendo os dados
 * mais recentes dos sensores a serem exibidos.
 */
void show_default_screen(sensors_data_t latest_data) {
    oled_clear(&oled);

    char text[32];
    int line = LINE_ONE;

    snprintf(text, sizeof(text), "DATA SUMMARY");
    print_text_center(&oled, text, line);
    line += LINE_WITH_MARGIN;
        
    snprintf(text, sizeof(text), "PH: %.2f", latest_data.ph);
    print_text_left(&oled, text, line);
    line+= LINE_WITH_MARGIN;
        
    snprintf(text, sizeof(text), "PPM: %.2f", latest_data.tds);
    print_text_left(&oled, text, line);
    line+= LINE_WITH_MARGIN;

    snprintf(text, sizeof(text), "Temp: %.2f ºC", latest_data.temperature);
    print_text_left(&oled, text, line);
    
    oled_render(&oled);
}