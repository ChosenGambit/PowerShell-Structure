
# Change execution policy
#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
<#
    .SYNOPSIS
        Check current winget version, downloads and installs when not found or outdated
    .DESCRIPTION
#>
function Get-WingetVersion {

    try {

        Write-Info "Checking latest winget version ... "

        $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"

        # Send a request to the GitHub API
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

        # Extract the latest version tag
        $latestVersion = $response.tag_name    
        $latestVersion = [version] $latestVersion.TrimStart("v")
        Write-Info "Latest winget version = $latestVersion"

        $currentVersion = winget -v
        $currentVersion = [version] $currentVersion.TrimStart("v")
        Write-Info "Current winget version = $currentVersion"

        if ($latestVersion -gt $currentVersion) {
            Get-WingetRemote
        }

     }
     catch {
        Get-WingetRemote
     }
}

<#
    .SYNOPSIS
       Download and install winget
    .DESCRIPTION
#>
function Get-WingetRemote {
    Write-Info "Downloading winget from Microsoft website"
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile $HOME/Downloads/Microsoft.DesktopAppInstaller_wingetcg.msixbundle
    Add-AppxPackage -Path $HOME/Downloads/Microsoft.DesktopAppInstaller_wingetcg.msixbundle
    winget upgrade --id Microsoft.AppInstaller

    $wVersion = winget -v
    Write-Success "Winget version: $wVersion"
}

<#
    .SYNOPSIS
        Get Environment module path that is in program files
        If not, creates a new dir in $HOME
    .DESCRIPTION
#>
function Get-EnvModulePath {

    #$Env:PSModulePath += ";C:\Program Files (x86)\WindowsPowerShell\Modules"
    $paths = $Env:PSModulePath.Split(';')

    # Remove duplicate paths
    $uniquePaths = $paths | Select-Object -Unique

    # Join the unique paths back into a single string
    $Env:PSModulePath = [string]::Join(';', $uniquePaths)

    $newPath = "PowerShellModules"
    # create new module path which we can access
    if (-not (Test-Path "$HOME\$newPath")) {
        New-Item -Name "$newPath" -Path "$HOME" -ItemType Directory
        Write-Host -ForegroundColor Cyan "Directory created: $HOME\$newPath"
        
        # add env variable
        [Environment]::SetEnvironmentVariable("PSModulePath", "$env:PSModulePath;$HOME\$newPath", [EnvironmentVariableTarget]::User)
    }
    return "$HOME\$newPath"
}

<#
    .SYNOPSIS
        Installs a specific PowerShell module from the PSGallery to Destination
    .DESCRIPTION
#>
function Install-ModuleToDirectory {

    [CmdletBinding()]
    [OutputType('System.Management.Automation.PSModuleInfo')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [ValidateNotNullOrEmpty()]
        $Destination
    )

    # Is the module already installed?
    if (-not (Test-Path (Join-Path $Destination $Name))) {
        # Install the module to the custom destination.
        Write-Info "Installing $Name"
        Find-Module -Name $Name -Repository 'PSGallery' | Save-Module -Path $Destination
    }
    else {
        Write-Info "$Name is already installed"
    }

    # Import the module from the custom directory.
    Import-Module -FullyQualifiedName (Join-Path $Destination $Name)

}

