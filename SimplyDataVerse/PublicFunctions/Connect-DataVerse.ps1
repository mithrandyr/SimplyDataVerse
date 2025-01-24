Function Connect-DataVerse {
    [cmdletbinding(DefaultParameterSetName = "name")]
    param(
        [Parameter(Mandatory, ParameterSetName = "url")][string]$EnvironmentUrl # URL of DataVerse Environment
        , [Parameter(Mandatory, ParameterSetName = "name", Position=0)][string]$Name # Name of DataVerse Environment
    )
    
    if($Name) {
        $EnvironmentUrl = [SDVApp]::DataVerseEnvironments() | Where-Object FriendlyName -eq $Name | Select-Object -ExpandProperty ApiUrl
        if(-not $EnvironmentUrl) {
            throw "Could not find EnvironmentUrl for '$Name', try again and specify '-EnvironmentUrl'"
        }
    }
    [SDVApp]::SetEnvironment($EnvironmentUrl)
    Write-Verbose "Connecting to $EnvironmentUrl..."
    [SDVApp]::GetToken() | Out-Null
    
    Write-Verbose "Initializing Schema Cache..."
    [SDVApp]::InitializeSchema()
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
    
    if($WordToComplete.StartsWith("'")) {
        $WordToComplete = $WordToComplete.Trim("'").Trim()
    }    
    
    Find-DataVerseOrg |
        Where-Object FriendlyName -like "*$WordToComplete*" |
        ForEach-Object { "'{0}'" -f $_.FriendlyName }
}