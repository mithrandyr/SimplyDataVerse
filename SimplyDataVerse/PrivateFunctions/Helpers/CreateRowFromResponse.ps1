Function CreateRowFromResponse {
    param(
        [parameter(Mandatory, ValueFromPipeline)][PSObject]$Object
        ,[parameter(Mandatory)][string]$EntitySetName
    )
    begin {
        [SDVApp]::LoadColumnDetails($EntitySetName)
        $Attributes = [SDVApp]::Tables[$entitySetName].Attributes.Values        
    }
    process {
        $filterAttributesByObject = $Attributes.where({$_.LogicalName -in $Object.psobject.Properties.Name})
        $ht = [ordered]@{ PSTypeName = "SimplyDataVerse.$EntitySetName" }
        foreach($attribute in $filterAttributesByObject) {
            $name = $attribute.LogicalName
            $display = $attribute.SchemaName
            if($attribute.AttributeType -eq "Navigation") {
                $esName = [SDVApp]::GetEntitySetFromLogical($attribute.DataType)
                if($Object.$name -is [psobject]) {
                    $ht.$display = CreateRowFromResponse -Object $Object.$name -EntitySetName $esName
                } else {
                    $idName = [SDVApp]::GetTableIdAttribute($esName)
                    $rawName = $attribute.RawName
                    $ht.$display = [PSObject]@{
                        $idName = $Object.$rawName
                    }
                }
            } else {
                $ht.$display = $Object.$name
            }
        }
        [PSCustomObject]$ht
    }

}
Export-ModuleMember CreateRowFromResponse