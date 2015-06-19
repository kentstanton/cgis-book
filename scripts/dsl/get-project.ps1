<#
.Synopsis
   get-project
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

Param
(
    # Param1 help description
    [ Parameter(Mandatory=$false) ] $outputType = "grid",
    [ Parameter(Mandatory=$false) ] $projectName = "all"
)


import-module mdbc


function get-cgisroot() {
    Connect-Mdbc . cgis cgis.admin
    $data = Get-MdbcData -As PS
    return $data.cgisroot
}

function test-cgisroot($cgisRoot) {

    $isOK = test-path $cgisRoot
    return $isOK
}


function get-projects() {
    Connect-Mdbc . cgis cgis.projects
    $projects = Get-MdbcData -As PS
    return $projects
}

$cgisRoot = get-cgisroot
$isOK = test-cgisroot $cgisRoot
if ( -not $isOK ) {
    Write-Host "Terminating Error: The CGIS root folder does not exist."
    exit
}

$projects = get-projects

$projects | Out-GridView

