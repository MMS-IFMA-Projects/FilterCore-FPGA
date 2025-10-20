#include "task_sensors.h"
#include "events.h"
#include "ds18b20.h"
#include "ph4502c.h"
#include "tds_meter.h"
#include "buttons.h"

#define SENSORS_INTERVAL_MS 125

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

        if(xQueueSend(queue_sensors_data, &data, pdMS_TO_TICKS(100)) != pdPASS){
            notification_t notification = {
                .type = ERROR,
                .message = "Failed to insert data"
            };

            xQueueSend(queue_notifications, &notification, pdMS_TO_TICKS(50));
        } 

        vTaskDelay(pdMS_TO_TICKS(SENSORS_INTERVAL_MS));
    }
}

void create_task_sensors() {
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