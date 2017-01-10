import-module PanoShell
connect-panosdevice scagpano
#Should Error One Way
#invoke-panosapirequest -url '/api/?type=op&cmd=<show><devices><all /></devices></show>' -rawxml
#Should Error Another Way
#invoke-panosapirequest -url '/api/?type=asdfasdf'
#(Invoke-PANOSOperationalCommand -command "show system info" -target 'SCAGFW*').system | fl -prop *
Invoke-panosapirequest -argumentlist @{type='config';action='complete';xpath='/config/devices'} -verbose