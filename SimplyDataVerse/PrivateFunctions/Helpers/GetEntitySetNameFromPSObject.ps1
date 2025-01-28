Function GetEntitySetNameFromPSObject {
    Param([Parameter(Mandatory, ValueFromPipeline)][psobject]$InputObject)
    
    $InputObject.psobject.TypeNames |
        Where-Object { $_ -like "SimplyDataVerse.*" } |
        ForEach-Object { $_.SubString(16) } |
        Select-Object -First 1
}