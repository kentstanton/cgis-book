<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function get-kml
{
    [CmdletBinding(DefaultParameterSetName='Rewrite KML', 
                  SupportsShouldProcess=$true,
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias("rkml")]
    [OutputType([String])]
    Param
    (
        # The action to take is required
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Rewrite KML')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("rewrite", "list", "table")]
        [Alias("aa")] 
        $action,

        # the selector - the name of the KML object, is required
        [Parameter(ParameterSetName='Rewrite KML')]
        [AllowEmptyString()]
        [string]
        $selector

    )

    Begin
    {
    }
    Process
    {
        $action
        $selector
        if ($pscmdlet.ShouldProcess("Target", "Operation"))
        {
        }
    }
    End
    {
    }
}