function Install-LatestWinget {

    <#
    .SYNOPSIS
        Check current winget version, downloads and installs when not found or outdated
    .DESCRIPTION
    #>

    [OutputType([bool])]
    param(
        $FilePath
    )

    if (! $PSBoundParameters.ContainsKey('FilePath')) {
        $FilePath = "$HOME\Downloads"
    }

    $latestVersion = Get-LatestWingetVersion
    $currentVersion = Get-LocalWingetVersionCLI

    if ($null -ne $latestVersion -and $null -ne $currentVersion) {

        $latestVersion = [version] $latestVersion
        $currentVersion = [version] $currentVersion

        if ($latestVersion -le $currentVersion) {
            Write-Info "The latest winget version seems to be installed"
            return $true
        }
    }
  
    Write-Info "Trying to install winget"
    
    $success = Add-WingetManualAppx -FilePath $FilePath -LatestVersion $latestVersion
    
    #if (! $success) {
      # Add-WingetPSGallery
    #}

    return $success
}


function Get-LatestWingetVersion {

    <#
    .SYNOPSIS
        Check latest winget version
    .DESCRIPTION
    #>

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
function Get-LocalWingetVersionCLI {
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

function Add-WingetPSGallery {

    <# 
    .SYNOPSIS
       Install winget via NuGet
    .DESCRIPTION
    #>

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

function Add-WingetManualAppx {

    <#
    .SYNOPSIS
       Download and install winget manually
    .DESCRIPTION
    #>

    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)] $FilePath,
        [Parameter(Mandatory=$true)] $LatestVersion
    )

    try {

        $outFile = "$FilePath\Microsoft.DesktopAppInstaller_wingetcg_$LatestVersion.msixbundle"

        # download latest winget version from internet
        if (! (Test-Path -Path $outFile)) {
            Write-Info "Downloading winget from Microsoft website"
            Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $outFile                    
        }
        # found latest winget version local
        else {
            Write-Info "Found latest winget version locally ($outFile), now trying to install..."
        }

        Start-Sleep -Seconds 2
        Add-AppxPackage -Path $outFile -ForceUpdateFromAnyVersion -ForceApplicationShutdown
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
