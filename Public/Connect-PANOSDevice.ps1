function Connect-PANOSDevice {
<#
.SYNOPSIS
Connects to a PANOS device via the XML API
#>

    [CmdletBinding()]
    param (
        #Hostname or IP Address of PANOS Device (Firewall, Panorama, Collector, etc.)
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)][String[]]$Hostname,
        #Credentials to use for obtaining an API key from the device
        [Parameter(Mandatory)][PSCredential]$Credential
    )

    begin {
        $PassThruParams = @{
            #Passthrough Common Parameters to Request
            Verbose = ($PSBoundParameters.Verbose -eq $true)
            WhatIf = ($PSBoundParameters.WhatIf -eq $true)
            #Obscure the password that would otherwise be shown in the "GET"
            HTTPMethod = "POST"
            #ErrorAction = ($PSBoundParameters.ErrorAction -eq $true)
        }
    }

#TODO: Save PANOS Device API Keys as secure credentials
#TODO: Add Parameter for API Key Directly
    process {
        foreach ($HostNameItem in $HostName) {
            $APIResponse = Invoke-PANOSAPIRequest @PassThruParams -Hostname $HostNameItem -ArgumentList @{
                type="keygen"
                user=$Credential.GetNetworkCredential().UserName
                password=$Credential.GetNetworkCredential().Password
            }

            $SCRIPT:PANOShellSessions.$HostNameItem = [PSCustomObject][Ordered]@{
                Key=$APIResponse.key
            }
        }
    }
}