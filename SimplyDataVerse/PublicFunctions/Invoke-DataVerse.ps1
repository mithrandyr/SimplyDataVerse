Function Invoke-DataVerse {
    [cmdletbinding()]
    Param([ValidateSet("GET", "POST")]$Method = "GET"
        , [parameter(Mandatory, position = 0)][string]$EndPoint
        , [hashtable]$AddHeaders = @{})

    $request = @{
        Uri     = [SDVApp]::GetBaseUri() + $EndPoint
        Method  = $Method
        Headers = [SDVApp]::GetBaseHeaders() + $AddHeaders
    }
    
    try {
        Invoke-RestMethod @request
    }
    catch {
        $exception = $_.Exception
        if($exception.GetType().Name -in @("WebException", "HttpResponseException")){
            if($exception.response.statuscode -eq 'TooManyRequests') {
                if (-not $request.ContainsKey('MaximumRetryCount')) { $request.Add('MaximumRetryCount', 3) }
                Invoke-RestMethod @request
            } else {
                throw [SimplyDataVerseException]::Create($_, $EndPoint)
            }
        } else {
            throw $_
        }        
    }
}