#include "sensor_analyzer.h"
#include "sensor_configs.h"
#include "notifications.h"

/**
 * @brief Armazena o estado normalizado (alertas) da leitura anterior.
 * @note Usado para detectar mudanças de estado (ex: transição de 'normal' para 'alerta')
 * e enviar notificações apenas uma vez por evento.
 */
static normalized_sensors_data_t prev_normalized_data = {0};

/**
 * @brief Verifica se a temperatura está fora dos limites seguros.
 * * @param temperature O valor da temperatura em Celsius.
 * @return true se a temperatura estiver abaixo do mínimo ou acima do máximo,
 * false caso contrário.
 */
bool analyzer_is_temperature_alert(celsius_t temperature){
    return temperature < MIN_TEMPERATURE_CELSIUS || temperature > MAX_TEMPERATURE_CELSIUS;
}

/**
 * @brief Verifica se o pH está fora dos limites seguros.
 * * @param ph O valor do pH.
 * @return true se o pH estiver abaixo do mínimo ou acima do máximo,
 * false caso contrário.
 */
bool analyzer_is_ph_alert(ph_t ph){
    return ph < MIN_PH || ph > MAX_PH;
}

/**
 * @brief Verifica se o TDS está acima do limite máximo permitido.
 * @note O limite máximo de TDS é dinâmico e depende dos valores
 * atuais de temperatura e pH, conforme as faixas definidas.
 * * @param data Estrutura (sensors_data_t) contendo os valores brutos
 * de tds, ph e temperatura.
 * @return true se o TDS estiver acima do limite máximo calculado,
 * false caso contrário.
 */
bool analyzer_is_tds_alert(sensors_data_t data){
    ppm_t max_tds = MAX_DEFAULT_TDS;

    if (data.temperature >= MIN_TEMPERATURE_CELSIUS && data.temperature <= MAX_TEMPERATURE_CELSIUS) {
        if (data.ph >= MIN_PH && data.ph < (MIN_PH + PH_FACTOR))
            max_tds = (-16.67f * data.temperature) + 1300.0f;
        if (data.ph >= (MIN_PH + PH_FACTOR) && data.ph < (MIN_PH + (PH_FACTOR * 3)))
            max_tds = (-33.33f * data.temperature) + 1575.0f;
        if (data.ph >= (MIN_PH + (PH_FACTOR * 3)) && data.ph <= MAX_PH)
            max_tds = (-16.67f * data.temperature) + 950.0f;
    }

    return (data.tds > max_tds);
}

/**
 * @brief Inicializa o estado do analisador.
 * @note Zera a estrutura 'prev_normalized_data' para garantir que
 * a primeira análise de dados funcione corretamente.
 */
void analyzer_init(void){
    prev_normalized_data.temperature = 0;
    prev_normalized_data.ph = 0;
    prev_normalized_data.tds = 0;
    prev_normalized_data.button_state = 0;
}

/**
 * @brief Processa os dados brutos dos sensores e gera dados normalizados (alertas).
 * @note Esta função converte os valores dos sensores em estados binários (alerta/normal)
 * e compara com o estado anterior (prev_normalized_data) para enviar
 * notificações apenas na transição de normal para alerta.
 * * @param data Estrutura (sensors_data_t) com os valores brutos atuais dos sensores.
 * @return Uma estrutura (normalized_sensors_data_t) com os estados
 * binários de alerta para cada sensor.
 */
normalized_sensors_data_t analyzer_process_data(sensors_data_t data){
    normalized_sensors_data_t new_data;

    new_data.temperature = analyzer_is_temperature_alert(data.temperature);
    new_data.ph = analyzer_is_ph_alert(data.ph);
    new_data.tds = analyzer_is_tds_alert(data);
    new_data.button_state = data.button_state;

    if (new_data.temperature && !prev_normalized_data.temperature) {
        if (data.temperature < MIN_TEMPERATURE_CELSIUS) {
            send_notification(ALERT, "Temp Low!");
        } else {
            send_notification(ALERT, "Temp High!");
        }
    }

    if (new_data.ph && !prev_normalized_data.ph) {
        if (data.ph < MIN_PH) {
            send_notification(ALERT, "PH Acidic!");
        } else {
            send_notification(ALERT, "PH Alkaline!");
        }
    }

    if (new_data.tds && !prev_normalized_data.tds) {
        send_notification(ALERT, "TDS High!");
    }

    prev_normalized_data = new_data;

    return new_data;
}