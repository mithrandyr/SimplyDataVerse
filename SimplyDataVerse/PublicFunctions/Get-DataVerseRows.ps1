function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
       , [Parameter()][ValidateSet("Custom","Updateable","All")][string]$Options = "Custom"
       , [Parameter()][switch]$IncludeAnnotations
    )
    $ep = $EntitySetName
    switch($Options) {
        "Custom" { $columns = [SDVApp]::Schema.ColumnsCustom($EntitySetName) | Select-Object -ExpandProperty LogicalName }
        "Updateable" { $columns = [SDVApp]::Schema.ColumnsCanUpdate($EntitySetName) | Select-Object -ExpandProperty LogicalName }
        "All" { $columns = [SDVApp]::Schema.Columns($EntitySetName) | Select-Object -ExpandProperty LogicalName }
    }
    $ep = QueryAppend $ep ('$select=' + ($columns -join ","))

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
            $ht = [ordered]@{ PSTypeName = "SimplyDataVerse.$EntitySetName" }
            foreach($c in $columns) { $ht[$c] = $_.$c }
            [PSCustomObject]$ht
        }
}