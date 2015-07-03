
# You must have this on to work effectively in PShell
Set-StrictMode -Version latest

# todo move these to params
$myPlacesFileName = "myplaces_hacked.kml";
$myPlacesFilePath = "C:\myworld\cgis\googleearth";
$myPlacesFilePathFull = "$myPlacesFilePath\$myPlacesFileName";
$myPlacesFileKmlOutputPathFull = "$myPlacesFilePath\kmlfiles";

$kmlPlaceFileName = "asiatic_bittersweet.kml";


# todo - uniquify the backup file filename

function write-kml( $kmlObject) {
    
    # if the folder does not exist, create it
    New-Item $myPlacesFileKmlOutputPathFull -type directory -ErrorAction SilentlyContinue

    # if the file exists, make a copy backup_filename.kml
    $fulloutputPath = "$myPlacesFileKmlOutputPathFull\$kmlPlaceFileName";
    if ( (test-path $fulloutputPath) -eq $true) {
        write-host "$fulloutputPath exists"
        $uniqueFileName = "backup`_$kmlPlaceFileName";
        $backupfulloutputPath = "$myPlacesFileKmlOutputPathFull\$uniqueFileName"
        Copy-Item $fulloutputPath $backupfulloutputPath
    } else {
        write-host "$fulloutputPath does not exist"
    }



}

$mockkmlObject = New-Object PSObject

write-kml $mockkmlObject