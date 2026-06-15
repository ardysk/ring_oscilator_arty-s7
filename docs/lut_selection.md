# Wybór LUT-ów i mapowanie strojenia — maksymalny zakres częstotliwości

## Dlaczego LUT, a nie BUFG/MMCM jako źródło ROSC?

Oscylator pierścieniowy (RO) w tym projekcie musi być **asynchroniczny** względem `clk_12mhz`.
Pętla kombinacyjna z inwerterami LUT:

- nie wymaga zewnętrznego kwarcu poza 12 MHz (używanym tylko do pomiaru),
- daje szeroki, ciągły zakres `f_ro` przez strojenie opóźnień,
- jest zgodna z celem laboratorium (propagacja w fabric FPGA).

MMCM (`arty_scope_freq_mux`) służy **wyłącznie** do próbkowania na JA — nie generuje `f_ro`.

## Struktura `ring_inverter_tunable`

Każdy bit `tune_sel[k]` wybiera segment toru:

| `tune_sel[k]` | Tor | Dodatkowe opóźnienie |
|---------------|-----|----------------------|
| 0 | bypass (`tnode[k]` → `tnode[k+1]`) | ~0 (tylko MUX) |
| 1 | 2 inwertery LUT (`~(~tnode[k])`) | 2× LUT delay |

**Kluczowa decyzja projektowa:** MUX + LUT6H są **zawsze** w torze dla obu wariantów.
Dzięki temu różnica między `0` a `1` to głównie **0 vs 2 inwertery**, a nie skok
o cały segment MUX — strojenie jest monotoniczne i przewidywalne.

`NUM_TAIL_INVERTERS = 2` (parzyste) zapewnia **nieparzystą** liczbę inwersji w pętli
(warunek oscylacji w sprzężeniu zwrotnym z NAND-enable).

## 8 banków — dyskretne pasma częstotliwości

`ro_bank_tune_pack` przypisuje każdemu bankowi stałą maskę 10-bitową `tune_sel`:

| Bank | `tune_sel` (hex) | Szac. f_ro [MHz] | Rola |
|------|------------------|------------------|------|
| 0 | 0x3FF (wszystkie 1) | ~48 | Najwolniejszy — max opóźnień |
| 1 | 0x2DB | ~70 | |
| 2 | 0x1F7 | ~95 | |
| 3 | 0x155 | ~120 | Środek pasma |
| 4 | 0x0ED | ~145 | |
| 5 | 0x07B | ~165 | |
| 6 | 0x02D | ~175 | |
| 7 | 0x000 (wszystkie 0) | ~185 | Najszybszy — min opóźnień |

Wartości wybrane **empirycznie na Arty S7-50** tak, by:

1. bank 0 dawał `f_ro` możliwie niską (łatwy pomiar przy 12 MHz referencji),
2. bank 7 dawał najwyższą stabilną częstotliwość bez „zaniku” oscylacji,
3. kroki między bankami były w przybliżeniu równomierne w skali logarytmicznej.

Rejestr `csr_tune[9:0]` (V1/V3) pozwala **dokładniej** stroić w obrębie wybranego banku
(OR z maską bazową w `ro_top_arty_axi`).

## Mapowanie TARGET MHz → bank + dzielnik

`ro_target_map` realizuje zakres **1–511 MHz** na wyjściu scope:

```
bank = (target_mhz - 1) >> 6        // co 64 MHz nowy bank
half_edges = f_est_bank / (2 * target_mhz)
div_bypass = (target_mhz >= 60)     // przy wysokich f — surowy RO
```

- **Niski TARGET:** wolny bank + duży `half_edges` w `ring_prog_toggle_div`.
- **Wysoki TARGET:** szybki bank + bypass dzielnika.

Dzięki temu użytkownik widzi jednolitą skalę MHz, a hardware pracuje w bezpiecznym
zakresie każdego pierścienia.

## Atrybuty syntezy

Na węzłach pętli:

```systemverilog
(* KEEP = "TRUE" *)
(* DONT_TOUCH = "TRUE" *)
```

Zapobiegają optymalizacji, która zwinęłaby pętlę kombinacyjną do stałej logicznej.

## CDC przed pomiarem

`ro_async_to_ref_sync` (3 stadia, `ASYNC_REG`) — próbkowanie `ro_out` w domenie 12 MHz
bez zakładania współfazowości z pierścieniem. Pomiar `f_Hz`:

```
f_ro ≈ edge_count * F_REF / (2 * gate_cycles)
```

Przy `gate_cycles = 60000` (~5 ms) i `F_REF = 12 MHz` rozdzielczość ~200 Hz.
