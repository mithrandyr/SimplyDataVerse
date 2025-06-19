function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
       , [Parameter()][string[]]$Columns
       , [Parameter()][string]$Where
       , [Parameter()][int]$Limit = 0
       , [Parameter()][ValidateSet("Custom","Updateable","All")][string]$Options = "Custom"
       , [Parameter()][switch]$IncludeAnnotations
    )
    $ep = $EntitySetName
    if(-not $Columns) {
        switch($Options) {
            "Custom" { $Columns = [SDVApp]::Schema.ColumnsCustom($EntitySetName) | Select-Object -ExpandProperty LogicalName }
            "Updateable" { $Columns = [SDVApp]::Schema.ColumnsCanUpdate($EntitySetName) | Select-Object -ExpandProperty LogicalName }
            "All" { $Columns = [SDVApp]::Schema.Columns($EntitySetName) | Select-Object -ExpandProperty LogicalName }
        }
    }
    $ep = QueryAppend $ep ('$select=' + ($Columns -join ","))
    if($Limit -gt 0) {$ep = QueryAppend $ep "`$top=$limit" }
    if($Where) { $ep = QueryAppend $ep "`$filter=$Where" }

    $addHdrs = @{'If-None-Match'= ""}
    if($IncludeAnnotations) { $addHdrs['Prefer'] ='odata.include-annotations="*"' }

    $request = @{
        Method = "GET"
        EndPoint = $ep
        AddHeaders = $addHdrs
    }
    <#this needs to handle lookup columns, using the $expand option.
        on list of columns, for every lookup column, append _value (this will retrieve the guid)
        if the option -Expand is used, then expand the columns using $expand uri option

        probably need to create a function to generate a psobject with the type name, then this can be
        handled recursively.

    #>

    Invoke-DataVerse @request |
        Select-Object -ExpandProperty value |
        ForEach-Object {
            $ht = [ordered]@{ PSTypeName = "SimplyDataVerse.$EntitySetName" }
            foreach($c in $columns) { $ht[$c] = $_.$c }
            [PSCustomObject]$ht
        }
}