function Get-DataVerseRows {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory)][String]$EntitySetName
       , [Parameter()][String[]]$Columns
       , [Parameter()][switch]$IncludeAnnotations
    )
    $ep = $EntitySetName
    if($Columns) {
        $ep = QueryAppend $query ('$select=' + ($columns -join ","))
    }
    $addHdrs = @{'If-None-Match'= ""}
    if($IncludeAnnotations) { $addHdrs['Prefer'] ='odata.include-annotations="*"' }

    $request = @{
        Method = "GET"
        EndPoint = $ep
        AddHeaders = $addHdrs
    }
    Invoke-DataVerse @request | Select-Object -ExpandProperty value
}

Register-ArgumentCompleter -CommandName "Get-DataVerseRows" -ParameterName EntitySetName -ScriptBlock {
    [OutputType([System.Management.Automation.CompletionResult])]
    param(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [System.Management.Automation.Language.CommandAst] $CommandAst,
        [System.Collections.IDictionary] $FakeBoundParameters
    )
    
    $result = CacheGet "EntitySetNames"
    if(-not $result) {
        $result = Get-DataVerseTables -AllTables | Select-Object -ExpandProperty EntitySetName
        CacheAdd -Key "EntitySetNames" -Value $result
    }

    $result | Where-Object {$_ -like "*$WordToComplete*"}
}