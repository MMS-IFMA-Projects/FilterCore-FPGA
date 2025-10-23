#include "task_sensors.h"
#include "events.h"
#include "ds18b20.h"
#include "ph4502c.h"
#include "tds_meter.h"
#include "buttons.h"
#include "notifications.h"
#include "sensor_analyzer.h"

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

        normalized_sensors_data_t normalized_data = analyzer_process_data(data);

        // Manual activation notification
        if(button_state) send_notification(INFO, "Manual Start");

        // Sending sensor data to the queue
        if(xQueueSend(queue_sensors_data, &data, pdMS_TO_TICKS(100)) != pdPASS) 
            send_notification(ERROR, "PI Data Fail");

        // Sending normalized data to the queue
        if(xQueueSend(queue_normalized_sensors_data, &normalized_data, pdMS_TO_TICKS(100)) != pdPASS) 
            send_notification(ERROR, "FPGA N Fail");

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
        tskIDLE_PRIORITY + 4, 
        &handle               
    );

    if(status != pdPASS || handle == NULL) printf("[Failed to create] | [Task 2] | [Sensors Reading]\n");
    else vTaskCoreAffinitySet(handle, (1 << 0)); // Set task to run on core 0
}