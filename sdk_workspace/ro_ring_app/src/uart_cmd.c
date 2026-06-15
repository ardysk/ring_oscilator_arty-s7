#include "uart_cmd.h"
#include "ro_regs.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xil_types.h"
#include "xuartlite.h"
#include "xuartlite_l.h"
#include "xparameters.h"

#define PROMPT "RO> "
#define MEAS_POLL_GAP 80000u

static char line_buf[UART_LINE_MAX];
static int  line_len;
static int  cursor_pos;
static int  drawn_len;

static char hist_buf[UART_HIST_MAX][UART_LINE_MAX];
static int  hist_count;
static int  hist_pos;

typedef enum {
    ESC_NONE = 0,
    ESC_GOT,
    ESC_BRACKET
} esc_state_t;

static esc_state_t esc_state;
static u8 meas_live_mode;
static u32 meas_poll_cnt;

static void term_putc(char c)
{
    XUartLite_SendByte(STDOUT_BASEADDRESS, (u8)c);
}

static void term_puts(const char *s)
{
    while (*s)
        term_putc(*s++);
}

static char to_upper(char c)
{
    if (c >= 'a' && c <= 'z')
        return (char)(c - 'a' + 'A');
    return c;
}

static int str_eq_ci(const char *a, const char *b)
{
    while (*a && *b) {
        if (to_upper(*a) != to_upper(*b))
            return 0;
        a++;
        b++;
    }
    return (to_upper(*a) == to_upper(*b));
}

static int str_prefix_ci(const char *line, const char *prefix)
{
    while (*prefix) {
        if (to_upper(*line) != to_upper(*prefix))
            return 0;
        line++;
        prefix++;
    }
    return 1;
}

static void line_reset(void)
{
    line_len = 0;
    cursor_pos = 0;
    drawn_len = 0;
    line_buf[0] = '\0';
    hist_pos = hist_count;
}

static void line_redraw(void)
{
    int i;

    term_puts("\r" PROMPT);
    if (line_len > 0)
        term_puts(line_buf);

    for (i = line_len; i < drawn_len; i++)
        term_putc(' ');

    term_puts("\r" PROMPT);
    if (line_len > 0)
        term_puts(line_buf);

    for (i = line_len; i > cursor_pos; i--)
        term_putc('\b');

    drawn_len = line_len;
}

static void line_set(const char *s)
{
    int i = 0;

    while (s[i] && i < (UART_LINE_MAX - 1)) {
        line_buf[i] = s[i];
        i++;
    }
    line_buf[i] = '\0';
    line_len = i;
    cursor_pos = i;
    line_redraw();
}

static void hist_add_current(void)
{
    int i;
    int last;

    if (line_len <= 0)
        return;

    if (hist_count > 0) {
        last = hist_count - 1;
        if (str_eq_ci(hist_buf[last], line_buf))
            return;
    }

    if (hist_count < UART_HIST_MAX) {
        for (i = 0; i < line_len; i++)
            hist_buf[hist_count][i] = line_buf[i];
        hist_buf[hist_count][line_len] = '\0';
        hist_count++;
    } else {
        for (i = 1; i < UART_HIST_MAX; i++) {
            int j = 0;
            while (hist_buf[i][j]) {
                hist_buf[i - 1][j] = hist_buf[i][j];
                j++;
            }
            hist_buf[i - 1][j] = '\0';
        }
        for (i = 0; i < line_len; i++)
            hist_buf[UART_HIST_MAX - 1][i] = line_buf[i];
        hist_buf[UART_HIST_MAX - 1][line_len] = '\0';
    }
}

static void hist_up(void)
{
    if (hist_count == 0)
        return;
    if (hist_pos == hist_count)
        hist_pos = hist_count - 1;
    else if (hist_pos > 0)
        hist_pos--;
    else
        return;
    line_set(hist_buf[hist_pos]);
}

static void hist_down(void)
{
    if (hist_count == 0 || hist_pos == hist_count)
        return;
    if (hist_pos < (hist_count - 1)) {
        hist_pos++;
        line_set(hist_buf[hist_pos]);
    } else {
        hist_pos = hist_count;
        line_reset();
        line_redraw();
    }
}

static void cursor_left(void)
{
    if (cursor_pos > 0) {
        cursor_pos--;
        term_putc('\b');
    }
}

static void cursor_right(void)
{
    if (cursor_pos < line_len) {
        term_putc(line_buf[cursor_pos]);
        cursor_pos++;
    }
}

static void line_insert(char c)
{
    int i;

    if (line_len >= (UART_LINE_MAX - 1))
        return;

    if (cursor_pos == line_len) {
        line_buf[line_len++] = c;
        line_buf[line_len] = '\0';
        cursor_pos = line_len;
        term_putc(c);
        drawn_len = line_len;
        return;
    }

    for (i = line_len; i > cursor_pos; i--)
        line_buf[i] = line_buf[i - 1];
    line_buf[cursor_pos] = c;
    line_len++;
    line_buf[line_len] = '\0';
    cursor_pos++;
    line_redraw();
}

static void line_delete_left(void)
{
    int i;

    if (cursor_pos <= 0)
        return;

    for (i = cursor_pos - 1; i < line_len; i++)
        line_buf[i] = line_buf[i + 1];
    line_len--;
    cursor_pos--;
    line_buf[line_len] = '\0';
    line_redraw();
}

static void line_sanitize_paste(void)
{
    int i = 0;

    while (line_buf[i] == ' ' || line_buf[i] == '\t')
        i++;

    if (str_prefix_ci(line_buf + i, "RO>")) {
        i += 3;
        while (line_buf[i] == ' ')
            i++;
    }

    if (i > 0) {
        int j = 0;
        while (line_buf[i + j]) {
            line_buf[j] = line_buf[i + j];
            j++;
        }
        line_buf[j] = '\0';
        line_len = j;
        cursor_pos = j;
    }

    for (i = 0; i < line_len; i++) {
        if (line_buf[i] == '\r' || line_buf[i] == '\n') {
            line_buf[i] = '\0';
            line_len = i;
            cursor_pos = i;
            break;
        }
    }
}

static void line_trim(void)
{
    int start = 0;
    int i;

    while (line_buf[start] == ' ' || line_buf[start] == '\t' ||
           line_buf[start] == '\r' || line_buf[start] == '\n')
        start++;

    if (start > 0) {
        i = 0;
        while (line_buf[start + i]) {
            line_buf[i] = line_buf[start + i];
            i++;
        }
        line_buf[i] = '\0';
        line_len = i;
        cursor_pos = i;
    }

    while (line_len > 0) {
        char c = line_buf[line_len - 1];
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n')
            line_buf[--line_len] = '\0';
        else
            break;
    }
    cursor_pos = line_len;
}

static int parse_set_hz(const char *arg, u32 *hz_out)
{
    u64 val = 0;
    char suffix = 0;
    const char *p = arg;

    while (*p == ' ' || *p == '\t')
        p++;
    if (*p == '\0')
        return 0;

    while (*p >= '0' && *p <= '9') {
        val = val * 10u + (u64)(*p - '0');
        p++;
    }
    if (*p != '\0') {
        suffix = to_upper(*p);
        p++;
    }
    while (*p == ' ' || *p == '\t')
        p++;
    if (*p != '\0')
        return 0;

    if (suffix == 'K')
        val *= 1000u;
    else if (suffix == 'M')
        val *= 1000000u;

    if (val == 0u || val > 0xFFFFFFFFu)
        return 0;

    *hz_out = (u32)val;
    return 1;
}

static int parse_u32(const char *s, u32 *out)
{
    u32 val = 0;
    int any = 0;

    while (*s == ' ' || *s == '\t')
        s++;
    while (*s >= '0' && *s <= '9') {
        val = val * 10u + (u32)(*s - '0');
        any = 1;
        s++;
    }
    if (!any)
        return 0;
    *out = val;
    return 1;
}

static void print_how(u32 target_hz)
{
    u32 bank = ro_get_route_bank();
    u32 half = ro_get_half_edges();
    u32 fcal = ro_cal_hz_for_bank(bank);
    u32 fout;

    if (bank == 0u)
        bank = ro_get_bank_active();
    if (fcal == 0u)
        fcal = ro_cal_hz_for_bank(bank);

    if (half < 1u)
        half = 1u;
    fout = fcal / (2u * half);

    xil_printf("  jak: %s (hw %u)  f_ring=%u Hz\r\n",
               ro_label_from_hw(bank), (unsigned)bank, (unsigned)fcal);
    xil_printf("       bufor+div /%u  f_out=%u Hz\r\n",
               (unsigned)(2u * half), (unsigned)fout);
    if (target_hz > 0u && fout > 0u && target_hz != fout) {
        u32 err = (fout >= target_hz) ? (fout - target_hz) : (target_hz - fout);
        xil_printf("       target=%u Hz  blad~%u Hz\r\n",
                   (unsigned)target_hz, (unsigned)err);
    }
}

static void cmd_help(void)
{
    xil_printf("RO Synthesizer\r\n");
    xil_printf("  CLEAR             - wyczysc tabele CAL\r\n");
    xil_printf("  CAL               - kalibruj B1..B16 (B1=najszybszy)\r\n");
    xil_printf("  MEAS              - ciagly pomiar f (Q=wyjscie)\r\n");
    xil_printf("  BANK <1-16>       - podglad Bn na wyj. bufor.\r\n");
    xil_printf("  SET <n>K|<n>M      - ustaw f, pokaz jak osiagnieto\r\n");
    xil_printf("SW0=ON wlacza pierścienie\r\n");
}

static void cmd_clear(void)
{
    ro_cal_clear();
    xil_printf("OK: CAL wyczyszczona\r\n");
}

static void cmd_cal(void)
{
    int i;
    int ok = 1;
    u32 ctrl;

    ro_enable(1u);
    ctrl = (u32)Xil_In32(RO_REG_CTRL);
    if ((ctrl & 1u) == 0u) {
        xil_printf("ERR: brak RO CSR (bitstream?)\r\n");
        return;
    }

    xil_printf("CAL...\r\n");
    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        u32 hw = (u32)ro_cal_bank_ids[i];
        xil_printf("  %s (hw %u)...\r\n", ro_label_from_hw(hw), (unsigned)hw);
        if (!ro_cal_bank(i))
            ok = 0;
    }
    if (!ok)
        xil_printf("WARN: czesciowa kalibracja\r\n");
    for (i = 0; i < RO_CAL_BANK_COUNT; i++) {
        u32 hw = (u32)ro_cal_bank_ids[i];
        if (ro_cal_table[i].valid)
            xil_printf("  %s: %u Hz  tune=0x%03X\r\n",
                       ro_label_from_hw(hw),
                       (unsigned)ro_cal_table[i].hz,
                       (unsigned)ro_cal_table[i].tune);
        else
            xil_printf("  %s: FAIL edges=%u last_hz=%u\r\n",
                       ro_label_from_hw(hw),
                       (unsigned)ro_cal_table[i].last_edges,
                       (unsigned)ro_cal_table[i].last_hz);
    }
}

static void cmd_meas_enter(void)
{
    u32 hz = 0u;

    meas_live_mode = 1u;
    meas_poll_cnt = MEAS_POLL_GAP;
    xil_printf("MEAS (Q=koniec)\r\n");
    if (ro_measure_output_hz(&hz))
        xil_printf("f = %u Hz\r\n", (unsigned)hz);
}

static void meas_live_step(void)
{
    u32 hz = 0u;

    meas_poll_cnt++;
    if (meas_poll_cnt < MEAS_POLL_GAP)
        return;
    meas_poll_cnt = 0u;

    if (!ro_measure_output_hz(&hz))
        xil_printf("f = ?\r\n");
    else
        xil_printf("f = %u Hz\r\n", (unsigned)hz);
}

static void cmd_bank(const char *arg)
{
    u32 sel;
    u32 hw;
    u32 fcal;

    if (!parse_u32(arg, &sel)) {
        xil_printf("ERR: BANK <1-16>  np. BANK 3\r\n");
        return;
    }
    if (sel < 1u || sel > RO_CAL_BANK_COUNT) {
        xil_printf("ERR: BANK 1..%u\r\n", (unsigned)RO_CAL_BANK_COUNT);
        return;
    }
    hw = ro_hw_from_logical(sel);
    if (!ro_preview_bank(hw)) {
        xil_printf("ERR: %s\r\n", ro_label_from_logical(sel));
        return;
    }
    fcal = ro_cal_hz_for_bank(hw);
    xil_printf("OK: %s (hw %u) -> wyj. bufor.\r\n",
               ro_label_from_hw(hw), (unsigned)hw);
    if (fcal > 0u)
        xil_printf("  f_ring~%u Hz  tune=0x%03X  (div /2)\r\n",
                   (unsigned)fcal, (unsigned)ro_cal_tune_for_bank(hw));
    else
        xil_printf("  (brak CAL — uruchom CAL)\r\n");
}

static void cmd_set(const char *arg)
{
    u32 hz;

    if (!parse_set_hz(arg, &hz)) {
        xil_printf("ERR: SET <n>K lub SET <n>M\r\n");
        return;
    }
    if (!ro_set_output_hz(hz)) {
        xil_printf("ERR: SET (najpierw CAL)\r\n");
        return;
    }
    xil_printf("OK: %u Hz\r\n", (unsigned)hz);
    print_how(hz);
}

static void cmd_dispatch(void)
{
    const char *arg;

    line_sanitize_paste();
    line_trim();
    if (line_len == 0)
        return;

    if (str_eq_ci(line_buf, "HELP") || str_eq_ci(line_buf, "?")) {
        cmd_help();
        return;
    }
    if (str_eq_ci(line_buf, "CLEAR")) {
        cmd_clear();
        return;
    }
    if (str_eq_ci(line_buf, "CAL")) {
        cmd_cal();
        return;
    }
    if (str_eq_ci(line_buf, "MEAS")) {
        cmd_meas_enter();
        return;
    }
    if (str_prefix_ci(line_buf, "BANK")) {
        arg = line_buf + 4;
        cmd_bank(arg);
        return;
    }
    if (str_prefix_ci(line_buf, "SET")) {
        arg = line_buf + 3;
        cmd_set(arg);
        return;
    }

    xil_printf("ERR: nieznane (HELP)\r\n");
}

static void handle_escape(int ch)
{
    switch (esc_state) {
    case ESC_GOT:
        if (ch == '[')
            esc_state = ESC_BRACKET;
        else
            esc_state = ESC_NONE;
        break;
    case ESC_BRACKET:
        esc_state = ESC_NONE;
        if (ch == 'A')
            hist_up();
        else if (ch == 'B')
            hist_down();
        else if (ch == 'C')
            cursor_right();
        else if (ch == 'D')
            cursor_left();
        break;
    default:
        break;
    }
}

void uart_cmd_init(void)
{
    line_reset();
    esc_state = ESC_NONE;
    hist_count = 0;
    meas_live_mode = 0u;
    meas_poll_cnt = 0u;
    ro_set_gate(RO_GATE_5MS);
    ro_enable(1u);
    xil_printf("\r\n=== RO Synthesizer ===\r\n");
    cmd_help();
    term_puts(PROMPT);
}

void uart_cmd_poll(void)
{
    int ch;

    if (meas_live_mode) {
        while (XUartLite_IsReceiveEmpty(STDOUT_BASEADDRESS) == 0u) {
            ch = (int)XUartLite_RecvByte(STDOUT_BASEADDRESS);
            if (ch == 'q' || ch == 'Q' || ch == 27) {
                meas_live_mode = 0u;
                xil_printf("\r\n");
                term_puts(PROMPT);
                return;
            }
        }
        meas_live_step();
        return;
    }

    if (XUartLite_IsReceiveEmpty(STDOUT_BASEADDRESS) != 0u)
        return;

    ch = (int)XUartLite_RecvByte(STDOUT_BASEADDRESS);

    if (esc_state != ESC_NONE) {
        handle_escape(ch);
        return;
    }

    if (ch == 27) {
        esc_state = ESC_GOT;
        return;
    }

    if (ch == '\r' || ch == '\n') {
        term_putc('\r');
        term_putc('\n');
        if (line_len > 0) {
            line_buf[line_len] = '\0';
            hist_add_current();
            cmd_dispatch();
        }
        line_reset();
        term_puts(PROMPT);
        return;
    }

    if (ch == '\b' || ch == 127)
        line_delete_left();
    else if (ch == 3) {
        term_puts("^C\r\n");
        line_reset();
        term_puts(PROMPT);
    } else if (ch >= 32 && ch < 127)
        line_insert((char)ch);
}
