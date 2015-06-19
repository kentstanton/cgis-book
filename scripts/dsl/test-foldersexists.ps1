# test-foldersexist


$projectRoot = "c:\myworld\cgis"

$folderList = @("projects","scripts","datums")
foreach ($folder in $folderList) {
    $fullPath = "$projectRoot\$folder"
    $isFound = Test-Path $fullPath
    if ( $isFound -eq $false) {
        return $false
    }
}

return $true
