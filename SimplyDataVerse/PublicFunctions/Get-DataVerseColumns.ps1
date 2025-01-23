function Get-DataVerseColumns {
    [cmdletbinding()]
    param([Parameter(Mandatory)][string]$EntitySetName
        , [Parameter()][switch]$CanUpdate
        , [Parameter()][switch]$IsCustom
    )

    $LogicalName = [TableCache]::LogicalName($EntitySetName)
    $cols = @(
        "MetadataId"
        "LogicalName"
        "ColumnNumber"
        "AttributeType"
        "IsCustomAttribute"
        "IsPrimaryId"
        "IsPrimaryName"
        "IsValidForCreate"
        "IsValidForUpdate"
    )
    
    $ep = "EntityDefinitions(LogicalName='$LogicalName')/Attributes"
    $ep += '?$select=' + ($cols -join ",")
    $ep += '&$filter=IsValidODataAttribute eq true'
    if($CanUpdate) { $ep += " and IsValidForUpdate eq true" }
    if($IsCustom) { $ep += " and IsCustomAttribute eq true" }

    $request = @{
        Method = "GET"
        EndPoint = $ep
        AddHeaders = @{
            'If-None-Match' = ""
            'Consistency' = 'Strong'
        }
    }
    Invoke-DataVerse @request | 
        Select-Object -ExpandProperty value |
        Select-Object $cols
}