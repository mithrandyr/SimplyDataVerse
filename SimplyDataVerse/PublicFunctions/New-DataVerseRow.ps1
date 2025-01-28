function New-DataVerseRow {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
       , [Parameter()][switch]$AllUpdateable
    )
    if($AllUpdateable) {
        $columns = [SDVApp]::Schema.ColumnsCanUpdate($EntitySetName) | Select-Object -ExpandProperty LogicalName
    } else {
        $columns = [SDVApp]::Schema.ColumnsCustom($EntitySetName) | Select-Object -ExpandProperty LogicalName
    }
    
    $ht = [ordered]@{PSTypeName = "SimplyDataVerse.$EntitySetName"}
    foreach($c in $columns) { $ht[$c] = $null }

    return [PSCustomObject]$ht    
}
