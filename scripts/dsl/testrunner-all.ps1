param(
    #[Parameter(mandatory=$true)]
    $testFolder
)

cls
$testFolder = "c:\myworld\cgis\tests"
$testPasses = $false
 
try {
    $testList = get-childitem -Path $testFolder
    
    foreach ($test in $testList) {
    
    $testPasses =  Invoke-expression $test

    if ( $testPasses -eq $false) {
        write-host "fail"
    }

}

    $testList
} catch {
    write-host "Error"
}

Write-Host "All Pass"



