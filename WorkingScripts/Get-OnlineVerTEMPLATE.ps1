<#
.Synopsis
    Queries [TEMPLATESOFTWARE]'s Website for the current version of
    [TEMPLATESOFTWARE] and returns the version, date updated, and
    download URLs if available.
.DESCRIPTION
    Utilizes Invoke-WebRequest to query [TEMPLATESOFTWARE]'s [PAGE] and
    pulls out the Version, Update Date and Download URLs for both
    x68 and x64 versions. It then outputs the information as a
    PSObject to the Host.
.EXAMPLE
   PS C:\> Get-OnlineVer[TEMPLATESOFTWARE] -Quiet
.INPUTS
    -Quiet
        Use of this parameter will output just the current version of
        [TEMPLATESOFTWARE] instead of the entire object. It will always be the
        last parameter.
.OUTPUTS
    An object containing the following:
        Software Name: Name of the software
        Software URL: The URL info was sourced from
        Online Version: The current version found
        Online Date: The date the version was updated
        Download URL x86: Download URL for the win32 version
        Download URL x64: Download URL for the win64 version
    
    If -Quiet is specified then just the value of 'Online Version'
    will be displayed.
.NOTES
    Resources/Credits:

    Helpful URLs:

#>

function Get-OnlineVerTEMPLATE
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [switch]
        $Quiet
    )

    # Initial Variables
    $SoftwareName = '[TEMPLATESOFTWARE]'
    $URI = '[TEMPLATESOFTWARE_URL]'

    begin
    {
        $hashtable = [ordered]@{
            'Software_Name'    = $softwareName
            'Software_URL'     = $uri
            'Online_Version'   = 'UNKNOWN' 
            'Online_Date'      = 'UNKNOWN'
            'Download_URL_x86' = 'UNKNOWN'
            'Download_URL_x64' = 'UNKNOWN'
        }
    
        $swObject = New-Object -TypeName PSObject -Property $hashtable
    }


    Process
    {
        try
        {

        }
        catch
        {
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }
        finally
        {
        
        }
    }

    End
    {
        # Output to Host
        if ($Quiet)
        {
            Return $swObject.Online_Version
        }
        else
        {
            Return $swobject
        }
    }
} # END Function Get-OnlineVerTEMPLATE