<#
.SYNOPSIS
	Reboots FRITZ! devices
.DESCRIPTION
	This PowerShell script reboots different FRITZ! devices in the Local Area Network (LAN)
	(Options: 1: Router, 2: Repeater, 3: Multi-Devices (Default: Router & Repeater), 4: Custom FQDN/IP)
.PARAMETER option
	Specifies device to be rebooted
.PARAMETER customFQDN
	To be used for option 4 to predefine the customFQDN/IP
.PARAMETER useCredentialManager
    Activate the option to use the Windows Credential Manager
.PARAMETER winCredStoreName
    The name of the credential store (of the Windows Credential Manager) you want to use
.PARAMETER consistentCredentials
    If your FRITZ!Devices are configured with different credentials, set this parameter to $false
.EXAMPLE
	PS> ./reboot-fritzdevice -option 1
	PS> ./reboot-fritzdevice -option 4 -customFQDN fritz.repeater2
	PS> ./reboot-fritzdevice -option 4 -customFQDN 192.168.178.1
.NOTES
	Scipt-Author: B0rKaS
	Module: CredentialManager, Author: Dave Garnar, Copyright: (c) 2016 Dave Garnar. All rights reserved.
#>

param([string]$option, [string]$customFQDN)

# PARAMETERS --------------------------

$FQDN_FritzBox = "fritz.box"
$FQDN_FritzRepeater = "fritz.repeater"
$FQDN_MultiDevices = @($FQDN_FritzBox, $FQDN_FritzRepeater)

$useCredentialManager = $false
$winCredStoreName = "fritz"
$consistentCredentials = $true

# -------------------------------------

Write-Host "Info: This script reboots specific FRITZ! Devices automatically (if you want to abort it, press CTRL+C)"

$validInput = $false
do {
    if(!$option) {
        Write-Host "`nWhich FRITZ! Device you want to reboot?`n`n1: Router (FQDN: $FQDN_FritzBox)`n2: Repeater (FQDN: $FQDN_FritzRepeater)`n3: Multi-Devices (Default: $FQDN_FritzBox & $FQDN_FritzRepeater)`n4: Custom (insert a custom FQDN/IP)"
        Write-Host "`nChoose (1-4): " -NoNewline 
        $action = Read-Host
    } else {
        if($option -ge 1 -and $option -le 4) {
            $action = $option
        } else {
            Write-Host "`nPredefined option has to be between 1 and 4 - modify parameter to continue...`nPress any key to leave script..." -ForegroundColor Red
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit
        }
    }

    switch ($action) {
        1 {
            $targetFQDN = $FQDN_FritzBox
            $validInput = $true
        }
        2 {
            $targetFQDN = $FQDN_FritzRepeater
            $validInput = $true
        }
        3 {
            $targetFQDN = $FQDN_MultiDevices
            $validInput = $true
        }
        4 {
            if($customFQDN) {
                $targetFQDN = $customFQDN
            } else {
                Write-Host "`nInsert device FQDN or IP: " -NoNewline
                $targetFQDN = Read-Host
            }
            $validInput = $true
        }
        default {
            Write-Host "`nNo match found, please choose between 1 - 4... (or leave with CTRL+C)`n" -ForegroundColor Red
        }
    }
} while(!$validInput)

if($useCredentialManager -and $consistentCredentials) {
    try{
        Write-Host "`nInstalling module 'CredentialManager'" -ForegroundColor Magenta
        Install-Module CredentialManager -Scope CurrentUser -MinimumVersion 2.0
        $cred = Get-StoredCredential -Target $winCredStoreName
    } catch {Write-Host $PSItem.Exception}

    if($cred) {
        Write-Host "`nGot credentials from credential-store '$winCredStoreName'" -ForegroundColor Green
    } else {
        Write-Host "`nNo stored credentials found. " -ForegroundColor Yellow
    }
}

foreach($FQDN in $targetFQDN){    
    if(!$cred) {
        Write-Host "`nPlease insert administrative credentials for your FRITZ! Device ($FQDN)"
        Write-Host "Username: " -NoNewline
        $username = Read-Host
    
        Write-Host "Password: " -NoNewline
        $password = Read-Host -AsSecureString

        $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
    }

    try {
        $headers = @{}
        $headers.Add("Content-Type","text/xml; charset='utf-8'")
        $headers.Add("SoapAction", "urn:dslforum-org:service:DeviceConfig:1#Reboot")

        Write-Host "`nSending reboot-call to FRITZ! Device (FQDN: $($FQDN))..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Method Post -Uri "http://$($FQDN):49000/upnp/control/deviceconfig" -Headers $headers -Credential $cred -UseBasicParsing -Body "<?xml version='1.0' encoding='utf-8'?><s:Envelope s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:s='http://schemas.xmlsoap.org/soap/envelope/'><s:Body><u:Reboot xmlns:u='urn:dslforum-org:service:DeviceConfig:1'></u:Reboot></s:Body></s:Envelope>"
        
        if($response.StatusCode -eq 200) {
            Write-Host "`nSuccess! Device ($FQDN) should reboot now...`n(this action takes like 2-5 minutes until the device is available again)" -ForegroundColor Green
        } else {
            Write-Host "`nSomething went wrong! Device ($FQDN) responded:`n$response" -ForegroundColor Red
        }
    } catch {
        Write-Host "`n"$PSItem.Exception -ForegroundColor Red
    }

    if(!$consistentCredentials) {
        $cred = $null
    }
}

if(!$option -or ($response.StatusCode -ne 200) -or ($username -and $password)) {
    Write-Host "`nPress any key to leave script..."
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
