function New-DataVerseRow {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
    )
    $ep = $EntitySetName
    if($Columns) {
        $ep = QueryAppend $query ('$select=' + ($columns -join ","))
    }
    $addHdrs = @{'If-None-Match'= ""}
    if($IncludeAnnotations) { $addHdrs['Prefer'] ='odata.include-annotations="*"' }

    $request = @{
        Method = "GET"
        EndPoint = $ep
        AddHeaders = $addHdrs
    }
    Invoke-DataVerse @request | Select-Object -ExpandProperty value
}
