#SentinelOne Debugger Tool

#define file name - For debug only
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$filename = $env:COMPUTERNAME + "_SentinelOne.log"

if (Test-Path -Path (Join-Path $DesktopPath $filename)) {
 Remove-Item -Path (Join-Path $DesktopPath $filename) -Force
}

New-Item -Path $DesktopPath -Name $filename -ItemType File
$logfile = $DesktopPath+'\'+$filename

#define divider
$divider  = '================================================================================='

#systeminfo / partial data
Add-Content $logfile -Value (Get-Date) #datetime
#Add-Content $logfile -Value (systeminfo) #systeminfo
Add-Content $logfile -Value ($divider)



#Agent json 
Add-Content $logfile -Value ("SentinelOne Details")
$data = (New-Object -ComObject 'SentinelHelper.1').GetAgentStatusJSON() | ConvertFrom-Json 
Add-Content $logfile -Value ("Is agent installed")
Add-Content $logfile -Value ((if ($data -is [System.Management.Automation.ErrorRecord]) { "Error: Agent not installed"} else { "Agent is installed"}))
Add-Content $logfile -Value ($data| Out-String)
#agent is running
Add-Content $logfile -Value (Get-Service -Name SentinelAgent | Out-String)
#ping network issue
$url = ($data.'mgmt-url' -split "https://")[1]
Add-Content $logfile -Value ("Network Request")
Add-Content $logfile -Value (ping $url)