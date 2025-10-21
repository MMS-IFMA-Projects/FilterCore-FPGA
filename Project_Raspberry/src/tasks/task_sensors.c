#include "task_sensors.h"
#include "events.h"
#include "ds18b20.h"
#include "ph4502c.h"
#include "tds_meter.h"
#include "buttons.h"
#include "notifications.h"

#define SENSORS_INTERVAL_MS 125

static bool get_normalized_tds(sensors_data_t data){
    ppm_t max_tds = MAX_DEFAULT_TDS;

    // Linear functions for PH range
    if(data.temperature >= MIN_TEMPERATURE_CELSIUS && data.temperature <= MAX_TEMPERATURE_CELSIUS){
        if(data.ph >= MIN_PH && data.ph < (MIN_PH + PH_FACTOR)) max_tds = (-16.67f * data.temperature) + 1300.0f;
        if(data.ph >= (MIN_PH + PH_FACTOR) && data.ph < (MIN_PH + (PH_FACTOR * 3))) max_tds = (-33.33f * data.temperature) + 1575.0f;
        if(data.ph >= (MIN_PH + (PH_FACTOR * 3)) && data.ph <= MAX_PH) max_tds = (-16.67f * data.temperature) + 950.0f;
    }

    return (data.tds > max_tds) ? 1 : 0; // Default TDS > 750ppm
}

static normalized_sensors_data_t normalize_sensors_data(sensors_data_t data){
    // Normalized data
    bool normalized_temperature, normalized_ph, normalized_tds;
    
    // Normalization
    normalized_temperature = (data.temperature < MIN_TEMPERATURE_CELSIUS || data.temperature > MAX_TEMPERATURE_CELSIUS) ? 1 : 0; // 24ºC < Temperature > 30ºC
    normalized_ph = (data.ph < MIN_PH || data.ph > MAX_PH) ? 1 : 0; // 6.0 < pH < 8.0
    normalized_tds = get_normalized_tds(data);


    normalized_sensors_data_t normalized_data = {
        .temperature = normalized_temperature,
        .ph = normalized_ph,
        .tds = normalized_tds,
        .button_state = data.button_state
    };

    return normalized_data;
}

static void task_sensors(void *params) {
    printf("[Started] | [Task 2] | [Sensors Reading]\n");

    while(true){
        celsius_t temperature = ds18b20_read_temperature();
        ph_t ph = ph4502c_read_ph();
        ppm_t tds = tds_meter_read_ppm(temperature);
        bool button_state = get_button_a();

        sensors_data_t data = {
            .temperature = temperature,
            .ph = ph,
            .tds = tds,
            .button_state = button_state
        };

        normalized_sensors_data_t normalized_data = normalize_sensors_data(data);

        // Manual activation notification
        if(button_state) send_notification(INFO, "Manual execution started");

        // Sending sensor data to the queue
        if(xQueueSend(queue_sensors_data, &data, pdMS_TO_TICKS(100)) != pdPASS) send_notification(ERROR, "Failed to insert PI data");

        // Sending normalized data to the queue
        if(xQueueSend(queue_normalized_sensors_data, &normalized_data, pdMS_TO_TICKS(100)) != pdPASS) send_notification(ERROR, "Failed to insert N FPGA data");

        vTaskDelay(pdMS_TO_TICKS(SENSORS_INTERVAL_MS));
    }
}

void create_task_sensors(void) {
    init_button_a();

    TaskHandle_t handle;
    BaseType_t status = xTaskCreate(
        task_sensors,          
        "Task Sensors",       
        configMINIMAL_STACK_SIZE * 2, 
        NULL,                 
        tskIDLE_PRIORITY + 2, 
        &handle               
    );

    if(status != pdPASS || handle == NULL) printf("[Failed to create] | [Task 2] | [Sensors Reading]\n");
    else vTaskCoreAffinitySet(handle, (1 << 0)); // Set task to run on core 0
}