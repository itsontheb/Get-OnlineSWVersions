<#
.Synopsis
   Queries Wireshark's Website for the current version of
   WireShark and returns the version, date updated, and
   download URLs
.DESCRIPTION
   Utilizes Invoke-WebRequest to query WireShark's pad.xml and
   pulls out the Version, Update Date and Download URLs for both
   x68 and x64 versions. It then outputs the information as a
   PSObject to the Host.
.EXAMPLE
   PS:> Get-OnlineVerWireshark -Quiet
.INPUTS
    -Quiet
        Use of this parameter will output just the current version of
        Wireshark instead of the entire object.
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
    Sample Download Links:
        https://2.na.dl.wireshark.org/win64/Wireshark-win64-2.4.0.exe
        https://www.wireshark.org/download/win64/all-versions/Wireshark-win64-2.4.0.exe
        https://www.wireshark.org/download/win32/all-versions/Wireshark-win32-2.4.0.exe
#>

function Get-OnlineVerWireshark {
    
    [cmdletbinding()]
    param (
        [switch]$Quiet
    ) 

    # Reusing code
    $URI = 'https://www.wireshark.org/wireshark-pad.xml'
    $SoftwareName = 'Wireshark'

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
        [xml]$xmlContent = Invoke-WebRequest -Uri $uri
    }
    catch
    {
        $message = ("Line {0} : {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.exception.message)
        Write-Warning $message
    }
    finally
    {
        if ($XMLContent)
        {
            $swObject.Online_Version = $XMLContent.XML_DIZ_INFO.Program_Info.Program_Version
            $swObject.Online_Date = $XMLContent.XML_DIZ_INFO.Program_Info.Program_Release_Month + 
                                      '-' +
                                      $XMLContent.XML_DIZ_INFO.Program_Info.Program_Release_Day +
                                      '-' +
                                      $XMLContent.XML_DIZ_INFO.Program_Info.Program_Release_Year
            $swObject.Download_URL_x64 = $XMLContent.XML_DIZ_INFO.Web_Info.Download_URLs.Primary_Download_URL
            $swObject.Download_URL_x86 = $($swObject.Download_URL_x64).replace('64','32')
        }
    }

    if ($Quiet)
    {
        Return $swObject.Online_Version
    }
    else
    {
        Return $swobject
    }
}
