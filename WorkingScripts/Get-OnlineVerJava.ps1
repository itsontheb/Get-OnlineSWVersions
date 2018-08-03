# Credit:
# https://github.com/auberginehill/java-update/blob/master/Java-Update.ps1

$ReqBaseline = '1.8.0'
$URI = 'https://javadl-esd-secure.oracle.com/update/baseline.version'
$Regex = "(?<P1>\d+).(?<P2>\d+).(?<P3>\d+)_(?<P4>\d+)"
if ($JavaInfo)
{
    Remove-Variable -Name javaInfo -Force
}

# Step 1
# Query the Baseline.Version for current desired version
try
{
    $BaselineHTML = Invoke-WebRequest -Uri $URI
    $currentBaseline =  ($BaselineHTML.Content).Split() | Where { $_ -match $ReqBaseline }
    if ($currentBaseline)
    {
        $regex = $currentBaseline -match $Regex

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
catch [System.Net.WebException]
{
    $message = 'Failed to access: ' + $URI
    Write-Warning -Message $message
    Return 'Exiting without checking the latest Java version numbers (Step 1)'
}

# Step 2
# Query the current desired baseline version for what we want
# Source: http://superuser.com/questions/443686/silent-java-update-check
$updateMapURL = "http://javadl-esd.sun.com/update/$currentBase/map-m-$currentBase.xml"
try
{
    $javaMap = New-Object System.XML.XMLDocument
    $javaMap.Load($updateMapURL)
}
catch [System.Net.WebException]
{
    Write-Warning -Message "Failed to access below URL: `n    $updateMapURL"
    Return 'Exiting without checking for latest Java version numbers (Step 2)'
}


# Check for java_update_chart.csv later

# Step 3
# Check info on the most recent Java version Home Page (XML)
$recentXMLHomePage = ($updateChart | Select-Object -First 1).url
try
{
    $xmlInfo = New-Object System.Xml.XmlDocument
    $xmlInfo.Load($recentXMLHomePage)
}
catch [System.Net.WebException]
{
    Write-Warning -Message "Failed to access below URL: `n    $recentXMLHomePage"
    Return 'Exiting without checking for latest Java version numbers (Step 3)'
}

# Pull more information that may be wanted
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

# Build Information Object
$javaInfo += New-Object -TypeName PSCustomObject -Property @{
        'Most Recent Version'                       = $mostRecent_JavaVer
        'Most Recent Java Main Version'             = [int32]$currentMainVer
        'Most Recent Java Update Number'            = [int32]$currentUpdateNum
        'Most Recent Build'                         = $currBuildNum
        'Most Recent Build (Legacy Name, Full)'     = $currVerBuild
        'Most Recent Version (Legacy Name)'         = $currentFullVer
        'Description'                               = $description
        'Further Info'                              = $futherInfoURL
        #'Java Uninstall Tool URL'                   = $uninstaller_tool_url
        'Download URL'                              = $downloadURL
        'Full 32-bit Download URL'                  = $32DownloadURL
        'Full 64-bit Download URL'                  = $64DownloadURL        
}
$javaInfo.PSObject.TypeNames.Insert(0,'Most Recent non-beta Java Version Available')
$javaInfo_Selection = $javaInfo | Select-Object 'Most Recent Version (Legacy Name)', 'Full 32-bit Download URL',  'Full 64-bit Download URL'

Return $javaInfo_Selection
