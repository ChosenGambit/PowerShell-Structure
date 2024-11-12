Import-Module $PSScriptRoot\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\.."
Write-Info "--[Starting Clean Script @ $(Get-Date)]--" 

<#    
    .SYNOPSIS
        Clean up files that are used when initializing winget installer
        Cleans up files and folders with default names
    .DESCRIPTION
#>

function Remove-WingetInstallerFiles {

    Remove-Files -Path (Join-Path $HOME "Downloads") -Name "*Microsoft.UI.Xaml*"    
    Remove-Files -Path (Join-Path $HOME "Downloads") -Name "*Microsoft.DesktopAppInstaller_wingetcg.msixbundle*"
    Remove-Files -Path (Join-Path $HOME "Downloads") -Name "*Microsoft.VCLibs_cg.appx*"    
    Remove-Directories -Path "$($HOME)\Downloads" -Name "*Microsoft.UI.Xaml*"
    Remove-Directories -Path "$($HOME)\PowerShellModules" -Name "Microsoft.WinGet.Client"
    Remove-Directories -Path "$($HOME)" -Name "PowerShellModules"
    Write-Info "Cleanup done"
    Write-Alert "You can now close this window"
}


<#
    Removes folders recursively in path with specified name
#>
function Remove-Directories {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)] $Path,
        [Parameter(Mandatory=$True)] $Name
    )

    try {
        Write-Info "Trying to remove directory: $($Path)"
        Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -like $Name } | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        #Write-Error $_
        
        <#
        try {
            takeown /f $Path /a /r /d y
            icacls $Path /grant administrators:F
            Remove-Item -Path $Path -Recurse -Force 
        }
        catch {
          
        }
        #>
        
    }
}


<#
    Removes files with name
#>
function Remove-Files {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)] $Path,
        [Parameter(Mandatory=$True)] $Name
    )
    
    $files = Get-ChildItem -Path $path -File -Recurse -Force | Where-Object { $_.Name -like $Name } 

    foreach($file in $files) {

        try {
            Write-Alert "Removing file: $($file.FullName)"
            Remove-Item -Path $file.FullName -Recurse -Force
        }
        catch {
            Write-Error "Could not remove $($file.FullName)"
        }

    }
}


Remove-WingetInstallerFiles