
# Change execution policy
#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

<#
    .SYNOPSIS
        
    .DESCRIPTION
        Prerequisite for Winget
#>
function Get-XAMLVersion {

    $fullName = ""
    $packageName = ""
    # check latest version online
    try {        
    
        $packageName = "microsoft.ui.xaml"
        Write-Info "Checking latest $packageName version"

        $url = "https://api.nuget.org/v3-flatcontainer/$packageName/index.json"
        $response = Invoke-RestMethod -Uri $url

        for ($i = $response.versions.Count-1; $i -gt 0; $i--) {
            $version = $response.versions[$i]
            if ($version -inotlike "*prerelease*") {
                break
            }
        }

        $fullName = $packageName+"."+$version
        Write-Info "Latest version = $fullName"
    }

    catch {
        Write-Error $_.Exception.Message
    }

    # check installed version
    try {
        Write-Info "Checking currently installed version"
        $found = $false
        $installedList = Get-AppxPackage | Where-Object { $_.Name -ilike "*$packageName*" } | Select-Object -ExpandProperty Name 
        foreach($installed in $installedList) {
            if ($installed -ilike "*$packageName*") {
                $found = $true
                Write-Info "Found $installed"
            }
        }
    }
    catch {
        Write-Error $_.Exception
    }
    
    # download and install microsoft.ui.xaml
    try {
        if (! $found) {
            Write-Info "Downloading $packageName"
            $url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/$version"
            $zip = "$HOME\Downloads\Microsoft.UI.Xaml.zip"
            Invoke-WebRequest -Uri $url -OutFile $zip

            # extract
            $extractPath = "$HOME\Downloads\Microsoft.UI.Xaml_cg_$version"
            Expand-Archive -Path $zip -DestinationPath $extractPath -Force -ErrorAction Continue

            $filePath = "$extractPath\tools\AppX\x64\Release"
            $uiXAMLFile = Get-ChildItem -Path $filePath -Filter "*.appx" | Select-Object -First 1
            $uiXAMLFullPath = Join-Path -Path $filePath -ChildPath $uiXAMLFile

            Write-Host "Trying to install $uiXAMLFullPath"
            Add-AppxPackage -Path $uiXAMLFullPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Verbose

            Start-Process -FilePath "wsreset.exe" -NoNewWindow -ErrorAction SilentlyContinue
        }
        else {
            Write-Alert "Did not install $packageName"
        }
    }
    catch {
        Write-Host $_.Exception
    }

  
}


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
    Add-AppxPackage -Path $HOME/Downloads/Microsoft.DesktopAppInstaller_wingetcg.msixbundle -ForceUpdateFromAnyVersion -ForceApplicationShutdown 
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

