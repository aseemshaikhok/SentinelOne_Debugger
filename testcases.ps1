# Define file name - For debug only
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$filename = "$env:COMPUTERNAME`_SentinelOne.log"
$logfile = Join-Path $DesktopPath $filename

# Remove existing log file if present
if (Test-Path -Path $logfile) {
    Remove-Item -Path $logfile -Force
}

New-Item -Path $logfile -ItemType File | Out-Null

# Define divider
$divider  = '================================================================================='

######################### SentinelOne Info #########################

#hotfix information
Write-Host "Generating System logs" -BackgroundColor Green -ForegroundColor Black
$eventLogs = Get-EventLog -LogName System | Where-Object { $_.Message -match "Sentinel" } | Select-Object -First 10 

if ($eventLogs) {
    Add-Content $logfile -Value ($eventLogs | Format-Table -AutoSize | Out-String)
}
#Application logs - SentinelOne search



#System logs - SentinelOne search