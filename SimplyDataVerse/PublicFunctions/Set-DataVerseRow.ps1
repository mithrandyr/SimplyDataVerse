function Set-DataVerseRow {
    [cmdletbinding(DefaultParameterSetName="hash")]
    param (
       [Parameter(Mandatory, ParameterSetName="hash")][String]$EntitySetName
       , [Parameter(Mandatory, ParameterSetName="hash", ValueFromPipeline)][hashtable]$Changes
       , [Parameter(Mandatory, ParameterSetName="object", ValueFromPipeline)][psobject]$InputObject
    )
    begin {
        $hashList = [System.Collections.Generic.List[hashtable]]::new()        
    }
    process {
        if($PSCmdlet.ParameterSetName -eq "hash") {
            $hashList.Add($Changes)
        } else {
            $esName = $InputObject.TypeNames[0].Split(".")[1]
            if(-not $EntitySetName) { $EntitySetName = $esName }
            elseif($EntitySetName -ne $esName) { throw "Cannot use 'Set-DataVerseRow' with multiple EntitySets. "}
            #$changes = 

        }
        
    }
    end {
        $addHdrs = @{'If-None-Match'= ""}
        if($IncludeAnnotations) { $addHdrs['Prefer'] ='odata.include-annotations="*"' }
    
        $request = @{
            Method = "GET"
            EndPoint = $ep
            AddHeaders = $addHdrs
        }
        Invoke-DataVerse @request | Select-Object -ExpandProperty value
    }    
}
