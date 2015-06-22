# create project folders
# inputs:
# project root path

param(
    #[Parameter(mandatory=$true)]
    $projectRoot
)

$folderList = @("projects","scripts","data", "images", "tests")
$projectRoot = "C:\myworld\cgis\cgis-book"

$rootFolderExists = test-path "C:\myworld\cgis\cgis-book"
if ($rootFolderExists -eq $false) {
    write-host "Error: root folder not found: $projectRoot"
    exit
} else {
    foreach($folder in $folderList) {
        $fullPath = "$projectRoot\$folder"
        $folderAlreadyExists = test-path $fullPath
        if ($folderAlreadyExists) {
            write-host "Folder Exists: $fullPath"
        } else {
            mkdir $fullPath
            write-host "Folder Created: $fullPath"
        }
    }
}