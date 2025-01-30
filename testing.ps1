param([switch]$load)
if($load) {
    Write-Host "Starting nested session..."
    powershell -noexit ". .\testing.ps1; refresh"
    Write-Host "Finished nested session!"
}

function refresh {
    Clear-Host
    $error.Clear()
    Write-Host "Importing Module..."    
    Import-Module "$PSScriptRoot\SimplyDataVerse" -Force
    if($Error.Count -gt 0) {
        Write-Warning "Module Loading generated errors!"
    } else {
        Write-Host "Connecting to Dataverse..." -NoNewline
        Connect-DataVerse 'RBS DevSecOps & IT Ops'
        Write-Host "Done!"
    }    
}