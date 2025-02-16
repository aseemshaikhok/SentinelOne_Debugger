#SentinelOne Debugger Tool

Write-Host "SentinelOne Debugger Script Started" -BackgroundColor Green -ForegroundColor Black

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


################## SentinelOne Info #########################
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
    Add-Content $logfile -Value ($SentinelService | Format-Table | Out-String)
    Add-Content $logfile -Value ((Get-Process "Sentinel*" | Select-Object ProcessName, CPU, PrivateMemorySize, TotalProcessorTime, StartTime | Format-Table -AutoSize | Out-String))
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
Write-Host "Verifying WMI functionality" -BackgroundColor Green -ForegroundColor Black
try {
    $wmiresponse = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop | Out-String 
    Add-Content $logfile -Value "WMI is functioning correctly." -NoNewline
    Add-Content $logfile -Value ($wmiresponse)
} catch {
    Add-Content $logfile -Value "Error: WMI is not responding. It may be corrupted or disabled."
}


#Certificate Test
Write-Host "Verifying installed certificate" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "Performing Certificate Check" -NoNewline
$DigiCertGlobalRootCAThumbprint = 'A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436'

#$DigiCertGlobalRootCA = Get-ChildItem -Recurse Cert:\LocalMachine\Root | Where-Object -Property Thumbprint -EQ $DigiCertGlobalRootCAThumbprint | Select-Object -First 1
$DigiCertGlobalRootCA = Get-ChildItem -Recurse Cert:\LocalMachine\Root | Where-Object {$_.Thumbprint -match $DigiCertGlobalRootCAThumbprint} | Select-Object -First 1

if(!$DigiCertGlobalRootCA){
    Add-Content $logfile -Value 'ERROR: DigiCert Global Root (Thumbprint A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436) CA is not imported in the LocalMachine certificate store.'
} else {
    Add-Content $logfile -Value 'DigiCert Global Root CA is imported (Thunbprint A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436).' 
}


#Cipher Test



#EventViewer last 10 event viewer logs
Write-Host "Gathering SentinelOne agent event viewer logs" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "SentinelOne Event Logs" -NoNewline
try{
    Add-Content $logfile -Value (Get-WinEvent -LogName 'SentinelOne/Operational' -MaxEvents 10 | Format-Table -Wrap | Out-String)
} catch {
    Add-Content $logfile -Value "SentinelOne event logs not found" 
}

Add-Content $logfile -Value $divider
Add-Content $logfile -Value (systeminfo)