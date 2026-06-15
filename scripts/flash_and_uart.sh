#!/usr/bin/env bash
# Wgranie V1 (bitstream + MicroBlaze ELF przez JTAG) i test UART.
# Git Bash na Windows: ./scripts/flash_and_uart.sh
# Zmienne: COM_PORT=COM13 VIVADO_ROOT=/c/Xilinx/Vivado/2018.3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(dirname "$SCRIPT_DIR")"
VIVADO_ROOT="${VIVADO_ROOT:-/c/Xilinx/Vivado/2018.3}"
COM_PORT="${COM_PORT:-COM13}"
BAUD="${BAUD:-9600}"
XSDB="$VIVADO_ROOT/bin/xsdb.bat"
BIT="$PROJ/bitstreams/v1_uart.bit"
ELF="$PROJ/firmware/ro_ring_app.elf"
TCL="$SCRIPT_DIR/program_v1.tcl"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -f "$XSDB" ]] || die "Brak xsdb: $XSDB (ustaw VIVADO_ROOT)"
[[ -f "$BIT" ]] || die "Brak bitstreamu: $BIT"
[[ -f "$ELF" ]] || die "Brak firmware: $ELF"
[[ -f "$TCL" ]] || die "Brak $TCL"

echo "=== Wgrywanie V1 (JTAG) ==="
echo "BIT: $BIT"
echo "ELF: $ELF"
"$XSDB" "$TCL" || die "Wgrywanie nie powiodlo sie — sprawdz JTAG i zasilanie plytki"

echo ""
echo "=== Czekam na start MicroBlaze ==="
sleep 2

echo "=== Test UART $COM_PORT @ $BAUD ==="
python - "$COM_PORT" "$BAUD" <<'PY'
import sys
import time
try:
    import serial
except ImportError:
    sys.exit("pip install pyserial")

com, baud = sys.argv[1], int(sys.argv[2])
with serial.Serial(com, baud, timeout=0.5) as port:
    time.sleep(0.5)
    port.reset_input_buffer()
    port.write(b"HELP\r\n")
    port.flush()
    deadline = time.time() + 6.0
    buf = ""
    while time.time() < deadline:
        chunk = port.read(512).decode(errors="replace")
        if chunk:
            buf += chunk
            print(chunk, end="", flush=True)
            if "RO>" in buf or "RO Synthesizer" in buf:
                break
        else:
            time.sleep(0.05)
    if not buf.strip():
        sys.exit(f"Brak odpowiedzi na {com} @ {baud} — sprawdz port i SW0=ON")
print(f"\nOK: UART dziala na {com} @ {baud}")
PY

echo ""
echo "Gotowe. Interaktywny terminal:"
echo "  python scripts/auto_tune.py --com $COM_PORT --baud $BAUD --cmd HELP"
echo "  (lub PuTTY: $COM_PORT 9600 8N1, SW0=ON)"
