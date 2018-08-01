<#
.Synopsis
   Query Mozilla's Website for the current version of Mozilla Firefox and
   returns the version, dated updated, URL info obtained from and the
   download URLs for x64 & x86 version.
.DESCRIPTION
   Invokes a Web Request to Mozilla's Website to contain the contents of a
   JSON File. Based on the user input it selects the Main Build, ESR or Nightly
   Build Version and returns it back to the Host as a PSObject. If Quiet is 
   specified then just the version is returned with no additonal information.
   If the Firefox Type is not specified it defaults to the Main build.
.EXAMPLE
   PS C:\> Get-OnlineVerFirefox -FFType 'ESR' -Quiet
.INPUTS
    -FFType
        Specify the Type of Firefox to check for. Choose from the main 
        build, the ESR or the Nightly.

    -Quiet
        Use of this parameter will output just the current version of
        Firefox instead of the entire object.
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
    While there are other params available they should not be utilized as they
    are placeholders for templatization and ease of use if anything changes.

    Helpful URLs
        All Firefox Language Downloads
            https://www.mozilla.org/en-US/firefox/all/
        Firefox ESR 
            https://www.mozilla.org/en-US/firefox/organizations/
        Configure Firefox in the Enterprise
            https://support.mozilla.org/en-US/products/firefox-enterprise
#>

function Get-OnlineVerFirefox
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [Alias("SW")]
        [string]
        $SoftwareName = 'Mozilla Firefox',

        [Parameter(Mandatory=$false, 
                   Position=1)]
        [Alias("URL")]
        [string]
        $URI = 'https://product-details.mozilla.org/1.0/firefox_versions.json',

        [ValidateSet(
            'Main',
            'ESR',
            'Nightly'
        )]
        $FFType = 'Main',

        [Parameter(Mandatory=$false, 
                   Position=2)]
        [switch]
        $Quiet
    )

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
            $rawReq = Invoke-WebRequest -Uri $URI
            $json = $rawReq | ConvertFrom-Json

            switch ($FFType)
            {
                'ESR'     { $swObject.Online_Version = $json.FIREFOX_ESR }
                'Nightly' { $swObject.Online_Version = $json.FIREFOX_NIGHTLY }
                'Main'    { $swObject.Online_Version = $json.LATEST_FIREFOX_VERSION
                            $swObject.Download_URL_x86 = 'https://download.mozilla.org/?product=firefox-latest&os=win&lang=en-US'
                            $swObject.Download_URL_x64 = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US'}
            }
        }
        catch
        {
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }
        finally
        {
            if ($swObject.Online_Date -Match 'UNKNOWN')
            {
                $swObject.Online_Date = "$(Get-Date -Format FileDate)"
            }
        
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
} # END Function Get-OnlineVerFirefox
