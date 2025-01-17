Function Invoke-DataVerse {
    [cmdletbinding()]
    Param([ValidateSet("GET", "POST")]$Method = "GET"
        , [parameter(Mandatory, position = 0)][string]$EndPoint
        , [hashtable]$AddHeaders = @{})

        $request = @{
        Uri = $Script:baseURI + $EndPoint
        Method = $Method
        Headers = $Script:baseHeaders.Clone() + $AddHeaders
    }
    
    Invoke-RestMethod @request
}