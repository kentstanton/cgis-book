# parseXML.ps1


Function ParseKmlRecurse([xml] $kmlNode) {
    
}


$myPlacesFileName = "myplaces_hacked.kml"
$myPlacesFilePath = "C:\myworld\cgis\googleearth\"
$myPlacesFilePathFull = "$myPlacesFilePath\$myPlacesFileName"

write-host "`nParsing a KML file`n"

[xml]$kmlFileContent = get-content $myPlacesFilePathFull

# todo - this pushes the start down to the document - it may not be a valid assumption in all cases
$kmlDocumentRoot = $kmlFileContent.ChildNodes[1]

$placeMarks = $kmlFileContent.ChildNodes[1].SelectNodes("/kml/Document")

$placeMarks.Count

write-host "`nEnd parsing`n"