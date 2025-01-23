function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
       , [Parameter()][Switch]$CanUpdate
       , [Parameter()][switch]$IncludeAnnotations
    )
    $ep = $EntitySetName
    if($CanUpdate) {
        $columns = Get-DataVerseColumns -EntitySetName -CanUpdate | Select-Object -ExpandProperty LogicalName
        $ep = QueryAppend $ep ('$select=' + ($columns -join ","))
    }
    $addHdrs = @{'If-None-Match'= ""}
    if($IncludeAnnotations) { $addHdrs['Prefer'] ='odata.include-annotations="*"' }

    $request = @{
        Method = "GET"
        EndPoint = $ep
        AddHeaders = $addHdrs
    }
    Invoke-DataVerse @request |
        Select-Object -ExpandProperty value |
        ForEach-Object {
            if($CanUpdate) {
                $ht = [ordered]@{ PSTypeName = "DataVerse.$EntitySetName" }
                foreach($c in $columns) { $ht[$c] = $_.$c }
                [PSCustomObject]$ht
            } else {
                $_
            }
        }
}