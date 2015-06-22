# validate layers


import-module mdbc
Connect-Mdbc . cgis cgis.data

$projectidentifier = 'mlsp'

$layerList = Get-MdbcData (New-MdbcQuery project -eq $projectidentifier) 

foreach($layer in $layerList) {
    $layerPath = $layer.absolutepath
    $found = Test-Path $layerPath
    if ($found) {
        $msg = "FOUND " + $layer.layername
        write-host $msg -ForegroundColor DarkGreen -BackgroundColor Yellow 
    } else {
        $msg = "MISSING " + $layer.layername
        write-host $msg -ForegroundColor DarkRed -BackgroundColor Yellow 
    
    }
}
