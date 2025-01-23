Function Connect-DataVerse {
    [cmdletbinding(DefaultParameterSetName = "name")]
    param(
        [Parameter(Mandatory, ParameterSetName = "url")][string]$EnvironmentUrl # URL of DataVerse Environment
        , [Parameter(Mandatory, ParameterSetName = "name", Position=0)][string]$Name # Name of DataVerse Environment
    )
    
    if($Name) {
        $EnvironmentUrl = Find-DataVerseOrg | Where-Object FriendlyName -eq $Name | Select-Object -ExpandProperty ApiUrl
        if(-not $EnvironmentUrl) {
            throw "Could not find EnvironmentUrl for '$Name', try again and specify '-EnvironmentUrl'"
        }
    }

    Write-Verbose "Connecting to $EnvironmentUrl..."
    $Script:baseHeaders = AzureConnect -EnvironmentUrl $EnvironmentUrl
    
    # Set baseURI
    if(-not $EnvironmentUrl.EndsWith("/")) { $EnvironmentUrl += "/" }
    $Script:baseURI = $environmentUrl + 'api/data/v9.2/'
    
    [TableCache]::Initialize()
}

Register-ArgumentCompleter -CommandName "Connect-DataVerse" -ParameterName Name -ScriptBlock {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
    if($WordToComplete.StartsWith("'")) {
        $WordToComplete = $WordToComplete.Trim("'").Trim()
    }    
    
    Find-DataVerseOrg |
        Where-Object FriendlyName -like "*$WordToComplete*" |
        ForEach-Object {
            $r = "'{0}'" -f $_.FriendlyName
            $CompletionResults.add([System.Management.Automation.CompletionResult]::new($r)) | Out-Null
        }
    
    return $CompletionResults
}