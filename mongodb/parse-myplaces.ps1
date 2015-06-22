
$myPlacesFileName = "myplaces_hacked.kml"
$myPlacesFilePath = "C:\myworld\cgis\googleearth\"
$myPlacesFilePathFull = "$myPlacesFilePath\$myPlacesFileName"
$myPlacesFileKmlOutputPathFull = "$myPlacesFilePath\kmlfiles"

# todo - path validation cmdlet
if ( (test-path $myPlacesFilePath) -eq $false) {
    write-host "Terminating Error: Path not found. $myPlacesFilePath" -ForegroundColor DarkMagenta -BackgroundColor yellow
    exit
}

[xml]$kmlFileContent = get-content $myPlacesFilePathFull


class KmlDocument {
    [xml.xmlElement] $kmlDoc;
    [string] $kmlDocName;
    [string] $kmlDocType;
    [string] $kmlDocStyleIdentifier;

    # constructor - $this is now required for property references
    kmldocument([xml.xmlElement] $kmlDocElement) {

        $this.kmlDoc = $kmlDocElement;
        $this.kmlDocName = $this.kmlDoc.name;

        $this.AssignKmlDocType()
    
    }


    # method assigns to property so void
    [void] AssignKmlDocType() {
        if ($true) {
            $this.kmlDocType = "placemark"
        }       
    }

}


$kmlDocs = @()
foreach ($kmlDocument in $kmlFileContent.ChildNodes[1].ChildNodes.Item(0).folder.document) {
    $kmlDoc = [KmlDocument]::new($kmlDocument);
    $kmlDocs += $kmlDoc
}

$kmlDocs | Out-GridView