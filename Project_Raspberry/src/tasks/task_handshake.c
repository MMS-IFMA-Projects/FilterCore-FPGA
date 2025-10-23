#include "task_handshake.h"
#include "handshake.h"
#include "notifications.h"

#define HANDSHAKE_INTERVAL_MS 250

static void task_handshake(void *params){
    printf("[Started] | [Task 4] | [Handshake]\n");

    // Data pin initiation
    handshake_setup();

    normalized_sensors_data_t data;

    while(true){
        // Get data from the normalized data queue
        if(xQueueReceive(queue_normalized_sensors_data, &data, portMAX_DELAY)){
            bool success = false;

            for(int retry = 1; retry <= HANDSHAKE_MAX_RETRIES && !success; retry++){
                // Submit request
                handshake_request(data);

                // Wait for ACK
                if(!handshake_acknowledge()) continue;
                
                // Complete transaction
                success = true;
                gpio_put(REQ_PIN, 0);
                
                // Wait for ACK to go low
                handshake_await_ack_lower();
            }

            if(!success) send_notification(ERROR, "HS Failed!");
        }

        vTaskDelay(pdMS_TO_TICKS(HANDSHAKE_INTERVAL_MS));
    }
}

void create_task_handshake(void){
    TaskHandle_t handle;
    BaseType_t status = xTaskCreate(
        task_handshake,          
        "Task Handshake",       
        configMINIMAL_STACK_SIZE * 2, 
        NULL,                 
        tskIDLE_PRIORITY + 2, 
        &handle               
    );

    if(status != pdPASS || handle == NULL) printf("[Failed to create] | [Task 4] | [Handshake]\n");
    else vTaskCoreAffinitySet(handle, (1 << 1)); // Set task to run on core 1
}