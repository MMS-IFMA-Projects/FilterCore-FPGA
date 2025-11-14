#include "task_sensors.h"
#include "events.h"
#include "ds18b20.h"
#include "ph4502c.h"
#include "tds_meter.h"
#include "buttons.h"
#include "notifications.h"
#include "sensor_analyzer.h"

#define SENSORS_INTERVAL_MS 125

/**
 * @brief Função da task principal para leitura e processamento de sensores.
 * @note Esta task é responsável por:
 * 1. Ler os valores de todos os sensores (Temperatura, pH, TDS) e do botão A.
 * 2. Agrupar os dados brutos na estrutura 'sensors_data_t'.
 * 3. Chamar 'analyzer_process_data' para gerar dados normalizados (alertas).
 * 4. Enviar os dados brutos para 'queue_sensors_data' (para o display).
 * 5. Enviar os dados normalizados para 'queue_normalized_sensors_data' (para o handshake).
 * 6. Atrasar (vTaskDelay) antes de repetir.
 * * @param params Parâmetros de inicialização da task (não utilizados).
 */
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
        xQueueOverwrite(queue_sensors_data, &data);

        // Sending normalized data to the queue
        xQueueOverwrite(queue_normalized_sensors_data, &normalized_data);

        vTaskDelay(pdMS_TO_TICKS(SENSORS_INTERVAL_MS));
    }
}

/**
 * @brief Cria e inicia a task de leitura de sensores (task_sensors).
 * @note Inicializa o botão A antes de criar a task.
 * A task é criada com alta prioridade (IDLE + 4) e afinidade com o Core 0.
 */
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