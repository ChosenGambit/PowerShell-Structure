# for checking and installing Microsoft.UI.Xaml prequisite
.$PSScriptRoot\Install_MSUIXaml.ps1 

# for checking and installing VCLibs prequisite
.$PSScriptRoot\Install_VCLibs.ps1 

# for installing winget on the local system
.$PSScriptRoot\Install_Winget.ps1

# for installing apps using winget CLI
.$PSScriptRoot\Install_WingetApps.ps1

# Helper module that helps installing PowerShell modules from remote
Import-Module $PSScriptRoot\..\..\Helpers\ModuleSupport\PSModuleHelper.psm1


function Initialize-Winget {

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
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)] [bool]$InstallPrerequisites=$true,
        [Parameter(Mandatory=$false)] [bool]$InstallWinget=$true,
        [Parameter(Mandatory=$false)] [bool]$InstallWingetClient=$false,
        [Parameter(Mandatory=$false)] [bool]$UpdatePowerShell=$false     
        #[Parameter(Mandatory=$false)] [bool]$DefaultPS7=$false
    )

    BEGIN {

        if ($InstallPrerequisites -eq $true) {
            # prerequisite Microsoft.VCLibs
            Install-LatestVCLibs

            # prerequisite lib Microsoft.UI.Xaml, prefers NuGet version over Appx            
            Install-LatestMSUIXaml 
        }

        if ($InstallWinget -eq $true) {         

            # prefers appx version over nuget
            $installed = Install-LatestWinget
        }

        # works together with PSGallery version of winget
        if ($InstallWingetClient) {
            Add-EnvModulePath         
            Install-ModuleToDirectory -Name "Microsoft.WinGet.Client" -Path $(Join-Path -Path $HOME -ChildPath "PowerShellModules")
            Remove-DuplicateEnvPaths
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


function Install-WithWinget {

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

        # Merge file with appNames into one array
        if ($PSBoundParameters.ContainsKey('File')) {      
              
          try {
                $FileAppNames = Get-Content -Path $File -ErrorAction SilentlyContinue
                $AppNames = $AppNames + $FileAppNames                
            }
            catch {
                Write-Error "Could not find or read: $File"
            }            
        }

        Write-Info "List provided for installation:"

        # show what to install
        if ($AppNames -ne $null) {            
            $AppNames.Split(" ") | ForEach-Object {
                Write-Info " - $_ " 
            }
        }        
        else {
            Write-Alert "No apps provided for installation"
        }

        # check how to use winget as NuGet package or via cli
        $useCLI = $true
        try {
            $w = Get-Command winget -ErrorAction Stop # false when not available
            Write-Info "Using winget cli"
        }
        catch {
            $useCLI = $false
        }
        
    }
    PROCESS {

        foreach ($AppName in $AppNames) {

            # using winget via cli
            if ($useCLI) {                                            
                Use-CLIWingetInstall -AppName $AppName
            }

            else {
                #Use-PSWingetInstall -AppName $AppName         
            }
        }
    }

    END {
      
    }
}

function Update-WingetApps {

    <#
    .SYNOPSIS   
        Upgrades all winget apps as silently as possible when updates are found
    .DESCRIPTION        
    .INPUTS
    .OUTPUTS
    .EXAMPLE
    .LINK
    .NOTES
    #>

    try {
        winget upgrade -r --accept-package-agreements --accept-source-agreements --silent --nowarn --disable-interactivity --force
    }
    catch {
        Write-Error $_.Exception
    }
}


Export-ModuleMember -Function Initialize-Winget
Export-ModuleMember -Function Install-WithWinget
Export-ModuleMember -Function Update-WingetApps
