# Ustawianie częstotliwości po wgraniu bitstreamu

## Ścieżka A — `ro_top_arty` (przyciski / DIP, bez MicroBlaze)

1. **SW[0] = 1** — włącz pierścień (`ro_en`).
2. **BTN[1]** / **BTN[0]** — zwiększ / zmniejsz **docelowe MHz** (`target_mhz`, 1…511). Na LED widać młodsze 4 bity targetu.
3. Sprzęt wybiera **bank pierścienia** (0…7) i **dzielnik** na pinie **JA L17** (`ro_scope`).
4. **SW[3] = 1** — wyłącz dzielnik (surowe zbliżone do f pierścienia, dla wysokich MHz).
5. **BTN[2]** — impuls pomiaru (~5 ms domyślnie); po zakończeniu LED pokazuje młodsze bity **zmierzonej f w Hz** (`meas_freq_hz`).
6. **JA L18** (`ro_scope_ring`) — zawsze zsynchronizowany tap pierścienia (bez dzielnika programowego).

Kalibracja: po pomiarze na oscyloskopie dopasuj parametry `F_RO_EST_MHZ_BANK0/7` w `ro_top_arty.sv`, jeśli target MHz nie trafia w rzeczywistość.

---

## Ścieżka B — MicroBlaze + AXI (`mb_ro_system_wrapper`)

Mapa rejestrów (baza domyślnie `0x44A00000`):

| Offset | Nazwa | Opis |
|--------|--------|------|
| `0x00` | CTRL | bit0 `ro_en`, bit1 impuls `meas_start` |
| `0x08` | TUNE | OR na strojenie aktywnego banku (dokładniejsze strojenie) |
| `0x0C` | GATE | długość bramki w cyklach 12 MHz (`60000` ≈ 5 ms) |
| `0x20` | **FREQ_HZ** | odczyt: zmierzone **Hz** po pomiarze |
| `0x24` | **TARGET** | zapis: docelowe **MHz** wyjścia (1…511) |

### Minimalna sekwencja (C)

```c
Xil_Out32(RO_REG_GATE, 60000u);      // ~5 ms
Xil_Out32(RO_REG_TARGET, 25u);       // cel ~25 MHz na JA (po dzielniku)
Xil_Out32(RO_REG_CTRL, 1u);          // ro_en

/* impuls pomiaru */
Xil_Out32(RO_REG_CTRL, 3u);
Xil_Out32(RO_REG_CTRL, 1u);
/* czekaj STATUS[1], potem */
uint32_t f = Xil_In32(RO_REG_FREQ_HZ);
```

Pełny przykład: `software/mb_axi/main.c`.

### Zmiana f w dowolnym momencie

1. Zapisz nową wartość do **TARGET** (np. `10` → ~10 MHz, `150` → bank max + bypass dzielnika).
2. Opcjonalnie dopisz **TUNE** (np. `0x040`) dla drobnej korekty w dół.
3. Uruchom pomiar (impuls CTRL) i odczytaj **FREQ_HZ**, żeby zweryfikować wynik.

Przy **TARGET ≥ 60 MHz** dzielnik jest automatycznie omijany (surowy pierścień / wysokie MHz).

---

## Wzór (gdy liczysz ręcznie z EDGES)

\[
f_{\mathrm{Hz}} \approx \frac{\texttt{EDGES} \times 12\,000\,000}{2 \times \texttt{GATE}}
\]

Rejestr **FREQ_HZ** liczy to samo w sprzęcie po każdym pomiarze.
