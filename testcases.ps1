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

# Log Date & Time
Add-Content $logfile -Value (Get-Date)
Add-Content $logfile -Value $divider

# SentinelOne Details
Add-Content $logfile -Value "SentinelOne Details"
Add-Content $logfile -Value $divider

# Check if SentinelOne Service is Installed
$SentinelService = Get-Service -Name SentinelAgent -ErrorAction SilentlyContinue
if ($SentinelService) {
    Add-Content $logfile -Value "Agent Service Found: $($SentinelService.DisplayName) - Status: $($SentinelService.Status)"
} else {
    Add-Content $logfile -Value "Error: SentinelOne Agent Service Not Found!"
}

# Fetching SentinelOne Agent JSON Data
try {
    $SentinelHelper = New-Object -ComObject 'SentinelHelper.1'
    $data = $SentinelHelper.GetAgentStatusJSON() | ConvertFrom-Json
    Add-Content $logfile -Value "Agent Status JSON:"
    Add-Content $logfile -Value ($data | Out-String)
} catch {
    Add-Content $logfile -Value "Error: Unable to fetch SentinelOne Agent Data. COM Object may not be registered."
}

# Ping SentinelOne Management URL
if ($data.'mgmt-url') {
    $url = ($data.'mgmt-url' -split "https://")[-1]
    Add-Content $logfile -Value "Network Connectivity Check"
    
    $pingResult = Test-NetConnection -ComputerName $url -InformationLevel Detailed
    Add-Content $logfile -Value ($pingResult | Out-String)
} else {
    Add-Content $logfile -Value "Error: SentinelOne Management URL not found in agent data."
}


# WMI test to see issues
try {
    $s1Process = Get-WmiObject Win32_Process -Filter "Name='SentinelAgent.exe'" -ErrorAction Stop
    if ($s1Process) {
        Add-Content $logfile -Value "SentinelOne Process Found via WMI: $($s1Process.Name)"
    } else {
        Add-Content $logfile -Value "Warning: SentinelOne process NOT found via WMI."
    }
} catch {
    Add-Content $logfile -Value "Error: WMI Query for SentinelOne process failed. WMI may be corrupted."
}

Add-Content $logfile -Value $divider
Add-Content $logfile -Value "Log Collection Completed"