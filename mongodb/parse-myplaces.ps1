<#
.Synopsis
   Select a document, folder, or placemark in a KML and write a new file containg just that element.
   REQUIRES Powershell 5.x

.DESCRIPTION
   Parse KML files and produce new files containing selected kml objects.
   ParameterSets:
   -rewrite <-selector ""> <-outputtype grid,list,file> <-file "path/filename">
   -view <-selector ""> <-outputtype grid,list>

.EXAMPLE
   parse-kml -rewrite -file myfile.kml -selector "Moreau Lake State Park Trails"

.EXAMPLE
   parse-kml -view -selector "Moreau Lake State Park Trails" -output grid
#>
param(
    [Parameter(Mandatory=$true)]
    $NodeToSelect,
    $KmlType,
    $outputType
)


<#
Developer Notes:
The script is self-contained; all the code is present. Modularized code is available from my GitHub repo at:


Using Powersheel 5.x classes to structure the code using composition and the factory pattern.

Execution starts with call to main at the end of the script.
    
#>

#Requires –Version 5
Set-StrictMode -Version latest
cls

$myPlacesFileName = "myplaces.kml"
$myPlacesFilePath = "C:\myworld\cgis\googleearth\"
$myPlacesFilePathFull = "$myPlacesFilePath\$myPlacesFileName"
$myPlacesFileKmlOutputPathFull = "$myPlacesFilePath\kmlfiles"
$myPlacesHome = "C:\Users\kent\AppData\LocalLow\Google\GoogleEarth"



<#
    todo - Read the local config from an answer file. 
#>
class EnvironmentData {
    [string] $sourceFileName;
    [string] $sourcePath;
    [string] $sourceFullPath;
    [string] $outputPath;
    [boolean] $sourcePathValid;
    [boolean] $outputPathValid;

    EnvironmentData([string] $SourcefileName, [string] $SourcePath, [string] $OutputPath) {
        $This.sourceFileName = $SourcefileName;
        $This.sourcePath = $SourcePath;
        $This.sourceFullPath = "$($This.SourcePath)\$($This.SourceFileName)";
        $This.outputPath = $outputPath;

        $This.ReportPathErrors()
    }

    ReportPathErrors() {
        $This.sourcePathValid = test-path $This.SourceFullPath
        if ($This.sourcePathValid -eq $false) {
            write-host -foregroundcolor yellow -backgroundcolor red "Terminating Error: Full source path is invalid. $($This.sourceFullPath)"
        }

        $This.OutPutPathValid = test-path $This.outputPath;
        if ($This.OutPutPathValid -eq $false) {
            write-host -foregroundcolor yellow -backgroundcolor red "Terminating Error: Output path is invalid. $($This.outputPath)"
        }
    }
}


class KmlPoint {
    [float] $latitude;
    [float] $longitude;
    [float] $elevation;

    KmlPlacemarkEX([xml.xmlElement] $kmlDocElement) {
        $this.kmlStyleIdentifier = $kmlDocElement.styleUrl;
    }
}


class KmlPlacemarkEX {
    [string] $kmlStyleIdentifier;

    KmlPlacemarkEX([xml.xmlElement] $kmlDocElement) {
        $this.kmlStyleIdentifier = $kmlDocElement.styleUrl;
    }
}

class KmlFolderEX {
    [string] $kmlStyleIdentifier;

    KmlFolderEX([xml.xmlElement] $kmlDocElement) {
        $this.kmlStyleIdentifier = "";
    }
}

class KmlDocumentEX {
    [string] $kmlStyleIdentifier;

    KmlDocumentEX([xml.xmlElement] $kmlDocElement) {
        $this.kmlStyleIdentifier = "";
    }
}


class KmlPlacemark {
    [xml.xmlElement] $kmlDoc;
    [string] $kmlDocName;
    [string] $kmlDocType;
    [string] $kmlDocStyleIdentifier;

    KmlPlacemark([xml.xmlElement] $kmlDocElement) {
        $this.kmlDoc = $kmlDocElement;
        $this.kmlDocName = $this.kmlDoc.name;
        $this.kmlDocType = "placemark"
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
    }
}

# a document
class KmlDocument {
    [xml.xmlElement] $kmlDoc;
    [string] $kmlDocName;
    [string] $kmlDocType;
    [string] $kmlDocStyleIdentifier;
    [string] $kmlInnerXml;
    [string] $kmlSnippet;

    # constructor
    kmldocument([xml.xmlElement] $kmlDocElement) {
        $this.kmlDoc = $kmlDocElement;
        $this.kmlDocName = $this.kmlDoc.name;
        $this.kmlDocType = "document"
    }
}

# factory
class KmlNodeFactory {
    [xml.xmlElement] $xml;
    [string] $kmlNodeName;
    [string] $kmlNodeType;
    $TypedNode;
    [xml.xmlElement] $parentNode;
    [Boolean]$selectedNode = $false;

    # constructor
    KmlNodeFactory([xml.xmlElement] $xmlElement, $nodeType, [string] $nodeToSelect, $SelectedNodes) {
        $this.xml = $xmlElement;
        $this.kmlNodeName = $this.xml.name;
        $this.kmlNodeType = $nodeType
        $this.parentNode = $xmlElement.ParentNode;
        $this.SelectedNode

        Switch ($nodeType) {
            "Placemark" {$this.TypedNode = [KmlPlacemarkEX]::new($this.xml)}
            "Folder" {$this.TypedNode = [KmlFolderEX]::new($this.xml)}
            "Document" {$this.TypedNode = [KmlDocumentEX]::new($this.xml);}
        }


        if ($nodeToSelect -ne "" -and $this.kmlNodeName.ToLower() -eq $nodeToSelect.ToLower()) {
            $this.selectedNode = $true;    
        }

        $AllNodesList += $this;
    }

}


function AddContentToKmlTemplate($selectedNodes) {
$kmlNamespaces = @'
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
'@
    
    #$templatedKml = $kmlNamespaces + $selectedNodes.xml.Innerxml + "</kml>"
    $nodeTypeStartTag = "<$($selectedNodes.kmlNodeType)>"
    $nodeTypeEndTag = "</$($selectedNodes.kmlNodeType)>"
    $templatedKml = "$($kmlNamespaces)$($nodeTypeStartTag)$($selectedNodes.xml.Innerxml)$($nodeTypeEndTag)</kml>"
    return $templatedKml
}


function write-kmlEx($selectedNodes) {
# for each node
# create a folder nodetype_nodename ex: folder_vernalpool
# write the base kml file to the folder
# copy any referenced resources into the folder

    foreach($node in $selectedNodes) {
        $folderExists = test-path 
    }
}

function write-kml($selectedNodes) {
    
    # if the folder does not exist, create it
    New-Item $myPlacesFileKmlOutputPathFull -type directory -ErrorAction SilentlyContinue

    if ($selectedNodes.kmlNodeName -eq "") {
        write-host "We don't have a node name. We really ought to just stop here."
    } else {
        # not going to allow spaces in file names
        $kmlPlaceFileName = ($selectedNodes.kmlNodeName).replace(" ", "_");
    }

    # if the file exists, make a copy backup_filename.kml
    $fulloutputPath = "$myPlacesFileKmlOutputPathFull\$kmlPlaceFileName.kml";
    if ( (test-path $fulloutputPath) -eq $true) {
        write-host -ForegroundColor Black -BackgroundColor Yellow  "File Not written. $fulloutputPath exists. Specify overwrite to replace."
        $uniqueFileName = "backup`_$kmlPlaceFileName";
        $backupfulloutputPath = "$myPlacesFileKmlOutputPathFull\$uniqueFileName"
        Copy-Item $fulloutputPath $backupfulloutputPath
    } else {
        write-host "$fulloutputPath does not exist"
    }
    
    foreach($node in $selectedNodes) {
        $templatedKmlContent = AddContentToKmlTemplate $node
        $templatedKmlContent | Set-Content $fulloutputPath
    }
}


<#
    This could be refactored to incorporate the parsing 
    into the node classes themseleves. But this will be rewritten 
    with the core functionality provided by CmdLets written in C# so
    leaving it as is.  
#>
Function Main($envData) {
    [xml]$kmlFileContent = get-content $myPlacesFilePathFull

    $KmlDocumentsList = @()
    $KmlFoldersList = @()
    $KmlPlacemarksList = @()
    $AllNodesList = @()
    $SelectedNodes = @()

    <#
    Using the Powershell xml adapter syntax. Tried to do this using xpath but ran 
    into a gotcha with the KML namespace references sa saved by Google Earth. Turns
    out the PS xml syntax is frieghteningly convenient.
    #>
    $kmlPlacemarks = $kmlFileContent.kml.Document.folder.Placemark
    Write-host "`nProcessing Placemarks" -BackgroundColor DarkRed
    foreach ($KmlPlacemark in $kmlPlacemarks) {
        $PlaceMarkNode = [KmlNodeFactory]::new($KmlPlacemark, "Placemark", $NodeToSelect, $SelectedNodes);
        $KmlPlacemarksList += $PlaceMarkNode
        $AllNodesList += $PlaceMarkNode
        if ($PlaceMarkNode.SelectedNode) {
            $SelectedNodes += $PlaceMarkNode;
        }
    }

    $kmlDocuments = $kmlFileContent.kml.Document.folder.Document;
    Write-host "`nProcessing Documents" -BackgroundColor DarkRed
    foreach ($KmlDocument in $kmlDocuments) {
        $DocumentNode = [KmlNodeFactory]::new($KmlDocument, "Document", $NodeToSelect,$SelectedNodes);
        $KmlDocumentsList += $DocumentNode
        $AllNodesList += $DocumentNode
        if ($DocumentNode.SelectedNode) {
            $SelectedNodes += $DocumentNode;
        }
    }

    $kmlFolders = $kmlFileContent.kml.Document.Folder.Folder;
    Write-host "`nProcessing Folders" -BackgroundColor DarkRed
    foreach ($kmlFolder in $kmlFolders) {
        $FolderNode = [KmlNodeFactory]::new($KmlFolder, "Folder",$NodeToSelect,$SelectedNodes);
        $KmlFoldersList += $FolderNode
        $AllNodesList += $FolderNode
        if ($FolderNode.SelectedNode) {
            $SelectedNodes += $FolderNode;
        }
    }

    # Write the output; Display results
    if ($SelectedNodes.Count -eq 0) {
        #write-host "No nodes met the selection criteria"
        $AllNodesList | Out-GridView
    } else {
        write-kml $SelectedNodes
        $SelectedNodes | Out-GridView
    }

}

# global data

$EnvData = [EnvironmentData]::new($myPlacesFileName,$myPlacesFilePath,$myPlacesFileKmlOutputPathFull);


# Call main to start processing

Main $EnvData


