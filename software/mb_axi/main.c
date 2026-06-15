/*
 * MicroBlaze + pierścień RO — TARGET [MHz], FREQ_HZ na UART USB 115200 (xil_printf).
 * BSP: stdin/stdout = axi_uartlite_0
 */
#include "xil_io.h"
#include "xil_printf.h"
#include "xstatus.h"

#ifndef RO_RING_BASE
#define RO_RING_BASE 0x44A00000u
#endif

#define RO_REG_CTRL      (RO_RING_BASE + 0x00u)
#define RO_REG_GATE      (RO_RING_BASE + 0x0Cu)
#define RO_REG_STATUS    (RO_RING_BASE + 0x10u)
#define RO_REG_FREQ_HZ   (RO_RING_BASE + 0x20u)
#define RO_REG_TARGET    (RO_RING_BASE + 0x24u)

#define RO_GATE_5MS      60000u

static void ro_set_target_mhz(unsigned mhz)
{
    if (mhz < 1u) mhz = 1u;
    if (mhz > 511u) mhz = 511u;
    Xil_Out32(RO_REG_TARGET, mhz);
}

static void ro_enable(unsigned en)
{
    Xil_Out32(RO_REG_CTRL, en & 1u);
}

static unsigned ro_measure_freq_hz(void)
{
    volatile unsigned st;

    Xil_Out32(RO_REG_CTRL, 1u);
    Xil_Out32(RO_REG_CTRL, 3u);
    Xil_Out32(RO_REG_CTRL, 1u);

    do {
        st = (unsigned)Xil_In32(RO_REG_STATUS);
    } while (((st >> 1) & 1u) == 0u);

    Xil_Out32(RO_REG_STATUS, 2u);

    return (unsigned)Xil_In32(RO_REG_FREQ_HZ);
}

int main(void)
{
    unsigned target_mhz = 25u;
    unsigned f_hz;

    xil_printf("RO ring: init\r\n");

    Xil_Out32(RO_REG_GATE, RO_GATE_5MS);
    ro_set_target_mhz(target_mhz);
    ro_enable(1u);

    xil_printf("target=%u MHz, bramka=%u\r\n", target_mhz, RO_GATE_5MS);

    while (1) {
        f_hz = ro_measure_freq_hz();
        xil_printf("f=%u Hz\r\n", f_hz);

        for (volatile int i = 0; i < 2000000; i++) {
        }
    }

    return XST_SUCCESS;
}
