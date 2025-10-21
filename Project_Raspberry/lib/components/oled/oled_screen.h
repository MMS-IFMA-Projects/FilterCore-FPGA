#ifndef OLED_SCREEN_H
#define OLED_SCREEN_H

#include <stdint.h>


typedef enum {
    DEFAULT_SCREEN = 0,
    PH_SCREEN,
    TDS_SCREEN,
    TEMPERATURE_SCREEN,
    NOTIFICATIONS_SCREEN,
    TOTAL_SCREENS
} oled_screen_t;

#endif // OLED_SCREEN_H