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
    Remove-Directories -Path (Join-Path $HOME "Downloads") -Name "Microsoft.UI.Xaml"
    Remove-Directories -Path (Join-Path $HOME "PowerShellModules") -Name "Microsoft.WinGet.Client"
    Remove-Directories -Path $HOME -Name "PowerShellModules"    
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

    $directories = Get-ChildItem -Path $path -Directory -Recurse -Force | Where-Object { $_.Name -eq $Name } 

    foreach($dir in $directories) {

        try {
            Write-Alert "Removing directory: $($dir.FullName)"
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
        }
        catch {
             takeown /f $dir.FullName /a /d y
             icacls $dir.FullName /grant administrators:F
             Remove-Item -Path $dir.FullName -Recurse -Force 
        }

    }
}


<#
    Removes folders recursively in path with specified name
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
        }

    }
}
#takeown /f "C:\Users\Timon\PowerShellModules\Microsoft.WinGet.Client\1.9.2411\net48\Microsoft.WinGet.Client.Cmdlets.dll"
#icacls "C:\Users\Timon\PowerShellModules\Microsoft.WinGet.Client\1.9.2411\net48\Microsoft.WinGet.Client.Cmdlets.dll" /grant Administrators:F