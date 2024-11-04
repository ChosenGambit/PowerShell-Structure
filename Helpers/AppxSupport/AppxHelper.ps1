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
function Find-LocalAppxPackage {

    [OutputType([bool])]
    param(
        $PackageName
    ) 

    # check installed msstore version
    try {          
        $found = $false
        $installedList = Get-AppxPackage | Where-Object { $_.Name -ilike "*$PackageName*" } | Select-Object -ExpandProperty Name 
        foreach($installed in $installedList) {
            if ($installed -ilike "*$PackageName*") {                    
                Write-Info "Found $installed locally (AppX)"                
                return $true
            }
        }
    }
    catch {
        Write-Error $_.Exception
    }     

    Write-Info "Did not find $PackageName (AppX)" 
    return $false
}

<#
    Returns either x64 or x32
#>
function Get-SystemArchitecture {

    [OutputType([string])] 
    param()

    $architecture = (Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture
    if ($architecture -ilike "*64*") {
        return "x64"
    } 
    Write-Host $architecture              
    return "x86"
}
