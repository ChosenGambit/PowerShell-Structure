<#
    .SYNOPSIS
        Check current winget version, downloads and installs when not found or outdated
    .DESCRIPTION
#>
function Install-LatestWinget {

    [OutputType([bool])]
    param()

    $latestVersion = Get-LatestWingetVersion
    $currentVersion = Get-CurrentWingetCLI

    if ($null -ne $latestVersion -and $null -ne $currentVersion) {

        $latestVersion = [version] $latestVersion
        $currentVersion = [version] $currentVersion

        if ($latestVersion -le $currentVersion) {
            Write-Info "The latest winget version seems to be installed"
            return $true
        }
    }
  
    Write-Info "Trying to install winget"
    
    $success = Add-WingetManualAppx
    
    #if (! $success) {
      # Add-WingetPSGallery
    #}

    return $success
}

<#
    .SYNOPSIS
        Check latest winget version
    .DESCRIPTION
#>
function Get-LatestWingetVersion {

    [OutputType([version])]
    param()

    try {

        $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"

        # Send a request to the GitHub API
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

        # Extract the latest version tag
        $latestVersion = $response.tag_name                  
        $latestVersion = [version] $latestVersion.TrimStart("v")
        Write-Info "Latest winget version = $latestVersion"
        
     }
     catch {
        Write-Alert "Could not find latest winget version, please check your internet connection ..."
     }

     return $latestVersion
}

<#
    Checks current winget version
#>
function Get-CurrentWingetCLI {
    [OutputType([version])]
    param()

    try {
        $currentVersion = winget -v
        $currentVersion = [version] $currentVersion.TrimStart("v")
        Write-Info "Current winget version = $currentVersion"
        return $currentVersion
    }
    catch {
        Write-Error "Could not find current winget version"
    }    

    return $currentVersion
}

<# 
    .SYNOPSIS
       Install winget via NuGet
    .DESCRIPTION
#>
function Add-WingetPSGallery {
    [OutputType([bool])]
    param()
    try {
        Write-Info "Trying to install winget via NuGet"
        Install-Package winget -Force  
        return $true
    }
    catch {

        try {
            Install-Package winget -Force -AllowClobber -ErrorAction SilentlyContinue 
            return $true
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }    
    return $false
}

<#
    .SYNOPSIS
       Download and install winget manually
    .DESCRIPTION
#>
function Add-WingetManualAppx {
    [OutputType([bool])]
    param()

    try {
        Write-Info "Trying to install winget via Microsoft website"
        Write-Info "Downloading winget from Microsoft website"
        Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile $HOME\Downloads\Microsoft.DesktopAppInstaller_wingetcg.msixbundle
        Start-Sleep -Seconds 2

        Add-AppxPackage -Path $HOME/Downloads/Microsoft.DesktopAppInstaller_wingetcg.msixbundle -ForceUpdateFromAnyVersion -ForceApplicationShutdown
        Start-Sleep -Seconds 2

        winget source update
        Start-Sleep -Seconds 2
        
        winget upgrade --id Microsoft.AppInstaller --accept-package-agreements --accept-source-agreements
        Start-Sleep -Seconds 2

        $wVersion = winget -v
        Write-Success "Winget version: $wVersion"
        return $true
    }

    catch {
        Write-Warning "There was a problem installing Winget as App"
        return $false
    }
    return $false
}
