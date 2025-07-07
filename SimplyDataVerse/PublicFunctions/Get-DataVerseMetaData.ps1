Function Get-DataVerseMetaData {
    Param()

    $hdrs = [SDVApp]::GetBaseHeaders()
    $hdrs.Remove('Accept')
    $request = @{
        Uri     = [SDVApp]::GetBaseUri() + '$metadata'
        Method  = "GET"
        Headers = $hdrs
    }
    
    try {
        $result = Invoke-RestMethod @request
        $mdInfo = @{}
        foreach($x in $result.Edmx.DataServices.Schema.EntityType) {
            $mdInfo[$x.Name] = $x
        }
        $mdInfo
    }
    catch {
        $exception = $_.Exception
        if($exception.GetType().Name -in @("WebException", "HttpResponseException")){
            throw [SimplyDataVerseException]::Create($_, $EndPoint)
        } else {
            throw $_
        }        
    }
}