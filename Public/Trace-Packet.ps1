function Trace-Packet {
<#
.SYNOPSIS
Specify a test packet source and destination to report back the path it flows through the PAN-OS device and any rules
it may encounter.
.DESCRIPTION
This command executes several test commands to put together a picture of how the packet flows through the device. It is
meant to be similar to the excellent Cisco ASA Packet Tracer.
#>

    param (
        #Hostname or IP Address of PAN-OS device. If not specified, targets all connected systems.
        [String]$Hostname,
        #Name or Serial of a managed PAN-OS device connected to Panorama
        [String]$Target,
        #Source IP Address of the Packet
        [IPAddress]$Source,
        #Destination IP Address of the Packet
        [IPAddress]$Destination,
        #Source Zone
        [String]$From,
        [String]$FromInterface,
        #Destination Zone
        [String]$To,
        #Destination Interface
        [String]$ToInterface,
        #Destination Port
        [String]$Port,
        [String]$SourcePort,
        [String]$Application,
        [String]$Category,
        [String]$User,
        #Which IP Protocol is being tested. Defaults to 6 (TCP)
        #TODO: Add Protocol to Name Resolution
        [String]$Protocol=6
    )

    begin {
        #Prepare Testing Commands
        $traceCommandDefinition = @()
        $commonArgs = 'from','source','destination','port','protocol'
        #Security Policy Match
        $traceCommandDefinition += [PSCustomObject]@{
            Command = 'test security-policy-match'
            Arguments = $commonArgs + 'to','application','category','user'
        }
        $traceCommandDefinition += [PSCustomObject]@{
            Command = 'test nat-policy-match'
            Arguments = $commonArgs  + 'to','tointerface','sourceport'
        }
        $traceCommandDefinition += [PSCustomObject]@{
            Command = 'test pbf-policy-match'
            Arguments = $commonArgs + 'fromInterface','application','category','user'
        }
        $traceCommandDefinition += [PSCustomObject]@{
            Command = 'test qos-policy-match'
            Arguments = $commonArgs + 'application','category','to','user'
        }
        $traceCommandDefinition += [PSCustomObject]@{
            Command = 'test dos-policy-match'
            Arguments = $commonArgs + 'to','toInterface','user'
        }
        $traceCommandDefinition += [PSCustomObject]@{
            Command = 'test cp-policy-match'
            Arguments = 'from','to','source','destination','category'
        }
        $traceCommandDefinition += [PSCustomObject]@{
            Command = 'test decryption-policy-match'
            Arguments = 'from','to','source','destination','application','category'
        }


        $traceCommandFinished = @()
        foreach ($traceCommandItem in $traceCommandDefinition) {
            $rootCommandItem = $null
            $PSBoundParameters.keys |
                where-object {$traceCommandItem.Arguments -eq $PSItem} |
                foreach-object {
                    #Perform some CLI Keyword substitution
                    switch ($PSItem) {
                        "Port" {$PanoParameter = "destination-port"}
                        "SourcePort" {$PanoParameter = "source-port"}
                        "ToInterface" {$PanoParameter = "to-interface"}
                        "FromInterface" {$PanoParameter = "from-interface"}
                        "User" {$PanoParameter = "souce-user"}
                        default {$PanoParameter = $PSItem.tolower()}
                    }
                    $RootCommandItem = $RootCommandItem += " $PanoParameter=`"$($PSBoundParameters[$PSItem])`""
                }
            $traceCommandFinished += $traceCommandItem.command + $RootCommandItem
        }
    }

    process {
        $opCommandParams = @{}
        if ($target) {$opCommandParams.target = $target}
        write-host ''
        write-host -fore green '===================='
        write-host -fore green 'PAN-OS Packet Tracer'
        write-host -fore green '===================='

        foreach ($traceCommandFinishedItem in $traceCommandFinished) {
            $cmdResponse = $null
            #Write the test type, extracting from command
            write-host -fore cyan ($traceCommandFinishedItem -replace 'test ([\w\-]+) .*','$1')
            write-host -fore cyan '--------------------------------------'
            write-verbose "Running $traceCommandFinishedItem"
            try {
                $cmdResponse = Invoke-OperationalCommand @opCommandParams $traceCommandFinishedItem -erroraction Stop
            } catch {
                if ($PSItem.exception.message -match 'QoS policy lookup - no match') {
                    write-host -fore yellow "No QoS Matches Found"
                } else {
                    write-error $PSItem
                }
            }
            if ($cmdResponse -and $cmdResponse.selectsinglenode('.//entry')) {
                write-host -fore "Green" $cmdResponse.rules.entry
            }
            else { write-host -fore yellow "No Matches Found" }

            write-host -fore cyan '--------------------------------------'
            write-host ''
        }
    }
}