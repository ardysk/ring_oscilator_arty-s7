#ifndef UART_CMD_H
#define UART_CMD_H

#define UART_LINE_MAX 80
#define UART_HIST_MAX 16

void uart_cmd_init(void);
void uart_cmd_poll(void);

#endif
