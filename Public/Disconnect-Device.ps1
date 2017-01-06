function Disconnect-Device {
<#
.SYNOPSIS
Remove a PAN-OS device from the session table
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Hostname",
            Position=0)]
            [String[]]$Hostname,
        [Parameter(ParameterSetName="All")][Switch]$All
    )

    begin {
        #Reset the API Sessions if All is specified
        if ($All) {
            write-verbose "Disconnecting All Sessions"
            $SCRIPT:PANOSAPISessions = @{}
            return
        }
    }

    process {
        foreach ($HostnameItem in $Hostname) {
            write-verbose "Removing $HostnameItem from Sessions if present"
            $SCRIPT:PANOSAPISessions.Remove($HostnameItem)
        }
    }


}