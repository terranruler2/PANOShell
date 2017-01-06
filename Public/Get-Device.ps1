function Get-Device {
<#
.SYNOPSIS
Returns the session objects of PANOS Devices
#>

param (
    #Hostname or IP address of a PAN-OS device
    [String[]]$HostName,
    #Display the API key for the session. Not recommended unless you have a specific need for it.
    [Switch]$ShowAPIKey
)

process {
    #If no host specified, list all entries, otherwise list the specific entries requested
    if (!$Hostname) {
        $Hostname = $SCRIPT:PANOSAPISessions.keys
    }
    foreach ($HostnameItem in $HostName) {
        if ($SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem)) {
            $PANOSession = $SCRIPT:PANOSAPISessions[$HostNameItem].Clone()
            if (!$ShowAPIKey) {
                $PANOSession.Remove("Key")
            }
            #Output the new object with a custom view
            $ObjectDetailProps = @{
                TypeName = "PANOShell.PANOSession"
                DefaultProperties = "Hostname","Platform-Family","SW-Version","System-Mode"
                PassThru = $true
            }

            [PsCustomObject]$PANOSession | Add-ObjectDetail @ObjectDetailProps

        } else {
            write-error "Could not find a current PAN-OS session for $HostnameItem"
        }
    }
} #Process Foreach

}