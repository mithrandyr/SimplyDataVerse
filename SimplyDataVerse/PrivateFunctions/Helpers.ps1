function QueryAppend {
    Param([parameter(Mandatory, Position=0)][string]$query
        , [parameter(Mandatory, Position=1)][string]$append) 
    
    if($query.split("?").Count -gt 1) {
        $query += "&$append"
    } else {
        $query += "?$append"
    }
    $query
}
