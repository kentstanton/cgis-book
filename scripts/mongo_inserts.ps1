
$layerArray = @()
$cgisLayerAreaHydro = @{project="mlsp"; layeridentifier="areahydrology"; layername="areahydrology"; absolutepath="c:/myworld/gisdata/ny-hydro-24k-nysgc/AreaHydrography.shp"; active=$true}
$cgisdecLands = @{project="mlsp"; layeridentifier="nyslands"; layername="NYS DEC Lands"; absolutepath="c:/myworld/gisdata/declands/DEC_Lands.shp"; active=$true}
$cgisLayerLinearHydro = @{project="mlsp"; layeridentifier="linearhydrology"; layername="linearhydrology"; absolutepath="c:/myworld/gisdata/ny-hydro-24k-nysgc/LinearHydrography.shp"; active=$true}
$cgisLayermlspboundary = @{project="mlsp"; layeridentifier="mlspboundary"; layername="Moreau Lake State Park Boundary"; absolutepath="C:/myworld/github/kentstanton/CGIS/CGIS-BeechBarkDisease/layers/MoreauLakeSP/Moreau_lake_sp_complete.shp"; active=$true}
$cgisLayercountyboundaries = @{project="mlsp"; layeridentifier="nyscountyboundaries"; layername="NYS County Boundaries"; absolutepath="c:/myworld/gisdata/ny-county-boundaries-nysgc/counties.shp"; active=$true}
$cgisLayerecozoneboundaries = @{project="mlsp"; layeridentifier="nysecozones"; layername="NYS Ecological Zones"; absolutepath="c:/myworld/gisdata/nys_ecozones/dfw_ecozone.shp"; active=$true}


$layerArray += $cgisLayerAreaHydro
$layerArray += $cgisdecLands
$layerArray += $cgisLayerLinearHydro
$layerArray += $cgisLayermlspboundary
$layerArray += $cgisLayercountyboundaries
$layerArray += $cgisLayerecozoneboundaries


import-module mdbc
Connect-Mdbc . cgis cgis.data


foreach ($layer in $layerArray) {

    $data = Get-MdbcData (New-MdbcQuery layeridentifier -eq $layer.layeridentifier) 
    if ($data.Count -eq 0) {
        $layer | add-MdbcData
    }
   
}


<#
$aa = $data = Get-MdbcData (New-MdbcQuery layeridentifier -eq "nyslands") 
$aa
#>