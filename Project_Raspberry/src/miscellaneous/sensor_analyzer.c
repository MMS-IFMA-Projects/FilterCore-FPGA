#include "sensor_analyzer.h"
#include "sensor_configs.h"
#include "notifications.h"

static normalized_sensors_data_t prev_normalized_data = {0};

bool analyzer_is_temperature_alert(celsius_t temperature){
    return temperature < MIN_TEMPERATURE_CELSIUS || temperature > MAX_TEMPERATURE_CELSIUS;
}

bool analyzer_is_ph_alert(ph_t ph){
    return ph < MIN_PH || ph > MAX_PH;
}

bool analyzer_is_tds_alert(sensors_data_t data){
    ppm_t max_tds = MAX_DEFAULT_TDS;

    if (data.temperature >= MIN_TEMPERATURE_CELSIUS && data.temperature <= MAX_TEMPERATURE_CELSIUS) {
        if (data.ph >= MIN_PH && data.ph < (MIN_PH + PH_FACTOR))
            max_tds = (-16.67f * data.temperature) + 1300.0f;
        if (data.ph >= (MIN_PH + PH_FACTOR) && data.ph < (MIN_PH + (PH_FACTOR * 3)))
            max_tds = (-33.33f * data.temperature) + 1575.0f;
        if (data.ph >= (MIN_PH + (PH_FACTOR * 3)) && data.ph <= MAX_PH)
            max_tds = (-16.67f * data.temperature) + 950.0f;
    }

    return (data.tds > max_tds);
}

void analyzer_init(void){
    prev_normalized_data.temperature = 0;
    prev_normalized_data.ph = 0;
    prev_normalized_data.tds = 0;
    prev_normalized_data.button_state = 0;
}

normalized_sensors_data_t analyzer_process_data(sensors_data_t data){
    normalized_sensors_data_t new_data;

    new_data.temperature = analyzer_is_temperature_alert(data.temperature);
    new_data.ph = analyzer_is_ph_alert(data.ph);
    new_data.tds = analyzer_is_tds_alert(data);
    new_data.button_state = data.button_state;

    if (new_data.temperature && !prev_normalized_data.temperature) {
        if (data.temperature < MIN_TEMPERATURE_CELSIUS) {
            send_notification(ALERT, "Temp Low!");
        } else {
            send_notification(ALERT, "Temp High!");
        }
    }

    if (new_data.ph && !prev_normalized_data.ph) {
        if (data.ph < MIN_PH) {
            send_notification(ALERT, "PH Acidic!");
        } else {
            send_notification(ALERT, "PH Alkaline!");
        }
    }

    if (new_data.tds && !prev_normalized_data.tds) {
        send_notification(ALERT, "TDS High!");
    }

    prev_normalized_data = new_data;

    return new_data;
}