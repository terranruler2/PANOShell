import-module PanoShell
connect-panosdevice scagpano -quiet
#Should Error One Way
#invoke-panosapirequest -url '/api/?type=op&cmd=<show><devices></devices></show>' -rawxml
#Should Error Another Way
#invoke-panosapirequest -url '/api/?type=asdfasdf'
#(Invoke-PANOSOperationalCommand -command "show system info" -target 'SCAGFW*').system | fl -prop *
Invoke-panosapirequest -argumentlist @{type='op';action='complete';command='show devicegroups name'} -rawxml -verbose