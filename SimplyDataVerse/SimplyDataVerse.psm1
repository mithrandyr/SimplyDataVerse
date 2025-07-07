foreach ($c in @("CacheService.ps1", "SDVApp.ps1", "ErrorHandling.ps1")) {
    . "$PSScriptRoot\Classes\$c"
}

Get-ChildItem "$PSScriptRoot\PrivateFunctions" -Recurse -Filter "*.ps1" |
    ForEach-Object {
        . $_.FullName
    }

    $FunctionsToExport = @()
Get-ChildItem "$PSScriptRoot\PublicFunctions" -Recurse -Filter "*.ps1" |
    ForEach-Object {
        . $_.FullName
        $FunctionsToExport += $_.BaseName
    }

Export-ModuleMember -Function $FunctionsToExport