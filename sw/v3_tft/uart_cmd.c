#include "uart_cmd.h"
#include "ro_regs.h"
#include "xil_printf.h"
#include "xil_types.h"
#include "xuartlite.h"
#include "xuartlite_l.h"
#include "xparameters.h"

static char line_buf[UART_LINE_MAX];
static int  line_len;

static void line_reset(void)
{
    line_len = 0;
    line_buf[0] = '\0';
}

static int str_eq(const char *a, const char *b)
{
    while (*a && *b) {
        if (*a != *b) return 0;
        a++;
        b++;
    }
    return (*a == *b);
}

static int parse_u32(const char *s, u32 *out)
{
    u32 val = 0u;
    int any = 0;

    while (*s == ' ' || *s == '\t') s++;

    while (*s >= '0' && *s <= '9') {
        val = val * 10u + (u32)(*s - '0');
        any = 1;
        s++;
    }

    if (!any) return 0;
    *out = val;
    return 1;
}

static void cmd_help(void)
{
    xil_printf("Commands:\r\n");
    xil_printf("  HELP              - this list\r\n");
    xil_printf("  SET <MHz>         - target 1..511 MHz\r\n");
    xil_printf("  GET               - read last measured Hz\r\n");
    xil_printf("  MEAS              - trigger measurement\r\n");
    xil_printf("  STATUS            - busy/done/target/gate\r\n");
    xil_printf("  TARGET            - read target MHz\r\n");
}

static void cmd_dispatch(char *line)
{
    char *arg;
    u32 val;

    while (*line == ' ' || *line == '\t') line++;

    if (*line == '\0') return;

    if (str_eq(line, "HELP") || str_eq(line, "?")) {
        cmd_help();
        return;
    }

    if (str_eq(line, "GET")) {
        xil_printf("f=%u Hz\r\n", ro_read_freq_hz_snap());
        return;
    }

    if (str_eq(line, "MEAS")) {
        val = ro_measure_freq_hz();
        xil_printf("f=%u Hz\r\n", val);
        return;
    }

    if (str_eq(line, "STATUS")) {
        val = ro_read_status();
        xil_printf("busy=%u done=%u target=%u gate=%u\r\n",
                     (val >> 0) & 1u,
                     (val >> 1) & 1u,
                     ro_get_target_mhz(),
                     RO_GATE_5MS);
        return;
    }

    if (str_eq(line, "TARGET")) {
        xil_printf("target=%u MHz\r\n", ro_get_target_mhz());
        return;
    }

    if (line[0] == 'S' && line[1] == 'E' && line[2] == 'T') {
        arg = line + 3;
        if (parse_u32(arg, &val)) {
            if (val >= RO_TARGET_MIN && val <= RO_TARGET_MAX) {
                ro_set_target_mhz(val);
                xil_printf("OK target=%u MHz\r\n", val);
            } else {
                xil_printf("ERR range %u..%u MHz\r\n", RO_TARGET_MIN, RO_TARGET_MAX);
            }
        } else {
            xil_printf("ERR usage: SET <MHz>\r\n");
        }
        return;
    }

    xil_printf("ERR unknown command (HELP)\r\n");
}

void uart_cmd_init(void)
{
    line_reset();
}

void uart_cmd_poll(void)
{
    int ch;

    if (!XUartLite_IsReceiveEmpty(STDIN_BASEADDRESS)) {
        ch = (int)XUartLite_RecvByte(STDIN_BASEADDRESS);

        if (ch == '\r' || ch == '\n') {
            if (line_len > 0) {
                line_buf[line_len] = '\0';
                cmd_dispatch(line_buf);
            }
            line_reset();
        } else if (ch >= 32 && ch < 127) {
            if (line_len < (UART_LINE_MAX - 1)) {
                line_buf[line_len++] = (char)ch;
                line_buf[line_len] = '\0';
            }
        }
    }
}
