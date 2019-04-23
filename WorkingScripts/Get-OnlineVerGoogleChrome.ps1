<#
.Synopsis
    Queries Google Chrome's Website for the current version of
    [TEMPLATESOFTWARE] and returns the version, date updated, and
    download URLs if available.
.DESCRIPTION
    Utilizes Invoke-WebRequest to query Google Chrome's OmahaProxy Page and
    pulls out the Version, Update Date and Download URLs for both
    x68 and x64 versions. It then outputs the information as a
    PSObject to the Host.
.EXAMPLE
   PS C:\> Get-OnlineVerGoogleChrome -Quiet
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
    https://xenappblog.com/2018/download-and-install-latest-google-chrome-enterprise/

    Helpful URLs:
    https://omahaproxy.appspot.com/

#>

function Get-OnlineVerGoogleChrome
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [switch]
        $Quiet,

        [Parameter(Mandatory = $False)]
        [ValidateSet('win', 'win64', 'mac', 'linux', 'ios', 'cros', 'android', 'webview')]
        [string] $Platform = "win",

        [Parameter(Mandatory = $False)]
        [ValidateSet('stable', 'beta', 'dev', 'canary', 'canary_asan')]
        [string] $Channel = "stable"
    )

    begin
    {
        # Initial Variables
        $SoftwareName = 'Google Chrome'
        $URI = "https://omahaproxy.appspot.com/all.json"
            
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
            Write-Verbose -Message "Attempting to pull info from the below URL: `n $URI"
            $request = Invoke-WebRequest -Uri $URI

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
            If ($request)
            {
                $chromeVersions = $request.Content | ConvertFrom-Json
                $output = $chromeVersions | Where-Object { 
                    $_.os -eq $Platform
                }
                $output = $output.versions | Where-Object {
                    $_.Channel -eq $Channel
                }

                $swObject.Online_Version = $output.current_version
                $swObject.Online_Date = $output.current_reldate
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
} # END Function Get-OnlineVerGoogleChrome

Get-OnlineVerGoogleChrome