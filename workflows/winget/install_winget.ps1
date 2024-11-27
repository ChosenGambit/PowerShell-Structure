#
#Import-Module $PSScriptRoot\CG\_Global\Write\Write.psm1
#.$PSScriptRoot\CG\Modules\Winget\initialize_winget.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\.."
Write-Info "--[Starting Install Script @ $(Get-Date)]--" 
$ProxyPath = "$PSScriptRoot\..\..\..\Dependencies"
Initialize-Winget -InstallPrerequisites $false -InstallWinget $true -ProxyPath $ProxyPath
[System.GC]::Collect()



