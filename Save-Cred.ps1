$Path = "creds.xml"
$Credential = Get-Credential
$Credential | Export-Clixml -Path $Path