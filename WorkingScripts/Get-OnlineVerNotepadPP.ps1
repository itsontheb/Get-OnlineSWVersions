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
        Notepad++ Repository
            https://notepad-plus-plus.org/repository/
#>

function Get-OnlineVerNotepadPP
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
        $SoftwareName = 'NotepadPP'
        $URI = 'https://notepad-plus-plus.org/download'
        $verRegex = '.\d.\d.\d'
        $dateRegex = '\d{4}-\d{2}-\d{2}'
        $desiredString = 'Release Date:'
            
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
        # Get Version Info
        try
        {
            $rawReq = Invoke-WebRequest -Uri $URI
            Write-Verbose -Message "Attempting to pull info from the below URL: `n $URI"
            
            $parsedHTML = $rawReq.ParsedHtml
            $title = $parsedHTML.title
        }
        catch
        {
            Write-Verbose -Message "Error accessing the below URL: `n $URI"
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }
        finally
        {
            Write-Verbose -Message 'Write to $swObject the newly gained information.'
            $swObject.Online_Version = ( $($title.Split(' - ')) -match $verRegex )[0]
        }

        # Get the Release Date
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

        # Get the Download URLs
        If ($swObject -ne 'UNKNOWN')
        {
            $baseURL = 'https://notepad-plus-plus.org'
            $links = $rawReq.Links.href
            $repoLinks = $links -match 'repository'
            $installerLinks = $repoLinks -match 'installer'

            if ($installerLinks.Count -eq '2')
            {
                $32URL = $baseURL + $($installerLinks -notmatch 'x64')
                $64URL = $baseURL + $($installerLinks -match 'x64')

                # Add the DL URLs to the Object
                $swObject.Download_URL_x86 = $32URL
                $swObject.Download_URL_x64 = $64URL
            }
            else
            {
                Write-Verbose -Message "Something went wrong with the download links. There are more than 2. `n $installerlinks"
            }

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
} # END Function Get-OnlineVerNotepadPP

Get-OnlineVerNotepadPP