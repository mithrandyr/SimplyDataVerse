Function Get-DataVerseTablePrimaryId {
    Param([Parameter(Mandatory)][string]$EntitySetName)
    
    [SDVApp]::Schema.TablePrimaryId($EntitySetName)
}