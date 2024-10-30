
<#
    .SYNOPSIS
        Add a new environment module path
        Path is the parent path
        Name is the new directory name
        Default = $HOME\PowerShellModules
    .DESCRIPTION
#>
function Add-EnvModulePath {

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

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = $HOME
    }
    if ([string]::IsNullOrEmpty($Name)) {
        $Name = "PowerShellModules"
    }
    
    # create new module path which we can access
     $newPath = Join-Path -Path $Path -ChildPath $Name

    if (! (Test-Path $newPath)) {
        New-Item -Name $Name -Path "$Path" -ItemType Directory -InformationAction SilentlyContinue | Out-Null
        Write-Info "Directory created: $newPath"
        
        # add env variable
        [Environment]::SetEnvironmentVariable("PSModulePath", "$env:PSModulePath;$newPath", [EnvironmentVariableTarget]::User)
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
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    # Is the module already installed?
    
    $fullModulePath = Join-Path -Path $Path -ChildPath $Name

    Write-Host "Checking existence of $fullModulePath"

    if (! (Test-Path $fullModulePath)) {
        # Install the module to the custom destination.
        Write-Info "Installing $Name"
        Find-Module -Name $Name -Repository 'PSGallery' | Save-Module -Path $Path
    }

    # Import the module from the custom directory.
    try {        
        Import-Module -FullyQualifiedName $fullModulePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Could not import $fullModulePath"
    }
    
    
}

Export-ModuleMember -Function Install-ModuleToDirectory
