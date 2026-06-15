$portName = "COM13"
$baud = 9600

Add-Type -AssemblyName System.IO.Ports
$sp = New-Object System.IO.Ports.SerialPort $portName, $baud, None, 8, One
$sp.ReadTimeout = 3000
$sp.NewLine = "`r`n"
try {
    $sp.Open()
    Write-Host "Opened $portName @ $baud"
    Start-Sleep -Milliseconds 500
    $deadline = (Get-Date).AddSeconds(3)
    $buf = New-Object System.Text.StringBuilder
    while ((Get-Date) -lt $deadline) {
        try {
            $ch = $sp.ReadChar()
            [void]$buf.Append([char]$ch)
        } catch [System.TimeoutException] {
            # keep waiting until deadline
        }
    }
    $text = $buf.ToString()
    if ($text.Length -gt 0) {
        Write-Host "RECEIVED ($($text.Length) chars):"
        Write-Host $text
    } else {
        Write-Host "NO DATA on $portName (empty read)"
    }
    $sp.Write("HELP`r")
    Start-Sleep -Milliseconds 800
    $resp = $sp.ReadExisting()
    if ($resp) {
        Write-Host "RESPONSE to HELP:"
        Write-Host $resp
    } else {
        Write-Host "NO RESPONSE to HELP"
    }
} catch {
    Write-Host "ERROR: $_"
} finally {
    if ($sp.IsOpen) { $sp.Close() }
}
