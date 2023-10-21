<#
.SYNOPSIS    
    Unzip files to their own directory
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Expand-ZipFiles {

    [CmdletBinding()]
    param(
        [Parameter(
            Position=0, 
            Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$Path,

        [Parameter(
            Mandatory=$false
        )]
        [String]$Recurse = $false,

        [Parameter(
            Mandatory=$false
        )]
        [boolean]$With7z = $false

    )

    BEGIN {

         if ($Path -eq $null -or $Path -eq "") {
            $Path = Get-Location 
        }     
    }

    PROCESS {

        $Params = @{                     
            Filter = "*.zip" 
            Path = $Path
        }
        if ($Recurse) {
            $Params.Recurse = $true
        }

        Write-Info "Starting to find and unzip"
        Write-Output $Params

        $Test = Get-ChildItem @Params
        Write-Host "Found $($Test.Count)"
                     
        try {

            Get-ChildItem @Params | ForEach-Object {

                Write-Info "Found $($_.FullName)"

                if ($With7z) {
                    [String]$NewDirName = Split-Path -Path "$($_.FullName)"
                    $NewDirName += "\$($_.BaseName)"
                    $Command = "7z x -o`"$NewDirName`" `"$($_.FullName)`""
                    Invoke-Expression $command -ErrorAction Stop
                }
                else {
                    [String]$NewDirName = Split-Path -Path "$($_.FullName)"
                    $NewDirName += "\$($_.BaseName)"
                    Expand-Archive -Path $_.FullName -DestinationPath $NewDirName -Force -ErrorAction Stop 
                }
            }

        }
        catch {
            Write-Error "Error: $($_)"
        }
    }
    
    END {

    }
}

Export-ModuleMember -Function Expand-ZipFiles

