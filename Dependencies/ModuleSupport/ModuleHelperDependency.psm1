
<#
    .SYNOPSIS
        Add a new environment module path
        Path is the parent path
        Name is the new directory name
        Default = $HOME\PowerShellModules
    .DESCRIPTION
#>
function Add-EnvModulePath {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$Path,

        [Parameter(
            Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$Name 
    )

    BEGIN {
        if ([string]::IsNullOrEmpty($Path)) {
            $Path = $HOME
        }
        if ([string]::IsNullOrEmpty($Name)) {
            $Name = "PowerShellModules"
        }
    }
    PROCESS {
        # create new module path which we can access
         $newPath = Join-Path -Path $Path -ChildPath $Name

        if (-not (Test-Path $newPath)) {
            New-Item -Name $Name -Path "$Path" -ItemType Directory
            Write-Host -ForegroundColor Cyan "Directory created: $newPath"
        
            # add env variable
            [Environment]::SetEnvironmentVariable("PSModulePath", "$env:PSModulePath;$newPath", [EnvironmentVariableTarget]::User)
        }
    }
    END {
        return $newPath
    }            
}

Export-ModuleMember -Function Add-EnvModulePath

<#
    .SYNOPSIS
       Removes duplicate environment module paths
    .DESCRIPTION
#>
function Remove-DuplicateEnvPaths {
    
    Write-Info "Removing duplicate environment paths"
    $paths = $Env:PSModulePath.Split(';')

    # Remove duplicate paths
    $uniquePaths = $paths | Select-Object -Unique

    # Join the unique paths back into a single string
    $Env:PSModulePath = [string]::Join(';', $uniquePaths)
}

Export-ModuleMember -Function Remove-DuplicateEnvPaths


<#
    .SYNOPSIS
        Installs a specific PowerShell module from the PSGallery to Destination
    .DESCRIPTION
#>
function Install-ModuleToDirectory {

    [CmdletBinding()]
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
        # Import the module from the custom directory.
        Import-Module -FullyQualifiedName (Join-Path $Destination $Name)
    }
    else {
        Write-Info "$Name is already installed"
        Import-Module $Name #-Verbose
    }

    
}

Export-ModuleMember -Function Install-ModuleToDirectory
