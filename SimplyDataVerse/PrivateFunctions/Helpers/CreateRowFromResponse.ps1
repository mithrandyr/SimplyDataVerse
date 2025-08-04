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
        $primaryIdCol = [SDVApp]::GetTableIdAttribute($EntitySetName)
    }
    process {
        $ht = [ordered]@{
            PSTypeName = "SimplyDataVerse.$EntitySetName"
            #__OriginalValues = @{} #intended to enable set-dataverse to only patch changed attributes
        }
        foreach($property in $Object.psobject.Properties.Name) {
            if($attributes.ContainsKey($property)) { $attribute = $attributes[$property] }
            elseif ($rawAttributes.ContainsKey($property)) { $attribute = $rawAttributes[$property] }
            else { continue }

            $name = $attribute.LogicalName
            $display = $attribute.SchemaName
            if($attribute.AttributeType -eq "Navigation") {
                $esName = [SDVApp]::GetEntitySetFromLogical($attribute.DataType)
                $idName = [SDVApp]::GetTableIdAttribute($esName)
                if($Object.$name -is [psobject]) {
                    $ht.$display = CreateRowFromResponse -Object $Object.$name -EntitySetName $esName
                    #$ht.__OriginalValues[$display] = $Object.$name.$idName
                } else {                    
                    $rawName = $attribute.RawName
                    $ht.$display = $Object.$rawName
                    #$ht.__OriginalValues[$display] = $Object.$rawName
                }
            } else {
                $ht.$display = $Object.$name
                if($display -ne $primaryIdCol) { #exclude primaryId from original values
                    #$ht.__OriginalValues[$display] = $Object.$name
                }                
            }
        }
        
        [PSCustomObject]$ht
    }

}
Export-ModuleMember CreateRowFromResponse