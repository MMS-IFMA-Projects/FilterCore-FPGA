#ifndef EVENTS_H
#define EVENTS_H

#include <stdio.h>
#include "pico/stdlib.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "units.h"

typedef enum {
    INFO,
    WARNING,
    ERROR
} severity_t;

typedef struct{
    celsius_t temperature;
    ph_t ph;
    ppm_t ppm;
    bool button_state;
} sensors_data_t;

typedef struct{
    severity_t severity;
    char message[16];
} notification_t;

extern TaskHandle_t handle_display;
extern QueueHandle_t queue_sensors_data;
extern QueueHandle_t queue_notifications;


#endif // EVENTS_H