<#
.Synopsis
   Query Oracle's Website for the current version of Java SE and
   returns the version, dated updated, URL info obtained from and the
   download URLs for x64 & x86 version. Other information can be provided
   if specified.
.DESCRIPTION
    Invokes a series of Web Requests to Oracles website to trace the desired
    baseline version's (ie Java 8, 9 or 10) current version among other
    information such as download URLs and release date.

    There is work with both iterating through HTML Tables for the release
    date and plenty of walking XMLs for various pieces of information.
    More information can be provided with the -Loud parameter. If the
    '-ReqBaseline' is not specified then 1.8.0 is selected by default.
.EXAMPLE
   PS C:\> Get-OnlineVerJavaSE -ReqBasline '10.0' -Quiet
.INPUTS
    -ReqBasline
        Specify the Java Baseline to check for. Choose from the 1.7.0, 
        1.8.0 or 10.0.

    -Quiet
        Use of this parameter will output just the current version of
        Java for the requested baseline instead of the entire object.

    -Loud
        Use of this parameter will output a ton of various information
        about the requested version of Java. 
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

    If -Loud is specified information such as the different version numbers
    will be provided for the specified version, uninstaller URL, Description
    and 'More Info' URL.
.NOTES
    Resources/Credits:
        https://github.com/auberginehill/java-update/blob/master/Java-Update.ps1
        https://gist.github.com/midnightfreddie/69d25ddf5ed784d75c1180f12bee84a6
    Helpful URLs:
        https://javadl-esd-secure.oracle.com/update/baseline.version
        https://www.java.com/en/download/faq/release_dates.xml        
#>

function Get-OnlineVerJavaSE
{
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [ValidateSet(
            '1.7.0', 
            '1.8.0', 
            '10.0'
        )]
        $ReqBaseline = '1.8.0',

        [Parameter(Mandatory=$false, 
                   Position=1)]
        [switch]
        $Quiet,

        [Parameter(Mandatory=$false, 
                   Position=2)]
        [switch]
        $Loud
    )

    begin
    {
        # Initial Variables
        $SoftwareName = 'Java SE'
        $URI = 'https://javadl-esd-secure.oracle.com/update/baseline.version'

        $hashtable = [ordered]@{
            'Software_Name'    = $softwareName
            'Software_URL'     = $uri
            'Online_Version'   = 'UNKNOWN' 
            'Online_Date'      = 'UNKNOWN'
            'Download_URL_x86' = 'UNKNOWN'
            'Download_URL_x64' = 'UNKNOWN'
        }

        $swObject = New-Object -TypeName PSObject -Property $hashtable

        # Initial Variables
        $Regex = "(?<P1>\d+).(?<P2>\d+).(?<P3>\d+)_(?<P4>\d+)"
        $uninstaller_tool_url = "https://javadl-esd-secure.oracle.com/update/jut/JavaUninstallTool.exe"
        $uninstaller_info_url = "https://www.java.com/en/download/help/uninstall_java.xml"
        $release_history_url = "https://www.java.com/en/download/faq/release_dates.xml"
    }


    Process
    {
        # Step 1
        # Query baseline.version for current desired version.
        try
        {
            $rawReq = Invoke-WebRequest -Uri $URI
            $currentBaseline = ($rawReq.Content).Split() | Where { $_ -match $ReqBaseline }
            if ($currentBaseline)
            {
                Write-Verbose -Message "Desired baseline was aquired as: $currentBaseline"
                # Most Recent Java Baseline Version (x.y.z) - Old Name:
                $currentBase = $currentBaseline.split('_')[0]
                # Most Recent Java Update Number (nnn):
                $currentUpdateNum = [int32]$currentBaseline.split('_')[1]
                # Most Recent Java Main Version (y):
                $currentMainVer = [int32]$Matches.P2
                # Most Recent Java Version (x.y.z_nnn) - Legacy Format
                $currentFullVer = $currentBaseline                
            }
        }

        catch
        {
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }



        # Step 2
        # Query the current desired baseline version for what we want
        # Source: http://superuser.com/questions/443686/silent-java-update-check
        $updateMapURL = "http://javadl-esd.sun.com/update/$currentBase/map-m-$currentBase.xml"
        try
        {
            $javaMap = New-Object System.XML.XMLDocument
            $javaMap.Load($updateMapURL)
            # Update Chart
            $updateChart = $javaMap.SelectNodes("/java-update-map/mapping")
        }
        catch
        {
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }


        # Step 3
        # Check info on the most recent Java version Home Page (XML)
        $recentXMLHomePage = ($updateChart | Select-Object -First 1).url
        try
        {
            $xmlInfo = New-Object System.Xml.XmlDocument
            $xmlInfo.Load($recentXMLHomePage)
        }
        catch
        {
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }

        # Step 4
        # Pull the release date information from the release history page
        $releaseURL = 'https://www.java.com/en/download/faq/release_dates.xml'
        $releaseArray = @()
        try
        {
            $releaseHTML = Invoke-WebRequest -Uri $releaseURL
            $releaseTable = @($releaseHTML.ParsedHTML.getElementsByTagName("TBody"))[0]

            $releaseTable | ForEach-Object {
                $Headers = @( 'Java Version', 'Release Date' )

                # Iterate through <tr> in the table body
                $_.getElementsByTagName('tr') | ForEach-Object {
                    # Select the <td>, but grab the innertext and make into an array
                    $OutputRow = $_.getElementsByTagName('td') | Select-Object -ExpandProperty InnerText

                    #
                    if ($Headers) {
                        $OutputHash = [ordered]@{}
                        for($i=0;$i -lt $OutputRow.Count;$i++) {
                            $OutputHash[$Headers[$i]] = $OutputRow[$i]
                        }
                        $object = New-Object psobject -Property $OutputHash
                        $releaseArray += $Object
                
                    } else {
                        $Headers = $OutputRow
                    }
                }
            }

        }
        catch
        {
            $message = $("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
            $swObject | Add-Member -MemberType NoteProperty -Name 'ERROR' -Value $message
        }

        finally
        {
            # Sort out information
            # Pull the information together that may be desired
            # Further Info URL
            $futherInfoURL = $xmlInfo.SelectNodes("/java-update/information") | Select-Object -First 1 | Select-Object -ExpandProperty MoreInfo
            # Description
            $description = $xmlInfo.SelectNodes("/java-update/information") | Select-Object -First 1 | Select-Object -ExpandProperty descriptionfrom8
            # Current Version (Full: x.y.z_nnn-abc):
            $currVerBuild = $xmlInfo.SelectNodes("/java-update/information") | Select-Object -First 1 | Select-Object -ExpandProperty version
            # Most Recent Java Version
            $mostRecent_JavaVer = [string]'Java ' + $currentMainVer + ' Update ' + $currentUpdateNum
            # Most Recent Build
            $currBuildNum = $currVerBuild.Split('-')[-1]
            # Download URLs
            $downloadURL = $xmlInfo.SelectNodes("/java-update/information") | Select-Object -First 1 | Select-Object -ExpandProperty url
                # Get RootURL based on the powershell version
                $psVersion = $PSVersionTable.PSVersion
                If ($downloadURL.EndsWith('/') -eq $true)
                {
                    $downloadURL = $downloadURL.Replace(".{1}$")
                }
                else
                {
                    $continue = $true
                }

                If ( ($psVersion.Major -ge '5') -and ($psVersion.Minor -ge '1') )
                {
                    $rootURL = (Split-Path -Path $downloadURL -Parent).Replace('\', '/')
                }
                else
                {
                    $filename = $downloadURL.Split('/')[-1]
                    $rootURL = $downloadURL.Replace("/$filename", "")
                }
            # Full 32-Bit Download URL
            $32DownloadURL = [string]$rootURL + '/jre-' + $currentMainVer + 'u' + $currentUpdateNum + '-windows-i586.exe'
            # Full 64-Bit Download URL
            $64DownloadURL = [string]$rootURL + '/jre-' + $currentMainVer + 'u' + $currentUpdateNum + '-windows-x64.exe'
            # Release Date
            $releaseDate = ($releaseArray -match "$currentUpdateNum").'Release Date'

           
            If ($Loud)
            {
                # Build the Information Object
                $info += New-Object -TypeName PSCustomObject -Property @{
                    'Most Recent Version'                       = $mostRecent_JavaVer
                    'Most Recent Java Main Version'             = [int32]$currentMainVer
                    'Most Recent Java Update Number'            = [int32]$currentUpdateNum
                    'Most Recent Build'                         = $currBuildNum
                    'Most Recent Build (Legacy Name, Full)'     = $currVerBuild
                    'Most Recent Version (Legacy Name)'         = $currentFullVer
                    'Description'                               = $description
                    'Further Info'                              = $futherInfoURL
                    'Java Uninstall Tool URL'                   = $uninstaller_tool_url
                    'Download URL'                              = $downloadURL
                    'Full 32-bit Download URL'                  = $32DownloadURL
                    'Full 64-bit Download URL'                  = $64DownloadURL  
                }
            }
            else
            {
                $swObject.Online_Version   = $currentFullVer
                $swObject.Download_URL_x86 = $32DownloadURL
                $swObject.Download_URL_x64 = $64DownloadURL 
                if ($releaseDate)
                {
                    $swObject.Online_Date = $releaseDate
                }
                else
                {
                    $swObject.Online_Date = "$(Get-Date -Format FileDate)"
                }
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
        elseif ($Loud)
        {
            Return $info
        }
        else
        {
            Return $swobject
        }
    }
} # END Function Get-OnlineVerJavaSE
