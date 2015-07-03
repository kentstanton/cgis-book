# daterml

$acceleratorsType = [PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$accelerators = ($acceleratorsType::Get)
$xlinq = Add-Type -AssemblyName System.Xml.Linq -PassThru
$xlinq | ? { $_.IsPublic -and !$_.IsSerializable -and $_.Name -ne "Extensions" -and !$accelerators.ContainsKey($_.Name) } | % {
   $acceleratorsType::Add($_.Name,$_.FullName)
}

if(-not $accelerators.ContainsKey('PSParser')){
    $acceleratorsType::Add('PSParser','System.Management.Automation.PSParser, System.Management.Automation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35')
}

$acceleratorArray = @()
foreach($accelerator in $accelerators) {
    
    $acceleratorArray += [PsObject]$accelerator
}

$acceleratorArray | out-gridview
