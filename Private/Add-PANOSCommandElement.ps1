function Add-PANOSCommandElement {
<#
.SYNOPSIS
Constructs an XML based on PAN-OS CLI-Like Format
#>
    param(
        #The command parts
        [Parameter(Mandatory,ValueFromPipeline)][String[]]$Command,
        #XML Object to append to. If not specified,creates a new one.
        [XML]$xmlObject = (New-Object System.XML.XmlDocument)
    )

    $XPATHDeepestChildElement = '//*[not(../*/*)]'
    $XPATHCommandRoot = '//*[@CommandRoot]'

    #region Command Parsing Regex
    $REGEXNameValuePairQuoted = @'
(\w+?\=["'][^"']+?["'])
'@
    $REGEXNameValuePair = @'
(\w+?\=[^"' ]+)
'@
    $REGEXValue = @'
(["'][^"']+?["'])
'@
    $REGEXArgument = @'
([^"' ]+)
'@
    #Construct Regex Command Parser
    $REGEXCmdParser = [RegEx](
        $REGEXNameValuePairQuoted + '|' +
        $REGEXNameValuePair + '|' +
        $REGEXValue + '|' +
        $REGEXArgument
    )

    #Special Delimiter for the root of the command
    $REGEXRootCommandDelimiter = '^[#^!:@>]$'

    #Combine the string if it was provided as an array or from the pipeline
    $Command = "$Command"

    foreach ($CommandItem in $REGEXCmdParser.matches($Command).value) {
        #Process the XML depending on what type of command line syntax was provided
        switch -regex ($CommandItem) {
            $REGEXRootCommandDelimiter {
                #This specifies if we should mark the deepest element as a parent, so future entries can behave like
                #The PAN-OS CLI
                if (!$xmlObject.SelectSingleNode($XPATHCommandRoot)) {
                    $commandRoot = $XmlObject.SelectSingleNode($XPATHDeepestChildElement)
                    $commandRoot.setAttribute("CommandRoot","true")
                } else {
                    $commandRoot = $xmlObject.SelectSingleNode($XPATHCommandRoot)
                }
                break
            }
            $REGEXNameValuePairQuoted {
                write-debug "RegexNameValuePairQuoted: $CommandItem"
                #Same as REGEXNameValuePair but strip quotes
                #TODO: Deduplicate RegexNameValuePair Logic to a function
                #Strip out the quotes
                $commandItem = $commandItem.replace('"','')

                #only split on first equals in case there is one in the value
                $splitCommandItem = $CommandItem -split '=',2
                $CommandItemParameter = $splitCommandItem[0]
                $CommandItemValue = $splitCommandItem[1]
                #We Assume if we are doing this we are as deep in the command XML we will go.
                #So we add a "CommandRoot" attribute to the XML so additional elements know not to go deeper
                if (!$xmlObject.SelectSingleNode($XPATHCommandRoot)) {
                    $commandRoot = $XmlObject.SelectSingleNode($XPATHDeepestChildElement)
                    $commandRoot.setAttribute("CommandRoot","true")
                } else {
                    $commandRoot = $xmlObject.SelectSingleNode($XPATHCommandRoot)
                }
                $newParam = $commandRoot.AppendChild($xmlObject.CreateElement($commandItemParameter))
                $newParam.InnerText = $CommandItemValue

                break
            }
            $REGEXNameValuePair {
                #Create a new element and add it to the command root to represent a parameter

                write-debug "Converting NameValuePair: $CommandItem into XML"

                #only split on first equals in case there is one in the value
                $splitCommandItem = $CommandItem -split '=',2
                $CommandItemParameter = $splitCommandItem[0]
                $CommandItemValue = $splitCommandItem[1]
                #We Assume if we are doing this we are as deep in the command XML we will go.
                #So we add a "CommandRoot" attribute to the XML so additional elements know not to go deeper
                if (!$xmlObject.SelectSingleNode($XPATHCommandRoot)) {
                    $commandRoot = $XmlObject.SelectSingleNode($XPATHDeepestChildElement)
                    $commandRoot.setAttribute("CommandRoot","true")
                } else {
                    $commandRoot = $xmlObject.SelectSingleNode($XPATHCommandRoot)
                }
                $newParam = $commandRoot.AppendChild($xmlObject.CreateElement($commandItemParameter))
                $newParam.InnerText = $CommandItemValue

                break
            }
            $REGEXValue {
                #Adds the text of the value to the deepest XML element
                write-debug "Converting Value: $CommandItem into XML";
                #Strip out the quotes
                $commandItem = $commandItem.replace('"','')

                if ($xmlObject.HasChildNodes) {
                    $xmlObject.SelectSingleNode($XPATHDeepestChildElement).appendchild($xmlObject.CreateElement($CommandItem)) | out-null
                } else {
                    $xmlObject.appendchild($xmlObject.CreateElement($CommandItem)) | out-null
                }
                break
            }
            $REGEXArgument{
                #Add a new Child Element to the deepest element
                write-debug "Converting Argument $CommandItem into XML"
                if ($xmlObject.HasChildNodes) {
                    $xmlObject.SelectSingleNode($XPATHDeepestChildElement).appendchild($xmlObject.CreateElement($CommandItem)) | out-null
                } else {
                    $xmlObject.appendchild($xmlObject.CreateElement($CommandItem)) | out-null
                }
                break
            }
            default {throw "Unknown Command Format Syntax"}
        }

    }


    $xmlObject
}