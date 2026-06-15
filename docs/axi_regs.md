# Mapa rejestrów AXI4-Lite — V1 UART

Baza: **`0x44A00000`** (`RO_RING_BASE` w `sw/v1_uart/ro_regs.h`)  
Moduł: `csr_ro_axi_lite.sv` — interfejs MicroBlaze ↔ pierścienie RO.

| Offset | Nazwa | R/W | Opis |
|--------|-------|-----|------|
| `0x00` | **CTRL** | R/W | W: `[0]` `ro_en`, `[1]` impuls startu pomiaru. R: `[0]` `ro_en` |
| `0x04` | **FREQ** | R/W | Legacy `freq_sel[2:0]` |
| `0x08` | **TUNE** | R/W | Strojenie `[11:0]` aktywnego banku |
| `0x0C` | **GATE** | R/W | Okno pomiaru w cyklach `clk` (domyślnie **60000** @ 12 MHz ≈ 5 ms) |
| `0x10` | **STATUS** | R/W | R: `[0]` busy, `[1]` done, `[2]` ring_done, `[3]` out_done. W: `[1]=1` czyści sticky |
| `0x14` | **PLL** | R | `[0]` MMCM locked |
| `0x18` | **EDGES** | R | Zbocza na wyjściu (OUT) |
| `0x1C` | **BANK** | R/W | W: bank HW `0…15` + manual. R: aktywny bank |
| `0x20` | **FREQ_HZ** | R | Zmierzona częstotliwość wyjścia [Hz] |
| `0x24` | **TARGET** | R/W | Docelowa częstotliwość **[kHz]** (`SET` w firmware) |
| `0x28` | **FREQ_RING** | R | Zmierzona częstotliwość pierścienia [Hz] |
| `0x2C` | **EDGES_RING** | R | Zbocza pierścienia |
| `0x30` | **PRED_KHZ** | R | Predykcja wyjścia [kHz] z mapowania bank+dzielnik |
| `0x34` | **HALF_EDGES** | R/W | Dzielnik: zbocza narastające na półokres (min. 1) |
| `0x38` | **ROUTE** | R | `[0]` div_bypass, `[1]` bank_manual, `[5:2]` bank_auto, `[6]` div_manual |
| `0x3C` | **DIV_CTRL** | R/W | Ręczny tryb dzielnika / bypass / auto |

Tabela kalibracji **16 banków** (`ro_cal_table[]`) jest w RAM MicroBlaze — nie w rejestrach PL.
