$EmailFrom = "from1@gmail.com"
$EmailTo = "to1@gmail.com"
$Subject = "Happy New Year! - test email from PowerShell"
$Body = "Wishing you a prosperous and joyful new year!"
$SMTPServer = "mail.gmail.com"

$credPath = "creds.xml"
$credential = Import-Clixml -Path $credPath

$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = $credential.GetNetworkCredential()
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)