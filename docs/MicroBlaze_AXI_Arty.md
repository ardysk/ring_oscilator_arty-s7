# MicroBlaze + AXI4-Lite (ścieżka B na Arty S7)

RTL: **`ro_top_arty_axi.sv`** + **`csr_ro_axi_lite.sv`** (wrapper BD: **`ro_top_arty_axi_bd_wrap.v`**).

## Szybki start (Vivado + Vitis)

### 1. Block Design

```powershell
cd C:\Users\HP\Downloads\csd_lab6\ring_oscilator_prj
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source scripts/create_mb_ro_axi_bd.tcl
```

### 2. Vivado — bitstream

- **Top module:** `mb_ro_system_wrapper`
- **Constrainty:** `pins_arty_mb_axi.xdc` = Used, `pins_arty_s7.xdc` = User Disabled
- Run Synthesis → Implementation → Generate Bitstream

Alternatywnie (batch):

```powershell
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source scripts/build_mb_bitstream.tcl
```

### 3. Vitis — program MicroBlaze

1. Platform z `.xsa` / hardware export
2. Application: skopiuj **`software/mb_axi/main.c`**
3. Build → Run (JTAG)

Szczegóły użycia rejestrów: **`docs/ustawianie_czestotliwosci.md`**.

---

## Architektura

```
MicroBlaze ──AXI4-Lite──► csr_ro_axi_lite ──► ro_top_arty_axi
                                                    ├── 8× ring_inverter_tunable
                                                    ├── ring_prog_toggle_div (TARGET MHz)
                                                    ├── ro_freq_measure → FREQ_HZ
                                                    └── arty_scope_freq_mux → JA
```

Zegar: **12 MHz** wszędzie (`clk_12mhz` = `s_axi_aclk`).

---

## Mapa rejestrów (baza `0x44A00000`)

| Offset | Nazwa | R/W | Opis |
|--------|--------|-----|------|
| `0x00` | CTRL | W | bit0 `ro_en`; bit1 impuls `meas_start` (przy zapisie CTRL) |
| `0x04` | FREQ | R/W | legacy preset 0…7 (LUT); **używaj TARGET** |
| `0x08` | TUNE | R/W | bity 9:0 OR na strojenie aktywnego banku |
| `0x0C` | GATE | R/W | bramka pomiaru [cykle]; domyślnie **60000** ≈ 5 ms |
| `0x10` | STATUS | R | bit0 busy; bit1 done (sticky). Zapis `2` → W1C done |
| `0x14` | PLL | R | MMCM locked (scope buffer) |
| `0x18` | EDGES | R | liczba zboczy z ostatniego pomiaru |
| `0x1C` | BANK | R/W | bank 0…7; przy zapisie **TARGET** aktualizuje się auto |
| `0x20` | **FREQ_HZ** | R | **zmierzona f pierścienia [Hz]** |
| `0x24` | **TARGET** | R/W | **docelowe MHz wyjścia** 1…511 |

Adres sprawdź w *Address Editor* po wygenerowaniu BD.

---

## Zmiana f w locie (C)

```c
#define RO_BASE 0x44A00000u

Xil_Out32(RO_BASE + 0x0C, 60000u);   // bramka ~5 ms
Xil_Out32(RO_BASE + 0x24, 25u);      // cel ~25 MHz (bank + dzielnik)
Xil_Out32(RO_BASE + 0x00, 1u);       // włącz pierścień

// później, bez resetu:
Xil_Out32(RO_BASE + 0x24, 40u);      // nowa f

// pomiar surowego pierścienia:
Xil_Out32(RO_BASE + 0x00, 3u);
Xil_Out32(RO_BASE + 0x00, 1u);
while ((Xil_In32(RO_BASE + 0x10) & 2u) == 0u) { }
Xil_Out32(RO_BASE + 0x10, 2u);
uint32_t f = Xil_In32(RO_BASE + 0x20);
```

Pełny przykład: **`software/mb_axi/main.c`**.

---

## Piny (Arty S7)

| Pin | Sygnał |
|-----|--------|
| L17 | `ro_scope` — wyjście po dzielniku (TARGET MHz) |
| L18 | `ro_scope_ring` — surowy pierścień |
| LED | TARGET[3:0] / stan pomiaru |
| btn[3] | reset pierścienia (HIGH = reset) |

---

## Parametry IP

W `ro_top_arty_axi_bd_wrap`: **`RO_BANKS=8`**, **`MEAS_GATE_CYCLES_DEFAULT=60000`**.

Po zmianie parametrów: **Re-customize IP** w BD lub ponownie uruchom skrypt TCL.
