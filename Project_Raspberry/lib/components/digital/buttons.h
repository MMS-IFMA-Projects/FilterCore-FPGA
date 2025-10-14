#ifndef BUTTONS_H
#define BUTTONS_H

#include "pico/stdlib.h"

//Tipagem para definir o botão
typedef enum{
    BUTTON_A,
    BUTTON_B,
    BUTTON_SW
} button_id_t;

//Estrutura para dados do botão
typedef struct{
    button_id_t button;
    bool pressioned;
} button_data_t;

void init_button_a();
void init_button_b();
void init_button_sw();
bool get_button_a();
bool get_button_b();
bool get_button_sw();

#endif //BUTTONS_H