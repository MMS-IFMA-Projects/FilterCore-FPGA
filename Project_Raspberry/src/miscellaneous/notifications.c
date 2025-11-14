#include "notifications.h"

/**
 * @brief Envia uma notificação para a fila de notificações do FreeRTOS.
 * @note Esta é uma função wrapper que formata a estrutura 'notification_t'
 * e a envia para a fila global 'queue_notifications' de forma segura
 * (com timeout de 50ms).
 * * @param type O tipo de notificação (INFO, ALERT, ERROR).
 * @param message Uma string (char*) contendo a mensagem da notificação.
 */
void send_notification(notification_type_t type, char *message){
    notification_t notification = {
        .type = type,
        .message = message
    };

    xQueueSend(queue_notifications, &notification, pdMS_TO_TICKS(50));
}