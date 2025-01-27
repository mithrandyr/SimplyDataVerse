function New-DataVerseRow {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
    )
    
    $columns = @(
        [SDVApp]::Schema.TablePrimaryId($EntitySetName)
        [SDVApp]::Schema.ColumnsCanUpdate($EntitySetName) | Select-Object -ExpandProperty LogicalName
    )
    $ht = [ordered]@{PSTypeName = "DataVerse.$EntitySetName"}
    foreach($c in $columns) { $ht[$c] = $null }

    return [PSCustomObject]$ht    
}
