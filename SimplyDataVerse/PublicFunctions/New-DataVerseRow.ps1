function New-DataVerseRow {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
    )
    
    $columns = Get-DataVerseColumns -EntitySetName $EntitySetName -CanUpdate |
        Select-Object -ExpandProperty LogicalName
    $ht = [ordered]@{PSTypeName = "DataVerse.$EntitySetName"}
    foreach($c in $columns) { $ht[$c] = $null }

    return [PSCustomObject]$ht    
}
