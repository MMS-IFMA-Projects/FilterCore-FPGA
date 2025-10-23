#include "notifications_screen.h"
#include "oled_prints.h"

#define LINE_ONE 0

void show_notifications_screen(notification_t *latest_notifications) {
    oled_clear(&oled);

    char title[] = "NOTIFICATIONS";
    print_text_center(&oled, title, LINE_ONE);

    for(uint8_t i = 0; i < MAX_NOTIFICATIONS; i++){
        char type[10];

        // Convert type to string
        switch(latest_notifications[i].type) {
            case INFO:
                snprintf(type, sizeof(type), "IN: ");
                break;
            case ALERT:
                snprintf(type, sizeof(type), "AL: ");
                break;
            case ERROR:
                snprintf(type, sizeof(type), "ER: ");
                break;
            default:
                snprintf(type, sizeof(type), "UN: ");
                break;
        }

        char text[16];
        snprintf(text, sizeof(text), "%s%s", type, latest_notifications[i].message);

        print_text_left(&oled, text, i + 2);
    }
    
    oled_render(&oled);
}