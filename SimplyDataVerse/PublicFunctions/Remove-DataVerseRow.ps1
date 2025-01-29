Function Remove-DataVerseRow {
    [cmdletbinding(DefaultParameterSetName="guid")]
    param (
       [Parameter(Mandatory, ParameterSetName="guid")][String]$EntitySetName
       , [Parameter(Mandatory, ParameterSetName="guid", ValueFromPipeline)][guid]$Guid
       , [Parameter(Mandatory, ParameterSetName="object", ValueFromPipeline)][psobject]$InputObject
    )

    process {
        Write-Host $guid
    }
}