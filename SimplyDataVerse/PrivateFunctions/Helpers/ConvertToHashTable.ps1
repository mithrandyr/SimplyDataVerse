filter ConvertToHashTable {
    Param(
        [Parameter(Mandatory, ValueFromPipeline)][psobject]$InputObject
        , [switch]$IgnoreNull
    )
    $ht = @{}
    foreach($prop in $InputObject.psobject.Properties) {
        if($prop.Value -or -not $IgnoreNull) {
            $ht.Add($prop.Name, $prop.Value)
        }
    }
    $ht
}