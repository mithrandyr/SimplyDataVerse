function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
       , [Parameter()][string[]]$Columns
       , [Parameter()][string]$Where
       , [Parameter()][int]$Limit = 0
       , [Parameter()][ValidateSet("Custom","Updateable","All")][string]$Options = "Custom"
       , [Parameter()][string[]]$ExpandColumns
       , [Parameter()][switch]$IncludeAnnotations
    )
    $ep = $EntitySetName
    if(-not $Columns) {
        switch($Options) {
            "Custom" { $columnList = [SDVApp]::Schema.ColumnsCustom($EntitySetName) }
            "Updateable" { $columnList = [SDVApp]::Schema.ColumnsCanUpdate($EntitySetName) }
            "All" { $columnList = [SDVApp]::Schema.Columns($EntitySetName) }
            
        }
    } else {
        $columnList = [SDVApp]::Schema.Columns($EntitySetName).where({$_.LogicalName -in $Columns})
    }

    $columnNames = $columnList |
        ForEach-Object {
            if($_.AttributeType -eq "Lookup") {
                if($_.SchemaName -notin $ExpandColumns) {
                "_{0}_value" -f $_.LogicalName
                } else {
                    $_.SchemaName
                }
            } else {
                $_.LogicalName
            }
        }

    $ep = QueryAppend $ep ('$select=' + ($columnNames -join ","))
    if($Limit -gt 0) {$ep = QueryAppend $ep "`$top=$limit" }
    if($Where) { $ep = QueryAppend $ep "`$filter=$Where" }
    if($ExpandColumns) { $ep = QueryAppend $ep ('$expand='+ ($ExpandColumns -join ",")) }

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
            foreach($c in $columnNames) { $ht[$c] = $_.$c }
            [PSCustomObject]$ht
        }
}