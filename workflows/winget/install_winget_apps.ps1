#
#Import-Module $PSScriptRoot\CG\_Global\Write\Write.psm1
#.$PSScriptRoot\CG\Modules\Winget\initialize_winget.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\.."
Write-Info "--[Starting Install Apps Script @ $(Get-Date)]--" 
winget source update --disable-interactivity

if (! (Test-Path -Path $PSScriptRoot\..\..\..\apps.txt)) {
    Write-Alert "To install apps with winget, provide an apps.txt file with winget ID's inside on each line"
}
else {
    Install-WithWinget -File $PSScriptRoot\..\..\..\apps.txt
}


[System.GC]::Collect()



