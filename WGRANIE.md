# Wgrywanie na płytkę

## Wymagania

- Digilent **Arty S7-50** pod USB (JTAG + UART)
- **Vivado 2018.3** (`C:\Xilinx\Vivado\2018.3`)
- Pliki w repo: `bitstreams/v1_uart.bit`, `firmware/ro_ring_app.elf`

## PowerShell (zalecane)

```powershell
cd ring_oscilator_arty-s7
.\scripts\flash_and_uart.ps1
```

Inny port COM:

```powershell
.\scripts\flash_and_uart.ps1 -ComPort COM5
```

## Git Bash

```bash
./scripts/flash_and_uart.sh
# COM_PORT=COM5 ./scripts/flash_and_uart.sh
```

## Tylko JTAG (bez testu UART)

```powershell
.\scripts\flash_board.ps1
```

## Ręcznie (xsdb)

```powershell
C:\Xilinx\Vivado\2018.3\bin\xsdb.bat scripts\program_v1.tcl
```

## Po wgraniu

1. **SW0 = ON**
2. Terminal **9600 8N1** (np. COM13)
3. `HELP` → `CLEAR` → `CAL` → `SET 1M`
