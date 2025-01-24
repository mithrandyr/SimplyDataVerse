<#
.SYNOPSIS
    Returns list of DataVerse environments (commercial only).

.DESCRIPTION
    Returns list of DataVerse environments (commercial only).

#>
Function Find-DataVerseOrg {
    [cmdletbinding()]
    Param([switch]$IgnoreCache)
    
    [SDVApp]::DataVerseEnvironments($IgnoreCache)
}