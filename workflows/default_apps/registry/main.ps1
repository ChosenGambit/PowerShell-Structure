[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\..\.."
Write-Info "--[Starting Default Apps Workflow Script @ $(Get-Date)]--" 

function Confirm-SetDefaultApps {    

    $userInput = Read-Host "Please check if apps have been installed, continue with setting default apps? (Y/N)"

    if ($userInput.ToLower() -eq "y") {        
        Export-RegistryHKCU -Path "$($PSScriptRoot)\..\..\..\.."
        Set-DefaultApps -FilePath "$($PSScriptRoot)\..\..\..\..\def_app_reg.txt" 

        Write-Info "Restarting explorer.exe"
        # Stop-Process -Name explorer -Force 
        # Start-Process explorer
        [System.GC]::Collect()
    }
    else {
        Write-Info "Aborted by user"
    }
}

Confirm-SetDefaultApps