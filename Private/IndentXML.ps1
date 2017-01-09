#Retrieved from: https://gist.github.com/PrateekKumarSingh/96032bd63edb3100c2dda5d64847a48e#file-indentxml-ps1
Function IndentXML
{
    param (
        [Parameter(Mandatory,ValueFromPipeline)][xml]$Content,
        [int]$Indent = 2
    )
    process {
        # String Writer and XML Writer objects to write XML to string
        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter

        # Default = None, change Formatting to Indented
        $xmlWriter.Formatting = "indented"

        # Gets or sets how many IndentChars to write for each level in
        # the hierarchy when Formatting is set to Formatting.Indented
        $xmlWriter.Indentation = $Indent

        $Content.WriteContentTo($XmlWriter)
        $XmlWriter.Flush();$StringWriter.Flush()
        $StringWriter.ToString()
    }
}

# IndentXML -Content $xml -Indent 1