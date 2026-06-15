# Mapa rejestrów AXI4-Lite — `csr_ro_axi_lite`

Bazowy adres IP w Block Design: **0x44A0_0000** (MicroBlaze).

| Offset | Nazwa | R/W | Opis |
|--------|-------|-----|------|
| 0x00 | CTRL | R/W | bit0: `ro_en`; bit1: pulse `meas_start` przy zapisie |
| 0x04 | FREQ | R/W | Legacy scope preset (3 bity) |
| 0x08 | TUNE | R/W | Strojenie `tune[11:0]` (OR z maską aktywnego banku) |
| 0x0C | GATE | R/W | Bramka pomiaru (legacy; HW używa 100k cykli @ 100 MHz) |
| 0x10 | STATUS | R/W | bit0: `busy`; bit1: `done`; zapis bit1=1 kasuje done |
| 0x14 | PLL | R | bit0: `ref_locked` (MMCM 100 MHz) |
| 0x18 | EDGES | R | Zbocza — wyjście systemu (MEAS) |
| 0x1C | BANK | R/W | Wybór banku MUX (3, 4, 5, 10) |
| 0x20 | FREQ_HZ | R | Zmierzona f wyjścia [Hz] |
| 0x24 | TARGET | R/W | Target [kHz] (legacy mapowanie HW) |
| 0x28 | FREQ_RING | R | Zmierzona f pierścienia (CAL) |
| 0x2C | EDGES_RING | R | Zbocza pierścienia |
| 0x30 | PRED_KHZ | R | Predykcja mapowania |
| 0x34 | HALF_EDGES | R/W | 32-bit divider half-period |
| 0x38 | ROUTE | R | bank_auto, bank_manual, div_bypass |
| 0x3C | DIV_CTRL | W | bit0: div_manual; bit1: bypass; bit2: auto |

## Sekwencja CAL / MEAS (V1 synthesizer)

1. `CAL`: dla każdego banku zapis `BANK`, pulse `CTRL=3`, odczyt `FREQ_RING`.
2. `MEAS`: pulse `CTRL=3`, odczyt `FREQ_HZ`.
3. `SET` (SW): wybór banku + `HALF_EDGES` + `DIV_CTRL` z kalibracji RAM.
