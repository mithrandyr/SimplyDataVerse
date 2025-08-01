function Set-DataVerseRow {
    [cmdletbinding(DefaultParameterSetName="object")]
    param (
       #[Parameter(Mandatory, ParameterSetName="hash")][String]$EntitySetName
       #, [Parameter(Mandatory, ParameterSetName="hash", ValueFromPipeline)][hashtable]$Changes
       [Parameter(Mandatory, ParameterSetName="object", ValueFromPipeline)][psobject]$InputObject
       #, [Parameter(ParameterSetName="object", ValueFromPipeline)][switch]$IgnoreNull
    )
    begin {
        $hashList = [System.Collections.Generic.List[hashtable]]::new()   
        <#
        if($EntitySetName) {
            $primaryIdCol = [SDVApp]::GetTableIdAttribute($EntitySetName)
            $columnDetails = [SDVApp]::ColumnsForUpdate($EntitySetName)
        }
        #>
    }
    process {
        if($PSCmdlet.ParameterSetName -eq "object") {
            $esName = GetEntitySetNameFromPSObject $InputObject
            if([string]::IsNullOrWhiteSpace($esName)) {
                throw "Pipelined Objects must be have EntitySet through TypeName, use 'Get-DataVerseRow' or 'New-DataVerseRow'."
            } elseif(-not [string]::IsNullOrWhiteSpace($EntitySetName) -and $EntitySetName -ne $esName) {
                throw "Cannot use 'Set-DataVerseRow' with multiple EntitySets."
            } else {
                $EntitySetName = $esName
                $primaryIdCol = [SDVApp]::Schema.TablePrimaryId($EntitySetName)
                $columnDetails = [SDVApp]::ColumnsForUpdate($EntitySetName)
                $keyList = $InputObject.psobject.Properties.Name
            }
        }
        $htForUpdate = @{}
        foreach($col in $columnDetails) {
            $colName = $col.SchemaName
            #we only want the keys that are updateable, and we want them as LogicalName, not SchemaName
            # we also need special handling for navigation properties.
            if($colName -notin $keyList) { continue }
            elseif($col.AttributeType -eq "Navigation") {
                $colES = [SDVApp]::TableMap[$col.DataType]
                $colId = [SDVApp]::GetTableIdAttribute($colES)
                $colName = $col.LogicalName
                $colValue = "{0}({1})" -f $colES, $InputObject.$colName.$colid
                $colName += "@odata.bind"
                $htForUpdate[$colName] = $colValue
            } else {                
                $htForUpdate[$col.LogicalName] = $InputObject.$colName
            }
        }
        if($htForUpdate.Keys.Count -gt 0) { 
            $htForUpdate[$primaryIdCol] = $InputObject.$primaryIdCol
            $hashList.Add($htForUpdate)
        }        
    }
    end {
        $addHdrs = @{'Content-Type'= "application/json"}
    
        foreach($body in $hashList) {
            $request = @{
                EndPoint = $EntitySetName
                AddHeaders = $addHdrs
            }

            if($body.$primaryIdCol) { #update row
                $request.Method = "PATCH"
                $request.EndPoint += "({0})" -f $body.$primaryIdCol
                $request.Body = $body | ConvertTo-Json
                Invoke-DataVerse @request | Out-Null

            } else { #create row
                $body.Remove($primaryIdCol)
                $request.Method = "POST"
                $request.Body = $body | ConvertTo-Json

                (Invoke-DataVerse @request -ReturnHeaders)["OData-EntityId"] |
                    Select-String -Pattern '(?<=\().*?(?=\))' |
                    Select-Object -ExpandProperty Matches |
                    Select-Object -ExpandProperty value |
                    ForEach-Object { [guid]::new($_) }
            }
        }
    }    
}
