<#
.Synopsis
    Script to assist with untangling a Google Earth MyPlaces file (that has gotten out of control)
    Selects document, folder or placemark top-level entities in your myplaces file 
        and writes new files containing just the elements of that type.


.DESCRIPTION
    Parse KML files and produce new files containing selected kml objects.

    Specify "all" to create new files for everything in your MyPlaces file.

    Make a copy of your MyPlaces file and set the global path variables below to run the script.

    IMPORTANT: This version of the script requires Powershell 5.0. See my github site for information
        on versions that work with older versions of Powershell.

    Developer Notes:
    Using Powersheel 5.x classes to structure the code using composition and the factory pattern.
    Execution starts with call to main at the end of the script.   

.EXAMPLE
   parse-kml -sourceFileName myplaces_copy.kml -NodeTypeToSelect folder

   Parse the KML file named myplaces_copy.kml in the current folder and outputs all top level folder nodes 
    to new files in a sub-folder of the source file location. 
   Overwrite defaults to false so if files exist in the output location, the process is halted.

.EXAMPLE
   parse-kml -sourceFileName myplaces_copy.kml -NodeTypeToSelect all -overwrite true

   Parse the KML file named myplaces_copy.kml in the current folder and output all top level nodes 
    to new files in a sub-folder of the source file location. 
   Overwrite existing output files if any are found.

.EXAMPLE
   parse-kml -sourceFileName myplaces_copy.kml -path "c:\temp" -NodeTypeToSelect all -overwrite true

   Parse the KML file named myplaces_copy.kml in the current folder and output all top level nodes 
    to new files in a sub-folder of the source file location. 
   Overwrite existing output files if any are found.


#>

param(
    [Parameter(Mandatory=$true)]
    $SourceFileName,
    [Parameter(Mandatory=$true)]
    $NodeTypeToSelect,
    [Parameter(Mandatory=$false)]
    $AllowOverwrite = $false,
    [Parameter(Mandatory=$false)]
    $path = $(Convert-Path("."))

)

#####
# Execution starts with the call to main() at the end of the script
#####

# PS 5.x is required.
#Requires –Version 5
Set-StrictMode -Version latest

# Stop on any error. Change this if you want to hanlde errors in a more granular way.
$ErrorActionPreference = "Stop"

CLS

# Using standard input parameter names but keeping these internal names.
# You can override the input parameters by changing these assignments with values approprite for your working environment.
# The KML files created by the script go into a subfolder named below. 
$myPlacesFileName = $SourceFileName
$myPlacesFilePath = $path
$OutputSubFolder = "kmlfiles"


<# Build the paths for the input file and for output. Path validation is done here. 
    Checking if overwriting is an issue is done here.
#>
class EnvironmentData {
    [string] $sourceFileName;
    [string] $sourcePath;
    [string] $sourceFullPath;
    [string] $outputPath;

    EnvironmentData([string] $SourcefileName, [string] $SourcePath, [string] $OutputSubFolder, [boolean]$AllowOverwrite) {
        try {
            $This.sourceFileName = $SourcefileName;
            
            if ($SourcePath.EndsWith("\")) { 
                $This.sourcePath = $SourcePath;
            } else {
                $This.sourcePath = "$($SourcePath)\";
            }
            $This.sourceFullPath = "$($This.SourcePath)$($This.SourceFileName)";
            $This.outputPath = "$($This.sourcePath)$($OutputSubFolder)"

            # If the output folder does not exist, create it
            if ($(test-path $This.outputPath) -eq $false) {
                new-item -itemtype directory -force -Path $This.outputPath
            }

            $This.MakeOutputfolder($AllowOverwrite)
            $This.ReportPathErrors()
        } catch {
            "Unhandled Exception: EnvironmentData - Error building the input and/or output paths."
        }
    }

    MakeOutputfolder ($AllowOverwrite) {
        $dateForName = $((Get-Date).ToShortDateString());
        $dateForName = $dateForName.Replace("/", "_");
        $pathWithSubFolder = "$($this.outputPath)\$($dateForName)"
        
        # brute 
        if ($(test-path $pathWithSubFolder) -eq $true) {
            $countFilesInOutputPath = @( Get-ChildItem $pathWithSubFolder).Count;
            #= Get-ChildItem -Path $pathWithSubFolder -Include *.kml
            if ( $($countFilesInOutputPath -ne 0) -and $($AllowOverwrite -eq $false)) {
                Write-host "Error: You must pass $true for $AllowOverwrite OR the output folder must be empty. No files were written." -ForegroundColor red -BackgroundColor Yellow
                Exit 4
            }
        } else {
            New-Item -Path $pathWithSubFolder -type directory -ErrorAction SilentlyContinue
            $This.outputPath = $pathWithSubFolder 
        }
        $This.outputPath = $pathWithSubFolder
    }

    ReportPathErrors() {
        if ($(test-path $This.SourceFullPath) -eq $false) {
            write-host -foregroundcolor yellow -backgroundcolor red "Terminating Error: The Source path is invalid. $($This.sourceFullPath)"
            Exit 2
        }

        if ($(test-path $This.outputPath) -eq $false) {
            write-host -foregroundcolor yellow -backgroundcolor red "Terminating Error: The Output path is invalid. $($This.outputPath)"
            Exit 2
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


class KmlPlacemark {
    [string] $kmlStyleIdentifier;
    [string] $kmlTypeIdentifier;

    KmlPlacemark([xml.xmlElement] $kmlDocElement) {
        $this.kmlStyleIdentifier = $kmlDocElement.styleUrl;
        $this.kmlTypeIdentifier = "placemark";
    }
}

class KmlFolder {
    [string] $kmlStyleIdentifier;
    [string] $kmlTypeIdentifier;

    KmlFolder([xml.xmlElement] $kmlDocElement) {
        $this.kmlStyleIdentifier = "";
        $this.kmlTypeIdentifier = "folder";

    }
}

class KmlDocument {
    [string] $kmlStyleIdentifier;
    [string] $kmlTypeIdentifier;

    KmlDocument([xml.xmlElement] $kmlDocElement) {
        $this.kmlStyleIdentifier = "";
        $this.kmlTypeIdentifier = "document";

    }
}




# Node Factory using Powershell 5
class KmlNodeFactory {
    [xml.xmlElement] $xml;
    [string] $kmlNodeName;
    [object] $TypedNode;
    [xml.xmlElement] $parentNode;
    [Boolean]$selectedNode = $false;

    KmlNodeFactory([xml.xmlElement] $xmlElement, [string] $nodeTypeName, [string] $NodeTypeToSelect) {
        try {
            $this.xml = $xmlElement;

            # need a better way to handle this...
            if ($this.xml.name.GetType().Name -eq "XmlElement") {
                $this.kmlNodeName = $this.xml.name.'#text'
            } else {
                $this.kmlNodeName = $this.xml.name;
            }
            $this.parentNode = $xmlElement.ParentNode;
            $this.SelectedNode

            Switch ($nodeTypeName) {
                "Placemark" {$this.TypedNode = [KmlPlacemark]::new($this.xml)}
                "Folder" {$this.TypedNode = [KmlFolder]::new($this.xml)}
                "Document" {$this.TypedNode = [KmlDocument]::new($this.xml);}
            }

            if ($NodeTypeToSelect.ToLower() -eq "all") {
                $this.selectedNode = $true;
            } elseif ($NodeTypeToSelect -ne "" -and ($this.TypedNode.kmlTypeIdentifier.ToLower() -eq $NodeTypeToSelect.ToLower()) ) {
                $this.selectedNode = $true;    
            }

            $AllNodesList += $this;
        } catch {
            Write-host "Terminating Error: KmlNodeFactory" -BackgroundColor Red -ForegroundColor Yellow
            $_.Exception.Message;
            Exit 3;
        }

    }

}


# Brute force approach to building up the output XML
# Todo: wrap this in a kmlwriter class
function AddContentToKmlTemplate($selectedNodes) {
$kmlNamespaces = @'
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
'@
    
    try {  
        $nodeTypeStartTag = "<$($selectedNodes.TypedNode.kmlTypeIdentifier)>"
        $nodeTypeEndTag = "</$($selectedNodes.TypedNode.kmlTypeIdentifier)>"
        $templatedKml = "$($kmlNamespaces)$($nodeTypeStartTag)$($selectedNodes.xml.Innerxml)$($nodeTypeEndTag)</kml>"
        return $templatedKml
    } catch {
        Write-host "Terminating Error: AddContentToKmlTemplate" -BackgroundColor Red -ForegroundColor Yellow
        $_.Exception.Message;
        Exit 4;
    }

}


<#
    Create a sub-folder using today's date as the name. Nodes are written as files in this folder.
    # Todo: wrap this in a kmlwriter class
#>
function WriteKml($selectedNodes, $env) {
    
    try {

        foreach($nodeToWrite in $selectedNodes) {
            if ($nodeToWrite.kmlNodeName -eq "") {
                write-host "Warning: No name found for the node to write. We really ought to just stop here but we'll try the next one."
            } else {
                # not going to allow spaces in file names
                $kmlPlaceFileName = ($nodeToWrite.kmlNodeName).replace(" ", "_");
            }

            $fullOutputPath = "$($env.outputpath)\$($kmlPlaceFileName).kml";

            foreach($node in $nodeToWrite) {
                $templatedKmlContent = AddContentToKmlTemplate $node
                $templatedKmlContent | Set-Content $fullOutputPath
            }

        }    
    } catch {
        "Unhandled Exception: WriteKml"
    }


}


<#
    This should/could be refactored to incorporate the parsing 
    into the factory class. My intent is to rewrite this  
    with the core functionality provided by CmdLets written in C#. 
    Pending that this is OK as is.  
#>
Function Main($envData) {

    [xml]$kmlFileContent = get-content $envData.sourceFullPath -ErrorAction Continue

    $KmlDocumentsList = @()
    $KmlFoldersList = @()
    $KmlPlacemarksList = @()
    $AllNodesList = @()
    $SelectedNodes = @()
        
    $kmlPlacemarks = $kmlFileContent.kml.Document.folder.Placemark
    Write-host "`nProcessing Placemarks" -BackgroundColor DarkRed
    foreach ($KmlPlacemark in $kmlPlacemarks) {
        $PlaceMarkNode = [KmlNodeFactory]::new($KmlPlacemark, "Placemark", $NodeTypeToSelect);
        $KmlPlacemarksList += $PlaceMarkNode
        $AllNodesList += $PlaceMarkNode
        if ($PlaceMarkNode.SelectedNode) {
            $SelectedNodes += $PlaceMarkNode;
        }
    }

    $kmlDocuments = $kmlFileContent.kml.Document.folder.Document;
    Write-host "`nProcessing Documents" -BackgroundColor DarkRed
    foreach ($KmlDocument in $kmlDocuments) {
        $DocumentNode = [KmlNodeFactory]::new($KmlDocument, "Document", $NodeTypeToSelect);
        $KmlDocumentsList += $DocumentNode
        $AllNodesList += $DocumentNode
        if ($DocumentNode.SelectedNode) {
            $SelectedNodes += $DocumentNode;
        }
    }

    $kmlFolders = $kmlFileContent.kml.Document.Folder.Folder;
    Write-host "`nProcessing Folders" -BackgroundColor DarkRed
    foreach ($kmlFolder in $kmlFolders) {
        $FolderNode = [KmlNodeFactory]::new($KmlFolder, "Folder",$NodeTypeToSelect);
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
        WriteKml $SelectedNodes $envData
        $SelectedNodes | Out-GridView
    }

}


# load the paths and other globals into an object
$Configuration = [EnvironmentData]::new($myPlacesFileName,$myPlacesFilePath,$OutputSubFolder, $AllowOverwrite);

Main $Configuration $overWrite


