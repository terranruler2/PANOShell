function Invoke-APIRequest {
<#
.SYNOPSIS
Executes the requested command and associated arguments against the Palo Alto XML api
.NOTES
This command is the core of the PANOS Module and is used by nearly every other command to interact with the API
#>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        #Hostname or IP Address of PANOS (Firewall, Panorama, Collector, etc.) device to issue the request.
        #If not specified it will use the global session information
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)][String[]]$Hostname,

        #A hashtable list of arguments for the command, such as Type, Action, and XPath/CMD
        $ArgumentList = @{},

        #HTTP Method to Use. Defaults to POST. API Key Requests are always done as POST regardless to obfuscate the credentials used
        #WARNING: GET WILL SHOW THE ENTIRE API REQUEST URI IN VERBOSE LOGS, INCLUDING API KEYS
        [ValidateSet("GET","POST")]$HTTPMethod = "POST",

        #Ignore SSL Errors. Not recommended for production use but useful for testing or systems with self-signed certificates
        #WARNING: Due to the nature of validation aching, if you specify this once it may take effect for future commands in the session.
        [Switch]$Insecure,

        #If a credential is specified, use those credentials for the request.
        #This is a one-time action and is not saved, Use Connect-PANOSDevice to persist login information
        [PSCredential]$Credential
    )

    begin {
        #Initialize a PANOSAPISessions Variable if it doesn't already exist
        if ($SCRIPT:PANOSAPISessions -eq $null) {
            $SCRIPT:PANOSAPISessions = @{}
        }
    }

    process {
        foreach ($HostnameItem in $Hostname) {
            $RequestParams = @{
                Method = $HTTPMethod
                #Passthrough Common Parameters to Request
                Verbose = ($PSBoundParameters.Verbose -eq $true)
                Insecure = $Insecure
            }

            #Check for an existing session with this host and use that key if available unless one was manually specified
            if ($SCRIPT:PANOSAPISessions.ContainsKey($HostnameItem) -and (! $ArgumentList.key)) {
                $ArgumentList.key = $SCRIPT:PANOSAPISESSIONS[$HostnameItem].key
            }

            #Retrieve API credentials unless 'keygen' action is specified or an API key was manually provided to the command
            if (($ArgumentList.Type -notlike 'keygen') -and (! $ArgumentList.key)) {

                #If Credentials are present, use those to fetch an API key for a one-time operation
                if ($Credential) {
                    write-verbose "PANOS Credential specified for $HostnameItem, fetching API Key"
                    $APIRequestParams = @{
                        type="keygen"
                        user=$Credential.GetNetworkCredential().UserName
                        password=$Credential.GetNetworkCredential().Password
                    }
                    #Adjust the action but preserve all other parameters such as verbose, insecure, etc.
                    $PSBoundParameters.Remove("ArgumentList") | out-null
                    $PSBoundParameters.Remove("Hostname") | out-null
                    $ArgumentList.key = (Invoke-APIRequest @PSBoundParameters -Hostname $HostNameItem -ArgumentList $APIRequestParams).key
                } else {
                    throw "No API Key Found"
                    #TODO: Attempt the connect using any in-memory connection info
                    #Connect-Device -Hostname $HostNameItem
                }
            }

            #If a keygen is requested, always use POST to obfuscate the credentials used from verbose LOGS
            if ($ArgumentList.type -like 'keygen') { $ArgumentList.method = "POST" }

            if ($PSCmdlet.ShouldProcess($HostNameItem,"Invoking API $($ArgumentList.Type) Request")) {
                #Use TLS1.2 by Default. TLS1.0 might be disabled on some Palo Alto Security Profiles.
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                try {
                    $APIResponse = (Invoke-RestMethod @RequestParams -Uri "https://${HostnameItem}/api" -Body $ArgumentList).response
                }
                catch [System.Net.WebException] {
                    $lastError = $_
                    if ($lastError.exception.status -match 'TrustFailure') {
                        write-error "Could not establish trust relationship for the SSL/TLS secure channel to $HostNameItem. Try running Invoke-APIRequest again with the -insecure parameter"
                        continue
                    } else {
                        #Pass through the error
                        $lastError
                    }
                }
                #>

                switch ($APIResponse.status) {
                    'Error' {
                        write-error ("$HostnameItem responded with Error " + $APIResponse.code + ": " + $APIResponse.result.msg)
                    }
                    'Success' {
                        $APIResponse.result
                    }
                    default {
                        write-error "$HostnameItem responded with unknown status" $APIResponse.status
                    }
                }
            }
        } #ForEach
    } #Process
} #Function