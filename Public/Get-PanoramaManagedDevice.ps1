function Get-PanoramaManagedDevice {
<#
.SYNOPSIS
Returns a list of devices that Panorama manages
.NOTES
Only works on Panorama devices
#>

    [CmdletBinding()]
    param (
        #Only return devices which are currently connected to the firewall
        [Switch]$Connected
    )

    begin {
        $cmdXML = Add-PANOSCommandElement "show devices"
        if ($Connected) {$cmdxml = Add-PANOSCommandElement "connected" $cmdXML}
        else {$cmdxml = Add-PANOSCommandElement "all" $cmdXML}
    }

    process {
        $APIResponse = Invoke-APIRequest -ArgumentList @{
            type="op"
            cmd=$cmdXML.innerxml
        }
        $APIResponse.devices.entry
    }
}