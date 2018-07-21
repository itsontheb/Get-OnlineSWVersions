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

Get-OnlineVerTEMPLATE
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [Alias("SW")]
        $SoftwareName = 'TEMPLATE',
        [Parameter(Mandatory=$false, 
                   Position=1)]
        [Alias("URL")]
        [string]$URI = 'TEMPLATE',
        [Parameter(Mandatory=$false, 
                   Position=2)]
        [switch]$Quiet
    )

    $hashtable = [ordered]@{
        'Software_Name'    = $softwareName
        'Software_URL'     = $uri
        'Online_Version'   = 'UNKNOWN' 
        'Online_Date'      = 'UNKNOWN'
        'Download_URL_x86' = 'UNKNOWN'
        'Download_URL_x64' = 'UNKNOWN'
    }
    
    $swObject = New-Object -TypeName PSObject -Property $hashtable

    try
    {

    }
    catch
    {
        $message = ("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
        Write-Warning $message
    }
    finally
    {
        
    }

    # Output to Host
    if ($Quiet)
    {
        Return $swObject.Online_Version
    }
    else
    {
        Return $swobject
    }

} # END Function Get-OnlineVerTEMPLATE