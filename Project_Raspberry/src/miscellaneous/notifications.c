#include "notifications.h"

void send_notification(notification_type_t type, char *message){
    notification_t notification = {
        .type = type,
        .message = message
    };

    xQueueSend(queue_notifications, &notification, pdMS_TO_TICKS(50));
}