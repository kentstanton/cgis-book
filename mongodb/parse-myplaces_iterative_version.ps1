

param(
    [switch]
    $folders
)

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

class KmlPlacemark {
    [xml.xmlElement] $kmlDoc;
    [string] $kmlDocName;
    [string] $kmlDocType;
    [string] $kmlDocStyleIdentifier;

    KmlPlacemark([xml.xmlElement] $kmlDocElement) {
        $this.kmlDoc = $kmlDocElement;
        $this.kmlDocName = $this.kmlDoc.name;
        $this.SetKmlDocType()
    }

    [void] SetKmlDocType() {
        $this.kmlDocType = "placemark"
    }
    
    [string] GetKmlDocType() {
        return $this.kmlDocType
    }

}

# a folder 
class KmlFolder {
    [xml.xmlElement] $kmlDoc;
    [string] $kmlDocName;
    [string] $kmlDocType;
    [string] $kmlDocStyleIdentifier;
    [string] $nodeParent;

    KmlFolder([xml.xmlElement] $kmlDocElement) {
        $this.kmlDoc = $kmlDocElement;
        $this.kmlDocName = $this.kmlDoc.name;
        $this.kmlDocType = "folder"
        $this.SetParent()
    }

    [void] SetParent() {
        [string] $nodeParent = $this.kmlDoc.ParentNode
        $this.kmlDocType = "placemark"
    }
    
    [string] GetKmlDocType() {
        return $this.kmlDocType
    }

}

# generic, takes a type in the constructor
class KmlDocument {
    [xml.xmlElement] $kmlDoc;
    [string] $kmlDocName;
    [string] $kmlDocType;
    [string] $kmlDocStyleIdentifier;
    [string] $kmlInnerXml;
    [string] $kmlSnippet;
    [string] $nodeParent;

    # constructor
    kmldocument([xml.xmlElement] $kmlDocElement, [string] $type) {
        $this.kmlDoc = $kmlDocElement;
        $this.kmlDocName = $this.kmlDoc.name;
        $this.kmlDocType = $type
        $this.ConstructKmlElement()
    }

    # method assigns to property so void
    [void] ConstructFolder() {
        if ($this.kmlDoc -eq "placemark") {
            $this.kmlDocType = "placemark"
        }       
    }

}


<#

Notes:
#$kmlFileContent.ChildNodes[1].ChildNodes.Folder.Placemark
#$kmlFileContent.ChildNodes[1].ChildNodes.Folder.style
#$kmlFileContent.ChildNodes[1].ChildNodes.Folder.folder
#$kmlFileContent.ChildNodes[1].ChildNodes.Folder.document


#$kmlFileContent.ChildNodes[1].ChildNodes
# contains sytlemap(s), style(s), folder(s)

#$kmlFileContent.ChildNodes[1].ChildNodes.folder
# contains style(s), placemarks(s), folder(s), document(s)

------------
don't separate the nodes early; build the complete list of nodes then operate on the list
so iterate over every xml node and add an object to the master list
then it's easy to iterate over the list to find what you want
------------
#>

$KmlDocuments = @()
$KmlFolders = @()
$KmlPlacemarks = @()

<#
foreach ($kmlDocument in $kmlFileContent.ChildNodes[1].ChildNodes.Item(0).folder.document) {

    #if ($folders.IsPresent) {
    if ($true) {
        foreach($folderElement in $kmlFileContent.ChildNodes[1].ChildNodes.folder) {
            $kmlFolderNode = [KmlFolder]::new($folderElement);
            $FoldersList += $kmlFolderNode
        }
    }
}
#>

cls

<# 
Trying to use xpath. The problem is that the xpath .Net parser is sensitive to errors or unexpected stuff in the xml file.
In at least some cases it provides no feedback about what it does not like. It just fails to return anything.
The myPlaces KML file on my computer has this kml definition:
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">

The .Net xPath parser will not find anything in the document with that in place. It has to be:
<kml xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">

This makes sense, the first namespace attribute is probably an error, but it doesn't complain, it just returns nothing.
Ouch, two hours to figure that out.
#>


#$kmlFileContent.ChildNodes[1].SelectNodes("/kml/Document/Folder/Placemark")

$kmlPlacemarks = $kmlFileContent.ChildNodes[1].SelectNodes("/kml/Document/Folder/Placemark")
Write-host "`nPlacemarks`n" -BackgroundColor DarkRed
foreach ($PlacemarkNode in $kmlPlacemarks) {
    Write-Host $PlacemarkNode.name
}

$kmlDocuments = $kmlFileContent.ChildNodes[1].SelectNodes("/kml/Document/Folder/Document")
Write-host "`nDocuments`n" -BackgroundColor DarkRed
foreach ($kmlDocumentsNode in $kmlDocuments) {
    Write-Host $kmlDocumentsNode.name
}

$kmlFolders = $kmlFileContent.ChildNodes[1].SelectNodes("/kml/Document/Folder/Folder")
Write-host "`nFolders`n" -BackgroundColor DarkRed
foreach ($kmlFoldersNode in $kmlFolders) {
    Write-Host $kmlFoldersNode.name
}
<#
function iteratorOverNodes() {
    foreach ($node in $kmlFileContent.ChildNodes[1].Document.childnodes) {
	    #write-host $node.NodeType
        if ($node.NodeType -eq "Element") {
            foreach ($innernode in $node) {
                write-host "  --- $innernode.LocalName"
            }
        } else {
            write-host "Element -- Node Name: $innernode.LocalName"
        }

    }
}

iteratorOverNodes
#>

#$kmlDocs | Out-GridView