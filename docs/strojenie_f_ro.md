## Jak zmieniać częstotliwość pierścienia (`f_ro`) i obserwacji na JA

### Mapa presetów `sw[3:1]` / `FREQ[2:0]` (binarnie: SW3 = MSB)

W `arty_tune_preset.sv` przyjęta jest **logika pod lab**:

| `preset` (bin) | `tune` (skrót) | Typowa `f_ro` pierścienia | Co idzie na JA (po MMCM) |
|----------------|----------------|---------------------------|---------------------------|
| **000** | `10'h3FF` (najwięcej opóźnień przez mux) | **najniżej** w skali preseta (tens MHz zależnie od temp/układu) | **MSB licznika `ring_ro_edge_div`** ⇒ ok. **f_ro / 2ⁿ** (domyślnie n=6 ⇒ **≈ /64** zboczy) — **cel ~1 MHz na scope** przy f_ro rzędu dziesiątek MHz |
| … | stopniowo mniej jedynek | rośnie między 000 a 111 | surowe `ro_out` |
| **111** | `10'h000` (bypass segmentów) | **najwyżej** przy `RO_NUM_TAIL_INVERTERS=2` | surowe `ro_out` ⇒ **cel rzędu ~150 MHz** (różnice sztuka / PVT) |

**Uwaga fizyczna Arty**: jeśli zmierzony kierunek preseta jest odwrotny (HIGH/LOW przełączników), zamień kolejność w `sw[3:1]` w topie albo zaneguj bity w kodzie — logika RTL mapuje **„000 = wolno + dzielnik na JA”**.

### Dobór ~1 MHz na `000`

Parametr **`PRESET000_SCOPE_DIVIDER_W`** w `ro_top_arty.sv` (= szerokość licznika taktowanego `posedge ro_out`):

- przybliżenie: **`f_ja_slow ≈ f_ro / 2^W`** przy sensownej symetrycznej fali z pierścienia;
- domyślnie **W=6** → przy **~64 MHz** wewnętrznie dostajesz **~1 MHz** na JA;
- przy niżej `f_ro` zwiększ **W** (np. 7) lub zmniejsz (np. 5) wg pomiaru.

### Co dalej reguluje szerokość zakresu

1. **`RO_NUM_TAIL_INVERTERS`** (domyślnie **2** dla maksimum na `111`): parzyste 2,4,… — **większy** ⇒ wszystkie presety trochę wolniej.
2. **Środkowe słowa w `arty_tune_preset.sv`** — płynniejsza skala MHz między 000 i 111.
3. **`TUNE` przez AXI (OR)** — dokłada invertery ⇒ zwykle **obniża** `f_ro` (wszystkie presety w danym strojeniu).

### Dlaczego na JA często widzisz „sinus”

- pojemność sondy, BW-limit Rigola, jitter — patrz wcześniejsze uwagi laboratoryjne.

### Pomiar `meas_edge_count` / LED

Licznik w `clk_12mhz` nadal dokonuje zboczy **na zsynchronizowanym `ro_out`** (bez dzielnika) — przy `111` bardzo dużej `f_ro` pomiar bywa tylko orientacyjny. **WYJście JA przy `000`** pokazuje **już dzielnik** (wolniej), więc numery wyświetlacza scope nie muszą się zgadzać z pomiarem krawędzi pierścienia 1:1.

### Aktualizacja Block Design po zmianie parametrów wrappera IP

Jeśli używasz ścieżki MicroBlaze, po zmianie `RO_NUM_TAIL_INVERTERS` / `PRESET000_SCOPE_DIVIDER_W` uruchom **Re-customize IP** lub wygeneruj BD ponownie, żeby XCI zebrał aktualny model.
