<#
.SYNOPSIS    
    Search in Word documents and return path if searchkey has been found
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Search-InWordDoc {

    [CmdletBinding()]
    param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$SearchKey,

        [Parameter(
            Mandatory=$False, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [String]$StartPath = $null,   
        
        [Parameter(
            Mandatory=$False, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]     
        [bool]$Recurse = $true
    )

    BEGIN {

        if ($StartPath -eq $null -or $StartPath -eq "") {
            $StartPath = Get-Location 
        }        
    }

    PROCESS {

        try {

            Write-Info "Searching for '$($SearchKey)', at path $($StartPath), Recurse = $($Recurse)"

            if (Test-Path $StartPath) {

                $Params = @{                     
                    Include = "*.doc","*.docx" 
                    Path = $StartPath+'\*'
                }

                if ($Recurse) {
                    $Params.Recurse = $true
                }

                # check if word is installed
                $WordVersion = (New-Object -ComObject word.application).version

                if ($WordVersion) {

                    Write-Info "Starting search for Word documents"
                    $Files = Get-ChildItem @Params
                    Write-Info "Found $($Files.Count) files"       
                    
                    # track matches
                    $Matches = 0             

                    $Word = New-Object -ComObject word.application   
                     
                    foreach ($File in $Files) {

                        if ($VerbosePreference) { Write-Neutral "WordDoc Found -> $($File.fullname)" }

                        $Doc = $Word.documents.open($File.fullname)

                        # check if we can find a match in a doc
                        if ($Doc.content.find.execute($SearchKey)) {
                            Write-Success "Found match in $($File.fullname)"
                            $Matches++
                        }
                        else {
                            if ($VerbosePreference) { Write-Info "No match in -> $($File.fullname)" }
                        }

                        $Doc.close()
                    }

                    Write-Neutral "Done searching $($Files.Count) files, found $($Matches) matches"
                }
                else {
                    Write-Error "Cannot find Microsoft Word on the system"
                }        
            }
            else {
                Write-Error "Path provided is not valid."
            }
        }
        catch {
            Write-Error "Error: $($_)"
            
        }
    }

    END {
    }
}

Export-ModuleMember -Function Search-InWordDoc

