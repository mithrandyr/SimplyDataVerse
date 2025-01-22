Register-ArgumentCompleter -CommandName @("Get-DataVerseRows", "GetLogicalName") -ParameterName EntitySetName -ScriptBlock {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    
    CacheLoadTables
    CacheGet "TableNames" |
        Select-Object -ExpandProperty EntitySetName |
        Where-Object {$_ -like "*$WordToComplete*"}
}

Register-ArgumentCompleter -CommandName @("Get-DataVerseColumns") -ParameterName LogicalName -ScriptBlock {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    
    CacheLoadTables
    CacheGet "TableNames" |
        Select-Object -ExpandProperty LogicalName |
        Where-Object {$_ -like "*$WordToComplete*"}
}