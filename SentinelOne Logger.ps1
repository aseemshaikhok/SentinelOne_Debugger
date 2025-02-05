#SentinelOne Debugger Tool

#define file name``
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$filename = hostname
$filename = 'SentinelOne_' + $filename + "_" + (Get-Date -format "MMMddyyyyHHmm") +'.log' #time
New-Item -path $DesktopPath -name $filename -ItemType "file"
$logfile = $DesktopPath+'\'+$filename

#define divider
$divider  = '================================================================================='

#systeminfo / partial data
Add-Content $logfile -Value (Get-Date) #datetime
Add-Content $logfile -Value (systeminfo) #systeminfo
Add-Content $logfile -Value ($divider)



#Agent json 
Add-Content $logfile -Value ((New-Object -ComObject 'SentinelHelper.1').GetAgentStatusJSON() | ConvertFrom-Json | Out-String)