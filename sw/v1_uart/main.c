#include "uart_cmd.h"
#include "xil_printf.h"

int main(void)
{
    uart_cmd_init();
    for (;;) {
        uart_cmd_poll();
    }
    return 0;
}
