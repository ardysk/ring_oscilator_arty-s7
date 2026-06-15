# Wgranie na Arty S7 — Vivado 2018.3 + Xilinx SDK (bez Vitis)

Masz **Vivado 2018** → soft MicroBlaze wgrywasz przez **Xilinx SDK 2018.3**, nie Vitis.

SDK zwykle jest tutaj:
`C:\Xilinx\SDK\2018.3\bin\xsdk.bat`

---

## Wybierz wariant

| Wariant | Bitstream | Soft (SDK) | Sterowanie |
|---------|-----------|--------------|------------|
| **A — prosty** | `ro_top_arty.bit` | **nie trzeba** | przyciski + DIP |
| **B — MicroBlaze** | `mb_ro_system_wrapper.bit` | **tak, SDK** | rejestry AXI z C |

---

## Wariant A — tylko FPGA (przyciski, bez SDK)

### 1. Zbuduj bitstream (jeśli jeszcze nie ma)

```powershell
cd C:\Users\HP\Downloads\csd_lab6\ring_oscilator_prj
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source scripts/build_arty_bitstream.tcl
```

### 2. Wgraj w Vivado

1. Otwórz `ring_oscilator_prj.xpr`
2. **Flow → Open Hardware Manager → Open Target → Auto Connect**
3. Prawy klik **xc7s50_0** → **Program Device**
4. Plik: `ring_oscilator_prj.runs\impl_1\ro_top_arty.bit`
5. **Program**

### 3. Użycie

- SW[0]=1 — włącz pierścień
- BTN[1]/BTN[0] — ±1 MHz (target)
- BTN[2] — pomiar
- JA L17 / L18 — oscyloskop

---

## Wariant B — MicroBlaze + program C (SDK)

### Krok 1 — bitstream FPGA

```powershell
cd C:\Users\HP\Downloads\csd_lab6\ring_oscilator_prj
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source scripts/create_mb_ro_axi_bd.tcl
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source scripts/build_mb_bitstream.tcl
& "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source scripts/export_hw_for_sdk.tcl
```

Powstaje: `export\mb_ro_system_wrapper.hdf`

**Albo ręcznie w Vivado GUI** (po Implementation OK):

1. **File → Export → Export Hardware…**
2. Zaznacz **Include bitstream**
3. Zapisz jako `export\mb_ro_system_wrapper.hdf`

### Krok 2 — wgraj bitstream (Hardware Manager)

Jak wyżej, ale plik:
`ring_oscilator_prj.runs\impl_1\mb_ro_system_wrapper.bit`

*(SDK przy „Run” też może wgrać bitstream, jeśli w projekcie jest HDF z bitem.)*

### Krok 3 — projekt w Xilinx SDK 2018.3

1. Uruchom **Xilinx SDK 2018.3** (`xsdk.bat`)
2. Wybierz workspace, np. `C:\Users\HP\Downloads\csd_lab6\ring_oscilator_prj\sdk_workspace`
3. **File → New → Application Project**
4. **Name:** `ro_ring_app`
5. **Hardware Platform:** Browse → wybierz `export\mb_ro_system_wrapper.hdf`
6. **Processor:** `microblaze_0`
7. **OS:** `standalone`
8. **Template:** **Empty Application**
9. Finish

### Krok 4 — wklej kod + ustaw stdout (UART)

1. Skopiuj `software\mb_axi\main.c` → `ro_ring_app\src\main.c`
2. **Kluczowe:** prawy klik **ro_ring_app_bsp** → **Board Support Package Settings**
   - **stdin** → `axi_uartlite_0`
   - **stdout** → `axi_uartlite_0`
3. **OK** → prawy klik BSP → **Re-generate BSP Sources**
4. **Build** aplikacji

Program wypisuje `f=... Hz` co pomiar (~5 ms bramki).

### Odczyt f na PC (terminal COM)

1. Po wgraniu bitstreamu + `.elf` podłącz Arty USB
2. W **Menedżerze urządzeń** znajdź port **COM** (Digilent / USB Serial)
3. **Tera Term** lub **PuTTY**: **115200**, 8N1, brak flow control
4. Zobaczysz np.:
   ```
   RO ring: init
   target=25 MHz (wyjscie JA), bramka=60000 cykli
   f=48234567 Hz
   f=48234567 Hz
   ```

*(Przy debug w SDK tekst może być też w zakładce **SDK Terminal** / konsola JTAG.)*

### Krok 5 — zbuduj i uruchom

1. Podłącz Arty USB (JTAG)
2. **Xilinx → Program FPGA** (jeśli SDK pyta — wybierz bitstream z HDF)
3. Prawy klik **ro_ring_app** → **Run As → Launch on Hardware (System Debugger)**

MicroBlaze startuje `main()` — LED + pierścień + pomiar FREQ_HZ.

### Krok 7 — debug (opcjonalnie)

**Run As → Launch on Hardware (System Debugger)** w trybie debug — breakpoint w `main`, podgląd `f_hz`.

---

## Zmiana f z programu (po wgraniu)

```c
Xil_Out32(0x44A00000 + 0x24, 25);   // TARGET MHz
Xil_Out32(0x44A00000 + 0x00, 1);    // włącz pierścień
```

Pełny przykład: `software/mb_axi/main.c`

---

## Typowe problemy (SDK 2018)

| Problem | Rozwiązanie |
|---------|-------------|
| Nie ma SDK w menu Vivado | Osobno: `C:\Xilinx\SDK\2018.3\bin\xsdk.bat` |
| Brak `.hdf` | Export Hardware w Vivado lub skrypt `export_hw_for_sdk.tcl` |
| Run failed / no target | Hardware Manager: czy widać `xc7s50`? |
| Program się nie resetuje | btn[3] nie wciśnięty (reset pierścienia) |

---

## Szybka rekomendacja na lab

Jeśli **nie potrzebujesz C** — wariant **A** (`ro_top_arty.bit`) jest najszybszy: jeden plik `.bit`, zero SDK.

Jeśli **musisz** pisać rejestry AXI — wariant **B** z SDK 2018.3.
