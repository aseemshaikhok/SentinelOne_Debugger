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


# Fetching SentinelOne Agent JSON Data
$procs = Get-Process | Sort-Object "WorkingSet"
foreach($proc in $procs) {
   $NonPagedMem = [int]($proc.NPM/1024)
   $WorkingSet = [int64]($proc.WorkingSet64/1024)
   $VirtualMem = [int]($proc.VM/1MB)
   $id= $proc.Id
   $machine = $proc.MachineName
   $process = $proc.ProcessName
   $procdata = new-object psobject
   $procdata | Add-Member noteproperty NonPagedMem $NonPagedMem
   $procdata | Add-Member noteproperty WorkingSet $WorkingSet 
   $procdata | Add-Member noteproperty machine $machine
   $procdata | Add-Member noteproperty process $process
   $procdata | Select-Object machine,process,WorkingSet,NonPagedMem
}



Add-Content $logfile -Value $divider
Add-Content $logfile -Value "Log Collection Completed"