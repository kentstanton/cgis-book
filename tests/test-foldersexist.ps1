# test-foldersexist


$projectRoot = "c:\myworld\cgis"

$folderList = @("projects","scripts","data")
$testpasses = $true
foreach ($folder in $folderList) {
    $fullPath = "$projectRoot\$folder"
    $testpasses = Test-Path $fullPath
}

if ( $testpasses -eq $false) {
    displayTestResult "FAIL: test-foldersexist - path: $fullpath" $false
} else {
    displayTestResult "FAIL: test-foldersexist - path: $fullpath" $true
}


