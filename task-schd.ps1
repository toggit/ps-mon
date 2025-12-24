# --- Configuration ---
$TaskName = "DailyDiskSpaceMonitor"
$ScriptPath = "C:\scripts\monitor-script.ps1"
$RunTime = "07:30AM"

# Credentials for the task to run under
$TaskUser = "user1"
$TaskPass = "P@ssw0rd123!" 

# --- Task Components ---

$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger -Daily -At $RunTime

# Ensure 'Highest' RunLevel so the user1 account has admin rights if needed
# $Principal = New-ScheduledTaskPrincipal -UserId $TaskUser -LogonType Password -RunLevel Highest

# --- Registration ---

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# We pass the password directly here to authorize "Run whether user is logged on or not"
Register-ScheduledTask -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -User $TaskUser `
    -Password $TaskPass
    # -Principal $Principal `

Write-Host "Task '$TaskName' deployed. It will run as $TaskUser daily at $RunTime." -ForegroundColor Green