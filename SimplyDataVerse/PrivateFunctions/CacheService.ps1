$Script:Cache = @{

}
Function CacheAdd {
    param([Parameter(Mandatory, Position=0)][string]$Key
        , [Parameter(Mandatory, position=1)]$Value
        , [Parameter()][int]$AgeInSeconds = 300)

    $Script:Cache[$Key] = @{
        Expires = (Get-Date).AddSeconds($AgeInSeconds)
        Value = $Value
    }
}

Function CacheValid([Parameter(Mandatory)][string]$Key) {
    return ($Script:Cache.ContainsKey($Key) -and $Script:Cache[$Key].Expires -gt (Get-Date))
}

Function CacheGet {
    param([Parameter(Mandatory)][string]$Key)
    if(CacheValid -Key $Key) {
        return $Script:Cache[$key].Value
    }
}

Function CacheClear { $Script:Cache.Clear() }
Function CacheReset {
    Param([string[]]$KeepKeys = @("OrgUrls"))
    $keyList = $Script:Cache.Keys
    foreach($key in $keyList) {
        if($key -notin $KeepKeys) {
            $Script:Cache.Remove($key)
        }
    }
    CacheLoadTables -force
}

Function CacheLoadTables([switch]$force, [switch]$return) {
    if($force -or -not (CacheValid -Key "TableNames")) {
        $result = Get-DataVerseTables -AllTables |
            Select-Object LogicalName, EntitySetName |
            Sort-Object LogicalName
        CacheAdd -Key "TableNames" -Value $result
    }
    if($return) { return CacheGet -Key "TableNames" }
}