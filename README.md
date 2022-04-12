# Reboot-FritzDevice
PowerShell-Script to reboot specific FRITZ! Devices in local network.

# Windows Credential Store
If you want to use credentials from the Windows Credential Store activate the paramter $useCredentialManager ($true) and create generic credentials with a title (e.g. 'fritz') there

# Execute Script
To execute script with a pre-defined option, create a windows shortcut with the target:

'powershell.exe -file ".\reboot-fritzdevice.ps1" -option [1..4]'
(Options: 1: Router, 2: Repeater, 3: Multiple-Devices (default: Router & Repeater), 4: Custom FQDN/IP)

As location to be executed the folder-path of the script-file.

# Have fun
Have fun using this!
( I will appreciate every feedback! :-) )
