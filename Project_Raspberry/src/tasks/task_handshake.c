#include "task_handshake.h"
#include "handshake.h"
#include "notifications.h"

#define HANDSHAKE_INTERVAL_MS 250

/**
 * @brief Função da task principal para comunicação via handshake com o FPGA.
 * @note Esta task é responsável por:
 * 1. Inicializar e resetar o FPGA ('reset_fpga_setup', 'handshake_setup').
 * 2. Bloquear aguardando dados na 'queue_normalized_sensors_data'.
 * 3. Ao receber dados, executar o protocolo de handshake (Request, Wait for ACK).
 * 4. Tentar novamente (até HANDSHAKE_MAX_RETRIES) em caso de falha no ACK.
 * 5. Enviar notificações de sucesso ou falha na comunicação.
 * 6. Atrasar (vTaskDelay) antes de aguardar os próximos dados.
 * * @param params Parâmetros de inicialização da task (não utilizados).
 */
static void task_handshake(void *params){
    printf("[Started] | [Task 4] | [Handshake]\n");

    // Reset FPGA setup
    reset_fpga_setup();

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
            else send_notification(INFO, "HS Success!");
        }
        vTaskDelay(pdMS_TO_TICKS(HANDSHAKE_INTERVAL_MS));
    }
}

/**
 * @brief Cria e inicia a task de handshake com o FPGA (task_handshake).
 * @note A task é criada com prioridade (IDLE + 2) e afinidade com o Core 1.
 */
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