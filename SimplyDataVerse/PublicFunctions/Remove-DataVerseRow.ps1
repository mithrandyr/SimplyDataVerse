Function Remove-DataVerseRow {
    [cmdletbinding(DefaultParameterSetName="guid")]
    param (
       [Parameter(Mandatory, ParameterSetName="guid")][String]$EntitySetName
       , [Parameter(Mandatory, ParameterSetName="guid", ValueFromPipeline)][guid]$Guid
       , [Parameter(Mandatory, ParameterSetName="object", ValueFromPipeline)][psobject]$InputObject
    )
    process {
        if($PSCmdlet.ParameterSetName -eq "object") {
            $EntitySetName = GetEntitySetNameFromPSObject $InputObject
            if(-not $EntitySetName) {
                $PSCmdlet.WriteError((ErrorEntitySetMissing $InputObject))
                return
            }

            $primaryIdCol = [SDVApp]::Schema.TablePrimaryId($EntitySetName)
            try {
                $guid = $InputObject.$primaryIdCol
            } catch {
                $PSCmdlet.WriteError((ErrorPrimaryIdColumnMissing $InputObject $EntitySetName $primaryIdCol))
                return
            }
        }
        
        $request = @{
            Method = "DELETE"
            Endpoint = "$EntitySetName($guid)"
        }
        try {
            Invoke-DataVerse @request | Out-Null
            Write-Verbose "Removed '$guid' on '$EntitySetName'"
        } catch {
            $PSCmdlet.WriteError($_)
        }
    }
}