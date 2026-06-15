#!/usr/bin/env python3
"""
Hardware-in-the-loop RO bank calibration for Arty S7 V1.

Flow:
  1) Vivado batch build (bitstream + optional PBLOCK XDC)
  2) Program bitstream + ELF via Vivado hw_server / xsdb (if available)
  3) UART CAL on COM port, parse bank frequencies
  4) Adjust PBLOCK Tcl if targets missed, loop

Usage:
  python scripts/auto_tune.py --com COM13 --baud 9600
  python scripts/auto_tune.py --build-only
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from pathlib import Path

try:
    import serial
except ImportError:
    serial = None

ROOT = Path(__file__).resolve().parents[1]
GEN_PRESETS = ROOT / "scripts" / "gen_ro_presets.py"
VIVADO = Path(r"C:\Xilinx\Vivado\2018.3\bin\vivado.bat")
BUILD_TCL = ROOT / "scripts" / "build_v1.tcl"
PBLOCK_TCL = ROOT / "constraints" / "v1_uart" / "floorplan_ro_banks.tcl"
BIT = ROOT / "bitstreams" / "v1_uart.bit"
ELF_CANDIDATES = [
    ROOT / "sdk_workspace" / "ro_ring_app" / "Debug" / "ro_ring_app.elf",
    ROOT / "sdk_workspace" / "ro_synth_app" / "Debug" / "ro_synth_app.elf",
]

TARGETS = {
    10: (80_000_000, 200_000_000),
    3: (45_000_000, 70_000_000),
    4: (15_000_000, 30_000_000),
    5: (1_000_000, 4_000_000),
}

CAL_OK_RE = re.compile(r"BANK\s+(\d+):\s+(\d+)\s+Hz", re.I)
CAL_FAIL_RE = re.compile(r"BANK\s+(\d+):\s+FAIL", re.I)
MEAS_RE = re.compile(r"(?:Current Output:|f =)\s+(\d+)\s+Hz", re.I)
RING_RE = re.compile(r"Ring bank\s+(\d+):\s+(\d+)\s+Hz", re.I)
FAST_RE = re.compile(r"f_max=(\d+)\s+Hz", re.I)


def run(cmd: list[str], cwd: Path = ROOT) -> int:
    print("+", " ".join(str(c) for c in cmd))
    return subprocess.call(cmd, cwd=str(cwd))


def gen_presets() -> bool:
    if not GEN_PRESETS.exists():
        return False
    return run([sys.executable, str(GEN_PRESETS)]) == 0


def vivado_build() -> bool:
    if not VIVADO.exists():
        print("WARN: Vivado not found at", VIVADO)
        return False
    gen_presets()
    return run([str(VIVADO), "-mode", "batch", "-source", str(BUILD_TCL)]) == 0


def gen_lut_mapping() -> bool:
    tcl = ROOT / "scripts" / "gen_lut_mapping.tcl"
    if not tcl.exists():
        return False
    return run([str(VIVADO), "-mode", "batch", "-source", str(tcl)]) == 0


def program_fpga() -> bool:
    prog_tcl = ROOT / "scripts" / "program_v1.tcl"
    if prog_tcl.exists() and VIVADO.exists():
        return run([str(VIVADO), "-mode", "batch", "-source", str(prog_tcl)]) == 0
    print("INFO: program_v1.tcl missing or Vivado absent — skip program step")
    return False


def uart_exchange(com: str, baud: int, cmd: str, wait_s: float = 8.0) -> str:
    if serial is None:
        raise RuntimeError("pip install pyserial")
    with serial.Serial(com, baud, timeout=0.5) as port:
        time.sleep(0.3)
        port.reset_input_buffer()
        port.write((cmd.strip() + "\r\n").encode("ascii"))
        port.flush()
        deadline = time.time() + wait_s
        buf = ""
        while time.time() < deadline:
            chunk = port.read(1024).decode(errors="replace")
            if chunk:
                buf += chunk
                print(chunk, end="", flush=True)
                if "RO> " in buf:
                    break
            else:
                time.sleep(0.05)
        return buf


def uart_session(com: str, baud: int):
    if serial is None:
        raise RuntimeError("pip install pyserial")
    return serial.Serial(com, baud, timeout=0.5)


def uart_meas_once(port, wait_s: float = 5.0) -> int | None:
    port.reset_input_buffer()
    port.write(b"MEAS\r\n")
    port.flush()
    deadline = time.time() + wait_s
    buf = ""
    hz = None
    while time.time() < deadline:
        chunk = port.read(512).decode(errors="replace")
        if chunk:
            buf += chunk
            m = MEAS_RE.search(buf)
            if m:
                hz = int(m.group(1))
                break
        else:
            time.sleep(0.05)
    port.write(b"Q")
    port.flush()
    end = time.time() + 2.0
    while time.time() < end:
        chunk = port.read(512).decode(errors="replace")
        if chunk and "RO> " in chunk:
            break
        time.sleep(0.05)
    return hz


def uart_send(port, cmd: str, wait_s: float = 8.0) -> str:
    port.write((cmd.strip() + "\r\n").encode("ascii"))
    port.flush()
    deadline = time.time() + wait_s
    buf = ""
    while time.time() < deadline:
        chunk = port.read(1024).decode(errors="replace")
        if chunk:
            buf += chunk
            print(chunk, end="", flush=True)
            if "RO> " in buf:
                break
        else:
            time.sleep(0.05)
    return buf


def uart_cal(com: str, baud: int, timeout_s: float = 30.0) -> dict[int, int]:
    if serial is None:
        raise RuntimeError("pip install pyserial")

    results: dict[int, int] = {}
    with serial.Serial(com, baud, timeout=0.5) as port:
        time.sleep(0.5)
        port.reset_input_buffer()
        port.write(b"CAL\r\n")
        deadline = time.time() + timeout_s
        buf = ""
        while time.time() < deadline:
            chunk = port.read(512).decode(errors="replace")
            if chunk:
                buf += chunk
                print(chunk, end="", flush=True)
                for m in CAL_OK_RE.finditer(buf):
                    results[int(m.group(1))] = int(m.group(2))
                if len(CAL_FAIL_RE.findall(buf)) + len(results) >= len(TARGETS):
                    break
            time.sleep(0.1)
    return results


def pblock_needs_tightening(measured: dict[int, int]) -> list[int]:
    bad = []
    for bank, (lo, hi) in TARGETS.items():
        f = measured.get(bank)
        if f is None:
            bad.append(bank)
            continue
        if f < lo or f > hi:
            bad.append(bank)
    return bad


def write_pblock_tcl(iteration: int, banks: list[int]) -> None:
    """Emit shifted PBLOCK regions for slow banks."""
    y_shift = 10 + iteration * 8
    lines = [
        "# Auto-generated by auto_tune.py",
        f"# iteration {iteration}, tighten banks {banks}",
        "",
    ]
    regions = {
        3: f"SLICE_X0Y{y_shift}:SLICE_X8Y{y_shift + 15}",
        4: f"SLICE_X25Y{y_shift}:SLICE_X35Y{y_shift + 20}",
        5: f"SLICE_X45Y{y_shift + 20}:SLICE_X55Y{y_shift + 45}",
    }
    for b in banks:
        if b not in regions:
            continue
        pb = f"pblock_ro_bank{b}"
        lines += [
            f"create_pblock {pb}",
            f"resize_pblock [get_pblocks {pb}] -add {{{regions[b]}}}",
            f"set_property IS_SOFT FALSE [get_pblocks {pb}]",
            f"add_cells_to_pblock [get_pblocks {pb}] "
            f"[get_cells -hierarchical -filter {{NAME =~ *u_core/g_bank\\[{b}\\]*}}]",
            "",
        ]
    PBLOCK_TCL.write_text("\n".join(lines), encoding="utf-8")
    print("Wrote", PBLOCK_TCL)


def pct_err(meas: int, target: int) -> float:
    if target <= 0:
        return 0.0
    return abs(meas - target) * 100.0 / float(target)


def uart_hil_test(com: str, baud: int) -> int:
    """Run CLEAR/CAL/SET/MEAS/RING/FAST suite; return exit code."""
    port = uart_session(com, baud)
    time.sleep(0.3)
    port.reset_input_buffer()
    ok = True
    cal: dict[int, int] = {}

    try:
        uart_send(port, "CLEAR", 2.0)
        out = uart_send(port, "CAL", 45.0)
        for m in CAL_OK_RE.finditer(out):
            cal[int(m.group(1))] = int(m.group(2))
        fails = [int(m.group(1)) for m in CAL_FAIL_RE.finditer(out)]
        if fails:
            ok = False
            print("CAL FAIL banks:", fails)

        cases = [
            ("SET 1k", 1_000, 5.0),
            ("SET 1M", 1_000_000, 5.0),
        ]
        for cmd, target, max_pct in cases:
            uart_send(port, cmd, 4.0)
            meas = uart_meas_once(port)
            if meas is None:
                ok = False
                print("FAIL", cmd, "no MEAS")
                continue
            err = pct_err(meas, target)
            status = "PASS" if err <= max_pct else "FAIL"
            print("%s %s meas=%d err=%.2f%%" % (status, cmd, meas, err))
            if err > max_pct:
                ok = False

        uart_send(port, "SET 100M", 4.0)
        meas = uart_meas_once(port)
        fcal = cal.get(10, cal.get(0, 0))
        if meas is not None and fcal > 0:
            err = pct_err(meas, fcal)
            status = "PASS" if err <= 20.0 else "FAIL"
            print("%s SET 100M meas=%d fcal=%d err=%.2f%%" % (status, meas, fcal, err))
            if err > 20.0:
                ok = False

        uart_send(port, "BANK 10", 4.0)
        meas = uart_meas_once(port)
        if meas is not None:
            print("BANK 10 preview f:", meas)
    finally:
        port.close()

    print("HIL TEST:", "PASS" if ok else "FAIL")
    return 0 if ok else 2


def main() -> int:
    ap = argparse.ArgumentParser(description="RO synthesizer HIL auto-tune")
    ap.add_argument("--com", default="COM13")
    ap.add_argument("--baud", type=int, default=9600)
    ap.add_argument("--max-iter", type=int, default=5)
    ap.add_argument("--build-only", action="store_true")
    ap.add_argument("--skip-build", action="store_true")
    ap.add_argument("--hil-test", action="store_true", help="UART test only (no Vivado)")
    ap.add_argument("--cmd", default="", help="Single UART command after connect")
    args = ap.parse_args()

    if args.cmd:
        uart_exchange(args.com, args.baud, args.cmd, 30.0)
        return 0

    if args.hil_test:
        return uart_hil_test(args.com, args.baud)

    for it in range(args.max_iter):
        print(f"\n=== HIL iteration {it + 1}/{args.max_iter} ===")
        if not args.skip_build:
            if not vivado_build():
                print("Build failed")
                return 1
            gen_lut_mapping()

        if args.build_only:
            print("Build-only done.")
            return 0

        if not BIT.exists():
            print("Missing", BIT)
            return 1

        program_fpga()

        try:
            measured = uart_cal(args.com, args.baud)
        except Exception as e:
            print("UART error:", e)
            return 1

        print("Measured:", measured)
        bad = pblock_needs_tightening(measured)
        if not bad:
            print("All banks within target bands.")
            return 0

        slow = [b for b in bad if b in (3, 4, 5)]
        if not slow:
            print("Fast bank out of range — manual tune/PBLOCK review needed:", bad)
            return 2

        write_pblock_tcl(it + 1, slow)

    print("Max iterations reached without convergence.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
