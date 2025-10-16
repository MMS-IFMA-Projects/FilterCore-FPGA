#ifndef OLED_SCREEN_H
#define OLED_SCREEN_H

#include <stdint.h>

typedef enum {
    OLED_SCREEN = 0,
    AX_SCREEN,
    AY_SCREEN,
    AZ_SCREEN,
    GX_SCREEN,
    GY_SCREEN,
    GZ_SCREEN,
    TEMP_SCREEN,
    TOTAL_SCREENS
} oled_screen_t;

#endif // OLED_SCREEN_H