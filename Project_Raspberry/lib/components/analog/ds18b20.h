#ifndef DS18B20_H
#define DS18B20_H

#include "units.h"

#define DS18B20_PIN 18 // gpio pin where the DS18B20 is connected

celsius_t ds18b20_read_temperature(void);

#endif // Temperature sensor DS18B20