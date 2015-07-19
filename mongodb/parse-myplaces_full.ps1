<#
.Synopsis
   Selects a document, folder, or placemark in a KML file and writes a new file containg just that element.
   Specify "all" to rewrite the entire KML file as new files with one top level entry per file.

   IMPORTANT: This version of the script requires Powershell 5.0. See my github site for information
   on versions that work with older versions of Powershell.

.DESCRIPTION
    Parse KML files and produce new files containing selected kml objects.

    Developer Notes:
    Using Powersheel 5.x classes to structure the code using composition and the factory pattern.
    Execution starts with call to main at the end of the script.   

.EXAMPLE
   parse-kml -selector "Moreau Lake State Park Trails"

   Select any folders, documents or placemarks with the name "Moreau Lake State Park Trails" and write to file(s)

.EXAMPLE
   parse-kml -selector all

#>

param(
    [Parameter(Mandatory=$true)]
    $NodeToSelect,
    $outputType
)


# make sure the user has PS 5.x
Requires –Version 5
Set-StrictMode -Version latest
cls



class EnvironmentData {
    [string] $sourceFileName;
    [string] $sourcePath;
    [string] $sourceFullPath;
    [string] $outputPath;
    [boolean] $sourcePathValid;
    [boolean] $outputPathValid;

    EnvironmentData([string] $SourcefileName, [string] $SourcePath, [string] $OutputPath) {
        try {
            $This.sourceFileName = $SourcefileName;
            $This.sourcePath = $SourcePath;
            $This.sourceFullPath = "$($This.SourcePath)\$($This.SourceFileName)";
            $This.outputPath = $outputPath;

            $This.ReportPathErrors()
        } catch {
            "Warning: error occurred in EnvironmentData" 
        }
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
    KmlNodeFactory([xml.xmlElement] $xmlElement, $nodeType, [string] $nodeToSelect) {
        try {
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

            if ($nodeToSelect.ToLower() -eq "all") {
                $this.selectedNode = $true;
            } elseif ($nodeToSelect -ne "" -and ($this.kmlNodeName.ToLower() -eq $nodeToSelect.ToLower()) ) {
                $this.selectedNode = $true;    
            }

            $AllNodesList += $this;
        } catch {
            "Warning: error occurred in KMLNodeFactory" 
        }

    }

}


# refactoring the nodewriter
class NodeWriter {
    [string] $nodeName;
    [string] $outputPath;
    [xml.xmlElement] $xml;
    [string] $nodeType;
    [string] $nodeFullName;

    NodeWriter([string] $outputPath, [string] $nodeName, [string] $nodeType, [xml.xmlElement] $xml) {
        write-host "hello from nodewriter"
    }

    writeKmlEx($selectedNodes) {
    # for each node
    # create a folder nodetype_nodename ex: folder_vernalpool
    # write the base kml file to the folder
    # copy any referenced resources into the folder
        
        <#
        foreach($node in $selectedNodes) {
            $folderExists = test-path 
        }
        #>

        $this.MakeNodeOutputFullName();
        write-host $this.nodeFullName;
    }

    MakeNodeOutputFullName() {
        # fullname is $outputPath + type + name
        # example: d:\mykmlfiles\placemark123\placemark123.kml
        $this.outputPath.trimend("\");
        $this.nodeName.Replace(" ", "_")

        $this.nodeFullName = "$($this.outputPath)\$($this.nodeName)\$($this.nodeName).kml" 

    }

}

function AddContentToKmlTemplate($selectedNodes) {
$kmlNamespaces = @'
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
'@
    
    try {    
        #$templatedKml = $kmlNamespaces + $selectedNodes.xml.Innerxml + "</kml>"
        $nodeTypeStartTag = "<$($selectedNodes.kmlNodeType)>"
        $nodeTypeEndTag = "</$($selectedNodes.kmlNodeType)>"
        $templatedKml = "$($kmlNamespaces)$($nodeTypeStartTag)$($selectedNodes.xml.Innerxml)$($nodeTypeEndTag)</kml>"
        return $templatedKml
    } catch {
        "Warning: error occurred in AddContentToKmlTemplate" 
    }

}


<#
    Create a folder using today's date
    write each node in the selected node list to a file in the folder
#>
function WriteKml($selectedNodes, $env, $overWrite) {
    
    try {
        # if the folder does not exist, create it
        $dateForName = $((Get-Date).ToShortDateString());
        $dateForName = $dateForName.Replace("/", "_");
        $newPath = "$($env.outputPath)\$($dateForName)" 
        New-Item -Path $newPath -type directory -ErrorAction SilentlyContinue 

        foreach($nodeToWrite in $selectedNodes) {
            if ($nodeToWrite.kmlNodeName -eq "") {
                write-host "Error: No name found for the node to write. We really ought to just stop here but we'll try the next one."
            } else {
                # not going to allow spaces in file names
                $kmlPlaceFileName = ($nodeToWrite.kmlNodeName).replace(" ", "_");
            }

            $fulloutputPath = "$newPath\$kmlPlaceFileName.kml";

            foreach($node in $nodeToWrite) {
                $templatedKmlContent = AddContentToKmlTemplate $node
                $templatedKmlContent | Set-Content $fulloutputPath
            }

            <#
            # if the file does not exist, or overwrite is true, write the file
            if ( ((test-path $fulloutputPath) -eq $false) -or ($overWrite -eq $true) ) {
                $backupFileName = "backup`_$($kmlPlaceFileName).kml";
                $backupfulloutputPath = "$myPlacesFileKmlOutputPathFull\$backupFileName"
                Copy-Item $fulloutputPath $backupfulloutputPath
                # validate that the backup was created. write message


            } else {
                write-host -ForegroundColor Black -BackgroundColor Yellow  "File Not written. $fulloutputPath exists. Specify overwrite to replace."
            }
            #>
        }    
    } catch {
        "Warning: error occurred in WriteKml"
    }


}


<#
    This could be refactored to incorporate the parsing 
    into the node classes themseleves. But this will be rewritten 
    with the core functionality provided by CmdLets written in C# so
    leaving it as is.  
#>
Function Main($envData) {

    try {
        [xml]$kmlFileContent = get-content $myPlacesFilePathFull

        $KmlDocumentsList = @()
        $KmlFoldersList = @()
        $KmlPlacemarksList = @()
        $AllNodesList = @()
        $SelectedNodes = @()
        

        <#
        if ($outputAllNodesToFiles) {
            $StaticNodeWriter = [NodeWriter]::new($outputPath, $nodeName, $nodeType, $xml)
        }
        #>

        <#
        Using the Powershell xml adapter syntax. Started using xpath but the PS syntax is much easier 
        #>
        $kmlPlacemarks = $kmlFileContent.kml.Document.folder.Placemark
        Write-host "`nProcessing Placemarks" -BackgroundColor DarkRed
        foreach ($KmlPlacemark in $kmlPlacemarks) {
            $PlaceMarkNode = [KmlNodeFactory]::new($KmlPlacemark, "Placemark", $NodeToSelect);
            $KmlPlacemarksList += $PlaceMarkNode
            $AllNodesList += $PlaceMarkNode
            if ($PlaceMarkNode.SelectedNode) {
                $SelectedNodes += $PlaceMarkNode;
            }
        }

        $kmlDocuments = $kmlFileContent.kml.Document.folder.Document;
        Write-host "`nProcessing Documents" -BackgroundColor DarkRed
        foreach ($KmlDocument in $kmlDocuments) {
            $DocumentNode = [KmlNodeFactory]::new($KmlDocument, "Document", $NodeToSelect);
            $KmlDocumentsList += $DocumentNode
            $AllNodesList += $DocumentNode
            if ($DocumentNode.SelectedNode) {
                $SelectedNodes += $DocumentNode;
            }
        }

        $kmlFolders = $kmlFileContent.kml.Document.Folder.Folder;
        Write-host "`nProcessing Folders" -BackgroundColor DarkRed
        foreach ($kmlFolder in $kmlFolders) {
            $FolderNode = [KmlNodeFactory]::new($KmlFolder, "Folder",$NodeToSelect);
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
            WriteKml $SelectedNodes $envData $overWrite
            $SelectedNodes | Out-GridView
        }
    } catch {
        #PropertyNotFoundException - unexpected xml structure
        "Warning: error occurred in Main" 
    }

}

# global data; Call main to start processing

$myPlacesFileName = "myplaces_backup.kml"
$myPlacesFilePath = "C:\myworld\cgis\googleearth\"
$myPlacesFilePathFull = "$myPlacesFilePath\$myPlacesFileName"
$myPlacesFileKmlOutputPathFull = "$($myPlacesFilePath)kmlfiles"
$myPlacesHome = "C:\Users\kent\AppData\LocalLow\Google\GoogleEarth"
$overWrite = $true

$outputAllNodesToFiles = $true

$EnvData = [EnvironmentData]::new($myPlacesFileName,$myPlacesFilePath,$myPlacesFileKmlOutputPathFull);
Main $EnvData $overWrite


