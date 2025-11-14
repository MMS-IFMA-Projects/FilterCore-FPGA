#include "task_pagination.h"
#include "events.h"
#include "buttons.h"
#include "oled_environment.h"


#define PAGINATION_INTERVAL_MS 125

/**
 * @brief Função da task para gerenciar a paginação do display.
 * @note Esta task monitora o botão B (com debounce simples/detecção de borda)
 * para circular entre as telas.
 * 1. Lê o estado do botão B.
 * 2. Se o botão for pressionado (transição de solto para pressionado),
 * incrementa a variável global 'current_screen'.
 * 3. Usa o operador módulo (%) para garantir que 'current_screen'
 * retorne a 0 após a última tela (TOTAL_SCREENS).
 * 4. Atrasar (vTaskDelay) antes de repetir.
 * * @param params Parâmetros de inicialização da task (não utilizados).
 */
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

/**
 * @brief Cria e inicia a task de paginação (task_pagination).
 * @note Inicializa o botão B antes de criar a task.
 * A task é criada com prioridade (IDLE + 3) e afinidade com o Core 0.
 */
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