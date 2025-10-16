#include "events.h"
#include "i2c_configs.h"
#include "oled_environment.h"

TaskHandle_t handle_display = NULL;
QueueHandle_t queue_sensors_data = NULL;
QueueHandle_t queue_notifications = NULL;

int main(){
    stdio_init_all();

    i2c0_configs(I2C_BAUDRATE_DEFAULT);

    // Initializes the OLED display
    if(!oled_init(&oled)){
        printf("Error starting OLED display!\n");
        while(true);
    }

    // Creates mutex for shared use of OLED
    oled_mutex = xSemaphoreCreateMutex();
    if(oled_mutex == NULL){
        printf("Error creating OLED display mutex!\n");
        while(true);
    }

    while(true);
}