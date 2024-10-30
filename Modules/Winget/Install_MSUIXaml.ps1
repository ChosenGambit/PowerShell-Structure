# for finding appx packages locally
.$PSScriptRoot\..\..\Dependencies\AppxSupport\AppxHelper.ps1

<#
    .SYNOPSIS
        Tries to install microsoft.ui.xaml with nuget
        When that fails, it tries to install it manually
    .DESCRIPTION
        Prerequisite for Winget
#>
function Install-LatestMSUIXaml {

    # get latest version available online
    $latestVersion = Get-LatestMSUIXaml

    # check available local version (nuget package)
    $found = Find-LocalMSUIXaml -LatestVersion $latestVersion

    if (! $found) {
        # install Microsoft.UI.Xaml with NuGet
        $success = Add-MSUIXamlWithNuGet 
        if (! $success) {
            Write-Info "Failed to install via NuGet. Now trying to install Microsoft.UI.XAML manually (msstore)"
            Add-MSUIXamlManualAppx -LatestVersion $latestVersion
        }  
    }
}

<# 
    Returns true when found locally 
#>
function Find-LocalMSUIXaml { 

    [OutputType([bool])]
    param(
        [version] $LatestVersion
    )

    $installed = Get-Package Microsoft.UI.Xaml -ErrorAction SilentlyContinue
    if ($installed -is [Microsoft.PackageManagement.Packaging.SoftwareIdentity]) {

        $installedVersion = $installed.Version
        $installedName = $installed.Name
        Write-Info "Found $installedName $installedVersion locally (NuGet)"
            
        # when current equals latest version  
        if ($LatestVersion -ne $null -and $installedVersion -ne $null) {
            if ($LatestVersion -eq $installedVersion) {
                Write-Info "$($installedName) $($installedVersion) is up to date"
                return $True
            }
        }
    }
    else {
        
        $packageName = "Microsoft.UI.Xaml.$($LatestVersion.Major).$($LatestVersion.Minor)"
        $found = Find-LocalAppxPackage -PackageName $packageName

        if ($found) {
            Write-Info "$($packageName) is up to date"
            return $true
        }
        
    }
    Write-Info "Microsoft.UI.Xaml could not be found on the local system"
    return $false
}

<# 
    Checks for the latest microsoft.ui.xaml version online 
    Returns the version when found or null
#>
function Get-LatestMSUIXaml {

    [OutputType([version])]
    param()

    [version]$version = $null

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

        $fullName = $packageName+" "+$version
        Write-Info "Latest version = $fullName"        
    }

    catch {
        Write-Error $_.Exception.Message
    }
    return $version
}

<# 
    Helper to add Microsoft.UI.Xaml with NuGet 
#>
function Add-MSUIXamlWithNuGet {

    try {            
        Write-Info "Trying to install Microsoft.UI.Xaml"
        Install-PackageProvider -Name NuGet -Force
        Import-PackageProvider -Name NuGet -Force
        Unregister-PackageSource -Name "nuget.org" -ErrorAction SilentlyContinue
        Register-PackageSource -Name "nuget.org" -Location "https://www.nuget.org/api/v2" -ProviderName "NuGet" -Trusted    
        Install-Package "Microsoft.UI.Xaml" -Verbose
        return $True            
    }
    catch {
        Write-Error $_.Exception
        return $False        
    }
    return $False
}

<# 
    Helper to add Microsoft.UI.Xaml with manually downloading and installing Appx 
#>
function Add-MSUIXamlManualAppx {

    param(
        $LatestVersion
    )

    # download and install microsoft.ui.xaml
    try {
        $found = $false
        if (! $found) {
            Write-Info "Downloading $packageName"
            $url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/$LatestVersion"
            $zip = "$HOME\Downloads\Microsoft.UI.Xaml.zip"
            Invoke-WebRequest -Uri $url -OutFile $zip

            # extract
            $extractPath = "$HOME\Downloads\Microsoft.UI.Xaml_cg_$LatestVersion"
            Expand-Archive -Path $zip -DestinationPath $extractPath -Force -ErrorAction Continue
            Start-Sleep -Seconds 2

            $filePath = "$extractPath\tools\AppX\x64\Release"
            $uiXAMLFile = Get-ChildItem -Path $filePath -Filter "*.appx" | Select-Object -First 1
            $uiXAMLFullPath = Join-Path -Path $filePath -ChildPath $uiXAMLFile

            Write-Host "Trying to install $uiXAMLFullPath"
            Add-AppxPackage -Path $uiXAMLFullPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Verbose

            Start-Process -FilePath "wsreset.exe" -NoNewWindow -ErrorAction SilentlyContinue
        }
        else {
            Write-Info "Did not install $packageName"
        }
    }
    catch {
        Write-Error $_.Exception
        Write-Warning "Failed to install $packageName"
    }

}






