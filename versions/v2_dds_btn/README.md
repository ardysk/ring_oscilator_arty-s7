# Wersja 2 — Przyciski + DDS + ścieżka RO z buforem

## Cel

Zmiana docelowej częstotliwości **przyciskami** (z debounce), generacja czystego sygnału przez **DDS**, równoległa ścieżka pomiarowa RO z MUX i buforem wyjścia.

**Top FPGA:** `ro_top_v2` (czysty RTL, bez MicroBlaze)

## Pliki wersji

| Katalog | Pliki |
|---------|-------|
| `rtl/common/btn_debouncer.sv` | Filtr drgań przycisku |
| `rtl/common/ro_bank_mux.sv` | Wybór banku pierścienia |
| `rtl/common/ro_output_buffer.sv` | Bufor wyjścia scope |
| `rtl/v2_dds_btn/btn_freq_selector.sv` | UP/DOWN/MEAS → target MHz |
| `rtl/v2_dds_btn/dds_core.sv` | DDS kwadrat z MSB fazy |
| `rtl/v2_dds_btn/freq_to_ftw.sv` | Hz → FTW |
| `rtl/v2_dds_btn/dds_phase_accum.sv` | Akumulator fazy |
| `rtl/v2_dds_btn/ro_top_v2.sv` | Top całości |
| `sim/v2_dds_btn/` | `tb_btn_debouncer.sv`, `tb_dds_core.sv` |
| `constraints/v2_dds_btn/pins.xdc` | Piny Arty S7 |
| `scripts/build_v2.tcl` | Build bitstream V2 |

## Mapowanie przycisków

| Przycisk | Funkcja |
|----------|---------|
| btn[0] | UP — zwiększ target MHz o 1 |
| btn[1] | DOWN — zmniejsz target MHz o 1 |
| btn[2] | MEAS — wyzwól pomiar RO |
| btn[3] | RESET (aktywny HIGH) |

## Jak działa kod

### Debouncer (`btn_debouncer`)

1. Double-flop synchronizacja wejścia.
2. Licznik 20 ms — stabilizacja przed zmianą `btn_stable`.
3. `btn_posedge` — jeden cykl po naciśnięciu.

### DDS (`dds_core`)

```
FTW = f_out * 2^32 / F_CLK
phase += FTW każdy cykl 12 MHz
dds_out = phase[31]   // kwadrat, ostre zbocza
```

Przy `F_CLK = 12 MHz` rozdzielczość częstotliwości DDS ≈ 2.8 Hz (dla pełnego zakresu).

### Ścieżka RO (bez dotykania pierścieni z GPIO)

```
8× ring → ro_bank_mux → ring_prog_toggle_div → ro_output_buffer → arty_scope_freq_mux → JA
```

Sterowanie: `btn_freq_selector` → `target_mhz` → `ro_target_map` → bank + divider.

**GPIO nigdy nie trafia w tune_sel pierścienia bezpośrednio** — tylko przez mapowanie banków.

## Zestawienie

### Synteza i bitstream

```powershell
vivado -mode batch -source scripts/build_v2.tcl
```

Wynik: `bitstreams/v2_dds_btn.bit` + `bitstreams/v2_dds_btn_timing.rpt`

Skrypt wyłącza Block Design na czas buildu i przywraca go po zakończeniu (żeby V1 nadal działał).

### Test na płytce

| Sygnał | Pin | Opis |
|--------|-----|------|
| Scope RO | JA L17 | Po dzielniku + buforze |
| Scope ring | JA L18 | Surowy pierścień |
| DDS out | M14 | Kwadrat ~target Hz |
| LED[3:0] | E18…H15 | Dolne bity target MHz (lub `0xA` gdy busy) |

## Symulacja

### Testbenchy

| TB | Moduł | Co weryfikuje |
|----|-------|----------------|
| `tb_btn_debouncer.sv` | `btn_debouncer` | Odfiltrowanie 5× drgań, wykrycie stabilnego zbocza |
| `tb_dds_core.sv` | `dds_core` | Okres i częstotliwość przy `freq_hz = 1_000_000` |

### Uruchomienie

```powershell
vivado -mode batch -source scripts/run_sim_all.tcl
```

Logi: `sim/results/btn_debouncer.log`, `sim/results/dds_core.log`

### Wyniki (XSim 2018.3, 2026-06-06)

**Debouncer:**
```
PASS: debouncer detected 1 posedge(s)
```

**DDS:**
```
DDS: edges=8000 period=1000.0 ns f_meas=1000000 Hz
PASS: ~1 MHz
```

## Timing i bitstream

| Parametr | Wartość |
|----------|---------|
| Plik | `bitstreams/v2_dds_btn.bit` |
| WNS | +48.7 ns |
| Failing endpoints | 0 |

## Dlaczego DDS + RO?

- **DDS** — przewidywalna częstotliwość na wyjściu, ostre zbocza do porównania z RO.
- **RO** — zgodność z celem laboratorium (LUT, asynchroniczna pętla).
- **Debouncer osobny moduł** — wymaganie projektu, reużywalność.

## Zakres częstotliwości

- Target: **1..511 MHz** (logiczna skala użytkownika).
- DDS realny max przy 12 MHz clk: ~6 MHz (Nyquist) — powyżej tego służy ścieżka RO + dzielnik.

## Firmware

Brak — cała logika w PL. Zobacz też `sw/v2_dds_btn/README.md`.
