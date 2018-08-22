<#
.Synopsis
    Queries 7-ZIP's Website for the current version of
    7-ZIP and returns the version, date updated, and
    download URLs if available.
.DESCRIPTION
    Utilizes Invoke-WebRequest to query 7-ZIP's Release History Page
     and pulls out the Version, Update Date and Download URLs for both
    x68 and x64 versions. It then outputs the information as a
    PSObject to the Host.
.EXAMPLE
   PS C:\> Get-OnlineVer7ZIP -Quiet
.INPUTS
    -Quiet
        Use of this parameter will output just the current version of
        7-ZIP instead of the entire object. It will always 
        be the last parameter.
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
        7-ZIP Download URLs
        https://www.7-zip.org/download.html
#>

function Get-OnlineVer7ZIP
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [switch]
        $Quiet
    )

    begin
    {
        # Initial Variables
        $SoftwareName = '7-ZIP'
        $URI = 'http://www.7-zip.org/history.txt'
        $verRegex = '\d\d.\d\d'
        $dateRegex = '\d{4}-\d{2}-\d{2}'
            
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
        # Get the Version & Release Date
        try
        {
            Write-Verbose -Message "Attempting to pull info from the below URL: `n $URI"
            $rawReq = Invoke-WebRequest -Uri $URI
            $content = $rawReq.Content -split '-------------------------'
        }
        catch
        {
            Write-Verbose -Message "Error accessing the below URL: `n $URI"
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }
        finally
        {
            $currVerInfo = ($content[0] -split '--------------------')[1].Trim()
            $currVerInfo = $currVerInfo.Split() | Where { $_ }
            $version = $currVerInfo[0]
            $releaseDate = $currVerInfo[1]

            Write-Verbose -Message 'Write to $swObject the newly gained information.'
            if ($version -match $verRegex)
            {
                $swObject.Online_Version = $version
            }
            else
            {
                Write-Verbose -Message 'Version does not match expected regex of ##.##'
            }

            if ($releaseDate -match $dateRegex)
            {
                $swObject.Online_Date = $releaseDate
            }
            else
            {
                Write-Verbose -Message 'Version does not match expected regex of yyyy-mm-dd'
            }
        }

        # Get the Download URLs
        if ($swObject.Online_Version -ne 'UNKNOWN')
        {
            $simpleVer = $version.Replace('.','')
            $swObject.Download_URL_x86 = "https://www.7-zip.org/a/7z$simpleVer.exe"
            $swObject.Download_URL_x64 = "https://www.7-zip.org/a/7z$simpleVer-x64.exe"
        }
    }

    End
    {
        # Output to Host
        if ($Quiet)
        {
            Write-Verbose -Message '$Quiet was specified. Returning just the version'
            Return $swObject.Online_Version
        }
        else
        {
            Return $swobject
        }
    }
} # END Function Get-OnlineVer7ZIP