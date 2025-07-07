Class SDVApp {
    static [CacheSvc] $Cache = [CacheSvc]::new()
    static [SchemaCache] $Schema = [SchemaCache]::new()
    hidden static [hashtable] $Tables = @{}
    hidden static [hashtable] $TableMap = @{}
    hidden static [hashtable] $TableColumns = @{}
    
    static [void] InitializeSchema() { [SDVApp]::Schema.Initialize() }
    
    #region Schema (tables/ columns)
    static [void] RefreshSchema() {
        [SDVApp]::Tables.Clear()
        [SDVApp]::TableMap.Clear()
        [SDVApp]::TableColumns.Clear()

        $metaDataHash = [SDVApp]::RefreshMetaData()
        
        foreach($tbl in (Get-DataVerseTables -AllTables)) {
            $logicalName, $entityName = $tbl.LogicalName, $tbl.EntitySetName
            [SDVApp]::TableMap[$logicalName] = $entityName
            [SDVApp]::Tables[$entityName] = @{
                IsManaged = $tbl.IsManaged
                LogicalName = $logicalName
                PrimaryNameAttribute = $tbl.PrimaryNameAttribute
                PrimaryIdAttribute = $tbl.PrimaryIdAttribute
                Columns = @{}
                Navigation = @{}
            }
            # Columns
            foreach($column in $metaDataHash[$logicalName].Property.where({$_.name -notlike "_*"})) {
                [SDVApp]::Tables[$entityName].Columns[$column.Name] = @{
                    LogicalName = $column.Name
                    Type = $column.Type.Split(".")[1]
                }
            }
            # Navigation
            foreach($column in $metaDataHash[$logicalName].NavigationProperty.where({$_.type -notlike "Collection(*)"})) {
                [SDVApp]::Tables[$entityName].Navigation[$column.Name] = @{
                    LogicalName = $column.Name
                    Type = $column.Type.Split(".")[1]
                }
            }
            
            #details for userDefinedTables (non-managed)
            if-not ($tbl.IsManaged) { 
                [SDVApp]::LoadColumnDetails($logicalName)
            }
        }

    }

    static [string] GetLogicalFromEntitySet($entityName) {
        return [SDVApp]::Tables($entityName).LogicalName
    }

    static [string] GetEntitySetFromLogical($logicalName) {
        return [SDVApp]::TableMap($logicalName)
    }
    
    static [string[]] ColumnsForCreate([string]$logicalName) {
        if(-not [SDVApp]::TableColumns.ContainsKey($logicalName)) {
            [SDVApp]::LoadColumnDetails($logicalName)
        }
        return [SDVApp]::TableColumns[$logicalName].where({$_.IsValidForCreate})
    }
    static [string[]] ColumnsForUpdate([string]$logicalName) {
        if(-not [SDVApp]::TableColumns.ContainsKey($logicalName)) {
            [SDVApp]::LoadColumnDetails($logicalName)
        }
        return [SDVApp]::TableColumns[$logicalName].where({$_.IsValidForUpdate})
    }

    hidden static [void] LoadColumnDetails([string]$logicalName) {
        $cols = @("LogicalName", "SchemaName", "ColumnNumber", "AttributeType", "IsCustomAttribute", "IsValidForCreate", "IsValidForUpdate")
        $ep = "EntityDefinitions(LogicalName='$LogicalName')/Attributes"
        $ep += '?$select=' + ($cols -join ",")
        $ep += '&$filter=IsValidODataAttribute eq true'
        
        $request = @{
            Method = "GET"
            EndPoint = $ep
            AddHeaders = @{
                'If-None-Match' = ""
                'Consistency' = 'Strong'
            }
        }
        
        [SDVApp]::Tables[$LogicalName] = Invoke-DataVerse @request | 
            Select-Object -ExpandProperty value |
            Select-Object $cols
    }

    hidden static [hashtable] RefreshMetaData() {
        $hdrs = [SDVApp]::GetBaseHeaders()
        $hdrs.Remove('Accept')
        $request = @{
            Uri     = [SDVApp]::GetBaseUri() + '$metadata'
            Method  = "GET"
            Headers = $hdrs
        }
        
        $result = Invoke-RestMethod @request
        $mdInfo = @{}
        foreach($x in $result.Edmx.DataServices.Schema.EntityType) { $mdInfo[$x.Name] = $x }
        return $mdInfo
    }

    #region Environment/Baseuri/Headers/Token
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