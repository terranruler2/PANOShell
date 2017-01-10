function Add-PANOSCommandElement {
<#
.SYNOPSIS
Constructs an XML based on words to be used in PANOS CLI commands
Currently only works for simple commands with no attributes or parameters
#>
    param(
        #The command parts
        [Parameter(Mandatory,ValueFromPipeline)][String[]]$Command,
        #XML Object to append to. If not specified,creates a new one.
        [XML]$xmlObject = (New-Object System.XML.XmlDocument)

    )

    begin {
        $XPATHDeepestChildElement = '//*[not(../*/*)]'
    }

    process {
        foreach ($CommandItem in $Command) {
            #Split into unquoted words (arguments) and quoted phrases (values)

            $CommandItem.split(' ') | foreach-object {
                write-verbose "Processing $PSItem"
                if ($xmlObject.HasChildNodes) {
                    $xmlObject.SelectSingleNode($XPATHDeepestChildElement).appendchild($xmlObject.CreateElement($PSItem)) | out-null
                } else {
                    $xmlObject.appendchild($xmlObject.CreateElement($PSItem)) | out-null
                }
            }
        }
    }

    end {
        $xmlObject
    }

}