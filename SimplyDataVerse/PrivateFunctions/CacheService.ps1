Class CacheSvc {
    hidden $Cache = @{}
    
    [void] Add([string]$key, $value) { $this.Add($key, $value, 300) }
    [void] Add([string]$key, $value, [int]$age) {
        $this.Cache[$key] = @{
            Expires = (Get-Date).AddSeconds($age)
            Value = $value
        }
    }

    [bool] IsValid([string]$key) {
        return ($this.Cache.ContainsKey($key) -and $this.Cache[$key].Expires -gt (Get-Date))
    }

    [object] Get($key) {
        if($this.IsValid($key)) { return $this.Cache[$key].Value }
        else { return $null }
    }
    
    [void] Clear() { $this.Cache.Clear() }
    [string[]] Keys() { return $this.Cache.Keys }
}

Class GeneralCache:CacheSvc {
    hidden static [CacheSvc] $_instance = [CacheSvc]::new()
    
    static [void] Add([string]$key, $value) {
        [GeneralCache]::_instance.Add($key, $value)
    }
    
    static [void] Add([string]$key, $value, [int]$age) {
        [GeneralCache]::_instance.Add($key, $value, $age)
    }

    static [bool] IsValid([string]$key) {
        return [GeneralCache]::_instance.IsValid($key)
    }

    static [object] Get($key) {
        return [GeneralCache]::_instance.Get($key)
    }
    
    static [void] Clear() { [GeneralCache]::_instance.Clear() }
}

Class TableCache:CacheSvc {
    hidden static [CacheSvc] $_tables = [CacheSvc]::new()
    hidden static [CacheSvc] $_columns = [CacheSvc]::new()

    static [void] Initialize() {
        [TableCache]::_tables.Clear()
        [TableCache]::_columns.Clear()

        Get-DataVerseTables -AllTables |
            Select-Object EntitySetName, LogicalName, PrimaryIdAttribute, PrimaryNameAttribute, IsManaged |
            ForEach-Object {
                [TableCache]::_tables.Add($_.EntitySetName, $_)
                if(-not $_.IsManaged) {
                    [TableCache]::_columns.Add($_.EntitySetName, $columns)
                    $columns = Get-DataVerseColumns -EntitySetName $_.EntitySetName
                }
            }
    }

    static [psobject] Table([string]$entitySetName) {
        if(-not [TableCache]::_tables.IsValid($entitySetName)) {
            $tbl = Get-DataVerseTables -EntitySetName $entitySetName
            [TableCache]::_tables.Add($entitySetName, $tbl)
            return $tbl
        } else {
            return [TableCache]::_tables.Get($entitySetName)
        }
    }
    
    static [string] LogicalName([string]$entitySetName) {
        return [TableCache]::Table($entitySetName).LogicalName
    }
    
    static [string] TablePrimaryId([string]$entitySetName) {
        return [TableCache]::Table($entitySetName).PrimaryIdAttribute
    }

    static [string[]] EntitySetNames() {
        return [TableCache]::_tables.Keys()
    }

    static [psobject[]] Columns([string]$entitySetName) {
        if(-not [TableCache]::_columns.IsValid($entitySetName)) {
            $columns = Get-DataVerseColumns -EntitySetName $entitySetName
            [TableCache]::_columns.Add($entitySetName, $columns)
            return $columns
        } else {
            return [TableCache]::_columns.Get($entitySetName)
        }
    }
    static [psobject[]] ColumnsCanUpdate([string]$entitySetName) {
        return [TableCache]::Columns($entitySetName).Where({$_.IsValidForUpdate})
    }
    
}

#region Old
<#
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
#>
#endregion