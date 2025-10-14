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

#endif // EVENTS_H