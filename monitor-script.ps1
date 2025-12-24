# --- Configuration ---
$LogFilePath = "C:\scripts\disk_space_alert.log"
$credPath = "C:\scripts\creds.xml"
$ThresholdPercent = 3.5
$ThresholdGB = 500
$SmtpServer = "mail.gmail.com"
$From = "from1@gmail.com"
# $Recipients = @("to1@gmail.com", "to2@gmail.com")
$Recipients = @("to1@gmail.com")
$myIP = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | 
        Where-Object { $_.PrefixOrigin -ne "WellKnown" } | 
        Select-Object -First 1 -ExpandProperty IPAddress

$MandatoryDrives = "D:", "G:", "H:", "I:", "J:", "K:", "L:", "M:", "N:", "O:", "E:", "R:", "P:"

# --- 1. Collect Disk Data ---
$AllDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
Select-Object DeviceID, VolumeName,
    @{Name="SizeGB";Expression={[math]::Round($_.Size / 1GB, 2)}},
    @{Name="FreeSpaceGB";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
    @{Name="FreePercent";Expression={[math]::Round((($_.FreeSpace / $_.Size) * 100), 2)}}

# --- 2. Build HTML Body (Inline CSS for Compatibility) ---
$HtmlHeader = @"
<html>
<body style="margin:0; padding:20px; background-color:#f4f4f4; font-family: 'Segoe UI', Arial, sans-serif;">
    <div style="width:100%; max-width:600px; margin:0 auto; background-color:#ffffff; padding:20px; border:1px solid #dddddd;">
        <h2 style="color:#333333; border-bottom:2px solid #333333; padding-bottom:10px;">Disk Space Report: $(hostname) - $myIP</h2>
        <p style="font-size:12px; color:#666666;">Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <table cellspacing="0" cellpadding="0" style="width:100%; border-collapse:collapse; table-layout:auto;">
            <thead>
                <tr style="background-color:#333333; color:#ffffff;">
                    <th style="padding:10px; border:1px solid #333333; text-align:left; font-size:13px;">Drive</th>
                    <th style="padding:10px; border:1px solid #333333; text-align:left; font-size:13px;">Name</th>
                    <th style="padding:10px; border:1px solid #333333; text-align:left; font-size:13px;">Free (%)</th>
                    <th style="padding:10px; border:1px solid #333333; text-align:left; font-size:13px;">Free (GB)</th>
                </tr>
            </thead>
            <tbody>
"@

$HtmlRows = ""
$NeedsAlert = $false

foreach ($DriveLetter in $MandatoryDrives) {

    # Check if the mandatory drive exists in the collected data
    $disk = $AllDisks | Where-Object { $_.DeviceID -eq $DriveLetter }

    if ($disk) {
    # Determine Status and Colors
    write-host "Drive $($disk.DeviceID): $($disk.FreePercent)% free, $($disk.FreeSpaceGB) GB free"
    $isCritical = ($disk.FreePercent -lt $ThresholdPercent) -or ($disk.FreeSpaceGB -lt $ThresholdGB)
    $bgColor = if ($isCritical) { "#ffdddd" } else { "#eaffea" }
    $textColor = if ($isCritical) { "#990000" } else { "#006400" }
    if ($isCritical) { $NeedsAlert = $true }

    $HtmlRows += @"
                <tr style="background-color:$bgColor; color:$textColor;">
                    <td style="padding:10px; border:1px solid #dddddd; font-size:13px;">$($disk.DeviceID)</td>
                    <td style="padding:10px; border:1px solid #dddddd; font-size:13px;">$($disk.VolumeName)</td>
                    <td style="padding:10px; border:1px solid #dddddd; font-size:13px; font-weight:bold;">$($disk.FreePercent)%</td>
                    <td style="padding:10px; border:1px solid #dddddd; font-size:13px; font-weight:bold;">$($disk.FreeSpaceGB)GB</td>
                </tr>
"@
    } else {
        # DRIVE IS MISSING - Trigger Alert
        $NeedsAlert = $true
        $HtmlRows += @"
                <tr style="background-color:#ffdddd; color:#990000;">
                    <td style="padding:10px; border:1px solid #dddddd;">$DriveLetter</td>
                    <td style="padding:10px; border:1px solid #dddddd; font-weight:bold;">DISCONNECTED / MISSING</td>
                    <td style="padding:10px; border:1px solid #dddddd; font-weight:bold;">N/A</td>
                    <td style="padding:10px; border:1px solid #dddddd; font-weight:bold;">N/A</td>
                </tr>
"@
    }
}

$HtmlFooter = @"
            </tbody>
        </table>
        <p style="margin-top:20px; font-size:11px; color:#999999; text-align:center;">
            Threshold set to: $ThresholdPercent% , $ThresholdGB GB | Automatic Server Alert Using Scheduled Task
        </p>
    </div>
</body>
</html>
"@

$FullHtml = $HtmlHeader + $HtmlRows + $HtmlFooter

# --- 3. Send Email & Log Results ---
if ($NeedsAlert) {
    try {
        $credential = Import-Clixml -Path $credPath
        $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
        $SMTPClient.EnableSsl = $true
        $SMTPClient.Credentials = $credential.GetNetworkCredential()

        $Subject = "BDO - DISK ALERT: $(hostname) is low on space!"

        $MailMessage = New-Object System.Net.Mail.MailMessage
        $MailMessage.From = $From
        foreach ($email in $Recipients) {
            $MailMessage.To.Add($email)
        }
        $MailMessage.Subject = $Subject
        $MailMessage.Body = $FullHtml
        $MailMessage.IsBodyHtml = $true

        $SMTPClient.Send($MailMessage)
        Add-Content  -Encoding utf8 -Path $LogFilePath -Value "$(Get-Date): Email sent ($Subject)"
    }
    catch {
        Add-Content -Encoding utf8 -Path $LogFilePath -Value "$(Get-Date): FAILED - $($_.Exception.Message)"
    }
} else {
    Add-Content  -Encoding utf8 -Path $LogFilePath -Value "$(Get-Date): OK - All mandatory drives are healthy And above the threshold. No email sent."
}