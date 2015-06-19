# test-mongodbservicerunning

cls

. "c:\myworld\cgis\cgis-book\tests\testglobals.ps1"

$mongoDBServiceName = "MongoDB"
$testpasses = $false

$mongoService = Get-Service -Name $mongoDBServiceName

 if ($mongoService.Status -eq "Running") {
    $testpasses = $true
 }

 if ( $testpasses -eq $false) {
    displayTestResult "FAIL: MongoDB service not running" $false
} else {
    displayTestResult "PASS: MongoDB service is running" $true
}


