# Update this path to your actual cred file path
$credPath = "C:\scripts\creds.xml"
$LogFilePath = "C:\scripts\TaskLog.txt"

$LogFolder = Split-Path $LogFilePath
if (!(Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force
}

"--------------------------------------------------" | Out-File $LogFilePath -Encoding utf8 -Append

try {
    $Cred = Import-CliXml -Path $credPath
    Write-Host "Success! Credential for $($Cred.UserName) was decrypted." -ForegroundColor Green
    "Script started at $(Get-Date): Success! Credential for $($Cred.UserName) was decrypted." | Out-File $LogFilePath -Encoding utf8 -Append
} catch {
    Write-Host "Failure! user1 cannot decrypt this file. Details: $($_.Exception.Message)" -ForegroundColor Red
     "Script started at $(Get-Date): Failure! user1 cannot decrypt this file. Details: $($_.Exception.Message)" | Out-File $LogFilePath -Encoding utf8 -Append
}

# Start-Process powershell.exe -Credential "user1" -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\scripts\Test-Creds.ps1" -Verbose -NoNewWindow