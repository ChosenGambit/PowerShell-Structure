[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\..\.."
Write-Info "--[Starting Change PowerConfig Script @ $(Get-Date)]--" 

powercfg /change monitor-timeout-dc 15
powercfg /change standby-timeout-dc 30
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0

Write-Info "Done changing power configurations"
