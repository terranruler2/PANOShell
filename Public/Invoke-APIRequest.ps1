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
        [String]$Hostname,

        #A hashtable list of arguments for the command, such as Type, Action, and XPath/CMD
        $ArgumentList = @{},

        #HTTP Method to Use. Defaults to GET, but POST is sometimes required for some commands that upload files
        [ValidateSet("GET","POST")]$HTTPMethod = "GET"
    )

    $RequestParams = @{
        Method = $HTTPMethod
        #Passthrough Common Parameters to Request
        Verbose = ($PSBoundParameters.Verbose -eq $true)
    }

    #Retrieve API credentials unless 'keygen' action is specified or an API key was manually provided to the command
    if ($ArgumentList.Type -notmatch 'keygen') {
        if (! $ArgumentList.key) {


        }
    }


    if ($PSCmdlet.ShouldProcess($HostNameItem,"Invoking API $($ArgumentList.Type) Request")) {
        #Use TLS1.2 by Default. TLS1.0 might be disabled on some Palo Alto Security Profiles.
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $APIResponse = (Invoke-RestMethod @RequestParams -Uri "https://$Hostname/api" -Body $ArgumentList).response

        switch ($APIResponse.status) {
            'Error' {
                write-error ("$Hostname responded with Error " + $APIResponse.code + ": " + $APIResponse.result.msg)
            }
            'Success' {
                $APIResponse.result
            }
            default {
                write-error "$Hostname responded with unknown status" $APIResponse.status
            }
        }
    }
}