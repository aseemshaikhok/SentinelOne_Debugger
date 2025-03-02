#SentinelOne Diagnostic Tool

Write-Host "SentinelOne Diagnostic Script Started" -BackgroundColor Green -ForegroundColor Black

#define file name
$DesktopPath = "C:\Windows\Temp\"
$filename = hostname
$filename = 'SentinelOne_' + $filename + "_" + (Get-Date -format "MMMddyyyyHHmm") +'.log' #time
New-Item -path $DesktopPath -name $filename -ItemType "file" | Select-Object DirectoryName
$logfile = $DesktopPath+'\'+$filename

# Define divider
$divider  = '================================================================================='

# Log Date & Time
Add-Content $logfile -Value ("SentinelOne Diagnostics - " + (Get-Date).DateTime + "`n") 
Add-Content $logfile -Value ('Hostname: ' + (hostname)) 
Add-Content $logfile -Value ('Windows Version: ' + ((Get-CimInstance Win32_OperatingSystem).Caption))  #Windows Version
Add-Content $logfile -Value ('Processor Info: ' + ((Get-WmiObject -Class Win32_Processor).Name)) #Processor Type
Add-Content $logfile -Value ('Architecture: ' + ((Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture)) #Windows Architecture
Add-Content $logfile -Value $divider 

######################### SentinelOne Info #########################
Add-Content $logfile -Value "`nSentinelOne Details `n"

# Fetching SentinelOne Agent JSON Data
Write-Host "Is SentinelOne installed: " -BackgroundColor Green -ForegroundColor Black
try {
    $data = (New-Object -ComObject 'SentinelHelper.1').GetAgentStatusJSON() | ConvertFrom-Json
    Write-Host "Yes, SentinelOne is installed" -BackgroundColor Green -ForegroundColor Black
    Add-Content $logfile -Value "Agent Status JSON:" -NoNewline
    Add-Content $logfile -Value ($data | Out-String -Width 180) -NoNewline
} catch {
    Add-Content $logfile -Value "Error: Unable to fetch SentinelOne Agent Data. COM Object may not be registered."
    Write-Host "Error: Not installed" -BackgroundColor Red -ForegroundColor Black
}


# Check if SentinelOne Services and process is Installed
Write-Host "Are SentinelOne services and process present" -BackgroundColor Green -ForegroundColor Black
$SentinelService = Get-Service -Name Sentinel* -ErrorAction SilentlyContinue
if ($SentinelService) {
    Add-Content $logfile -Value "Agent Service Found: " -NoNewline
    Add-Content $logfile -Value ($SentinelService | Format-Table -Wrap | Out-String -Width 180)
    Add-Content $logfile -Value ((Get-Process "Sentinel*" | Select-Object ProcessName, CPU, PrivateMemorySize, TotalProcessorTime, StartTime | Format-Table -Wrap | Out-String -Width 180))
    Write-Host "SentinelOne Agent Service Not Found!" -BackgroundColor Green -ForegroundColor Black
} else {
    Add-Content $logfile -Value "Error: SentinelOne Agent Service Not Found!"
    Write-Host "Error: SentinelOne Agent Service Not Found!" -BackgroundColor Red -ForegroundColor Black
}


# Ping SentinelOne Management URL
Write-Host "Ping SentinelOne console: " -BackgroundColor Green -ForegroundColor Black
if ($data.'mgmt-url') {
    $url = ($data.'mgmt-url' -split "https://")[-1]
    Add-Content $logfile -Value "Network Connectivity Check" -NoNewline
    $pingResult = Test-NetConnection -ComputerName $url -InformationLevel Detailed
    Add-Content $logfile -Value ($pingResult | Out-String -Width 180) 
} else {
    Add-Content $logfile -Value "Error: SentinelOne Management URL not found in agent data."
    Write-Host "Error: SentinelOne Management URL not found in agent data." -BackgroundColor Red -ForegroundColor Black
}


# WMI test to verify if WMI is functioning correctly
Write-Host "Testing WMI functionality" -BackgroundColor Green -ForegroundColor Black
try {
    $wmiresponse = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop | Out-String -Width 180 
    Add-Content $logfile -Value "WMI is functioning correctly." -NoNewline
    Write-Host "WMI is functioning correctly." -BackgroundColor Green -ForegroundColor Black
    Add-Content $logfile -Value ($wmiresponse)
} catch {
    Add-Content $logfile -Value "Error: WMI is not responding. It may be corrupted or disabled. `n Please repair the WMI."
    Write-Host "Error: WMI is not responding. It may be corrupted or disabled. `n Please repair the WMI." -BackgroundColor Red -ForegroundColor Black
}


#Certificate Test
Write-Host "Verifying installed certificate" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "Performing Certificate Check`n" -NoNewline
$DigiCertGlobalRootCAThumbprint = 'A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436'
$DigiCertGlobalRootCA = Get-ChildItem -Recurse Cert:\LocalMachine\Root | Where-Object {$_.Thumbprint -match $DigiCertGlobalRootCAThumbprint} | Select-Object -First 1

if(!$DigiCertGlobalRootCA){
    Add-Content $logfile -Value "ERROR: DigiCert Global Root (Thumbprint A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436) CA is not imported in the LocalMachine certificate store.`n"
} else {
    Add-Content $logfile -Value "DigiCert Global Root CA is imported (Thumbprint A8985D3A65E5E5C4B2D7D66D40C6DD2FB19C5436).`n" 
}


#Cipher Test
Write-Host "Verifying machine cipher suite" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "Machine Cipher Suite`n"
Add-Content $logfile -Value (Get-TlsCipherSuite | Format-Table -Property CipherSuite, Name | Out-String -Width 180)

#EventViewer last 10 event viewer logs
Write-Host "Generating SentinelOne agent event viewer logs" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "SentinelOne Event Logs`n"
$eventLogs = Get-WinEvent -LogName 'SentinelOne/Operational' -MaxEvents 10 -ErrorAction SilentlyContinue 
if ($eventLogs){
    Add-Content $logfile -Value ($eventLogs| Format-Table -Wrap | Out-String -Width 180)
} else {
    Add-Content $logfile -Value "SentinelOne event logs not found`n" 
}

Add-Content $logfile -Value $divider


######################### SentinelOne Installation Info #########################

Write-Host "Fetching SentinelOne Installation Details" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "Sentinel Installer logs `n"

#Read sc-exit code
try {
    $eventLogs = Get-Content -Path "C:\Windows\Temp\sc-exit-code.txt"
    Add-Content $logfile -Value ("Sentinel Installer Exit Code:" + $eventLogs)
}
catch {
    Add-Content $logfile -Value ("No Exit Code Found !!")
}

######################### SentinelOne Installation Info #########################

Write-Host "SentinelOne Installation Details" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "Sentinel Installer logs `n"

#Read sc-exit code
try {
    $eventLogs = Get-Content -Path "C:\Windows\Temp\sc-exit-code.txt" -ErrorAction Stop
    Add-Content $logfile -Value ("Sentinel Installer Exit Code:" + $eventLogs +"`n")
}
catch {
    Add-Content $logfile -Value ("No Exit Code Found !!`n")
}

#Read MSI logs. 
Add-Content $logfile -Value "Sentinel MSI logs"
$latestMsiFilePaths = Get-ChildItem -Recurse -Path "C:\Users\" -Filter "MSI*.LOG" -Force -ErrorAction SilentlyContinue |Select-Object FullName, LastWriteTime 
$latestMsiFilePaths = @($latestMsiFilePaths)
$latestMsiFilePaths += Get-ChildItem -Path "C:\Windows\Temp\" -Filter "MSI*.LOG" -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime 
$latestMsiFilePaths = $latestMsiFilePaths | Sort-Object LastWriteTime -Descending 
$latestMsiFilePaths | Format-Table -AutoSize

try {
    foreach ($latestMsiFilePath in $latestMsiFilePaths) {
        if ((Get-Content -Path $latestMsiFilePath.FullName -Filter "Sentinel") -ne $Null) {
            Add-Content $logfile -Value ($latestMsiFilePath.FullName, $latestMsiFilePath.LastWriteTime)
            Add-Content $logfile -Value (Get-Content -Path $latestMsiFilePath.FullName | Select-String "Error" | Out-String -Width 180)
            break foreach
        }
    }
}
catch {
    Add-Content $logfile -Value "No MSI logs found !!"
}


Add-Content $logfile -Value $divider


######################### Machine Info #########################

#Disk information
Write-Host "Generating machine logs" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value ("Disk Information") -NoNewline
Add-Content $logfile -Value (Get-Volume | Select-Object DriveLetter, FileSystem, FileSystemLabel, SizeRemaining, Size | Format-Table -Wrap | Out-String -Width 180)


#Memory information
Add-Content $logfile -Value ("Memory Information") -NoNewline
$memory = Get-CimInstance Win32_OperatingSystem | Select-Object @{Name="Total Memory (GB)"; Expression={[math]::round($_.TotalVisibleMemorySize / 1MB, 2)}},
                                                              @{Name="Free Memory (GB)"; Expression={[math]::round($_.FreePhysicalMemory / 1MB, 2)}},
                                                              @{Name="Total Virtual Memory (GB)"; Expression={[math]::round($_.TotalVirtualMemorySize / 1MB, 2)}},
                                                              @{Name="Free Virtual Memory (GB)"; Expression={[math]::round($_.FreeVirtualMemory / 1MB, 2)}}
Add-Content $logfile -Value ($memory | Format-Table -Wrap| Out-String -Width 180)


#Hotfix information
Add-Content $logfile -Value ("Hotfix Installed:") -NoNewline
Add-Content $logfile -Value (Get-HotFix | Select-Object HotFixID, InstalledOn, Description, InstalledBy | Sort-Object InstalledOn -Descending | Format-Table -Wrap| Out-String -Width 180)


#Application logs - SentinelOne search
Write-Host "Generating Application logs" -BackgroundColor Green -ForegroundColor Black
$eventLogs = Get-EventLog -LogName Application | Where-Object { $_.Message -match "Sentinel" } | Select-Object -First 10 
Add-Content $logfile -Value "EventViewer Logs: Application"
if ($eventLogs) {
    Add-Content $logfile -Value ($eventLogs | Format-Table -Wrap | Out-String -Width 180)
} else  {Add-Content $logfile -Value ("Sentinel events not found in application logs")}

#System logs - SentinelOne search
Write-Host "Generating System logs" -BackgroundColor Green -ForegroundColor Black
Add-Content $logfile -Value "EventViewer Logs: System"
$eventLogs = Get-EventLog -LogName System | Where-Object { $_.Message -match "Sentinel" } | Select-Object -First 10 
Add-Content $logfile -Value ($eventLogs | Format-Table -AutoSize -Wrap | Out-String -Width 180)



######################### Script Exit #########################
Write-Host "Thank you for using SentinelOne Installation Diagnostic tool! Please Share the log file with SentinelOne team. `nLog File Path: " -BackgroundColor Yellow -ForegroundColor Black
Write-Host $logfile
Start-Sleep -Seconds 10 