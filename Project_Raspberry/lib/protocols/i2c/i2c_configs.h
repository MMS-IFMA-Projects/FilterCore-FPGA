#ifndef I2C_CONFIGS_H
#define I2C_CONFIGS_H

#include "hardware/i2c.h"
#include "pico/stdlib.h"

// --- Pinos de I2C0 ---
#define I2C0_PORT i2c0
#define I2C0_SDA_PIN 0
#define I2C0_SCL_PIN 1

// --- Pinos de I2C1 ---
#define I2C1_PORT i2c1
#define I2C1_SDA_PIN 14
#define I2C1_SCL_PIN 15

#define I2C_BAUDRATE_DEFAULT 400000

void i2c0_configs(uint baudrate);

void i2c1_configs(uint baudrate);


#endif //I2C_CONFIGS_H