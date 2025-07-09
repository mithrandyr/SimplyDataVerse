function Get-DataVerseRows {
    [cmdletbinding(DefaultParameterSetName="custom")]
    param (
       [Parameter(Mandatory, Position=0)][String]$EntitySetName
       , [Parameter(ParameterSetName="specific", Mandatory)][string[]]$Columns
       , [Parameter(ParameterSetName="all", Mandatory)][switch]$AllColumns
       #, [Parameter(ParameterSetName="custom")][switch]$Custom
       , [Parameter()][string]$Where
       , [Parameter()][int]$Limit = 0
       , [Parameter()][switch]$NoExpand
    )
    [SDVApp]::LoadColumnDetails($EntitySetName)
    
    $columnList = @{}
    $expandColumns = @()
    foreach($attribute in [SDVApp]::Tables[$EntitySetName].Attributes.Values) {
        if($attribute.AttributeType -eq "Scalar") {
            $columnList[$attribute.LogicalName] = $attribute.LogicalName
        } elseif($NoExpand) {
            $columnList[$attribute.LogicalName] = $attribute.RawName
        } else {
            $expandColumns += $attribute.LogicalName
            $columnList[$attribute.LogicalName] = $attribute.LogicalName
        }
    }

    if($PSCmdlet.ParameterSetName -eq "custom") { $Columns = [SDVApp]::ColumnsForSelectCustom($EntitySetName) }
    if($Columns) {
       $keysToRemove = $columnList.Keys.where({$_ -notin $Columns})
       $keysToRemove.foreach({$columnList.Remove($_)})
       $expandColumns = $expandColumns.where({$_ -notin $keysToRemove})
    }

    $ep = QueryAppend $EntitySetName ('$select=' + ($columnList.Values -join ","))
    if(-not $NoExpand){ $ep = QueryAppend $ep ('$expand='+ ($expandColumns -join ",")) }
    if($Limit -gt 0) { $ep = QueryAppend $ep "`$top=$limit" }
    if($Where) { $ep = QueryAppend $ep "`$filter=$Where" }

    $addHdrs = @{'If-None-Match'= ""}

    $request = @{
        Method = "GET"
        EndPoint = $ep
        AddHeaders = $addHdrs
    }

    Invoke-DataVerse @request |
        Select-Object -ExpandProperty value |
        CreateRowFromResponse -EntitySetName $EntitySetName
}