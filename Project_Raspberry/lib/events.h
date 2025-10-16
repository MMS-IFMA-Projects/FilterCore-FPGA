#ifndef EVENTS_H
#define EVENTS_H

#include <stdio.h>
#include "pico/stdlib.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "units.h"

typedef struct{
    celsius_t temperature;
    ph_t ph;
    ppm_t ppm;
} sensors_data_t;

extern TaskHandle_t handle_display;
extern QueueHandle_t queue_sensors_data;
extern QueueHandle_t queue_notifications;


#endif // EVENTS_H