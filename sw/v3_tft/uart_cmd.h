#ifndef UART_CMD_H
#define UART_CMD_H

#include "xil_types.h"

#define UART_LINE_MAX 64

void uart_cmd_init(void);
void uart_cmd_poll(void);

#endif
