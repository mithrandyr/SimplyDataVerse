function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$TableName,
       [Parameter()][String[]]$Columns
    )
    $query = "?"
    if($Columns) {
        $query += '$select=' + ($columns -join ",")
    }

    $request = @{
        Method = "GET"
        EndPoint = $TableName + $query
        AddHeaders = @{
            'If-None-Match'= ""
            'Prefer'='odata.include-annotations="*"'
        }
    }
    Invoke-DataVerse @request
 }