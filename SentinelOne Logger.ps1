#SentinelOne Debugger Tool

#define file name``
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$filename = hostname
$filename = 'SentinelOne_' + $filename + "_" + (Get-Date -format "MMMddyyyyHHmm") +'.log' #time
New-Item -path $DesktopPath -name $filename -ItemType "file"
$logfile = $DesktopPath+'\'+$filename

# Define divider
$divider  = '================================================================================='

# Log Date & Time
Add-Content $logfile -Value (Get-Date)
Add-Content $logfile -Value (systeminfo)
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

# WMI test to verify if WMI is functioning correctly
try {
    $wmiresponse = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop | Out-String 
    Add-Content $logfile -Value "WMI is functioning correctly."
    Add-Content $logfile -Value ($wmiresponse)
} catch {
    Add-Content $logfile -Value "Error: WMI is not responding. It may be corrupted or disabled."
}

#Add EventViewer last 10 event viewer logs

Add-Content $logfile -Value $divider