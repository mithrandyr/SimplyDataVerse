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

Class SDVApp {
    static [CacheSvc] $Cache = [CacheSvc]::new()
    static [SchemaCache] $Schema = [SchemaCache]::new()

    static [void] InitializeSchema() { [SDVApp]::Schema.Initialize() }
    
    static [hashtable] GetBaseHeaders() { return [SDVApp]::GetBaseHeaders([SDVApp]::GetToken()) }
    static [hashtable] GetBaseHeaders([string]$token) {
        return @{
            'Authorization'    = 'Bearer ' + $token
            'Accept'           = 'application/json'
            'OData-MaxVersion' = '4.0'
            'OData-Version'    = '4.0'
        }
    }     

    static [string] GetToken() {
        if (-not [SDVApp]::_environmentUri) {
            throw [System.InvalidOperationException]::new("Cannot call 'GetToken()' unless 'SetEnvironment()' has been called first!")
        }
        return [SDVApp]::GetToken([SDVApp]::_environmentUri)
    }

    static [string] GetToken([string]$uri) {
        if (-not [SDVApp]::Cache.IsValid("IsAuthenticated")) {
            ## Login interactively if not already logged in
            if ($null -eq (Get-AzTenant -ErrorAction SilentlyContinue)) {
                Connect-AzAccount -ErrorAction Stop | Out-Null
            }
            [SDVApp]::Cache.Add("IsAuthenticated", $true, 15 * 60)
        }
        
        $key = "[TOKEN]$uri"
        $token = [SDVApp]::Cache.Get($key)
        if (-not $token) {
            $secureToken = (Get-AzAccessToken -ResourceUrl $uri -AsSecureString).Token

            # Convert the secure token to a string
            $token = [System.Net.NetworkCredential]::new("", $secureToken).Password
            [SDVApp]::Cache.Add($key, $token)
        }
        return $token
    }

    static [psobject[]] DataVerseEnvironments() { return [SDVApp]::DataVerseEnvironments($false) }
    static [psobject[]] DataVerseEnvironments([bool]$force) {
        $result = [SDVApp]::Cache.Get("DataVerseEnvironments")
        if ($force -or -not $result) {
            $request = @{
                Uri     = 'https://globaldisco.crm.dynamics.com/api/discovery/v2.0/Instances?$select=ApiUrl,FriendlyName'
                Method  = "GET"
                Headers = [SDVApp]::GetBaseHeaders([SDVApp]::GetToken("https://globaldisco.crm.dynamics.com/"))
            }
            $response = Invoke-RestMethod @request
            $result = $response.value
            [SDVApp]::Cache.Add("DataVerseEnvironments", $result)
        }
        return $result        
    }

    #region "Environment/Baseuri/Headers/Token"
    hidden static [string]$_environmentUri
    hidden static [string]$_baseUri
    static [void] SetEnvironment([string]$uri) {
        if (-not $uri.EndsWith("/")) { $uri += "/" }
        [SDVApp]::_environmentUri = $uri
        [SDVApp]::_baseUri = $uri + 'api/data/v9.2/'
    }
    static [string] GetBaseUri() { return [SDVApp]::_baseUri }
    #endregion
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