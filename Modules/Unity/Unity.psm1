$PackageJSONContent = @"
{
    "name": "com.[company-name].[package-name]",
    "version": "0.0.1",
    "displayName": "Package Example",
    "description": "This is an example package",
    "unity": "2019.1",
    "unityRelease": "0b5",
    "documentationUrl": "https://example.com/",
    "changelogUrl": "https://example.com/changelog.html",
    "licensesUrl": "https://example.com/licensing.html",
    "dependencies": {
        "com.[company-name].some-package": "1.0.0",
        "com.[company-name].other-package": "2.0.0"
    },
    "keywords": [
        "keyword for Package Manager Search API",
        "keyword2",
        "keyword3"
    ],
    "author": {
        "name": "Unity",
        "email": "unity@example.com",
        "url": "https://www.unity3d.com"
    }
}
"@

$LicenseContent = @"
Your Package Name
Copyright © [Your Name or Company] [Year]

Licensed under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)

SPDX License Identifier: CC-BY-NC-4.0

Full license text: https://creativecommons.org/licenses/by-nc/4.0/legalcode
"@


<#
.SYNOPSIS
    Create the folder and file structure for a New Unity Package, for the Unity Package Manager
    The structure will be made in the given Path
.DESCRIPTION
    https://docs.unity3d.com/6000.1/Documentation/Manual/CustomPackages.html
.PARAMETER Path
.EXAMPLE
.INPUTS
.OUTPUTS
.NOTES
.LINK
.COMPONENT
.ROLE
.FUNCTIONALITY
.EXTERNALHELP
#>

function New-UnityManagerPackage {

    param(
        [Parameter(Mandatory=$True)]
        [string]$Path
    )


    try {            
        
        if (Test-Path -Path $Path) {

            # Create directories

            $Dirs = @("Documentation~", "Editor", "Runtime", "Samples~", "Tests")
            $Dirs | ForEach-Object {
                New-Item -ItemType Directory -Path $Path -Name $_
            }

            New-Item -ItemType Directory -Path $(Join-Path -Path $Path -ChildPath "Tests") -Name "Editor"
            New-Item -ItemType Directory -Path $(Join-Path -Path $Path -ChildPath "Tests") -Name "Runtime"

                # Create files
            $Files = @("CHANGELOG.md", "LICENSE.md", "package.json", "README.md", "Third Party Notice.md")
            $Files | ForEach-Object {
                New-Item -ItemType File -Path $Path -Name $_
            }
            
            # Add content to files

            Add-Content -Path $(Join-Path -Path $Path -ChildPath "package.json") -Value $PackageJSONContent
            Add-Content -Path $(Join-Path -Path $Path -ChildPath "LICENSE.md") -Value $LicenseContent
        }
        else {
            Write-Host "Cannot find Path"
        }

    }
    catch {
        
        Write-Host $_.ScriptStackTrace
    }
    finally {
        
    }
}

Export-ModuleMember -Function New-UnityManagerPackage

<#
.SYNOPSIS
    Create the folder and file structure for a New Unity Asset Package
    The structure will be made in the given Path
.DESCRIPTION
    Asset Packages are meant for a compressed archive: .unitypackage
    https://docs.unity3d.com/2021.3/Documentation/Manual/AssetPackagesCreate.html
.PARAMETER Path
.EXAMPLE
.INPUTS
.OUTPUTS
.NOTES
.LINK
.COMPONENT
.ROLE
.FUNCTIONALITY
.EXTERNALHELP
#>
function New-UnityAssetPackage {

    param(
        [Parameter(Mandatory=$True)]
        [string]$Path
    )

    try {            
        
        if (Test-Path -Path $Path) {

            # Create directories

            $Dirs = @("Documentation", "Materials", "Prefabs", "Samples", "Scenes", "Scripts", "Textures")
            $Dirs | ForEach-Object {
                New-Item -ItemType Directory -Path $Path -Name $_
            }

            # Create files

            New-Item -Path $Path -ItemType File -Name "LICENSE.md"
            New-Item -Path $Path -ItemType File -Name "README.md"
            
            # Add content to files

            Add-Content -Path $(Join-Path -Path $Path -ChildPath "LICENSE.md") -Value $LicenseContent
        }
        else {
            Write-Host "Cannot find Path"
        }

    }
    catch {
        Write-Host $_.ScriptStackTrace
    }
    finally {
        
    }
}

Export-ModuleMember -Function New-UnityAssetPackage