Get-OnlineVerTEMPLATE
{
    [cmdletbinding()]
    param (
        [switch]$Quiet
    )

    # Variables
    $URI = 'TEMPLATE'
    $SoftwareName = 'TEMPLATE'

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