<#
.Synopsis
    Queries Adobe's Website for the current version of
    Flash and returns the version, date updated, and
    download URLs. 
.DESCRIPTION
    Utilizes Invoke-WebRequest to query Adobe Flash's fpdownload2 site
    and pulls out the Version based on the specified version of flash
    for both x68 and x64 versions. It then outputs the information as a
    PSObject to the Host.
.EXAMPLE
    PS C:\> Get-OnlineVerFlash -Quiet
.INPUTS
    -FlashType
        Specify the type of Adobe Flash to find the current version. 
        Choose between ActiveX, Plugin and Pepper. The default is 
        'ActiveX'.
    
    -Quiet
        Use of this parameter will output just the current version of
        Flash instead of the entire object. It will always be the
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
        https://www.reddit.com/r/PowerShell/comments/3tgr2m/get_current_versions_of_adobe_products/
#> 
function Get-OnlineVerAdobeFlash
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$false, 
                       Position=0)]
        [ValidateSet(
            'ActiveX',
            'Plugin',
            'Pepper'
        )]
        $FlashType = 'ActiveX',
        [Parameter(Mandatory=$false, 
                   Position=1)]
        [switch]$Quiet
    )

    # Initial Variables
    $SoftwareName = 'Adobe Flash Player'
    $URI = 'http://fpdownload2.macromedia.com/pub/flashplayer/update/current/sau'


    Begin
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
            # Get Major Version for Flash
            [xml]$FlashMajorVersion = Invoke-WebRequest -Uri "$($uri)/currentmajor.xml"
            $Version = $FlashMajorVersion.version.player.major

            # Get Minor Version
            [xml]$CurrentFlashVersion = Invoke-WebRequest -Uri "$($uri)/$($Version)/xml/version.xml"
            $swObject.Online_Version = $CurrentFlashVersion.version.$FlashType.major +
                                          '.' +
                                          $CurrentFlashVersion.version.$FlashType.minor +
                                          '.' +
                                          $CurrentFlashVersion.version.$FlashType.buildMajor + 
                                          '.' +
                                          $CurrentFlashVersion.version.$FlashType.buildMinor
        }
        catch
        {
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
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
} # END Function Get-OnlineVerAdobeFlash
