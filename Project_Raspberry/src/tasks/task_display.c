#include "task_display.h"
#include "events.h"
#include "oled_environment.h"
#include "oled_prints.h"

#define DISPLAY_INTERVAL_MS 250

static void task_display(void *params) {
    printf("[Started] | [Task 1] | [Display Printing]\n");

    //Screen cleaning
    if(xSemaphoreTake(oled_mutex, portMAX_DELAY)){
        oled_clear(&oled);
        oled_render(&oled);
        xSemaphoreGive(oled_mutex);
    }

    vTaskDelay(pdMS_TO_TICKS(DISPLAY_INTERVAL_MS));

    // Screen selection loop
    while(true){
        if(xSemaphoreTake(oled_mutex, pdMS_TO_TICKS(100))){
            switch(current_screen){
                case DEFAULT_SCREEN:
                    break;
                case PH_SCREEN:
                    break;
                case TDS_SCREEN:
                    break;
                case TEMPERATURE_SCREEN:
                    break;
                case NOTIFICATIONS_SCREEN:
                    break;
                default:
                    oled_clear(&oled);
                    print_text_center(&oled, "Invalid Screen", 3);
                    oled_render(&oled);
                    break;
            }
        }

        vTaskDelay(pdMS_TO_TICKS(DISPLAY_INTERVAL_MS));
    }

}

void create_task_display() {
   TaskHandle_t handle;
   BaseType_t status = xTaskCreate(
       task_display,          
       "Task Display",       
       configMINIMAL_STACK_SIZE, 
       NULL,                 
       tskIDLE_PRIORITY + 1, 
       &handle               
   );

   if(status != pdPASS || handle == NULL) printf("[Failed to create] | [Task 1] | [Display Printing]\n");
   else vTaskCoreAffinitySet(handle, (1 << 1)); // Set task to run on core 1
}