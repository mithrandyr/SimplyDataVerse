Function Get-DataVerseMetaData {
    Param()

    $hdrs = $Script:baseHeaders.Clone()
    $hdrs.Remove('Accept')
    $request = @{
        Uri     = $Script:baseURI + '$metadata'
        Method  = "GET"
        Headers = $hdrs
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