# Wersja 3 — TFT GC9A01 (RO + wyświetlacz zamiast samego terminala)

## Cel

Wizualizacja target MHz i zmierzonej częstotliwości na **okrągłym wyświetlaczu TFT 240×240** (sterownik **GC9A01**, SPI 3,3 V). Opcjonalnie równoległy UART jak w V1.

Moduł: [GC9A01 240×240 round TFT](https://elektroweb.pl/pl/moduly/1786-wyswietlacz-lcd-okragly-128-240x240-tft-sterownik-gc9a01-spi-33v.html)

**Top FPGA:** `ro_top_v3_wrapper`

## Pliki wersji

| Katalog | Pliki |
|---------|-------|
| `rtl/v3_tft/spi_master.sv` | SPI CPOL=0 CPHA=0 |
| `rtl/v3_tft/gc9a01_driver.sv` | Init + wypełnienie kolorem z freq |
| `rtl/v3_tft/ro_top_v3.sv` | RO + TFT (bez MB) |
| `rtl/v3_tft/ro_top_v3_wrapper.v` | Top z pinami płytki |
| `rtl/common/ro_top_arty_axi.sv` | Porty monitorujące `mon_*` (wariant AXI) |
| `sim/v3_tft/tb_spi_master.sv` | Test transmisji SPI |
| `constraints/v3_tft/pins.xdc` | Piny Arty S7 + PMOD JC |
| `scripts/build_v3.tcl` | Build bitstream V3 |

## Podłączenie TFT (PMOD JC — Arty S7-50)

| Sygnał FPGA | PMOD JC | Opis |
|-------------|---------|------|
| tft_sck | JC1 (U15) | SPI clock |
| tft_mosi | JC2 (V16) | SPI data |
| tft_cs_n | JC3 (U17) | Chip select |
| tft_dc | JC4 (U18) | Data/command |
| tft_rst_n | JC7 (U16) | Reset |
| 3V3 / GND | — | VCC, GND modułu TFT |

**Uwaga:** moduł jest 3,3 V — bezpośrednio kompatybilny z Arty S7.

## Jak działa kod

1. `ro_top_v3` integruje rdzeń RO, mapowanie target MHz i pomiar częstotliwości.
2. `gc9a01_driver` po resecie wysyła sekwencję init GC9A01 przez `spi_master`.
3. Kolor wypełnienia ekranu koduje zmierzoną częstotliwość (`color_from_freq`).
4. Przyciski / pomiar — analogicznie do V2 (debouncer + selector).

## Zestawienie

### Build

```powershell
vivado -mode batch -source scripts/build_v3.tcl
```

Wynik: `bitstreams/v3_tft.bit` + `bitstreams/v3_tft_timing.rpt`

### Test na płytce

1. Podłącz moduł TFT do **PMOD JC** (piny w tabeli powyżej).
2. Wgraj `bitstreams/v3_tft.bit` przez Hardware Manager (SPI x4).
3. Po resecie ekran powinien się zainicjalizować i wypełnić kolorem zależnym od częstotliwości RO.
4. Scope: JA L17 / L18 jak w V2.

## Symulacja

### Testbench

| Plik | Co weryfikuje |
|------|----------------|
| `sim/v3_tft/tb_spi_master.sv` | Transmisja bajtu `0xA5`, ≥8 zboczy SCK, sygnał `done` |

Pełny init GC9A01 (240×240×2 bajty) trwa zbyt długo w symulacji — weryfikacja wizualna na hardware.

### Uruchomienie

```powershell
vivado -mode batch -source scripts/run_sim_all.tcl
```

Log: `sim/results/spi_master.log`

### Wyniki (XSim 2018.3, 2026-06-06)

```
SPI TX done, sck_edges=16 mosi=1
PASS: byte transmitted
```

## Timing i bitstream

| Parametr | Wartość |
|----------|---------|
| Plik | `bitstreams/v3_tft.bit` |
| WNS | +78.2 ns |
| Failing endpoints | 0 |

## Dlaczego GC9A01 w PL, a nie w SW?

- SPI bit-bang z MicroBlaze obciążałby CPU i jitterował pomiar.
- FSM w `gc9a01_driver` odświeża wyświetlacz równolegle z pomiarem RO.
- Kolorystyka z `freq_hz` daje natychmiastową informację bez parsowania terminala.

## Rozszerzenia (opcjonalne)

- Font 8×16 w `gc9a01_driver` — wyświetlanie cyfr MHz/Hz.
- Odświeżanie tylko przy zakończeniu pomiaru (oszczędność SPI).
- Połączenie z firmware V1 (`sw/v1_uart/`) jeśli top wróci do wariantu MicroBlaze + TFT.

## Rozwiązywanie problemów

| Problem | Rozwiązanie |
|---------|-------------|
| Biały/czarny ekran | Sprawdź PMOD JC, reset TFT, zasilanie 3V3 |
| Błąd pinów w Vivado | Użyj `constraints/v3_tft/pins.xdc` (JC, nie JA) |
| DRC UCIO-1 na `tft_rst_n` | Upewnij się, że włączone `pins_v3_tft.xdc` |
