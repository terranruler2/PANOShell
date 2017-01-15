[Unofficial] PANOShell Palo Alto Networks PAN-OS Powershell Module
-
[![Build status](https://ci.appveyor.com/api/projects/status/hyh1xb65ebiiovoi/branch/master?svg=true)](https://ci.appveyor.com/project/JustinGrote/traverse/branch/master)

This module provides a Powershell interface for the [Palo Alto Networks PAN-OS](https://www.paloaltonetworks.com/) firewall and security**PANOS**hell. products.

The mode name is a portmanteu of PAN-OS and Powershell. **PANOS**hell.

This project focuses on providing PAN-OS management in line with the Powershell Promise:

**We respect your investment in learning Windows PowerShell by reusing concepts over and over to make sure learning Windows PowerShell was the best thing you ever did.**

Features
-
* **Full Comment Based Help**: All commands have Get-Help with documentation and examples.
* **[PowerCLI](https://www.vmware.com/support/developer/PowerCLI/)-Like Session Support**: Use the Connect-PANOSDevice command to automatically fetch API keys. You can even save them in the Windows Credential Store for SSO login to devices.
* **MultiDevice**: Fan out commands to multiple devices easily by connecting to multiple devices
* **ASA-Like Packet Tracer**: Inspired by the [Cisco ASA Packet Tracer](http://www.cisco.com/c/en/us/td/docs/security/asa/asa84/asdm64/configuration_guide/asdm_64_config/admin_trouble.html#wp1092412), the Trace-PANOSPacket command allows you to more quickly troubleshoot the flow of a simulated packet through the system.
* **Module Prefix Support**: Want to call the module something else? Import the module with the -Prefix argument and all the commands will automatically rename based on your specified prefix.

Installation
-
####[Powershell V5](https://www.microsoft.com/en-us/download/details.aspx?id=50395) and Later
You can install the Powershell module directly from the [Powershell Gallery](http://www.powershellgallery.com/packages/PANOShell)

**Method 1** *[Recommended]*: Install to your personal Powershell Modules folder
```powershell
Install-Module PANOShell -scope CurrentUser
```
**Method 2** *[Requires Elevation]*: Install for Everyone (computer Powershell Modules folder)
```powershell
Install-Module PANOShell
```
####Powershell V4 and Earlier
Download the module from the Github Releases page and unzip into to your personal modules folder (e.g. ~\Documents\WindowsPowerShell\Modules)

Getting Started
-

All commands have comment based help, so recommend starting with this:
```powershell
Get-Command -Module PANOShell
Get-Help <command> -ShowWindow
```

Quick Start Commands
-
```powershell
Connect-PANOSDevice -Hostname mypanosdevice.mycompany.local -Save
Get-PANOSDevice
(Invoke-PANOSOperationalCommand "show system info").system
Invoke-PANOSAPIRequest -ArgumentList @{type="op";cmd="<show><system><info></info></system></show>"}
```
