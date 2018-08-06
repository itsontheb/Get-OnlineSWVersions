<#
.Synopsis
    Queries PuTTY's Website for the current version of
    PuTTY and returns the version, date updated, and
    download URLs if available.
.DESCRIPTION
    Utilizes Invoke-WebRequest to query PuTTY's release page and
    pulls out the Version, Update Date and Download URLs for both
    x68 and x64 versions. It then outputs the information as a
    PSObject to the Host.
.EXAMPLE
   PS C:\> Get-OnlineVerPuTTY -Quiet
.INPUTS
    -Quiet
        Use of this parameter will output just the current version of
        PuTTY instead of the entire object. It will always be the
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

function Get-OnlineVerPuTTY
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
        $SoftwareName = 'PuTTY'
        $URI = 'https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html'
        $versionRegex = [regex]"\((.*)\)"
        $dateRegex = '\d{4}-\d{2}-\d{2}'
        $desiredString = 'released on'

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
        # Get the SW Version
        try
        {
            Write-Verbose -Message "Attempting to pull info from the below URL: `n $URI"
            $rawReq = Invoke-WebRequest -Uri $URI

            $currentVersion = [regex]::match($html.ParsedHtml.title, $versionRegex).Groups[1]            
        }
        catch
        {
            Write-Verbose -Message "Error accessing the below URL: `n $URI"
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }
        finally
        {
            If ($currentVersion)
            {
                # Download URLs
                $dlURL_x86 = "https://the.earth.li/~sgtatham/putty/latest/w32/putty-$currentVersion-installer.msi"
                $dlURL_x64 = "https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-$currentVersion-installer.msi"            
            
                Write-Verbose -Message 'Write to $swObject the newly gained information.'
                $swObject.Online_Version = $currentVersion
                $swObject.Download_URL_x86 = $dlURL_x86
                $swObject.Download_URL_x64 = $dlURL_x64
            }
        }

        # Get release date
        if ($rawReq)
        {
            $itMatches = @()
            $p = $rawReq.ParsedHtml.getElementsByTagName("p")
            Foreach ($item in $p)
            {
                $itemMatch = $item.outerText -match $desiredString
                if ($itemMatch)
                {
                    $itMatches += $item.outerText
                }
            }

            $swObject.Online_Date = ( ($itMatches[0].Replace('.','')).split(' ') -match $dateRegex )[0]
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
} # END Function Get-OnlineVerPuTTY
