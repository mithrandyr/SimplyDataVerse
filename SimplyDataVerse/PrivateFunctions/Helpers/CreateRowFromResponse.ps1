Function CreateRowFromResponse{
    param(
        [parameter(Mandatory, ValueFromPipeline)][PSObject]$Object
        ,[parameter(Mandatory)][string]$EntitySetName
    )
    begin {
        $Attributes = [SDVApp]::Tables[$entitySetName].Attributes.Values
        [SDVApp]::LoadColumnDetails($EntitySetName)
    }
    process {
        $ht = [ordered]@{ PSTypeName = "SimplyDataVerse.$EntitySetName" }
        foreach($attribute in $Attributes) {
            $name = $attribute.LogicalName
            $display = $attribute.SchemaName
            if($attribute.AttributeType -eq "Navigation") {
                $esName = [SDVApp]::GetEntitySetFromLogical($attribute.DataType)
                if($Object.$Name -is [psobject]) {
                    $ht.$display = CreateRowFromResponse -Object $Object.$Name -EntitySetName $esName
                } else {
                    $idName = [SDVApp]::GetTableIdAttribute($esName)
                    $ht.$display = [PSObject]@{
                        $idName = $Object.$Name
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