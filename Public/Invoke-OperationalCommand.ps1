function Invoke-OperationalCommand {
<#
.SYNOPSIS
Run an operational command on connected PAN-OS device or on PAN-OS devices managed by Panorama
*WARNING* THIS COMMAND IS NOT CURRENTLY SAFE WHEN CONNECTED TO MULTIPLE PANORAMAS AND MAY RESULT IN DUPLICATE EXECUTION
.DESCRIPTION
This is a wrapper for running operational commands against PAN-OS devices.
.EXAMPLE
Invoke-PANOSOperationalCommand "show system info"

Returns the system info for all connected PAN-OS devices.
.EXAMPLE
Invoke-PANOSOperationalCommand "show system info" -Hostname mypanosdevice.mycompany.local

Returns the system info for a specific PAN-OS device
.EXAMPLE
Invoke-PANOSOperationalCommand -XML '<show><system><info><info /></system></show>'

Returns the same information as Example 1 for all connected PAN-OS devices but using raw XML instead.
.EXAMPLE
Invoke-PANOSOperationalCommand "show system info" -Target '*'

Returns the system info for all devices managed by the connected panorama system (but not Panorama itself).
.EXAMPLE
Invoke-PANOSOperationalCommand "check pending-changes" -Target 'MyDev*'

Check to see if there are any pending changes on panorama managed devices with names starting with "MyDev".
.EXAMPLE
Get-PANOSPanoramaManagedDevice -Connected | Invoke-PANOSOperationalCommand "show high-availability state"

#>
    [CmdletBinding(DefaultParameterSetName="Command")]
    param (
        #The command to run in string form, same as what you would do at the CLI normally. PANOShell will convert it to XML
        #This currently only supports simple element commands such as "show system info"
        [Parameter(ParameterSetName="Command",Position=0,Mandatory)][String]$Command,

        #The command to run in XML form, which can be obtained from "debug cli on" in the CLI or from the API browser
        [Parameter(ParameterSetName="XML",Mandatory)][XML]$XML,

        #Hostname or IP Address of PANOS (Firewall, Panorama, Collector, etc.) device to issue the request.
        #If not specified it will use the global session information
        [String[]]$Hostname,

        #If you are connected to a Panorama system, run on the following managed devices.
        #You can specify one or more serial numbers or device name expressions. Wildcards are supported.
        #You can also pipe objects found in Get-PanoramaManagedDevice to this command and the command will be run there.
        [Parameter(ValueFromPipelineByPropertyName)][Alias('serial')][String]$Target
    )

    process {
        if ($Command) {
            $xml = Add-PANOSCommandElement $Command
        }

        $argumentList = @{
            type="op"
            cmd=$xml.innerxml
        }

        $requestParams = @{}
        if ($Hostname) {$requestParams.Hostname = $Hostname}

        #TODO: Make this safer when multiple panoramas or mixed panorama/PA device is attached
        if ($Target) {
            #Get the list of managed devices from the panorama device
            $panodevice = Get-PanoramaManagedDevice
            $targetDevices = @()
            foreach ($TargetItem in $Target) {
                $targetDevices += $panodevice | Where-Object {
                    ($PSItem.hostname -like $targetItem) -or ($PSItem.serial -like $targetItem)
                }
            }
            foreach ($targetDeviceItem in $targetDevices) {
                $ArgumentList.target = $targetDeviceItem.serial
                Invoke-APIRequest @RequestParams -ArgumentList $ArgumentList
            }
        } else {
            Invoke-APIRequest @RequestParams -ArgumentList $ArgumentList
        }
    }
}