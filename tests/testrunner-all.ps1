
cls
$PSTestsRoot = "c:\myworld\cgis\cgis-book\tests\active\*"
try {
    $testList = get-childitem -Path $PSTestsRoot -Include *.ps1
    
    foreach ($test in $testList) {
        & $test.FullName
    }

} catch {
    write-host "Error"
}



