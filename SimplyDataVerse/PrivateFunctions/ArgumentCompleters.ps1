Register-ArgumentCompleter -CommandName @("Get-DataVerseRows"
                                            "Get-DataVerseColumns"
                                            "Get-DataVerseTables"
                                            "Get-DataVerseTablePrimaryId"
                                            "Set-DataVerseRow"
                                            "New-DataVerseRow") -ParameterName EntitySetName -ScriptBlock {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    
    [SDVApp]::Schema.EntitySetNames() |
    Where-Object { $_ -like "*$WordToComplete*" }
}