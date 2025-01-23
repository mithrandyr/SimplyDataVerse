function Get-DataVerseTables {
    [cmdletbinding(DefaultParameterSetName="all")]
    param([Parameter(ParameterSetName="all")][switch]$AllTables #if not specified, limited to IsManaged=False
        , [Parameter(Mandatory, ParameterSetName="one")][string]$EntitySetName
        , [Parameter()][switch]$AllAttributes #if not specified, columns limited to MetadataId,TableType,DisplayName,EntitySetName,LogicalName,ExternalName,PrimaryIdAttribute,PrimaryNameAttribute,IsManaged
    )
    $ep = "EntityDefinitions"
    if($PSCmdlet.ParameterSetName -eq "one") {
        $ep = QueryAppend $ep "`$filter=EntitySetName eq '$entitySetName'"
    } elseif(-not $AllTables) {
        $ep = QueryAppend $ep '$filter=IsManaged eq false'
    }
    
    if(-not $AllAttributes) {
        $ep = QueryAppend $ep '$select=MetadataId,TableType,EntitySetName,LogicalName,ExternalName,PrimaryIdAttribute,PrimaryNameAttribute,IsManaged'
    }
    
    $request = @{
        Method = "GET"
        EndPoint = $ep
        AddHeaders = @{
            'If-None-Match' = ""
            'Consistency' = 'Strong'
        }
    }
    Invoke-DataVerse @request | Select-Object -ExpandProperty value
}