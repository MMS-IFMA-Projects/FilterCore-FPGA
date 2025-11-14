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
#include "notifications.h"

#define DISPLAY_INTERVAL_MS 250

/**
 * @brief Função da task principal para gerenciar o display OLED.
 * @note Esta task é responsável por:
 * 1. Obter o mutex do OLED para acesso seguro.
 * 2. Verificar a variável global 'current_screen' para decidir qual tela renderizar.
 * 3. Tentar ler os dados mais recentes da 'queue_sensors_data' (sem bloquear).
 * 4. Chamar a função 'show_...' apropriada para desenhar a tela.
 * 5. Na tela de notificação, consome itens da 'queue_notifications' e os exibe.
 * 6. Liberar o mutex e atrasar (vTaskDelay) antes de repetir.
 * * @param params Parâmetros de inicialização da task (não utilizados).
 */
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
        send_notification(INFO, "No data");
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

/**
 * @brief Cria e inicia a task de gerenciamento do display (task_display).
 * @note A task é criada com prioridade (IDLE + 2) e afinidade com o Core 1.
 */
void create_task_display(void) {
   TaskHandle_t handle;
   BaseType_t status = xTaskCreate(
       task_display,          
       "Task Display",       
       configMINIMAL_STACK_SIZE * 4, 
       NULL,                 
       tskIDLE_PRIORITY + 2, 
       &handle               
   );

   if(status != pdPASS || handle == NULL) printf("[Failed to create] | [Task 1] | [Display Printing]\n");
   else vTaskCoreAffinitySet(handle, (1 << 1)); // Set task to run on core 1
}