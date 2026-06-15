# Wersja 1 — RO Frequency Synthesizer (UART + MicroBlaze)

Sterowanie **4 bankami pierścieni RO** (10, 3, 4, 5), **32-bit divider**, pomiar **1 ms @ 100 MHz** przez terminal UART.

## Terminal

| Parametr | Wartość |
|----------|---------|
| Port | **COM13** (FTDI, typowo) |
| Prędkość | **9600** 8N1 |
| Klient | PuTTY — *Saved Session: FPGA* |

## Komendy CLI

| Komenda | Opis |
|---------|------|
| `HELP` | Lista komend |
| `SET 10K` / `SET 5M` | Cel wyjściowy w Hz (K=kHz, M=MHz); wybór banku z kalibracji + divider |
| `CAL` | Pomiar banków 10, 3, 4, 5 (okno 1 ms) → tablica referencyjna w RAM |
| `MEAS` | Pomiar częstotliwości na wyjściu systemu (za MUX + divider) |
| `ROUTE` | Bank MUX, f z kalibracji, `half_edges`, bypass, lista LUT (z `lut_mapping.h`) |
| `SCAN` | Greedy tune — max F per bank (opcjonalnie `SCAN 4`) |

Przykład sesji:

```
CAL
SET 2M
MEAS
ROUTE
```

## Architektura sprzętu

```
4× ring_inverter_tunable (bank 10,3,4,5)
        ↓ MUX
   ro_div32 (32-bit half_edges)
        ↓
   MEAS @ clk_100mhz (1 ms gate)
        ↓
   JA scope (MMCM bufor)
```

| Bank | Cel | Tail LUT | PBLOCK |
|------|-----|----------|--------|
| **10** | >100 MHz | 0 | — |
| **3** | 50–60 MHz | 2 | rozrzut po matrycy |
| **4** | ~20 MHz | 8 | długi łańcuch |
| **5** | ~2 MHz | 12 | PBLOCK + max tune |

Pomiar: `clk_ref_100mhz` (MMCM 12→100 MHz), bramka **100 000 cykli = 1 ms**, sygnał RO przez **2-FF sync**, gate cross-domain na `ro_async`.

## Build

```powershell
vivado -mode batch -source scripts/build_v1.tcl
```

Wynik: `bitstreams/v1_uart.bit`, `bitstreams/v1_uart_timing.rpt`, `sw/v1_uart/lut_mapping.h` (po `gen_lut_mapping.tcl`).

### Firmware MicroBlaze

1. Export hardware (`.xsa`) po bitstreamie.
2. Skopiuj `sw/v1_uart/*` do projektu aplikacji Vitis.
3. Dołącz `lut_mapping.h` (generowany po implementacji).
4. Build + wgraj `.elf` (JTAG).

## PBLOCK / LUT map

- `constraints/v1_uart/floorplan_ro_banks.xdc` — regiony PBLOCK banków 3/4/5.
- `scripts/gen_lut_mapping.tcl` — post-impl: SLICE/LUT → `lut_mapping.h` dla `ROUTE`.

## Auto-tune (HIL)

```powershell
pip install pyserial
python scripts/auto_tune.py --com COM13 --baud 9600
```

Pętla: build → program → `CAL` przez UART → korekta PBLOCK jeśli bank poza pasmem.

Opcje: `--build-only`, `--skip-build`, `--max-iter N`.

## Pliki

| Katalog | Zawartość |
|---------|-----------|
| `rtl/common/` | RO, `clk_ref_100mhz`, `ro_freq_gate_100m`, CSR |
| `sw/v1_uart/` | `uart_cmd.c`, `ro_regs.c`, `lut_mapping.h` |
| `scripts/` | `build_v1.tcl`, `gen_lut_mapping.tcl`, `auto_tune.py` |
| `constraints/v1_uart/` | piny + PBLOCK |
