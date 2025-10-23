#ifndef SENSOR_ANALYZER_H
#define SENSOR_ANALYZER_H

#include "events.h"

void analyzer_init(void);

normalized_sensors_data_t analyzer_process_data(sensors_data_t data);

bool analyzer_is_temperature_alert(celsius_t temperature);

bool analyzer_is_ph_alert(ph_t ph);

bool analyzer_is_tds_alert(sensors_data_t data);

#endif //SENSOR_ANALYZER_H