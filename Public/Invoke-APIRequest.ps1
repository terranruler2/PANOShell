function Invoke-APIRequest {
<#
.SYNOPSIS
Executes the requested command and associated arguments against the Palo Alto XML api
.NOTES
This command is the core of the PANOShell Module and is used by nearly every other command to interact with the API
.LINK
https://www.paloaltonetworks.com/documentation/71/pan-os/xml-api/get-started-with-the-pan-os-xml-api/explore-the-api
#>


    [CmdletBinding(SupportsShouldProcess)]
    #TODO: Add Regex Validate to URL for sanity checking
    param (
        #Hostname or IP Address of PANOS (Firewall, Panorama, Collector, etc.) device to issue the request.
        #If not specified it will use the global session information
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)][String[]]$Hostname,

        #A hashtable list of arguments for the command, such as Type, Action, and XPath/CMD
        [Parameter(ParameterSetName="ArgumentList",Mandatory)][HashTable]$ArgumentList = @{},

        #Specify a relative URL generated from the PAN-OS API Browser. Example: '/api/?type=commit&cmd=<commit></commit>'
        #See the LINKS section for more info on exploring the PAN-OS API
        #NOTE: You cannot use Keygen in this manner
        #WARNING: Whatever you enter here will be visible in verbose logs. Not recommended for sensitive data.
        [Parameter(ParameterSetName="URL",Mandatory)][String]$URL,

        #HTTP Method to Use. Defaults to POST. API Key Requests are always done as POST regardless to obfuscate the credentials used
        #WARNING: GET WILL SHOW THE ENTIRE API REQUEST URI IN VERBOSE LOGS, INCLUDING API KEYS
        [ValidateSet("GET","POST")]$HTTPMethod = "POST",

        #Ignore SSL Errors. Not recommended for production use but useful for testing or systems with self-signed certificates
        #WARNING: Due to the nature of validation aching, if you specify this once it may take effect for future commands in the session.
        [Switch]$Insecure,

        #If a credential is specified, use those credentials for the request.
        #This is a one-time action and is not saved, Use Connect-PANOSDevice to persist login information
        [PSCredential]$Credential,

        #Return Raw XML rather than an XML object. Useful for configs
        [Switch]$RawXML
    )

    begin {
        #Initialize a PANOSAPISessions Variable if it doesn't already exist
        if (!$Hostname) {
            write-verbose "No Hostname specified, sending to all connected sessions"
            $Hostname = $SCRIPT:PANOSAPISessions.keys
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
                    write-verbose "PAN-OS Credential specified for $HostnameItem, fetching API Key"
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
                    write-verbose "No Existing Session or Credentials for $HostnameItem found. Calling Connect-PANOSDevice"
                    $ConnectionInfo = Connect-Device $HostnameItem
                    if (!$ConnectionInfo) {
                        write-error "Request Failed. You must either have an existing session to $HostnameItem or specify a Credential or API Key"
                        continue
                    }
                    #TODO: Attempt the connect using any in-memory connection info
                    #Connect-Device -Hostname $HostNameItem
                }
            }

            #If a keygen is requested, always use POST to obfuscate the credentials used from verbose LOGS
            if ($ArgumentList.type -like 'keygen') { $ArgumentList.method = "POST" }

            #Prepare the URI depending on how the request was made
            #Raw URL Request
            if ($URL) {
                $RequestParams.URI = "https://${HostnameItem}" + $URL
                #ToDo: Parse out the request type using a regex
                $RequestType = "Direct URL"
            #ArgumentList
            } else {
                $RequestParams.URI = "https://${HostnameItem}/api"
                $RequestType = $ArgumentList.type
            }
            if ($PSCmdlet.ShouldProcess($HostNameItem,"Invoking API $RequestType Request")) {
                #Use TLS1.2 by Default. TLS1.0 might be disabled on some Palo Alto Security profiles due to heartbleed
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                try {
                    $APIResponse = (Invoke-RestMethod @RequestParams -Body $ArgumentList).response
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
                        continue
                    }
                    'Success' {
                        if ($RawXML) {
                            $APIResponse.result.innerxml
                        } else {
                            $APIResponse.result
                        }

                    }
                    default {
                        write-error "$HostnameItem responded with unknown status" $APIResponse.status
                        continue
                    }
                }
            }
        } #ForEach
    } #Process
} #Function