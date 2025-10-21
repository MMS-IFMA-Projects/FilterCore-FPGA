#include "task_sensors.h"
#include "events.h"
#include "ds18b20.h"
#include "ph4502c.h"
#include "tds_meter.h"
#include "buttons.h"

#define SENSORS_INTERVAL_MS 125

static normalized_sensors_data_t normalize_sensors_data(sensors_data_t data){
    // Continuous data
    celsius_t temperature = data.temperature;
    ph_t ph = data.ph;
    ppm_t tds = data.tds;

    // Normalized data
    bool normalized_temperature, normalized_ph, normalized_tds;
    
    // Basic Normalization
    normalized_temperature = (temperature < 24.0f || temperature > 30.0f) ? 1 : 0; // 24ºC < Temperature > 30ºC
    normalized_ph = (ph < 6.0f || ph > 8.0f) ? 1 : 0; // 6.0 < pH < 8.0
    normalized_tds = (tds > 750.0f) ? 1 : 0; // TDS > 750ppm

    // Advanced Normalization
    


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

        if(xQueueSend(queue_sensors_data, &data, pdMS_TO_TICKS(100)) != pdPASS){
            notification_t notification = {
                .type = ERROR,
                .message = "Failed to insert O data"
            };

            xQueueSend(queue_notifications, &notification, pdMS_TO_TICKS(50));
        }

        if(xQueueSend(queue_normalized_sensors_data, &normalized_data, pdMS_TO_TICKS(100)) != pdPASS){
            notification_t notification = {
                .type = ERROR,
                .message = "Failed to insert N data"
            };
        }

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