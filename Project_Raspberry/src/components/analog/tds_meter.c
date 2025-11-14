#include "tds_meter.h"
#include "ads1115.h"
#include "FreeRTOS.h"
#include "task.h"

#define TDS_ADC_CHANNEL 1
#define NUM_SAMPLES 30

/**
 * @brief Calcula o valor mediano de um array de amostras.
 * @note Esta função modifica o array de entrada (ordena-o).
 * * @param samples Ponteiro para o array de amostras (será ordenado).
 * @return O valor mediano do array.
 */
static int16_t get_median_value(int16_t *samples){
    // Simple bubble sort
    for (int i = 0; i < NUM_SAMPLES - 1; i++) {
        for (int j = 0; j < NUM_SAMPLES - i - 1; j++) {
            if (samples[j] > samples[j + 1]) {
                int16_t temp = samples[j];
                samples[j] = samples[j + 1];
                samples[j + 1] = temp;
            }
        }
    }

    return samples[(NUM_SAMPLES - 1) / 2];
}

/**
 * @brief Lê o valor de TDS (Total de Sólidos Dissolvidos) em PPM.
 * * Esta função coleta 30 amostras do ADC, encontra a mediana,
 * converte para tensão, aplica compensação de temperatura e,
 * finalmente, converte a tensão compensada para PPM.
 * * @param current_temperature A temperatura atual em Celsius (tipo celsius_t)
 * para aplicar a compensação.
 * @return O valor de TDS calculado em PPM (tipo ppm_t).
 */
ppm_t tds_meter_read_ppm(celsius_t current_temperature) {
    int16_t samples[NUM_SAMPLES];

    // Collect multiple samples from the ADC to reduce noise
    for (int i = 0; i < NUM_SAMPLES; i++) {
        samples[i] = ads1115_read_adc(TDS_ADC_CHANNEL);
        vTaskDelay(pdMS_TO_TICKS(10));
    }

    // Get the median ADC value to minimize the effect of outliers
    int16_t median_adc_value = get_median_value(samples);

    // Convert ADC value to voltage
    float voltage = (float)median_adc_value * (ADS1115_VREF / ADS1115_MAX_ADC_VALUE);

    // Apply temperature compensation
    // Typical compensation coefficient for TDS meters is around 2% per degree Celsius
    float compensation_coefficient = 1.0f + 0.02f * (current_temperature - 25.0f);
    float compensated_voltage = voltage / compensation_coefficient;

    // Convert voltage to TDS in ppm
    // The formula below is based on typical TDS meter calibration
    float tds_value = (133.42f * compensated_voltage * compensated_voltage * compensated_voltage
                 - 255.86f * compensated_voltage * compensated_voltage
                 + 857.39f * compensated_voltage) * 0.5f; 

    return tds_value;
}