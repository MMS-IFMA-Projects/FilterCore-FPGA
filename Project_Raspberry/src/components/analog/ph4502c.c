#include "ph4502c.h"
#include "ads1115.h"
#include "FreeRTOS.h"
#include "task.h"

#define PH_ADC_CHANNEL 0
#define NUM_SAMPLES 10
#define CALIBRATION_OFFSET 20.5f
#define VOLTS_TO_PH_SLOPE -5.70f

static void sort_samples(int16_t* samples, int num_samples) {
    for (int i = 0; i < num_samples - 1; i++) {
        for (int j = 0; j < num_samples - i - 1; j++) {
            if (samples[j] > samples[j + 1]) {
                int16_t temp = samples[j];
                samples[j] = samples[j + 1];
                samples[j + 1] = temp;
            }
        }
    }
}

ph_t ph4502c_read_ph(void) {
    int16_t samples[NUM_SAMPLES];
    int32_t total_raw_adc = 0;

    // Collects multiple samples from the ADC to reduce noise
    for (int i = 0; i < NUM_SAMPLES; i++) {
        samples[i] = ads1115_read_channel(PH_ADC_CHANNEL);
        vTaskDelay(pdMS_TO_TICKS(10));
    }

    // Sort the samples so we can discard the highest and lowest ones.
    sort_samples(samples, NUM_SAMPLES);
    
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