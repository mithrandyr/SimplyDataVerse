function Set-DataVerseRow {
    [cmdletbinding(DefaultParameterSetName="hash")]
    param (
       [Parameter(Mandatory, ParameterSetName="hash")][String]$EntitySetName
       , [Parameter(Mandatory, ParameterSetName="hash", ValueFromPipeline)][hashtable]$Changes
       , [Parameter(Mandatory, ParameterSetName="object", ValueFromPipeline)][psobject]$InputObject
       , [Parameter()][switch]$NoResult
    )
    begin {
        $hashList = [System.Collections.Generic.List[hashtable]]::new()   
        if($EntitySetName) { $PrimaryIdCol = [SDVApp]::Schema.TablePrimaryId($EntitySetName) }
    }
    process {
        if($PSCmdlet.ParameterSetName -eq "object") {
            $esName = $InputObject.psobject.TypeNames[0].Split(".")[1]
            if(-not $EntitySetName) {
                $EntitySetName = $esName
                $PrimaryIdCol = [SDVApp]::Schema.TablePrimaryId($EntitySetName)
            }
            elseif($EntitySetName -ne $esName) { throw "Cannot use 'Set-DataVerseRow' with multiple EntitySets. "}
            $Changes = ConvertToHashTable -InputObject $InputObject
        }
        $hashList.Add($Changes)        
    }
    end {
        $addHdrs = @{'Content-Type'= "application/json"}
        if(-not $NoResult) { $addHdrs["return"] = "representation" }
    
        foreach($body in $hashList) {
            $request = @{
                Method = "PATCH"
                EndPoint = "$EntitySetName({0})" -f $body.$PrimaryIdCol
                AddHeaders = $addHdrs
            }

            Invoke-DataVerse @request -Body ($body | ConvertTo-Json) |
                Select-Object -ExpandProperty value
        }
        
    }    
}
