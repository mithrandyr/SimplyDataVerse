<#
.DESCRIPTION
    By default, only returns custom rows & primaryId.
#>
function Get-DataVerseColumns {
    [cmdletbinding()]
    param([Parameter(Mandatory)][string]$EntitySetName
        , [Parameter()][ValidateSet("Custom","Updateable","All")][string]$Options = "Custom"
    )

    $LogicalName = [SDVApp]::Schema.LogicalName($EntitySetName)
    
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
    Switch($Options) {
        "Custom" { $ep += " and (IsPrimaryId eq true or IsCustomAttribute eq true)" }
        "Updateable" { $ep += " and (IsPrimaryId eq true or IsValidForUpdate eq true)" }
        "All" {}
    }

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