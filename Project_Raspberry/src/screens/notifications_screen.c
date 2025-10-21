#include "notifications_screen.h"
#include "oled_prints.h"

void show_notifications_screen(notification_t *latest_notifications) {
    oled_clear(&oled);

    char title[] = "NOTIFICATIONS";
    print_text_center(&oled, title, 1);

    for(uint8_t i = 0; i < MAX_NOTIFICATIONS; i++){
        char type[10];

        // Convert type to string
        switch(latest_notifications[i].type) {
            case INFO:
                snprintf(type, sizeof(type), "INFO: ");
                break;
            case WARNING:
                snprintf(type, sizeof(type), "WARNING: ");
                break;
            case ERROR:
                snprintf(type, sizeof(type), "ERROR: ");
                break;
            default:
                snprintf(type, sizeof(type), "UNKNOWN: ");
                break;
        }

        char text[32];
        snprintf(text, sizeof(text), "%s%s", type, latest_notifications[i].message);

        print_text_left(&oled, text, i + 2);
    }
    
    oled_render(&oled);
}