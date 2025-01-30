Function Invoke-DataVerse {
    [cmdletbinding()]
    Param([ValidateSet("GET", "POST", "PATCH", "DELETE")]$Method = "GET"
        , [Parameter(Mandatory, position = 0)][string]$EndPoint
        , [Parameter()][hashtable]$AddHeaders = @{}
        , [Parameter()][string]$Body
        , [Parameter()][switch]$ReturnHeaders
        )

    $request = @{
        Uri     = [SDVApp]::GetBaseUri() + $EndPoint
        Method  = $Method
        Headers = [SDVApp]::GetBaseHeaders() + $AddHeaders
    }
    if($Body) { $request["Body"] = $Body }
    
    try {
        if($ReturnHeaders) {
            Invoke-WebRequest -UseBasicParsing @request | Select-Object -ExpandProperty Headers            
        } else {
            Invoke-RestMethod @request
        }
    }
    catch {
        $exception = $_.Exception
        if($exception.GetType().Name -in @("WebException", "HttpResponseException")){
            if($exception.response.statuscode -eq 'TooManyRequests') {
                if (-not $request.ContainsKey('MaximumRetryCount')) { $request.Add('MaximumRetryCount', 3) }
                if($ReturnHeaders) {
                    Invoke-WebRequest -UseBasicParsing @request | Select-Object -ExpandProperty Headers            
                } else {
                    Invoke-RestMethod @request
                }
            } else {
                throw [SimplyDataVerseException]::Create($_, $EndPoint)
            }
        } else {
            throw $_
        }        
    }
}