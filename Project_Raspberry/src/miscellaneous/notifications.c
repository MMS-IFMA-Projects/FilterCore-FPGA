#include "notifications.h"
#include "events.h"

void send_notification(uint8_t type, char *message){
    notification_t notification = {
        .type = type,
        .message = message
    };

    xQueueSend(queue_notifications, &notification, pdMS_TO_TICKS(50));
}