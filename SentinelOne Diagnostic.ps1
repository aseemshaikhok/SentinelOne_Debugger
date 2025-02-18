#SentinelOne Diagnostic Tool

Write-Host "SentinelOne Diagnostic Script Started" -BackgroundColor Green -ForegroundColor Black

#define file name
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$filename = hostname
$filename = 'SentinelOne_' + $filename + "_" + (Get-Date -format "MMMddyyyyHHmm") +'.log' #time
New-Item -path $DesktopPath -name $filename -ItemType "file" | Select-Object DirectoryName
$logfile = $DesktopPath+'\'+$filename

# Define divider
$divider  = '================================================================================='

# Log Date & Time
Add-Content $logfile -Value ("SentinelOne " + (hostname) + " - " + (Get-Date | Out-String))
Add-Content $logfile -Value (systeminfo)
Add-Content $logfile -Value $divider


######################### SentinelOne Info #########################
Add-Content $logfile -Value "SentinelOne Details"

# Fetching SentinelOne Agent JSON Data
Write-Host "`Verifying if SentinelOne is installed" -BackgroundColor Green -ForegroundColor Black
try {
    $data = (New-Object -ComObject 'SentinelHelper.1').GetAgentStatusJSON() | ConvertFrom-Json
    Add-Content $logfile -Value "Agent Status JSON:" 
    Add-Content $logfile -Value ($data | Out-String) -NoNewline
} catch {
    Add-Content $logfile -Value "Error: Unable to fetch SentinelOne Agent Data. COM Object may not be registered."
}


# Check if SentinelOne Services and process is Installed
Write-Host "Verifying if SentinelOne services and process are running" -BackgroundColor Green -ForegroundColor Black
$SentinelService = Get-Service -Name Sentinel* -ErrorAction SilentlyContinue
if ($SentinelService) {
    Add-Content $logfile -Value "Agent Service Found: " -NoNewline
    Add-Content $logfile -Value ($SentinelService | Format-Table -Wrap | Out-String)
    Add-Content $logfile -Value ((Get-Process "Sentinel*" | Select-Object ProcessName, CPU, PrivateMemorySize, TotalProcessorTime, StartTime | Format-Table -Wrap | Out-String))
} else {
    Add-Content $logfile -Value "Error: SentinelOne Agent Service Not Found!"
}


# Ping SentinelOne Management URL
Write-Host "Verifying if SentinelOne ip addresses work" -BackgroundColor Green -ForegroundColor Black
if ($data.'mgmt-url') {
    $url = ($data.'mgmt-url' -split "https://")[-1]
    Add-Content $logfile -Value "Network Connectivity Check" -NoNewline
    $pingResult = Test-NetConnection -ComputerName $url -InformationLevel Detailed
    Add-Content $logfile -Value ($pingResult | Out-String) 
} else {
    Add-Content $logfile -Value "Error: SentinelOne Management URL not found in agent data."
}


# WMI test to verify if WMI is functioning correctly
Write-Host "`nVerifying WMI functionality" -BackgroundColor Green -ForegroundColor Black
try {
    $wmiresponse = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop | Out-String 
    Add-Content $logfile -Value "WMI is functioning correctly." -NoNewline
    Add-Content $logfile -Value ($wmiresponse)
} catch {
    Add-Content $logfile -Value "Error: WMI is not responding. It may be corrupted or disabled. `n Please repair the WMI."
}


#Certificate Test
Write-Host "Verifying installed certificate" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "Performing Certificate Check`n" -NoNewline
$DigiCertGlobalRootCAThumbprint = 'A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436'

#$DigiCertGlobalRootCA = Get-ChildItem -Recurse Cert:\LocalMachine\Root | Where-Object -Property Thumbprint -EQ $DigiCertGlobalRootCAThumbprint | Select-Object -First 1
$DigiCertGlobalRootCA = Get-ChildItem -Recurse Cert:\LocalMachine\Root | Where-Object {$_.Thumbprint -match $DigiCertGlobalRootCAThumbprint} | Select-Object -First 1

if(!$DigiCertGlobalRootCA){
    Add-Content $logfile -Value "ERROR: DigiCert Global Root (Thumbprint A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436) CA is not imported in the LocalMachine certificate store.`n"
} else {
    Add-Content $logfile -Value "DigiCert Global Root CA is imported (Thumbprint A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436).`n" 
}


#Cipher Test


#EventViewer last 10 event viewer logs
Write-Host "Gathering SentinelOne agent event viewer logs" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "Checking sentinelOne Event Logs`n"
$eventLogs = Get-WinEvent -LogName 'SentinelOne/Operational' -MaxEvents 10 
if ($eventLogs){
    Add-Content $logfile -Value ($eventLogs| Format-Table -Wrap | Out-String)
} else {
    Add-Content $logfile -Value "SentinelOne event logs not found`n" 
}

Add-Content $logfile -Value $divider


######################### SentinelOne Installation Info #########################
Write-Host "SentinelOne Installation Details" -BackgroundColor Green -ForegroundColor Black

#Read sc-exit code
$eventLogs = Get-Content -Path "C:\Windows\Temp\sc-exit-code.txt"
Add-Content $logfile -Value ("Sentinel Installer run exit code:" + $eventLogs)
$eventLogs

#Read etl logs. 


######################### Machine Info #########################

#Disk information
Add-Content $logfile -Value ("Disk Information") -NoNewline
Add-Content $logfile -Value (Get-Volume | Select-Object DriveLetter, FileSystem, FileSystemLabel, SizeRemaining, Size | Format-Table -Wrap | Out-String)


#Memory information
Add-Content $logfile -Value ("Memory Information") -NoNewline
$memory = Get-CimInstance Win32_OperatingSystem | Select-Object @{Name="Total Memory (GB)"; Expression={[math]::round($_.TotalVisibleMemorySize / 1MB, 2)}},
                                                              @{Name="Free Memory (GB)"; Expression={[math]::round($_.FreePhysicalMemory / 1MB, 2)}},
                                                              @{Name="Total Virtual Memory (GB)"; Expression={[math]::round($_.TotalVirtualMemorySize / 1MB, 2)}},
                                                              @{Name="Free Virtual Memory (GB)"; Expression={[math]::round($_.FreeVirtualMemory / 1MB, 2)}}
Add-Content $logfile -Value ($memory | Format-Table -Wrap| Out-String)


#Hotfix information
Add-Content $logfile -Value ("Hotfix Installed") -NoNewline
Add-Content $logfile -Value (Get-HotFix | Select-Object HotFixID, InstalledOn, Description, InstalledBy | Sort-Object InstalledOn -Descending | Format-Table -Wrap| Out-String)


#Application logs - SentinelOne search
Write-Host "Generating Application logs" -BackgroundColor Green -ForegroundColor Black
$eventLogs = Get-EventLog -LogName Application | Where-Object { $_.Message -match "Sentinel" } | Select-Object -First 10 

if ($eventLogs) {
    Add-Content $logfile -Value ($eventLogs | Format-Table -Wrap | Out-String)
} else  {Add-Content $logfile -Value ("Sentinel events not found in application logs")}

#System logs - SentinelOne search
Write-Host "Generating System logs" -BackgroundColor Green -ForegroundColor Black
$eventLogs = Get-EventLog -LogName System | Where-Object { $_.Message -match "Sentinel" } | Select-Object -First 10 
if ($eventLogs) {
    Add-Content $logfile -Value ($eventLogs | Format-Table -Wrap | Out-String)
}