function Get-Session {
<#
.SYNOPSIS
Returns session information for an API request
.EXAMPLE
Get-PANOSSession -Hostname mypanosevice.example.local -Credential (Get-Credential) -Persistent
#>

    [CmdletBinding()]
    param (
        #Hostname or IP Address of a PANOS device
        [String[]]$Hostname,
        #When specified, only returns persistent sessions
        [Switch]$Persistent
    )

    process { foreach ($HostnameItem in $Hostname) {
        #TODO: Add Login for getting sessions. Need to figure out how persistent sessions figure into this
    }}
}