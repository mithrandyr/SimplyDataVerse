Function ErrorEntitySetMissing {
    param([psobject]$InputObject)
    
    [System.Management.Automation.ErrorRecord]::new(
        [System.InvalidOperationException]::new("Pipelined Objects must have EntitySet specified through TypeName, use 'Get-DataVerseRow' or 'New-DataVerseRow'.")
        , $null
        , [System.Management.Automation.ErrorCategory]::InvalidData
        , $InputObject
    )
}
Function ErrorPrimaryIdColumnMissing {
    param([psobject]$InputObject, [string]$EntitySetName, [string]$PrimaryIdCol)
    
    [System.Management.Automation.ErrorRecord]::new(
        [System.InvalidOperationException]::new("Pipelined Object missing or invalid '$PrimaryIdCol' which is the primary GUID for '$EntitySetName'.")
        , $null
        , [System.Management.Automation.ErrorCategory]::InvalidData
        , $InputObject
    )
}