#include "oled_environment.h"

// Global variable for the OLED display instance
ssd1306_t oled;

SemaphoreHandle_t oled_mutex = NULL;

volatile oled_screen_t current_screen = OLED_SCREEN;