# Pelny build V1: presety + Vivado -> bitstreams/v1_uart.bit
param(
    [string]$VivadoRoot = "C:\Xilinx\Vivado\2018.3"
)

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $PSScriptRoot
$vivado = Join-Path $VivadoRoot "bin\vivado.bat"

if (-not (Test-Path $vivado)) {
    Write-Error "Nie znaleziono Vivado: $vivado"
}

Push-Location $proj
try {
    python scripts\gen_ro_presets.py
    if ($LASTEXITCODE -ne 0) { throw "gen_ro_presets.py failed" }

    & $vivado -mode batch -source scripts\build_v1.tcl -notrace
    if ($LASTEXITCODE -ne 0) { throw "build_v1.tcl failed" }

    Write-Host ""
    Write-Host "OK: bitstreams\v1_uart.bit" -ForegroundColor Green
} finally {
    Pop-Location
}
