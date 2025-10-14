#ifndef I2C_CONFIGS_H
#define I2C_CONFIGS_H

#include "hardware/i2c.h"
#include "pico/stdlib.h"

// --- Pinos de I2C ---
#define I2C_PORT i2c1
#define I2C_SDA_PIN 2
#define I2C_SCL_PIN 3

void i2c_configs();


#endif //I2C_CONFIGS_H