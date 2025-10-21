#ifndef EVENTS_H
#define EVENTS_H

#include <stdio.h>
#include "pico/stdlib.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "units.h"

#define MAX_NOTIFICATIONS 5
#define MAX_SENSORS_DATA 5
#define MAX_TEMPERATURE_CELSIUS 30.0f
#define MIN_TEMPERATURE_CELSIUS 24.0f
#define MAX_PH 8.0f
#define MIN_PH 6.0f
#define MAX_DEFAULT_TDS 750.0f


typedef enum {
    INFO,
    WARNING,
    ERROR
} notification_type_t;

typedef struct{
    celsius_t temperature;
    ph_t ph;
    ppm_t tds;
    bool button_state;
} sensors_data_t;

typedef struct{
    bool temperature;
    bool ph;
    bool tds;
    bool button_state;
} normalized_sensors_data_t;

typedef struct{
    notification_type_t type;
    char message[22];
} notification_t;

extern TaskHandle_t handle_display;
extern QueueHandle_t queue_sensors_data;
extern QueueHandle_t queue_normalized_sensors_data;
extern QueueHandle_t queue_notifications;


#endif // EVENTS_H