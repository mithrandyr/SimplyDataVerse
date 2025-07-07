Class CacheSvc {
    hidden $Cache = @{}
    
    [void] Add([string]$key, $value) { $this.Add($key, $value, 300) }
    [void] Add([string]$key, $value, [int]$age) {
        $this.Cache[$key] = @{
            Expires = (Get-Date).AddSeconds($age)
            Value   = $value
        }
    }

    [bool] IsValid([string]$key) {
        return ($this.Cache.ContainsKey($key) -and $this.Cache[$key].Expires -gt (Get-Date))
    }

    [object] Get($key) {
        if ($this.IsValid($key)) { return $this.Cache[$key].Value }
        else { return $null }
    }
    [void] Expire([string]$key) { if($this.Cache.ContainsKey($key)) { $this.Cache.Remove($key) } }
    [void] Clear() { $this.Cache.Clear() }
    [string[]] Keys() { return $this.Cache.Keys }
}

Class SchemaCache {
    hidden [CacheSvc] $_tables = [CacheSvc]::new()
    hidden [CacheSvc] $_columns = [CacheSvc]::new()

    [void] Initialize() {
        $this._tables.Clear()
        $this._columns.Clear()

        Get-DataVerseTables -AllTables |
            Select-Object EntitySetName, LogicalName, PrimaryIdAttribute, PrimaryNameAttribute, IsManaged |
            ForEach-Object {
                $this._tables.Add($_.EntitySetName, $_)
                if (-not $_.IsManaged) {
                    $columns = Get-DataVerseColumns -EntitySetName $_.EntitySetName -Options All
                    $this._columns.Add($_.EntitySetName, $columns)
                }
            }
    }

    [psobject] Table([string]$entitySetName) {
        if (-not $this._tables.IsValid($entitySetName)) {
            $tbl = Get-DataVerseTables -EntitySetName $entitySetName
            $this._tables.Add($entitySetName, $tbl)
            return $tbl            
        }
        else {
            return $this._tables.Get($entitySetName)
        }
    }
    
    [string] LogicalName([string]$entitySetName) {
        return $this.Table($entitySetName).LogicalName
    }
    
    [string] TablePrimaryId([string]$entitySetName) {
        return $this.Table($entitySetName).PrimaryIdAttribute
    }

    [string[]] EntitySetNames() {
        return $this._tables.Keys()
    }

    [psobject[]] Columns([string]$entitySetName) {
        if (-not $this._columns.IsValid($entitySetName)) {
            $columns = Get-DataVerseColumns -EntitySetName $entitySetName -Options All
            $this._columns.Add($entitySetName, $columns)
            return $columns
        }
        else {
            return $this._columns.Get($entitySetName)
        }
    }
    [psobject[]] ColumnsCustom([string]$entitySetName) {
        return $this.Columns($entitySetName).Where({ $_.IsCustomAttribute -or $_.IsPrimaryId })
    }
    [psobject[]] ColumnsCanUpdate([string]$entitySetName) {
        return $this.Columns($entitySetName).Where({ $_.IsValidForUpdate -or $_.IsPrimaryId })
    }
    
}

