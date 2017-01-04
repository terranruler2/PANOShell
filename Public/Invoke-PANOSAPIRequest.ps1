function Invoke-PANOSAPIRequest {
    [CmdletBinding()]

    param (
        #Hostname or IP Address of PANOS (Firewall, Panorama, Collector, etc.) device to issue the request.
        #If not specified it will use the global session information
        [String]$ComputerName,

        #A hashtable list of arguments for the command, such as Type, Action, and XPath/CMD
        $ArgumentList = @{}
    )

    #Use TLS1.2 by Default
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $APIResponse = (Invoke-RestMethod -Method POST -Uri "https://$ComputerName/api" -Body $ArgumentList).response

    switch ($APIResponse.status) {
        'Error' {
            write-error "$ComputerName responded with error " + $APIResponse.code + ": " + $APIResponse.result.msg
        }
        'Success' {
            $APIResponse.result
        }
        default {
            write-error "$ComputerName responded with unknown status" $APIResponse.status
        }
    }
}