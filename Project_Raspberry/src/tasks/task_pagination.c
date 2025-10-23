#include "task_pagination.h"
#include "events.h"
#include "buttons.h"
#include "oled_environment.h"


#define PAGINATION_INTERVAL_MS 125

static void task_pagination(void *params){
    printf("[Started] | [Task 3] | [Display Pagination]\n");

    bool pressioned = false;

    while(true){
        bool button_state = get_button_b();

        vTaskDelay(pdMS_TO_TICKS(10));

        if(button_state && !pressioned){
            pressioned = true;

            current_screen = (current_screen + 1) % TOTAL_SCREENS;
        }
        else if(!button_state && pressioned){
            pressioned = false;
        }
    
        vTaskDelay(pdMS_TO_TICKS(PAGINATION_INTERVAL_MS));
    }

}

void create_task_pagination(void){
    init_button_b();

    TaskHandle_t handle;
    BaseType_t status = xTaskCreate(
        task_pagination,          
        "Task Pagination",       
        configMINIMAL_STACK_SIZE * 2, 
        NULL,                 
        tskIDLE_PRIORITY + 3, 
        &handle               
    );

    if(status != pdPASS || handle == NULL) printf("[Failed to create] | [Task 3] | [Display Pagination]\n");
    else vTaskCoreAffinitySet(handle, (1 << 0)); // Set task to run on core 0
}