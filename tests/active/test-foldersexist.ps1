# test-foldersexist

. "c:\myworld\cgis\cgis-book\tests\testglobals.ps1"

$folderList = @("projects","scripts","data")
$testpasses = $true
foreach ($folder in $folderList) {
    $fullPath = "$projectRoot\$folder"
    $testpasses = Test-Path $fullPath
}


if ( $testpasses -eq $false) {
    displayTestResult "FAIL: test-foldersexist - path: $fullpath" $false
} else {
    displayTestResult "PASS: test-foldersexist - path: $fullpath" $true
}


