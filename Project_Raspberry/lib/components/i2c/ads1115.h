#ifndef ADS1115_H
#define ADS1115_H

#include "i2c_configs.h"

#define ADS1115_VREF 4.096f
#define ADS1115_MAX_ADC_VALUE 32767.0f

int16_t ads1115_read_adc(uint8_t channel);


#endif //ADS1115_H