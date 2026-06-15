# Szybkie wgrywanie (PowerShell)

```powershell
cd C:\Users\HP\Downloads\csd_lab6\ring_oscilator_spartan7
.\scripts\flash_and_uart.ps1
```

Git Bash:

```bash
./scripts/flash_and_uart.sh
```

Wymagania:
- Płytka Arty S7-50 pod USB (JTAG + UART)
- Vivado 2018.3 (`C:\Xilinx\Vivado\2018.3`)
- Pliki: `bitstreams/v1_uart.bit`, `firmware/ro_ring_app.elf`

Po wgraniu: terminal **COM13**, **9600 8N1**, **SW0=ON**, komenda `HELP`.

## Pełny rebuild bitstreamu

```powershell
.\scripts\build_bitstream.ps1
.\scripts\flash_board.ps1
```

## Tylko Tcl (xsdb)

```powershell
C:\Xilinx\Vivado\2018.3\bin\xsdb.bat scripts\program_v1.tcl
```
