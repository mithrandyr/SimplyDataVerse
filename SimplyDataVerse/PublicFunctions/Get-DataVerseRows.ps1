function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
       , [Parameter()][string[]]$Columns
       , [Parameter()][string]$Where
       , [Parameter()][int]$Limit = 0
       , [Parameter()][switch]$NoExpand
    )
    
    $columnList = @{}
    $expandColumns = @()
    foreach($attribute in [SDVApp]::Tables[$EntitySetName].Attributes.Values) {
        if($attribute.AttributeType -eq "Scalar") {
            $columnList[$attribute.LogicalName] = $attribute.LogicalName
        } elseif($NoExpand) {
            $columnList[$attribute.LogicalName] = ("_{0}_value" -f $attribute.LogicalName).ToLower()
        } else {
            $expandColumns += $attribute.LogicalName
            $columnList[$attribute.LogicalName] = $attribute.LogicalName
        }
    }

    if($Columns) {
       $keysToRemove = $columnList.Keys.where({$_ -notin $Columns})
       foreach($key in $keysToRemove) {
            $columnList.Remove
       }
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
    <#this needs to handle lookup columns, using the $expand option.
        on list of columns, for every lookup column, append _value (this will retrieve the guid)
        if the option -Expand is used, then expand the columns using $expand uri option

        probably need to create a function to generate a psobject with the type name, then this can be
        handled recursively.

    #>

    #Replace this with piping results to 'CreateRowFromResponse'...
    Invoke-DataVerse @request |
        Select-Object -ExpandProperty value |
        ForEach-Object {
            $ht = [ordered]@{ PSTypeName = "SimplyDataVerse.$EntitySetName" }
            foreach($key in $columnList.Keys) {
                $colName = $columnList[$key]
                $ht[$key] = $_.$colName
            }
            [PSCustomObject]$ht
        }
}