# Wgrywa bitstream V1 + firmware na Arty S7-50 (JTAG)
param(
    [string]$VivadoRoot = "C:\Xilinx\Vivado\2018.3",
    [string]$ComPort = "COM13"
)

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $PSScriptRoot
$xsdb = Join-Path $VivadoRoot "bin\xsdb.bat"
$tcl = Join-Path $PSScriptRoot "program_v1.tcl"
$bit = Join-Path $proj "bitstreams\v1_uart.bit"
$elf = Join-Path $proj "firmware\ro_ring_app.elf"

if (-not (Test-Path $xsdb)) {
    Write-Error "Nie znaleziono xsdb: $xsdb (ustaw -VivadoRoot)"
}
if (-not (Test-Path $bit)) {
    Write-Error "Brak bitstreamu: $bit"
}
if (-not (Test-Path $elf)) {
    Write-Error "Brak firmware: $elf"
}

Write-Host "=== Wgrywanie V1 na plytke ===" -ForegroundColor Cyan
Write-Host "BIT: $bit"
Write-Host "ELF: $elf"
Write-Host ""

& $xsdb $tcl
if ($LASTEXITCODE -ne 0) {
    Write-Error "Wgrywanie nie powiodlo sie (kod $LASTEXITCODE). Sprawdz JTAG i zasilanie plytki."
}

Write-Host ""
Write-Host "Gotowe. UART: $ComPort 9600 8N1, SW0=ON, wpisz HELP" -ForegroundColor Green
