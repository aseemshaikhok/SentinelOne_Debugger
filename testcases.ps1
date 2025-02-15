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

#Look for Event-Viewer
Add-Content $logfile -Value (Get-WinEvent -LogName 'SentinelOne/Operational' -MaxEvents 10 | Format-Table -Wrap | Out-String)
Add-Content $logfile -Value $divider
Add-Content $logfile -Value "Log Collection Completed"