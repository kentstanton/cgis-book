#requires -version 4.0
Function Get-FileMasher {


<#
    .Synopsis
        Get filtered file results

    .Description
        This function is a wrapper to Get-ChildItem  that makes it easier to filter files by the last write time or their size.


    .Example


    .Link

  Get-ChildItem

#>


[CmdletBinding(DefaultParameterSetName='Items',  SupportsTransactions=$true)]

param(
    [Parameter(ParameterSetName='Items', Position=0,  ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        if  ( (Resolve-Path $_).Provider.Name -eq 'FileSystem') {
            $True

        } else {
            Throw "This command only supports FileSystem paths."
        }
    })]


    [string[]]$Path=".",
    [Parameter(ParameterSetName='LiteralItems', Mandatory=$true,  ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [ValidateScript({
        if  ( (Resolve-Path $_).Provider.Name -eq 'FileSystem') {
            $True
        } else {
            Throw "This command only supports FileSystem paths."
        }
    })]

    [string[]]$LiteralPath,
    [Parameter(Position=1)]
    [string]$Filter,
    [string[]]$Include,
    [string[]]$Exclude,
    [Alias('s')]
    [switch]$Recurse,
    [switch]$Force,
    [switch]$Name,    
    [datetime]$After,
    [datetime]$Before,
    [int]$LargerThan,
    [int]$SmallerThan
)


begin {

    Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"

    try  {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
            $PSBoundParameters['OutBuffer'] = 1
        }

    #add -File to PSBoundParameters
    $PSBoundParameters.Add("File",$True)
    Write-Verbose "PSBoundParameters are: $($PSBoundParameters |  Out-String)"


    #My modification
    if ($After -OR $Before -OR $LargerThan -OR $SmallerThan) {

  #construct a filter 

  $filters = @()

  if ($after) {

  $filters+='$_.lastwritetime -ge $after'

  }

  if ($Before) {

  $filters+='$_.lastwritetime -le $before'

  }

  if ($SmallerThan) {

  $filters+= ' $_.length -le $smallerthan'

  }

  if ($LargerThan) {

  $filters+= ' $_.length -ge $largerthan'

  }

  $f = $filters -join " -AND"

  Write-Verbose $f

  $filterblock = [scriptblock]::Create($f)


           <#

  remove parameters to avoid errors when I splat parameters to 

  Get-ChildItem, or in the case of -Name, which I will manually 

  add back in at the end

  #>

  

  "After","Before","LargerThan","SmallerThan","Name"  | foreach {

  if ($PSBoundParameters.ContainsKey("$_")) {  $PSBoundParameters.Remove($_) | Out-Null }

  }

  

  }        

  

  }  catch {

  throw

  }


     $data=@()

  } #begin


process {

  try  {

  if ($filterblock) {

  $data+= (Get-ChildItem @PSBoundParameters).Where($filterblock)

  }

  else {

  $data+= Get-Childitem @PSBoundParameters

  }

  

  }  catch {

  throw

  }

  

  } #process


End {


    if  ($name) {

  Write-Verbose "send only the filename"

  

  $data | Select-Object -ExpandProperty Name

  }

  else  {

  #write the data to the pipeline

  $data

  }

  Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"

  } #end

  } #end function 