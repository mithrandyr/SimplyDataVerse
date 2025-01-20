function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$TableName,
       [Parameter()][String[]]$Columns,
       [Parameter()][switch]$IncludeAnnotations
    )
    $query = "?"
    if($Columns) {
        $query += '$select=' + ($columns -join ",")
    }
    $addHdrs = @{'If-None-Match'= ""}
    if($IncludeAnnotations) { $addHdrs['Prefer'] ='odata.include-annotations="*"' }

    $request = @{
        Method = "GET"
        EndPoint = $TableName + $query
        AddHeaders = $addHdrs
    }
    Invoke-DataVerse @request | Select-Object -ExpandProperty value
 }