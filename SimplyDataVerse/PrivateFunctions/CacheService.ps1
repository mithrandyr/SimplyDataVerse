$Script:Cache = @{

}
Function CacheAdd {
    param([Parameter(Mandatory)][string]$Key
        , [Parameter(Mandatory)]$Value
        , [Parameter()][int]$AgeInSeconds = 300)

    $Script:Cache[$Key] = @{
        Expires = (Get-Date).AddSeconds($AgeInSeconds)
        Value = $Value
    }
}

Function CacheGet {
    param([Parameter(Mandatory)][string]$Key)
    if($Script:Cache.ContainsKey($Key)) {
        if($Script:Cache[$key].Expires -gt (Get-Date)){
            return $Script:Cache[$key].Value
        }
    }
}

Function CacheClear { $Script:Cache.Clear() }