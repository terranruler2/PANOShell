#Initialize a PANOSAPISessions Variable if it doesn't already exist
if ($SCRIPT:PANOSAPISessions -eq $null) {
    $SCRIPT:PANOSAPISessions = @{}
}