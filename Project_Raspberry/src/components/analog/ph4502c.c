#include "ph4502c.h"
#include "ads1115.h"
#include "FreeRTOS.h"
#include "task.h"
#include <stdio.h>


#define PH_ADC_CHANNEL 0
#define NUM_SAMPLES 10
#define CALIBRATION_OFFSET 58.2470f
#define VOLTS_TO_PH_SLOPE -20.4082f

static void sort_samples(int16_t* samples) {
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
}

// Calibration
static float ph4502c_read_voltage(void) {
    int16_t samples[NUM_SAMPLES];
    int32_t total_raw_adc = 0;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        samples[i] = ads1115_read_adc(PH_ADC_CHANNEL);
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    sort_samples(samples);
    for (int i = 2; i < NUM_SAMPLES - 2; i++) {
        total_raw_adc += samples[i];
    }
    int16_t avg_sample = total_raw_adc / (NUM_SAMPLES - 4);
    float voltage = (float)avg_sample * (ADS1115_VREF / ADS1115_MAX_ADC_VALUE);

    // Imprima a tensão para você ver no console
    printf("Tensão do ADC: %.4f V\n", voltage);

    return voltage;
}

static void ph4502c_calibrate(void) {
    float acid_ph = 4.2f; //replace with acid pH
    float base_ph = 6.9f; //replace with base pH

    ph4502c_read_voltage();

    float voltage_at_acid_ph = 2.6532f; //replace with voltage at acid pH
    float voltage_at_base_ph = 2.5160f; //replace with voltage at base pH

    float slope = (base_ph - acid_ph) / (voltage_at_base_ph - voltage_at_acid_ph);
    float offset = acid_ph - (slope * voltage_at_acid_ph);

    printf("Slope: %.4f\n", slope);
    printf("Offset: %.4f\n", offset);
}

ph_t ph4502c_read_ph(void) {
    int16_t samples[NUM_SAMPLES];
    int32_t total_raw_adc = 0;
    
    // Collects multiple samples from the ADC to reduce noise
    for (int i = 0; i < NUM_SAMPLES; i++) {
        samples[i] = ads1115_read_adc(PH_ADC_CHANNEL);
        vTaskDelay(pdMS_TO_TICKS(10));
    }

    // Sort the samples so we can discard the highest and lowest ones.
    sort_samples(samples);
    
    // Calculate the average, discarding the lowest 20% and highest 20%.
    for (int i = 2; i < NUM_SAMPLES - 2; i++) {
        total_raw_adc += samples[i];
    }

    int16_t avg_sample = total_raw_adc / (NUM_SAMPLES - 4);

    // Convert the average ADC value to voltage.
    float voltage = (float)avg_sample * (ADS1115_VREF / ADS1115_MAX_ADC_VALUE);

    // Convert the voltage to the pH value using the linear formula
    ph_t ph_value = (VOLTS_TO_PH_SLOPE * voltage) + CALIBRATION_OFFSET;

    return ph_value;
}