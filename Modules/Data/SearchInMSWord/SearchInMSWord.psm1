<#
.SYNOPSIS    
    Search in Word documents and return path if searchkey has been found
.DESCRIPTION        
    Search for a string of text inside Word documents. Will use current 
    path when no path is provided.
.INPUTS
    - [string] SearchKey: The string to search in the documents
    - [string] Path: The startpath to search
    - [bool] Recurse: Search in underlying directories
.OUTPUTS
    - A list with paths of documents with the searchkey 
.EXAMPLE
    Search-InWordDoc -Path "C:\MyDir" -SearchKey "MyString"
    Search-InWordDoc -SearchKey "MyString" -Recurse $False
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
        [String]$Path = $null,   
        
        [Parameter(
            Mandatory=$False, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]     
        [bool]$Recurse = $true
    )

    BEGIN {

        
        if ($Path -eq $null -or $Path -eq "") {
            $Path = Get-Location 
        }       
        
        # Add verbose options
        if ($PSBoundParameters['Verbose']) {
            $VerbosePreference = "Continue"
        } else {
            $VerbosePreference = "SilentlyContinue"
            $ErrorActionPreference = 'SilentlyContinue'
        }    

        # check if word is installed
        $WordVersion = (New-Object -ComObject word.application).version

        if ($WordVersion) {          
            $Word = New-Object -ComObject word.application 
        }  
        else {
            Write-Error "Cannot find Microsoft Word on the system, script will exit"
            exit
        }
    }

    PROCESS {

        Write-Info "Searching for '$($SearchKey)', at path $($Path), Recurse = $($Recurse)"

        if (Test-Path $Path) {

            $Params = @{                     
                Include = "*.doc","*.docx" 
                Path = $Path+'\*'
            }

            if ($Recurse) {
                $Params.Recurse = $true
            }              
                
            Write-Info "Starting search for Word documents"
            $Files = Get-ChildItem @Params
            Write-Info "Found $($Files.Count) files"       
                    
            # track matches
            $Matches = 0     
                     
            foreach ($File in $Files) {

                try {

                    Write-Verbose "WordDoc Found -> $($File.fullname)"     
                    $Doc = $Word.documents.open($File.fullname, $false, $true)

                    # check if we can find a match in a doc
                    if ($Doc.content.find.execute($SearchKey)) {
                        Write-Success "Found match in $($File.fullname)"
                        $Matches++
                    }
                    else {
                        Write-Verbose "No match in -> $($File.fullname)" 
                    }
                }
                  catch {
                    Write-Error "Error while searching in document: $($File.fullname)"            
                }
                if ($null -ne $Doc) {
                    $Doc.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges)
                }                
            }
        }
            
        Write-Neutral "Done searching $($Files.Count) files, found $($Matches) matches"
             
        else {
            Write-Error "Path provided is not valid."
        }
    }


    END {

        if ($null -ne $Doc) {
            $Doc.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges)
        }

        if ($null -ne $Word) {
            $Word.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word) | Out-Null
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    }
}

Export-ModuleMember -Function Search-InWordDoc

