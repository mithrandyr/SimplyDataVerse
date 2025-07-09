Class SDVApp {
    static [CacheSvc] $Cache = [CacheSvc]::new()
    static [SchemaCache] $Schema = [SchemaCache]::new()
    hidden static [hashtable] $Tables = @{}
    hidden static [hashtable] $TableMap = @{}
    
    static [void] InitializeSchema() { [SDVApp]::Schema.Initialize() }
    
    #region Schema (tables/ columns)
    static [void] RefreshSchema() {
        $tableColumnsToLoad = [SDVApp]::Tables.Values.where({$_.HasAttributeDetails}).EntitySetName
        $metaDataHash = [SDVApp]::RefreshMetaData()
        [SDVApp]::Tables.Clear()
        [SDVApp]::TableMap.Clear()
        
        foreach($tbl in (Get-DataVerseTables -AllTables)) {
            $logicalName, $entitySetName = $tbl.LogicalName, $tbl.EntitySetName
            [SDVApp]::TableMap[$logicalName] = $entitySetName
            [SDVApp]::Tables[$entitySetName] = @{
                IsManaged = $tbl.IsManaged
                EntitySetName = $entitySetName
                LogicalName = $logicalName
                PrimaryNameAttribute = $tbl.PrimaryNameAttribute
                PrimaryIdAttribute = $tbl.PrimaryIdAttribute
                Attributes = @{}
                HasAttributeDetails = $false
            }
            # Columns
            foreach($column in $metaDataHash[$logicalName].Property) {
                if($column.name -notlike "_*") {
                    [SDVApp]::Tables[$entitySetName].Attributes[$column.Name] = [PSCustomObject]@{
                        AttributeType = "Scalar"
                        LogicalName = $column.Name
                        DataType = $column.Type.Split(".")[1]
                        DataVerseType = $null
                        SchemaName = $null
                        IsValidForCreate = $null
                        IsValidForUpdate = $null
                        IsCustom = $null
                    }
                }
            }
            # Navigation
            foreach($column in $metaDataHash[$logicalName].NavigationProperty) {
                if($column.Name -in @("ownerid", "activitypointer")) {}
                elseif($column.Type -like "Collection(*)") {}
                else {
                    [SDVApp]::Tables[$entitySetName].Attributes[$column.Name] = [PSCustomObject]@{
                        AttributeType = "Navigation"
                        LogicalName = $column.Name
                        DataType = $column.Type.Split(".")[1]
                        DataVerseType = $null
                        SchemaName = $null
                        IsValidForCreate = $null
                        IsValidForUpdate = $null
                        IsCustom = $null
                        RawName = ("_{0}_value" -f $column.Name).ToLower()
                    }
                }
            }
        }
        
        #refresh any tables already loaded
        $tableColumnsToLoad.ForEach({[SDVApp]::LoadColumnDetails($_)})
    }

    static [string] GetTableIdAttribute($entitySetName) {
        return [SDVApp]::Tables[$entitySetName].PrimaryIdAttribute
    }

    static [string] GetLogicalFromEntitySet($entitySetName) {
        return [SDVApp]::Tables[$entitySetName].LogicalName
    }

    static [string] GetEntitySetFromLogical($logicalName) {
        return [SDVApp]::TableMap[$logicalName]
    }
    
    static [psobject[]] ColumnsForCreate([string]$entitySetName) {
        [SDVApp]::LoadColumnDetails($entitySetName)
        return [SDVApp]::Tables[$entitySetName].Attributes.Values.where({$_.IsValidForCreate})
    }
    static [psobject[]] ColumnsForUpdate([string]$entitySetName) {
        [SDVApp]::LoadColumnDetails($entitySetName)
        return [SDVApp]::Tables[$entitySetName].Attributes.Values.where({$_.IsValidForUpdate})
    }
    static [string[]] ColumnsForSelectCustom([string]$entitySetName) {
        [SDVApp]::LoadColumnDetails($entitySetName)
        $result = @([SDVApp]::GetTableIdAttribute($entitySetName))
        $result += [SDVApp]::Tables[$entitySetName].Attributes.Values.where({$_.IsCustom}).LogicalName
        return $result 
    }

    hidden static [void] LoadColumnDetails([string]$entitySetName) {
        if([SDVApp]::Tables[$entitySetName].HasAttributeDetails) {
            return #already loaded the data...
        } else {
            $logicalName = [SDVApp]::GetLogicalFromEntitySet($entitySetName)
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

            $results = Invoke-DataVerse @request | 
                Select-Object -ExpandProperty value
            $results |
                ForEach-Object {
                    $attribute = [SDVApp]::Tables[$entitySetName].Attributes[$_.LogicalName]
                    if($attribute) {
                        $attribute.SchemaName = $_.SchemaName
                        $attribute.DataVerseType = $_.AttributeType
                        $attribute.IsValidForCreate = $_.IsValidForCreate
                        $attribute.IsValidForUpdate = $_.IsValidForUpdate
                        $attribute.IsCustom = $_.IsCustomAttribute
                    }
                }
            $keysToRemove = [SDVApp]::Tables[$entitySetName].Attributes.Values |
                Where-Object SchemaName -eq $null |
                Select-Object -ExpandProperty LogicalName

            foreach ($key in $keysToRemove) {
                [SDVApp]::Tables[$entitySetName].Attributes.Remove($key)
            }
            [SDVApp]::Tables[$entitySetName].HasAttributeDetails = $true
        }
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