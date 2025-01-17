<#
.SYNOPSIS
    Returns list of DataVerse environments (commercial only).

.DESCRIPTION
    Returns list of DataVerse environments (commercial only).

#>
Function Find-DataVerseOrg {
    [cmdletbinding()]
    Param([switch]$IgnoreCache)
    
    $result = CacheGet "OrgUrls"
    if($IgnoreCache -or -not $result) {
        Write-Verbose "Querying Azure..."
        $headers = AzureConnect -environmentUrl "https://globaldisco.crm.dynamics.com/"

        $request = @{
            Uri = 'https://globaldisco.crm.dynamics.com/api/discovery/v2.0/Instances?$select=ApiUrl,FriendlyName'
            Method = "GET"
            Headers = $headers
        }
        $response = Invoke-RestMethod @request
        $result = $response.value
        CacheAdd -Key "OrgUrls" -Value $result
    }
    $result
}