#ifndef OLED_ENVIRONMENT_H
#define OLED_ENVIRONMENT_H

#include "oled_display.h"
#include "oled_screen.h"
#include "FreeRTOS.h"
#include "semphr.h"

extern ssd1306_t oled;

extern SemaphoreHandle_t oled_mutex;

extern volatile oled_screen_t current_screen;

#endif // OLED_ENVIRONMENT_H