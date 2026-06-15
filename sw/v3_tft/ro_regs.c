#include "ro_regs.h"
#include "xil_io.h"

void ro_enable(u32 en)
{
    Xil_Out32(RO_REG_CTRL, en & 1u);
}

void ro_set_target_mhz(u32 mhz)
{
    if (mhz < RO_TARGET_MIN) mhz = RO_TARGET_MIN;
    if (mhz > RO_TARGET_MAX) mhz = RO_TARGET_MAX;
    Xil_Out32(RO_REG_TARGET, mhz);
}

u32 ro_get_target_mhz(void)
{
    return (u32)Xil_In32(RO_REG_TARGET);
}

void ro_set_gate(u32 cycles)
{
    if (cycles == 0u) cycles = RO_GATE_5MS;
    Xil_Out32(RO_REG_GATE, cycles);
}

u32 ro_measure_freq_hz(void)
{
    volatile u32 st;

    Xil_Out32(RO_REG_CTRL, 1u);
    Xil_Out32(RO_REG_CTRL, 3u);
    Xil_Out32(RO_REG_CTRL, 1u);

    do {
        st = (u32)Xil_In32(RO_REG_STATUS);
    } while (((st >> 1) & 1u) == 0u);

    Xil_Out32(RO_REG_STATUS, 2u);

    return (u32)Xil_In32(RO_REG_FREQ_HZ);
}

u32 ro_read_status(void)
{
    return (u32)Xil_In32(RO_REG_STATUS);
}

u32 ro_read_freq_hz_snap(void)
{
    return (u32)Xil_In32(RO_REG_FREQ_HZ);
}
