Register-ArgumentCompleter -CommandName @("Get-DataVerseRows", "Get-DataVerseColumns", "Get-DataVerseTables", "New-DataVerseRow") -ParameterName EntitySetName -ScriptBlock {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    
    [TableCache]::EntitySetNames() |
        Where-Object {$_ -like "*$WordToComplete*"}
}