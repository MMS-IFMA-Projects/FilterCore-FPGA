#include "task_display.h"
#include "events.h"
#include "oled_environment.h"
#include "oled_prints.h"

// Screens
#include "default_screen.h"
#include "ph_screen.h"
#include "tds_screen.h"
#include "temperature_screen.h"
#include "notifications_screen.h"

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

    notification_t latest_notifications[MAX_NOTIFICATIONS];
    for(uint8_t i = 0; i < MAX_NOTIFICATIONS; i++){
        latest_notifications[i].type = INFO;
        snprintf(latest_notifications[i].message, sizeof(latest_notifications[i].message), "No notifications.");
    }

    // Screen selection loop
    while(true){
        if(xSemaphoreTake(oled_mutex, pdMS_TO_TICKS(100))){
            sensors_data_t latest_data = {0};
            bool sensors_data_available = (xQueueReceive(queue_sensors_data, &latest_data, 0) == pdPASS);

            switch(current_screen){
                case DEFAULT_SCREEN:
                    if(sensors_data_available) show_default_screen(latest_data);
                    break;

                case PH_SCREEN:
                    if(sensors_data_available) show_ph_screen(latest_data);
                    break;

                case TDS_SCREEN:
                    if(sensors_data_available) show_tds_screen(latest_data);
                    break;

                case TEMPERATURE_SCREEN:
                    if(sensors_data_available) show_temperature_screen(latest_data);
                    break;

                case NOTIFICATIONS_SCREEN:
                    notification_t notification_received;

                    while(xQueueReceive(queue_notifications, &notification_received, 0) == pdPASS){
                        // Shift existing notifications down
                        for(int i = MAX_NOTIFICATIONS - 1; i > 0; i--){
                            latest_notifications[i] = latest_notifications[i - 1];
                        }
                        // Add new notification at the top
                        latest_notifications[0] = notification_received;
                    }

                    show_notifications_screen(latest_notifications);
                    break;
                    
                default:
                    oled_clear(&oled);
                    print_text_center(&oled, "No data available", 3);
                    oled_render(&oled);
                    break;
            }

            xSemaphoreGive(oled_mutex);
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