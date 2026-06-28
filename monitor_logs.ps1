param(
    [int]$Interval = 3
)

$logFile = "C:\Users\User\Desktop\Flutter\Chat\chatserver\backend.log"
$errFile = "C:\Users\User\Desktop\Flutter\Chat\chatserver\backend.err"
$lastLogSize = 0
$lastErrSize = 0

if (Test-Path $logFile) { $lastLogSize = (Get-Item $logFile).Length }
if (Test-Path $errFile) { $lastErrSize = (Get-Item $errFile).Length }

Write-Host "Monitoring started at $(Get-Date -Format 'HH:mm:ss')"
Write-Host "Press Ctrl+C to stop"

while ($true) {
    if (Test-Path $logFile) {
        $currentSize = (Get-Item $logFile).Length
        if ($currentSize -gt $lastLogSize) {
            $content = Get-Content $logFile -Tail 10
            Write-Host "`n=== LOG UPDATE ($(Get-Date -Format 'HH:mm:ss')) ==="
            $content | ForEach-Object { Write-Host $_ }
            $lastLogSize = $currentSize
        }
    }
    
    if (Test-Path $errFile) {
        $currentSize = (Get-Item $errFile).Length
        if ($currentSize -gt $lastErrSize) {
            $content = Get-Content $errFile -Tail 5
            Write-Host "`n=== ERROR UPDATE ($(Get-Date -Format 'HH:mm:ss')) ==="
            $content | ForEach-Object { Write-Host "ERROR: $_" }
            $lastErrSize = $currentSize
        }
    }
    
    Start-Sleep -Seconds $Interval
}
