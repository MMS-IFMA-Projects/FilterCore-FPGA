#include "events.h"
#include "i2c_configs.h"
#include "oled_display.h"

int main(){
    stdio_init_all();

    i2c0_configs(I2C_BAUDRATE_DEFAULT);

    // if(!oled_init(&oled)){
    //     printf("Erro ao iniciar o display OLED!\n");
    //     while(true);
    // }

    while(true);
}