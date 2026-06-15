#ifndef RO_REGS_H
#define RO_REGS_H

#include "xil_types.h"

#ifndef RO_RING_BASE
#define RO_RING_BASE 0x44A00000u
#endif

#define RO_REG_CTRL       (RO_RING_BASE + 0x00u)
#define RO_REG_FREQ       (RO_RING_BASE + 0x04u)
#define RO_REG_TUNE       (RO_RING_BASE + 0x08u)
#define RO_REG_GATE       (RO_RING_BASE + 0x0Cu)
#define RO_REG_STATUS     (RO_RING_BASE + 0x10u)
#define RO_REG_PLL        (RO_RING_BASE + 0x14u)
#define RO_REG_EDGES      (RO_RING_BASE + 0x18u)
#define RO_REG_BANK       (RO_RING_BASE + 0x1Cu)
#define RO_REG_FREQ_HZ    (RO_RING_BASE + 0x20u)
#define RO_REG_TARGET     (RO_RING_BASE + 0x24u)
#define RO_REG_FREQ_RING  (RO_RING_BASE + 0x28u)
#define RO_REG_EDGES_RING (RO_RING_BASE + 0x2Cu)
#define RO_REG_PRED_KHZ   (RO_RING_BASE + 0x30u)
#define RO_REG_HALF_EDGES (RO_RING_BASE + 0x34u)
#define RO_REG_ROUTE      (RO_RING_BASE + 0x38u)
#define RO_REG_DIV_CTRL   (RO_RING_BASE + 0x3Cu)

#define RO_STATUS_BUSY      (1u << 0)
#define RO_STATUS_DONE      (1u << 1)
#define RO_STATUS_RING_DONE (1u << 2)
#define RO_STATUS_OUT_DONE  (1u << 3)

#define RO_GATE_5MS         60000u
#define RO_MEAS_TIMEOUT     1500000u
#define RO_MEAS_SETTLE      20000u
#define RO_BANK_SETTLE      50000u
#define RO_CAL_STEPS        16u
#define RO_HALF_EDGES_MAX   50000000u
#define RO_EDGES_MAX        1048575u

#define RO_CAL_BANK_COUNT   16
#define RO_BANK_HW_B1       10u
#define RO_BANK_HW_B2       0u
#define RO_BANK_HW_B3       3u
#define RO_BANK_HW_B4       1u
#define RO_BANK_HW_B5       2u
#define RO_BANK_HW_B6       4u
#define RO_BANK_HW_B7       7u
#define RO_BANK_HW_B8       8u
#define RO_BANK_HW_B9       5u
#define RO_BANK_HW_B10      9u
#define RO_BANK_HW_B11      11u
#define RO_BANK_HW_B12      6u
#define RO_BANK_HW_B13      12u
#define RO_BANK_HW_B14      13u
#define RO_BANK_HW_B15      14u
#define RO_BANK_HW_B16      15u

extern const u8 ro_cal_bank_ids[RO_CAL_BANK_COUNT];

typedef struct {
    u32 hz;
    u32 tune;
    u32 last_edges;
    u32 last_hz;
    u8  valid;
} ro_cal_entry_t;

extern ro_cal_entry_t ro_cal_table[RO_CAL_BANK_COUNT];

void ro_enable(u32 en);
void ro_set_gate(u32 cycles);
void ro_set_bank(u32 bank);
void ro_set_tune(u32 tune12);
u32  ro_get_tune(void);
void ro_set_half_edges(u32 half, u32 bypass);
u32  ro_get_half_edges(void);
u32  ro_get_bank_active(void);
u32  ro_get_route_bank(void);
u32  ro_div_bypass_active(void);
u32  ro_cal_hz_for_bank(u32 bank);
u32  ro_cal_tune_for_bank(u32 bank);

int  ro_pulse_measure(void);
int  ro_measure_output_hz(u32 *freq_hz);
int  ro_measure_bank_hz(u32 bank, u32 *freq_hz);

int  ro_cal_run_all(void);
int  ro_cal_bank(int idx);
void ro_cal_clear(void);
int  ro_set_output_hz(u32 target_hz);
int  ro_preview_bank(u32 bank);

int  ro_scan_bank(u32 bank, u32 *best_tune, u32 *best_hz);
int  ro_fast_scan_bank(u32 bank, u32 *best_tune, u32 *best_hz);
int  ro_store_cal(u32 bank, u32 tune, u32 hz);

u32  ro_read_status(void);
u32  ro_read_pll_locked(void);

u32         ro_hw_from_logical(u32 b);
const char *ro_label_from_hw(u32 hw);
const char *ro_label_from_logical(u32 logical);

#endif
