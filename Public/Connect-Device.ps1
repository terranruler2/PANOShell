function Connect-Device {
<#
.SYNOPSIS
Connects to a PANOS device via the XML API
.EXAMPLE
Connect-Device -Hostname mypanosevice.example.local -Credential (Get-Credential) -Persistent
#>

    [CmdletBinding()]
    param (
        #Hostname or IP Address of PANOS Device (Firewall, Panorama, Collector, etc.)
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)][String[]]$Hostname,
        #Credentials to use for obtaining an API key from the device.
        #If a session was previously saved, Credential is not required.
        [Parameter(ParameterSetName="Credential")][PSCredential]$Credential,
        #Save the API Key to Windows Credential Manager after obtaining
        #Future connections with the same host will reconnect using the same API key and not require credentials.
        [Parameter(ParameterSetName="Credential")][Switch]$Save
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

        #Variable for the Windows Credential Store Prefix
        $WCSPrefix = 'PANOShell:'
    }

#TODO: Save PANOS Device API Keys as secure credentials
#TODO: Add Parameter for API Key Directly
    process {
        foreach ($HostnameItem in $HostName) {
            #Check if a session entry already exists
            if (Get-Variable -Name PANOSAPISessions -Scope Script -ErrorAction SilentlyContinue) {
                if ($SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem)) {
                    Write-Warning "Already Connected to $HostnameItem"; continue
                }
            }

            #Next, see if an entry exists in Windows Credential Manager
            $WCMCredential = Get-WCMCredential -target ($WCSPrefix + $HostnameItem)
            if ($WCMCredential) {
                write-verbose "${HostnameItem}: Stored API key found in Windows Credential Manager"
                #TODO: Separate out Session Object Creation to a separate private function.

                #Initialize a PANOSAPISessions Variable if it doesn't already exist
                if ($SCRIPT:PANOSAPISessions -eq $null) {
                    $SCRIPT:PANOSAPISessions = @{}
                }

                #Rehydrate session object from Credential Manager
                $SCRIPT:PANOSAPISessions[$HostNameItem] = (Get-WCMCredential -target ($WCSPrefix + $HostnameItem)).credentialblob | convertfrom-json
            }

            #Request a new key using credentials
            $APIResponse = Invoke-APIRequest @PassThruParams -Hostname $HostnameItem -ArgumentList @{
                type="keygen"
                user=$Credential.GetNetworkCredential().UserName
                password=$Credential.GetNetworkCredential().Password
            }

            if ($APIResponse) {
                #Initialize a PANOSAPISessions Variable if it doesn't already exist
                if ($SCRIPT:PANOSAPISessions -eq $null) {
                    $SCRIPT:PANOSAPISessions = @{}
                }

                $SCRIPT:PANOSAPISessions.$HostnameItem = [PSCustomObject][Ordered]@{
                    Key=$APIResponse.key
                }

                if ($Save) {
                    #Uses CredMan module
                    $SetCredentialParams = @{
                        Target = ($WCSPrefix + $HostnameItem)
                        UserName = $Credential.GetNetworkCredential().UserName
                        Password = (ConvertTo-JSON -Compress $SCRIPT:PANOSAPISessions[$HostnameItem])
                    }

                    Set-WCMCredential @SetCredentialParams
                }
            }
        }
    }
}