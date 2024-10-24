.$PSScriptRoot\MSUIXaml_Installer.ps1
.$PSScriptRoot\Winget_Installer.ps1

Import-Module $PSScriptRoot\..\..\Dependencies\ModuleSupport\ModuleHelperDependency.psm1

<#
.SYNOPSIS    
    Initialized the module prerequisites
.DESCRIPTION        
    Use before using Install-WithWinget 
.INPUTS
   
.OUTPUTS
   
.EXAMPLE
   
.LINK
.NOTES
#>
function Initialize-Winget {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)] [bool]$InstallWinget=$true,
        [Parameter(Mandatory=$false)] [bool]$InstallWingetClient=$true,
        [Parameter(Mandatory=$false)] [bool]$UpdatePowerShell=$false        
        #[Parameter(Mandatory=$false)] [bool]$DefaultPS7=$false
    )

    BEGIN {
        if ($InstallWinget -eq $true) {
            # prerequisite lib Microsoft.UI.Xaml, prefers NuGet version over Appx
            Install-LatestMSUIXaml 

            # prefers appx version over nuget
            Install-LatestWinget
        }

        if ($InstallWingetClient) {
            $ModulePath = Add-EnvModulePath
            Remove-DuplicateEnvPaths
            Install-ModuleToDirectory -Name 'Microsoft.WinGet.Client' -Destination $ModulePath
        }

        if ($UpdatePowerShell) {
            Install-WithWinget -AppNames "Microsoft.PowerShell"
        }

        if ($DefaultPS7) {
            if ($PSVersionTable.PSVersion.Major -lt 7) {
                
            }            
        }
    }
}

<#
.SYNOPSIS   
    Install a app by using winget
    Use Initialize-Winget if this function does not work out of the box
   
.DESCRIPTION        
    
.INPUTS
   Install-WithWinget -AppNames "app1", "app2", "app3"
   Install-WithWinget -File "apps.txt"
.OUTPUTS
   winget installation
.EXAMPLE
   
.LINK
.NOTES
#>
function Install-WithWinget {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String[]]$AppNames,

        [Parameter(
            Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$File 
    )

    BEGIN {

        if ($PSBoundParameters.ContainsKey('File')) {            

            # Read app names from the file
            try {
                $FileAppNames = Get-Content -Path $File -ErrorAction SilentlyContinue
                $AppNames = $AppNames + $FileAppNames                
            }
            catch {
                Write-Error "Could not find or read: $File"
            }            
        }

        # show what to install
        Write-Info "List provided for installation:"
        $AppNames.Split(" ") | ForEach-Object {
            Write-Host " - $_ " 
        }

        # check how to use winget as NuGet package or via cli
        $useCLI = $true
        try {
            $w = Get-Command winget -ErrorAction Stop # false when not available
        }
        catch {
            $useCLI = $false
        }
        
    }
    PROCESS {

        foreach ($AppName in $AppNames) {

            # using winget via cli
            if ($useCLI) {
                            
                $search = winget search $AppName

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
                        Write-Error "$AppName has failed to install"
                    }
                }  
            }
            # using powershell
            else {
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
                        Write-Error "$AppName has failed to install"
                    }
                }
                else {
                    Write-Info "Package could not be found for $AppName, please be more specific"
                }             
            }
        }
    }

    END {
      
    }
}


Export-ModuleMember -Function Initialize-Winget
Export-ModuleMember -Function Install-WithWinget
