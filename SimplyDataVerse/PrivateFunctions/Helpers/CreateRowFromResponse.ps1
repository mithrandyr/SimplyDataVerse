Function CreateRowFromResponse {
    param(
        [parameter(Mandatory, ValueFromPipeline)][PSObject]$Object
        ,[parameter(Mandatory)][string]$EntitySetName
    )
    begin {
        [SDVApp]::LoadColumnDetails($EntitySetName)
        $attributes = [SDVApp]::Tables[$entitySetName].Attributes
        $rawAttributes = @{}
        $attributes.Values.where({$_.RawName}).foreach({$rawAttributes[$_.RawName] = $_})
    }
    process {
        $ht = [ordered]@{ PSTypeName = "SimplyDataVerse.$EntitySetName" }
        foreach($property in $Object.psobject.Properties.Name) {
            if($attributes.ContainsKey($property)) { $attribute = $attributes[$property] }
            elseif ($rawAttributes.ContainsKey($property)) { $attribute = $rawAttributes[$property] }
            else { continue }

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