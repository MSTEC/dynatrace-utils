<#
Simple PowerShell script executed by GitHub Actions.
Usage: .\run.ps1 -Message "custom message"
#>
param(
    [string]$Message = "Hello from GitHub Actions (PowerShell)"
)

Write-Host $Message

openssl smime -encrypt -in ".\..\templates\credentials\credential.yml" -aes256 -out file.p7m -outform pem ".\..\certs\prod-cac_base64.cer"

exit 0
