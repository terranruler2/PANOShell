$verbosepreference = "Continue"
import-module PanoShell
connect-panosdevice -hostname scagfw02a
write-host -foreground cyan 'Should Error with "devices is missing"'
#invoke-panosapirequest -url '/api/?type=op&cmd=<show><devices></devices></show>' -rawxml
write-host -foreground cyan 'Should Error with "illegal value for parameter"'
#invoke-panosapirequest -url '/api/?type=asdfasdf'
write-host -foreground cyan 'Should Return System Information for two devices'
#Invoke-PANOSOperationalCommand -command "show system info" -target 'SCAGFW*'
#write-host -foreground cyan 'Should Error with "no completions available"'
#Invoke-panosapirequest -argumentlist @{type='op';action='complete';command='show devicegroups name'} -rawxml

write-host 'Testing advanced CLI layout'
#Invoke-PANOSOperationalCommand -target scagfw02a 'test security-policy-match from=Trusted to=Untrusted source=172.22.17.1 destination="4.2.2.2" destination-port=443 protocol=6 show-all=yes'
write-host 'Testing Packet Trace'
Trace-PANOSPacket -source '172.20.2.1' -destination '4.2.2.2' -port 443 -protocol 6 -application 'http' -From 'Trusted' -To 'Untrusted'