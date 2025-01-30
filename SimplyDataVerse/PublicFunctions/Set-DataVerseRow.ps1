function Set-DataVerseRow {
    [cmdletbinding(DefaultParameterSetName="hash")]
    param (
       [Parameter(Mandatory, ParameterSetName="hash")][String]$EntitySetName
       , [Parameter(Mandatory, ParameterSetName="hash", ValueFromPipeline)][hashtable]$Changes
       , [Parameter(Mandatory, ParameterSetName="object", ValueFromPipeline)][psobject]$InputObject
       , [Parameter(ParameterSetName="object", ValueFromPipeline)][switch]$IgnoreNull
    )
    begin {
        $hashList = [System.Collections.Generic.List[hashtable]]::new()   
        if($EntitySetName) { $PrimaryIdCol = [SDVApp]::Schema.TablePrimaryId($EntitySetName) }
    }
    process {
        if($PSCmdlet.ParameterSetName -eq "object") {
            $esName = GetEntitySetNameFromPSObject $InputObject
            if(-not $esName) {
                throw "Pipelined Objects must be have EntitySet through TypeName, use 'Get-DataVerseRow' or 'New-DataVerseRow'."
            } elseif(-not $EntitySetName) {
                $EntitySetName = $esName
                $PrimaryIdCol = [SDVApp]::Schema.TablePrimaryId($EntitySetName)
            }
            elseif($EntitySetName -ne $esName) { throw "Cannot use 'Set-DataVerseRow' with multiple EntitySets." }
            $Changes = ConvertToHashTable -InputObject $InputObject -IgnoreNull:$IgnoreNull
        }
        $hashList.Add($Changes)        
    }
    end {
        $addHdrs = @{'Content-Type'= "application/json"}
    
        foreach($body in $hashList) {
            $request = @{
                EndPoint = $EntitySetName
                AddHeaders = $addHdrs
            }

            if($body.$PrimaryIdCol) { #update row
                $request.Method = "PATCH"
                $request.EndPoint += "({0})" -f $body.$PrimaryIdCol
                $request.Body = $body | ConvertTo-Json
                Invoke-DataVerse @request

            } else { #create row
                $body.Remove($PrimaryIdCol)
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
