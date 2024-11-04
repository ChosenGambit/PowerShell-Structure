# Helps with the installation step of winget

<# Install with Winget using CLI #>
function Use-CLIWingetInstall {

    param(
        [Parameter(Mandatory=$True)]
        [String]$AppName
    )

    $search = winget search $AppName --accept-source-agreements --disable-interactivity

    if ($search -match "No package found") {
        Write-Error "Package not found $AppName"
    }
    else {                

        Write-Info "Trying to install $AppName"
               
        winget install --id $AppName --silent --force --accept-package-agreements --accept-source-agreements --source winget

        if ($LASTEXITCODE -eq 0) {
            Write-Success "$AppName has been installed succesfully!"
        }
        else {
            Write-Error "$AppName has failed to install ($($LASTEXITCODE))"
        }
    }  
}

<# Install with Winget using PowerShell #>
function Use-PSWingetInstall {

    param(
        [Parameter(Mandatory=$True)]
        [String]$AppName
    )

    $packages = Find-WingetPackage -Id $AppName -Source winget

    if (!$packages) {
        Write-Error "No Packages found for $AppName"
        continue # next AppName
    }

    $toInstall = $null
    Write-Info "Searching for $AppName"
    foreach ($package in $packages) {
        if ($package.Id -eq $AppName) {
            Write-Info "Found $AppName"
            $toInstall = $package.Id
            break
        }
    }

    if ($toInstall -ine $null) {

        Write-Info "Trying to install $AppName"
        $result = Install-WinGetPackage -Id $toInstall

        if ($result.InstallerErrorCode -eq 0) {
            Write-Success "$AppName has been installed successfully!"
        } else {
            Write-Error "$AppName has failed to install ($($result.InstallerErrorCode))"
        }
    }
    else {
        Write-Info "Package could not be found for $AppName"
    }    
}