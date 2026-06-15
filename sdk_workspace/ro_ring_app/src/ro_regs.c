#include "ro_regs.h"
#include "ro_tune_presets.h"
#include "xil_io.h"

const u8 ro_cal_bank_ids[RO_CAL_BANK_COUNT] = {
    RO_BANK_HW_B1, RO_BANK_HW_B2, RO_BANK_HW_B3, RO_BANK_HW_B4,
    RO_BANK_HW_B5, RO_BANK_HW_B6, RO_BANK_HW_B7, RO_BANK_HW_B8,
    RO_BANK_HW_B9, RO_BANK_HW_B10, RO_BANK_HW_B11, RO_BANK_HW_B12,
    RO_BANK_HW_B13, RO_BANK_HW_B14, RO_BANK_HW_B15, RO_BANK_HW_B16
};

static const struct {
    u8         logical;
    u8         hw;
    const char *label;
} ro_logical_map[RO_CAL_BANK_COUNT] = {
    { 1u,  RO_BANK_HW_B1,  "B1" },
    { 2u,  RO_BANK_HW_B2,  "B2" },
    { 3u,  RO_BANK_HW_B3,  "B3" },
    { 4u,  RO_BANK_HW_B4,  "B4" },
    { 5u,  RO_BANK_HW_B5,  "B5" },
    { 6u,  RO_BANK_HW_B6,  "B6" },
    { 7u,  RO_BANK_HW_B7,  "B7" },
    { 8u,  RO_BANK_HW_B8,  "B8" },
    { 9u,  RO_BANK_HW_B9,  "B9" },
    { 10u, RO_BANK_HW_B10, "B10" },
    { 11u, RO_BANK_HW_B11, "B11" },
    { 12u, RO_BANK_HW_B12, "B12" },
    { 13u, RO_BANK_HW_B13, "B13" },
    { 14u, RO_BANK_HW_B14, "B14" },
    { 15u, RO_BANK_HW_B15, "B15" },
    { 16u, RO_BANK_HW_B16, "B16" },
};

u32 ro_hw_from_logical(u32 b)
{
    int i;
    if (b >= 1u && b <= RO_CAL_BANK_COUNT)
        return (u32)ro_logical_map[b - 1u].hw;
    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        if ((u32)ro_logical_map[i].hw == b)
            return b;
    }
    return b;
}

const char *ro_label_from_hw(u32 hw)
{
    int i;
    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        if ((u32)ro_logical_map[i].hw == hw)
            return ro_logical_map[i].label;
    }
    return "?";
}

const char *ro_label_from_logical(u32 logical)
{
    if (logical >= 1u && logical <= RO_CAL_BANK_COUNT)
        return ro_logical_map[logical - 1u].label;
    return "?";
}

ro_cal_entry_t ro_cal_table[RO_CAL_BANK_COUNT];

static u32 ro_last_route_bank;

static u16 ro_preset_tune_for_bank(u32 bank)
{
    int i;
    for (i = 0; i < RO_PRESET_BANK_COUNT; i++) {
        if ((u32)RO_TUNE_PRESETS[i].bank == bank)
            return RO_TUNE_PRESETS[i].tune;
    }
    return 0u;
}

static const u32 ro_bank_f_min[RO_CAL_BANK_COUNT] = {
    30000000u, 30000000u, 20000000u, 15000000u, 12000000u, 8000000u,
    5000000u,  4000000u,  5000000u,  2000000u,  1000000u,  200000u,
    150000u,   100000u,   80000u,    60000u
};

static const u32 ro_bank_f_max[RO_CAL_BANK_COUNT] = {
    300000000u, 250000000u, 90000000u, 80000000u, 70000000u, 55000000u,
    45000000u,  35000000u,  55000000u,  40000000u,  35000000u,  5000000u,
    5000000u,   2000000u,   1500000u,   1000000u
};

static u32 ro_status(void)
{
    return (u32)Xil_In32(RO_REG_STATUS);
}

static u32 ro_scale_for_bank(u32 bank)
{
    switch (bank) {
    case RO_BANK_HW_B1:
    case RO_BANK_HW_B2: return 1024u;
    case RO_BANK_HW_B3:
    case RO_BANK_HW_B4:
    case RO_BANK_HW_B5: return 256u;
    case RO_BANK_HW_B6:
    case RO_BANK_HW_B7:
    case RO_BANK_HW_B8: return 64u;
    case RO_BANK_HW_B9:
    case RO_BANK_HW_B10:
    case RO_BANK_HW_B11: return 16u;
    case RO_BANK_HW_B12:
    case RO_BANK_HW_B13:
    case RO_BANK_HW_B14:
    case RO_BANK_HW_B15:
    case RO_BANK_HW_B16: return 512u;
    default:             return 64u;
    }
}

static u32 ro_hz_from_edges_raw(u32 edges)
{
    if (edges == 0u)
        return 0u;
    return (u32)(((u64)edges * 12000000u) / (u64)RO_GATE_5MS);
}

static u32 ro_hz_from_edges(u32 edges, u32 scale)
{
    u64 num;
    if (edges == 0u)
        return 0u;
    num = (u64)edges * 12000000u * (u64)scale;
    return (u32)(num / (u64)RO_GATE_5MS);
}

static int ro_find_cal_index(u32 bank)
{
    int i;
    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        if ((u32)ro_cal_bank_ids[i] == bank)
            return i;
    }
    return -1;
}

static int ro_hz_in_band(u32 bank, u32 hz)
{
    int idx = ro_find_cal_index(bank);
    if (idx < 0 || hz == 0u)
        return 0;
    return (hz >= ro_bank_f_min[idx] && hz <= ro_bank_f_max[idx]) ? 1 : 0;
}

static u32 ro_reconstruct_ring_hz(u32 bank, u32 edges)
{
    return ro_hz_from_edges(edges, ro_scale_for_bank(bank));
}

static int ro_hz_ok_for_cal(u32 bank, u32 hz)
{
    int idx;

    if (hz == 0u)
        return 0;
    idx = ro_find_cal_index(bank);
    if (idx >= 9)
        return (hz <= ro_bank_f_max[idx]) ? 1 : 0;
    if (bank == RO_BANK_HW_B9)
        return (hz >= 5000000u && hz <= 55000000u) ? 1 : 0;
    return ro_hz_in_band(bank, hz);
}

static int ro_bank_is_chain(u32 bank)
{
    switch (bank) {
    case RO_BANK_HW_B12:
    case RO_BANK_HW_B13:
    case RO_BANK_HW_B14:
    case RO_BANK_HW_B15:
    case RO_BANK_HW_B16:
        return 1;
    default:
        return 0;
    }
}

static int ro_bank_full_tune_scan(u32 bank)
{
    switch (bank) {
    case RO_BANK_HW_B6:
    case RO_BANK_HW_B7:
    case RO_BANK_HW_B8:
    case RO_BANK_HW_B9:
    case RO_BANK_HW_B10:
    case RO_BANK_HW_B11:
        return 1;
    default:
        return 0;
    }
}

static int ro_edges_sane(u32 edges)
{
    return (edges >= 1u && edges <= RO_EDGES_MAX) ? 1 : 0;
}

static u32 ro_read_ring_hz_for_bank(u32 bank)
{
    u32 e = (u32)Xil_In32(RO_REG_EDGES_RING);
    u32 scale = ro_scale_for_bank(bank);
    u32 f_hz;
    u32 f_raw;

    if (!ro_edges_sane(e))
        return 0u;

    f_hz = ro_hz_from_edges(e, scale);
    if (ro_hz_in_band(bank, f_hz))
        return f_hz;

    if (ro_bank_is_chain(bank)) {
        f_raw = ro_hz_from_edges_raw(e) * scale;
        if (ro_hz_ok_for_cal(bank, f_raw))
            return f_raw;
    }
    return 0u;
}

static u32 ro_abs_diff(u32 a, u32 b)
{
    return (a >= b) ? (a - b) : (b - a);
}

static u32 ro_read_out_hz_raw(void)
{
    u32 e = (u32)Xil_In32(RO_REG_EDGES);
    if (e == 0u)
        return 0u;
    return ro_hz_from_edges_raw(e);
}

static u32 ro_predict_output_hz(void)
{
    u32 bank = ro_last_route_bank;
    u32 fcal;
    u32 half;
    u32 bypass;

    if (bank == 0u)
        bank = ro_get_bank_active();
    fcal = ro_cal_hz_for_bank(bank);
    if (fcal == 0u)
        return 0u;

    half = ro_get_half_edges();
    if (half < 1u)
        half = 1u;
    return fcal / (2u * half);
}

static u32 ro_best_half_edges(u32 fbank, u32 target_hz, u32 *bypass_out)
{
    u64 half64;
    u32 half;
    u32 best_half;
    u32 best_err = 0xFFFFFFFFu;
    int h;

    if (bypass_out)
        *bypass_out = 0u;

    if (target_hz >= fbank)
        return 1u;
    half64 = ((u64)fbank + (u64)target_hz) / ((u64)target_hz * 2u);
    if (half64 < 1u)
        half64 = 1u;
    if (half64 > (u64)RO_HALF_EDGES_MAX)
        half64 = (u64)RO_HALF_EDGES_MAX;
    half = (u32)half64;
    best_half = half;

    for (h = -3; h <= 3; h++) {
        u32 th;
        u32 f_out;
        u32 err;
        int hi = (int)half + h;

        if (hi < 1)
            continue;
        if (hi > (int)RO_HALF_EDGES_MAX)
            continue;
        th = (u32)hi;
        f_out = fbank / (2u * th);
        err = ro_abs_diff(f_out, target_hz);
        if (err < best_err) {
            best_err = err;
            best_half = th;
        }
    }
    return best_half;
}

static u32 ro_achievable_hz(u32 fbank, u32 target_hz, u32 *half_out, u32 *bypass_out)
{
    u32 half = ro_best_half_edges(fbank, target_hz, bypass_out);

    if (half_out)
        *half_out = half;
    if (half < 1u)
        half = 1u;
    return fbank / (2u * half);
}

static void ro_meas_settle(void)
{
    volatile u32 d;
    for (d = 0; d < RO_MEAS_SETTLE; d++) { }
}

static void ro_bank_settle(void)
{
    volatile u32 d;
    for (d = 0; d < RO_BANK_SETTLE; d++) { }
}

static int ro_wait_measure(u32 done_mask)
{
    u32 st;
    u32 timeout = RO_MEAS_TIMEOUT;
    u32 saw_busy = 0u;
    u32 settle;

    while (timeout--) {
        st = ro_status();
        if ((st & done_mask) != 0u)
            return 1;
        if ((st & RO_STATUS_BUSY) != 0u)
            saw_busy = 1u;
        else if (saw_busy)
            break;
    }

    for (settle = 0u; settle < 80000u; settle++) {
        st = ro_status();
        if ((st & done_mask) != 0u)
            return 1;
    }
    return ((ro_status() & done_mask) != 0u) ? 1 : 0;
}

static int ro_arm_measure_ring(void)
{
    Xil_Out32(RO_REG_STATUS, 2u);
    Xil_Out32(RO_REG_CTRL, 1u);
    ro_meas_settle();
    Xil_Out32(RO_REG_CTRL, 3u);

    if (!ro_wait_measure(RO_STATUS_RING_DONE))
        goto fail;

    ro_meas_settle();
    Xil_Out32(RO_REG_CTRL, 1u);

    if ((ro_status() & RO_STATUS_RING_DONE) == 0u)
        goto fail;
    if (!ro_edges_sane((u32)Xil_In32(RO_REG_EDGES_RING)))
        goto fail;
    return 1;

fail:
    Xil_Out32(RO_REG_CTRL, 1u);
    return 0;
}

static int ro_arm_measure_out(void)
{
    Xil_Out32(RO_REG_STATUS, 2u);
    Xil_Out32(RO_REG_CTRL, 1u);
    ro_meas_settle();
    Xil_Out32(RO_REG_CTRL, 3u);

    if (!ro_wait_measure(RO_STATUS_OUT_DONE | RO_STATUS_DONE))
        goto fail_out;

    ro_meas_settle();
    Xil_Out32(RO_REG_CTRL, 1u);

    if ((ro_status() & (RO_STATUS_OUT_DONE | RO_STATUS_DONE)) == 0u)
        goto fail_out;
    if (Xil_In32(RO_REG_EDGES) == 0u)
        goto fail_out;
    return 1;

fail_out:
    Xil_Out32(RO_REG_CTRL, 1u);
    return 0;
}

static u32 ro_bank_target_hz(u32 bank)
{
    switch (bank) {
    case RO_BANK_HW_B1:  return 120000000u;
    case RO_BANK_HW_B2:  return 100000000u;
    case RO_BANK_HW_B3:  return 55000000u;
    case RO_BANK_HW_B4:  return 70000000u;
    case RO_BANK_HW_B5:  return 62000000u;
    case RO_BANK_HW_B6:  return 45000000u;
    case RO_BANK_HW_B7:  return 30000000u;
    case RO_BANK_HW_B8:  return 22000000u;
    case RO_BANK_HW_B9:  return 15000000u;
    case RO_BANK_HW_B10: return 10000000u;
    case RO_BANK_HW_B11: return 5000000u;
    case RO_BANK_HW_B12: return 1000000u;
    case RO_BANK_HW_B13: return 800000u;
    case RO_BANK_HW_B14: return 600000u;
    case RO_BANK_HW_B15: return 400000u;
    case RO_BANK_HW_B16: return 300000u;
    default:             return 20000000u;
    }
}

static int ro_score_hz(u32 bank, u32 hz)
{
    int idx;
    u32 target;
    u32 err;

    if (!ro_hz_in_band(bank, hz))
        return -1;

    idx = ro_find_cal_index(bank);
    if (idx < 0)
        return -1;

    target = ro_bank_target_hz(bank);
    err = ro_abs_diff(hz, target);
    return 2000 - (int)(err / 100000u);
}

void ro_enable(u32 en)
{
    Xil_Out32(RO_REG_CTRL, en & 1u);
}

void ro_set_gate(u32 cycles)
{
    if (cycles == 0u)
        cycles = RO_GATE_5MS;
    Xil_Out32(RO_REG_GATE, cycles);
}

void ro_set_bank(u32 bank)
{
    Xil_Out32(RO_REG_BANK, bank & 0xFu);
}

void ro_set_tune(u32 tune12)
{
    Xil_Out32(RO_REG_TUNE, tune12 & 0xFFFu);
}

u32 ro_get_tune(void)
{
    return (u32)Xil_In32(RO_REG_TUNE) & 0xFFFu;
}

void ro_set_half_edges(u32 half, u32 bypass)
{
    (void)bypass;
    if (half == 0u)
        half = 1u;
    if (half > RO_HALF_EDGES_MAX)
        half = RO_HALF_EDGES_MAX;
    Xil_Out32(RO_REG_HALF_EDGES, half);
    Xil_Out32(RO_REG_DIV_CTRL, 1u);
}

u32 ro_get_half_edges(void)
{
    return (u32)Xil_In32(RO_REG_HALF_EDGES);
}

u32 ro_get_bank_active(void)
{
    return (u32)Xil_In32(RO_REG_BANK) & 0xFu;
}

u32 ro_get_route_bank(void)
{
    return ro_last_route_bank;
}

u32 ro_div_bypass_active(void)
{
    u32 r = (u32)Xil_In32(RO_REG_ROUTE);
    return r & 1u;
}

u32 ro_read_status(void)
{
    return ro_status();
}

u32 ro_read_pll_locked(void)
{
    return (u32)Xil_In32(RO_REG_PLL) & 1u;
}

int ro_pulse_measure(void)
{
    return ro_arm_measure_ring();
}

int ro_measure_output_hz(u32 *freq_hz)
{
    u32 f_pred = ro_predict_output_hz();
    u32 f_meas = 0u;
    int have_meas = 0;

    if (ro_arm_measure_out())
        have_meas = 1;

    if (f_pred > 0u) {
        if (have_meas)
            f_meas = ro_read_out_hz_raw();
        if (have_meas && f_pred < 2000000u && f_meas > 0u) {
            u32 err = ro_abs_diff(f_meas, f_pred);
            if (err * 5u <= f_pred) {
                if (freq_hz)
                    *freq_hz = f_meas;
                return 1;
            }
        }
        if (freq_hz)
            *freq_hz = f_pred;
        return 1;
    }

    if (!have_meas)
        return 0;

    f_meas = ro_read_out_hz_raw();
    if (freq_hz)
        *freq_hz = f_meas;
    return (f_meas > 0u) ? 1 : 0;
}

int ro_measure_bank_hz(u32 bank, u32 *freq_hz)
{
    u32 f;
    u32 saved = ro_get_bank_active();

    ro_set_bank(bank);
    ro_set_half_edges(1u, 1u);
    ro_bank_settle();

    if (!ro_arm_measure_ring()) {
        ro_set_bank(saved);
        return 0;
    }

    f = ro_read_ring_hz_for_bank(bank);
    ro_set_bank(saved);

    if (freq_hz)
        *freq_hz = f;
    return (f > 0u) ? 1 : 0;
}

static u32 ro_cal_hz_lookup(u32 bank)
{
    int idx = ro_find_cal_index(bank);
    if (idx < 0 || !ro_cal_table[idx].valid)
        return 0u;
    return ro_cal_table[idx].hz;
}

u32 ro_cal_hz_for_bank(u32 bank)
{
    return ro_cal_hz_lookup(bank);
}

u32 ro_cal_tune_for_bank(u32 bank)
{
    int idx = ro_find_cal_index(bank);
    if (idx < 0 || !ro_cal_table[idx].valid)
        return 0u;
    return ro_cal_table[idx].tune;
}

static int ro_cal_try_tune(u32 bank, u32 tune, u32 *hz_out, u32 *edges_out)
{
    ro_set_tune(tune & 0xFFFu);
    ro_bank_settle();
    if (!ro_arm_measure_ring())
        return 0;
    if (edges_out)
        *edges_out = (u32)Xil_In32(RO_REG_EDGES_RING);
    if (hz_out)
        *hz_out = ro_reconstruct_ring_hz(bank, (u32)Xil_In32(RO_REG_EDGES_RING));
    return 1;
}

static int ro_cal_one_bank(u32 bank, int idx)
{
    u32 hz;
    u32 best_hz = 0u;
    u32 best_tune = ro_preset_tune_for_bank(bank);
    u32 last_edges = 0u;
    u32 last_hz = 0u;
    int best_score = -1;
    int d;
    u32 tune;
    u32 step = ro_bank_full_tune_scan(bank) ? 32u : 64u;

    ro_set_bank(bank);
    ro_set_half_edges(1u, 1u);
    ro_bank_settle();

    if (ro_bank_is_chain(bank)) {
        ro_set_tune(0u);
        ro_bank_settle();
        if (ro_cal_try_tune(bank, 0u, &hz, &last_edges)) {
            last_hz = hz;
            if (ro_hz_ok_for_cal(bank, hz)) {
                best_hz = hz;
                best_tune = 0u;
            }
        }
        goto cal_finish;
    }

    if (ro_bank_full_tune_scan(bank)) {
        u32 target = ro_bank_target_hz(bank);
        u32 best_err = 0xFFFFFFFFu;
        for (tune = 0u; tune < 4096u; tune += 32u) {
            u32 err;
            if (!ro_cal_try_tune(bank, tune, &hz, &last_edges))
                continue;
            if (hz != 0u)
                last_hz = hz;
            if (!ro_hz_ok_for_cal(bank, hz))
                continue;
            err = ro_abs_diff(hz, target);
            if (best_hz == 0u || err < best_err) {
                best_err = err;
                best_hz = hz;
                best_tune = tune;
            }
        }
        if (best_hz == 0u && ro_edges_sane(last_edges)) {
            hz = ro_reconstruct_ring_hz(bank, last_edges);
            last_hz = hz;
            if (ro_hz_ok_for_cal(bank, hz)) {
                best_hz = hz;
                best_tune = ro_get_tune();
            }
        }
        goto cal_finish;
    }

    for (d = -12; d <= 12; d++) {
        int score;
        int t;

        t = (int)best_tune + (int)(d * (int)step);
        if (t < 0)
            t = 0;
        if (t > 0xFFF)
            t = 0xFFF;
        tune = (u32)t;

        if (!ro_cal_try_tune(bank, tune, &hz, &last_edges))
            continue;
        if (hz != 0u)
            last_hz = hz;
        if (hz == 0u)
            continue;

        score = ro_score_hz(bank, hz);
        if (score < 0)
            continue;
        if (score > best_score ||
            (score == best_score &&
             ro_abs_diff(hz, ro_bank_target_hz(bank)) <
                 ro_abs_diff(best_hz, ro_bank_target_hz(bank)))) {
            best_score = score;
            best_hz = hz;
            best_tune = tune;
        }
    }

cal_finish:

    if (best_hz == 0u && ro_edges_sane(last_edges)) {
        u32 hz_fb = ro_reconstruct_ring_hz(bank, last_edges);
        if (ro_hz_ok_for_cal(bank, hz_fb)) {
            best_hz = hz_fb;
            best_tune = ro_get_tune();
            last_hz = hz_fb;
        }
    }

    ro_cal_table[idx].last_edges = last_edges;
    ro_cal_table[idx].last_hz = (last_hz != 0u) ? last_hz :
        (ro_edges_sane(last_edges) ? ro_reconstruct_ring_hz(bank, last_edges) : 0u);

    if (best_hz > 0u && ro_hz_ok_for_cal(bank, best_hz)) {
        ro_set_tune(best_tune);
        ro_cal_table[idx].hz = best_hz;
        ro_cal_table[idx].tune = best_tune;
        ro_cal_table[idx].valid = 1u;
        return 1;
    }

    ro_cal_table[idx].valid = 0u;
    return 0;
}

int ro_cal_bank(int idx)
{
    if (idx < 0 || idx >= RO_CAL_BANK_COUNT)
        return 0;
    return ro_cal_one_bank((u32)ro_cal_bank_ids[idx], idx);
}

int ro_cal_run_all(void)
{
    int i;
    int ok = 1;

    ro_enable(1u);

    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        if (!ro_cal_bank(i))
            ok = 0;
    }
    return ok;
}

void ro_cal_clear(void)
{
    int i;
    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        ro_cal_table[i].hz = 0u;
        ro_cal_table[i].tune = 0u;
        ro_cal_table[i].last_edges = 0u;
        ro_cal_table[i].last_hz = 0u;
        ro_cal_table[i].valid = 0u;
    }
}

int ro_preview_bank(u32 bank)
{
    u32 tune;
    int idx = ro_find_cal_index(bank);

    if (idx >= 0 && ro_cal_table[idx].valid)
        tune = ro_cal_table[idx].tune;
    else
        tune = ro_preset_tune_for_bank(bank);

    ro_set_bank(bank);
    ro_set_tune(tune);
    ro_set_half_edges(1u, 0u);
    ro_enable(1u);
    ro_last_route_bank = bank;
    return 1;
}

int ro_set_output_hz(u32 target_hz)
{
    int i;
    int best_i = -1;
    u32 best_err = 0xFFFFFFFFu;
    u32 bank;
    u32 half;
    u32 bypass;
    u32 tune;
    u32 khz;
    u32 f_out;

    if (target_hz == 0u)
        return 0;

    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        u32 err;
        u32 thalf;
        u32 tbypass;

        if (!ro_cal_table[i].valid)
            continue;
        if (!ro_hz_in_band((u32)ro_cal_bank_ids[i], ro_cal_table[i].hz))
            continue;

        f_out = ro_achievable_hz(ro_cal_table[i].hz, target_hz, &thalf, &tbypass);
        err = ro_abs_diff(f_out, target_hz);
        if (best_i < 0 || err < best_err) {
            best_i = i;
            best_err = err;
            half = thalf;
            bypass = tbypass;
        }
    }

    if (best_i < 0)
        return 0;

    bank = (u32)ro_cal_bank_ids[best_i];
    tune = ro_cal_table[best_i].tune;

    khz = (target_hz + 999u) / 1000u;
    if (khz < 1u)
        khz = 1u;

    Xil_Out32(RO_REG_TARGET, khz);
    ro_set_bank(bank);
    ro_set_tune(tune);
    ro_set_half_edges(half, bypass);
    ro_enable(1u);

    ro_last_route_bank = bank;
    return 1;
}

int ro_store_cal(u32 bank, u32 tune, u32 hz)
{
    int idx = ro_find_cal_index(bank);

    if (idx < 0 || hz == 0u || !ro_hz_in_band(bank, hz))
        return 0;

    ro_cal_table[idx].hz = hz;
    ro_cal_table[idx].tune = tune & 0xFFFu;
    ro_cal_table[idx].valid = 1u;
    return 1;
}

int ro_scan_bank(u32 bank, u32 *best_tune, u32 *best_hz)
{
    u32 tune;
    u32 max_hz = 0u;
    u32 max_tune = 0u;
    u32 saved_bank = ro_get_bank_active();
    u32 saved_tune = ro_get_tune();
    int steps = 32;
    u32 step = 4096u / (u32)steps;

    ro_enable(1u);
    ro_set_bank(bank);
    ro_set_half_edges(1u, 1u);
    ro_bank_settle();

    for (tune = 0u; tune < 4096u; tune += step) {
        u32 hz;
        ro_set_tune(tune);
        ro_bank_settle();
        if (ro_arm_measure_ring()) {
            hz = ro_read_ring_hz_for_bank(bank);
            if (hz > max_hz && ro_hz_in_band(bank, hz)) {
                max_hz = hz;
                max_tune = tune;
            }
        }
    }

    ro_set_bank(saved_bank);
    ro_set_tune(saved_tune);

    if (best_tune)
        *best_tune = max_tune;
    if (best_hz)
        *best_hz = max_hz;
    return (max_hz > 0u) ? 1 : 0;
}

int ro_fast_scan_bank(u32 bank, u32 *best_tune, u32 *best_hz)
{
    u32 tune;
    u32 max_hz = 0u;
    u32 max_tune = 0u;
    u32 saved_bank = ro_get_bank_active();
    u32 saved_tune = ro_get_tune();
    u32 center;
    int span;

    ro_enable(1u);
    ro_set_bank(bank);
    ro_set_half_edges(1u, 1u);
    ro_bank_settle();

    for (tune = 0u; tune < 4096u; tune += 128u) {
        u32 hz;
        ro_set_tune(tune);
        ro_bank_settle();
        if (!ro_arm_measure_ring())
            continue;
        hz = ro_read_ring_hz_for_bank(bank);
        if (hz > max_hz && ro_hz_in_band(bank, hz)) {
            max_hz = hz;
            max_tune = tune;
        }
    }

    center = max_tune;
    for (span = 64; span >= 1; span >>= 1) {
        int d;
        for (d = -1; d <= 1; d += 2) {
            int t = (int)center + d * (int)span;
            u32 hz;
            if (t < 0 || t > 0xFFF)
                continue;
            ro_set_tune((u32)t);
            ro_bank_settle();
            if (!ro_arm_measure_ring())
                continue;
            hz = ro_read_ring_hz_for_bank(bank);
            if (hz > max_hz && ro_hz_in_band(bank, hz)) {
                max_hz = hz;
                max_tune = (u32)t;
                center = (u32)t;
            }
        }
    }

    if (max_hz > 0u)
        ro_store_cal(bank, max_tune, max_hz);

    ro_set_bank(saved_bank);
    ro_set_tune(saved_tune);

    if (best_tune)
        *best_tune = max_tune;
    if (best_hz)
        *best_hz = max_hz;
    return (max_hz > 0u) ? 1 : 0;
}
