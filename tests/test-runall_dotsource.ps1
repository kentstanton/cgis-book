

cls

Function displayTestResult ($testResult, $passed) {
    if ($passed -eq $true) {
        write-host $testResult -backgroundcolor green -foregroundcolor white
    } else {
        write-host $testResult -backgroundcolor red -foregroundcolor white
    }
 }  


. "$PSScriptRoot\test-foldersexist.ps1"

