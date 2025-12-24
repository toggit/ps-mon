# Disk Space Monitoring Script
# This script checks the free disk space on all local fixed drives.
$LogFilePath = "disk_space_alert.log"
$Threshold = 30 

$DiskData = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
Select-Object DeviceID, VolumeName,
    @{Name="Size(GB)";Expression={[math]::Round($_.Size / 1GB, 2)}},
    @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
    @{Name="FreePercent";Expression={[math]::Round((($_.FreeSpace / $_.Size) * 100), 2)}}

$AlertDisks = $DiskData | Where-Object {$_.FreePercent -lt $Threshold}
if ($AlertDisks) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFilePath -Value "--- Disk Space Alert ($Timestamp) ---"
    $AlertDisks | Format-Table -AutoSize | Out-String | Add-Content -Path $LogFilePath
    Add-Content -Path $LogFilePath -Value "`n" 
     $AlertDisks | Format-Table -AutoSize | Out-String | Write-Host
    Write-Host "ALERT: Found $($AlertDisks.Count) disks below $($Threshold)% free space. Log written to $($LogFilePath)" -ForegroundColor Red
} else {
    Write-Host "INFO: All disks are above the $($Threshold)% free space threshold." -ForegroundColor Green
}