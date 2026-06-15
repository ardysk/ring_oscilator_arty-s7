#ifndef RO_REGS_H
#define RO_REGS_H

#include "xil_types.h"

#ifndef RO_RING_BASE
#define RO_RING_BASE 0x44A00000u
#endif

#define RO_REG_CTRL      (RO_RING_BASE + 0x00u)
#define RO_REG_FREQ      (RO_RING_BASE + 0x04u)
#define RO_REG_TUNE      (RO_RING_BASE + 0x08u)
#define RO_REG_GATE      (RO_RING_BASE + 0x0Cu)
#define RO_REG_STATUS    (RO_RING_BASE + 0x10u)
#define RO_REG_PLL       (RO_RING_BASE + 0x14u)
#define RO_REG_EDGES     (RO_RING_BASE + 0x18u)
#define RO_REG_BANK      (RO_RING_BASE + 0x1Cu)
#define RO_REG_FREQ_HZ   (RO_RING_BASE + 0x20u)
#define RO_REG_TARGET    (RO_RING_BASE + 0x24u)

#define RO_GATE_5MS      60000u
#define RO_TARGET_MIN    1u
#define RO_TARGET_MAX    511u

void ro_enable(u32 en);
void ro_set_target_mhz(u32 mhz);
u32  ro_get_target_mhz(void);
void ro_set_gate(u32 cycles);
u32  ro_measure_freq_hz(void);
u32  ro_read_status(void);
u32  ro_read_freq_hz_snap(void);

#endif
