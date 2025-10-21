#include "events.h"
#include "i2c_configs.h"
#include "oled_environment.h"

QueueHandle_t queue_sensors_data = NULL;
QueueHandle_t queue_normalized_sensors_data = NULL;
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

    // Creates queue for sensors data
    queue_sensors_data = xQueueCreate(MAX_SENSORS_DATA, sizeof(sensors_data_t));
    if(queue_sensors_data == NULL){
        printf("Error creating sensor data queue!\n");
        while(true);
    }

    // Creates queue for normalized sensors data
    queue_normalized_sensors_data = xQueueCreate(MAX_SENSORS_DATA, sizeof(normalized_sensors_data_t));
    if(queue_normalized_sensors_data == NULL){
        printf("Error creating sensor data queue!\n");
        while(true);
    }

    // Creates queue for notifications
    queue_notifications = xQueueCreate(MAX_NOTIFICATIONS, sizeof(notification_t));
    if(queue_notifications == NULL){
        printf("Error creating notifications queue!\n");
        while(true);
    }

    while(true);
}