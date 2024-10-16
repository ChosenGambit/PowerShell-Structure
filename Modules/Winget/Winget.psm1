
.$PSScriptRoot\initialize_winget.ps1

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
            Check-WingetVersion
        }

        if ($InstallWingetClient) {
            $ModulePath = Get-EnvModulePath
            Install-ModuleToDirectory -Name 'Microsoft.WinGet.Client' -Destination $ModulePath
        }

        if ($UpdatePowerShell) {
            Install-WingetApp -app "Microsoft.PowerShell"
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
            $FileAppNames = Get-Content -Path $File

            $AppNames = $AppNames + $FileAppNames


            Write-Info "List provided for installation:"
            $AppNames.Split(" ") | ForEach-Object {
               Write-Info " - $_ " 
            }
        }

    }
    PROCESS {

        foreach ($AppName in $AppNames) {

            Write-Info "Trying to install $AppName"
            $search = winget search $AppName

            if ($search -match "No package found") {
                Write-Error "Package not found $AppName"
            }
            else {
                #winget install --id $AppName --silent --force --accept-package-agreements --accept-source-agreements --source winget

                if ($LASTEXITCODE -eq 0) {
                    Write-Success "$AppName has been installed succesfully!"
                }
                else {
                    Write-Error "$AppName has failed to install"
                }
            }  
        }
    }

    END {
      
    }
}


Export-ModuleMember -Function Initialize-Winget
Export-ModuleMember -Function Install-WithWinget
