#requires -module CredMan
#TODO: Make this module work with Powershell for Linux
function Connect-Device {
<#
.SYNOPSIS
Connects to a PANOS device via the XML API
.DESCRIPTION
This command connects to the PANOS API of a system and establishes session information for API calls.
You can connect to multiple systems. If you run a command without specifying the Hostname parameter, the command
will run against all systems you are currently connected to.

You can also save a connection with the Save parameter, which stores your API key in the Windows Credential Store. You
can then run this command without a password or API key and it will automatically connect you using your saved credential.

.EXAMPLE
Connect-PANOSDevice -Hostname mypanodevice.example.local

Connect to a PANOS Device. If an existing session exists or has been saved it will validate that the session is still valid.
If an existing session doesn't exist it will prompt you for credentials to establish a new session.

.EXAMPLE
Connect-PANOSDevice -Hostname mypanodevice.example.local -APIKey 'OIWEoiwerjoawieiojWERO2348892='

Connect to a PANOS Device using an existing API key. Useful if you don't want to provide direct credentials to PANOShell.

.EXAMPLE
$cred = (get-credential)
Connect-PANOSDevice -Hostname mypanodevice.example.local -Credential $cred

Connect to a PANOS Device using a PSCredential object.
The first line will prompt for a PSCredential, or you can use a saved PSCredential.

.EXAMPLE
$cred = (get-credential)
Connect-PANOSDevice -Hostname mypanodevice.example.local -Credential $cred
Connect to a PANOS Device using a PSCredential object and save the session information to the Windows Credential Store
This will make the credentials you provided persistent across Powershell sessions.

.NOTES
This manages connections through the use of "sessions", but this is purely a Powershell construct. PANOS API activities
are not tracked as sessions on the PANOS device unlike HTTPS and CLI sessions
If you wish to remove or overwrite a "saved" session, use Disconnect-PANOSDevice or simply specify new credentials or API key.
#>

    [CmdletBinding(DefaultParameterSetName="HostnameOnly")]
    param (
        #Hostname or IP Address of PANOS Device (Firewall, Panorama, Collector, etc.)
        [Parameter(ParameterSetName="HostnameOnly",Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [Parameter(ParameterSetName="Credential",Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName="APIKey",Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [String[]]$Hostname,
        #Credentials to use for obtaining an API key from the device.
        #If a session was previously saved, Credential is not required.
        [Parameter(Mandatory,ParameterSetName="Credential")][PSCredential]$Credential,
        #The API key to use when connecting to the host, if you wish to specify it directly instead of specifying login credentials.
        #If you specify an API key it is assumed you wish to force reconnect
        [Parameter(Mandatory,ParameterSetName="APIKey")][String]$APIKey,
        #Save the session information to the Windows Credential Store
        #Future connections to the same host will reconnect with the same session without requiring a password even
        #After restarting
        [Switch]$Save,
        #Don't output connection objects, just connect
        [Switch]$Quiet
    )

    begin {
        $PassThruParams = @{
            #Passthrough Common Parameters to Request
            Verbose = ($PSBoundParameters.Verbose -eq $true)
            WhatIf = ($PSBoundParameters.WhatIf -eq $true)
            #Obscure the password that would otherwise be shown in the "GET"
            HTTPMethod = "POST"
        }

        #Variable for the Windows Credential Store Prefix
        $WCSPrefix = 'PANOShell:'
    }

    process {
        foreach ($HostnameItem in $HostName) {
            #Skip session creation if already connected
            if ($SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem)) {
                write-debug "Session Entry found in PANOSAPISessions for $HostnameItem"
                #Todo: Perform test connection to revalidate
                Write-Warning "You are already connected to $HostnameItem. Testing connection anyway..."
            }

            #If an API Key was specified, populate it directly
            if (!$SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem) -and ($APIKey)) {
                write-debug "API Key manually specified for $HostnameItem."
                $SCRIPT:PANOSAPISessions.$HostnameItem = [ordered]@{
                    Key=$APIKey
                }
            }

            #If Credentials were specified, fetch an API key using those credentials
            if (!$SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem) -and ($Credential)) {
                write-debug "Credentials manually specified for $HostnameItem"

                #Request a new key using credentials
                #TODO: This is repeated again below. Split into separate function
                $APIResponse = Invoke-APIRequest @PassThruParams -Hostname $HostnameItem -ArgumentList @{
                    type="keygen"
                    user=$Credential.GetNetworkCredential().UserName
                    password=$Credential.GetNetworkCredential().Password
                }

                if ($APIResponse) {
                    $SCRIPT:PANOSAPISessions.$HostnameItem = @{
                        HostName = $HostnameItem
                        Key=$APIResponse.key
                    }
                } else {
                    write-error "An Error occured attempting to obtain an API key for $HostnameItem using the specified credentials"
                    continue
                }
            }

            #See if an entry exists in Windows Credential Store
            if (!$SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem)) {
                $WCSTarget = "$WCSPrefix$HostnameItem"
                write-debug "Checking Windows Credential Store for $WCSTarget"
                $WCSCredential = Get-WCSCredential -Target $WCSTarget
                if ($WCSCredential) {
                    write-debug "${HostnameItem}: Stored API key found in Windows Credential Store"
                    #TODO: Separate out Session Object Creation to a separate private function.
                    #Rehydrate session object from Credential Store
                    $SCRIPT:PANOSAPISessions[$HostNameItem] = (Get-WCSCredential -Target ($WCSPrefix + $HostnameItem)).credentialblob |
                        ConvertFrom-Json |
                        ConvertTo-HashTable -verbose:$false
                }
            }

            #Finally, as a default action, fetch an API key by asking for credentials
            if (!$SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem)) {
                $Credential = Get-Credential -Message "Enter your PANOS credentials for $HostnameItem" -ErrorAction stop

                #Request a new key using credentials
                $APIResponse = Invoke-APIRequest @PassThruParams -Hostname $HostnameItem -ArgumentList @{
                    type="keygen"
                    user=$Credential.GetNetworkCredential().UserName
                    password=$Credential.GetNetworkCredential().Password
                }

                if ($APIResponse) {
                    $SCRIPT:PANOSAPISessions.$HostnameItem = @{
                        Key=$APIResponse.key
                    }
                } else {
                    write-error "An Error occured attempting to obtain an API key using the specified credentials"
                    continue
                }
            }

            #If we get this far we should always have a session one way or the other. If we don't then error out.
            if (!$SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem)) {
                write-error "Session Info couldn't be found or obtained for $HostnameItem. This should never happen..."
                continue
            } else {
                #Test connection to the system by fetching the basic system information.
                $APIResponse = Invoke-APIRequest @PassThruParams -Hostname $HostnameItem -ArgumentList @{
                    type="op"
                    cmd="<show><system><info></info></system></show>"
                }
                if ($APIResponse) {
                    $SystemInfoProps = "devicename","serial","sw-version","model","operational-mode"

                    #Add the hostname to the session info
                    $SCRIPT:PANOSAPISessions[$HostnameItem].HostName = $HostnameItem
                    #Add some additional properties, replacing if necessary
                    foreach ($SystemInfoPropItem in $SystemInfoProps) {
                        $SCRIPT:PANOSAPISessions[$HostnameItem].remove($SystemInfoPropItem) | out-null
                        $SCRIPT:PANOSAPISessions[$HostnameItem].add($SystemInfoPropItem,$APIResponse.system.$SystemInfoPropItem) | out-null
                    }

                    #Return the API Object
                    if (!$Quiet) {
                        Get-Device $HostnameItem
                    }
                } else {
                    write-error "Connection could not be established to $HostnameItem. Removing Session Entry"
                    $SCRIPT:PANOSAPISessions.Remove($HostnameItem)
                }
            }

            #Save Credentials to Windows Credential Store if requested (uses CredMan module)
            if ($Save) {
                $SetCredentialParams = @{
                    Target = ($WCSPrefix + $HostnameItem)
                    UserName = $Credential.GetNetworkCredential().UserName
                    Password = (ConvertTo-JSON -Compress $SCRIPT:PANOSAPISessions[$HostnameItem])
                }
                Set-WCSCredential @SetCredentialParams
            }
        }
    }
}