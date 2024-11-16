#
#Import-Module $PSScriptRoot\CG\_Global\Write\Write.psm1
#.$PSScriptRoot\CG\Modules\Winget\initialize_winget.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\.."

Write-Info "Using PowerShell version $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Info "--[Starting Prerequisites @ $(Get-Date)]--" 

# Test connection
$tnc = Test-NetConnection
if ($tnc.PingSucceeded -eq $False) {
    Write-Alert "Please check your internet connection and re-run the script"
    exit
}

# Initialize Winget Prerequisites
Initialize-Winget -InstallPrerequisites $true -InstallWinget $false
[System.GC]::Collect()



