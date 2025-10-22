#ifndef HANDSHAKE_H
#define HANDSHAKE_H

#include "events.h"

#define HANDSHAKE_TIMEOUT_MS 500
#define HANDSHAKE_MAX_RETRIES 3
#define REQ_PIN 9
#define ACK_PIN 8

void handshake_setup(void);
void handshake_request(normalized_sensors_data_t data);
bool handshake_acknowledge(void);
bool handshake_await_ack_lower(void);

extern volatile uint32_t out_mask;
extern volatile int timeout_ms;

#endif // HANDSHAKE_H