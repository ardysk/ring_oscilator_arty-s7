#include "uart_cmd.h"
#include "ro_regs.h"
#include "xil_printf.h"
#include "xstatus.h"

int main(void)
{
    xil_printf("\r\n=== RO Ring V3 TFT + UART ===\r\n");
    xil_printf("TFT shows freq color; UART: HELP\r\n");

    ro_set_gate(RO_GATE_5MS);
    ro_set_target_mhz(10u);
    ro_enable(1u);
    uart_cmd_init();

    while (1) {
        uart_cmd_poll();
    }

    return XST_SUCCESS;
}
