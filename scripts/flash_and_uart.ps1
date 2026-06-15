# Wgranie V1 (bitstream + MicroBlaze) + test UART @ 9600
param(
    [string]$VivadoRoot = "C:\Xilinx\Vivado\2018.3",
    [string]$ComPort = "COM13",
    [int]$Baud = 9600,
    [switch]$SkipUartTest
)

$ErrorActionPreference = "Stop"
& "$PSScriptRoot\flash_board.ps1" -VivadoRoot $VivadoRoot -ComPort $ComPort

if ($SkipUartTest) { return }

Start-Sleep -Seconds 2
Write-Host "=== Test UART $ComPort @ $Baud ===" -ForegroundColor Cyan

Add-Type -AssemblyName System.IO.Ports
$sp = New-Object System.IO.Ports.SerialPort $ComPort, $Baud, None, 8, One
$sp.ReadTimeout = 500
$sp.NewLine = "`r`n"
try {
    $sp.Open()
    Start-Sleep -Milliseconds 500
    $sp.DiscardInBuffer()
    $sp.Write("HELP`r`n")
    $deadline = (Get-Date).AddSeconds(6)
    $buf = ""
    while ((Get-Date) -lt $deadline) {
        try {
            $buf += $sp.ReadExisting()
            if ($buf -match "RO>" -or $buf -match "RO Synthesizer") { break }
        } catch { }
        Start-Sleep -Milliseconds 50
    }
    if ($buf.Trim()) {
        Write-Host $buf
        Write-Host "OK: UART dziala" -ForegroundColor Green
    } else {
        Write-Warning "Brak odpowiedzi na $ComPort — sprawdz port i SW0=ON"
    }
} finally {
    if ($sp.IsOpen) { $sp.Close() }
}
