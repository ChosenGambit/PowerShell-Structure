function Export-DefaultAppAssociationsXML {

    <#
        .SYNOPSIS
            Deployment Image Servicing and Management tool, export default app associations
            Then also backup this file
        .OUTPUTS
            DefaultAppAssoc.xml
    #>

    $path = "$($PSScriptRoot)\..\..\..\DefaultAppAssoc.xml"
    dism /Online /Export-DefaultAppAssociations:$path
    #Copy-Item -Path $path -Destination "..\..\..\$(Get-NiceName -Name "DefaultAppAssoc_Backup").xml"
    Write-Info "Created DefaultAppAssoc.xml"
}

function Import-DefaultAppAssociationXML {

    <#
        .SYNOPSIS
            Deployment Image Servicing and Management tool, import default app associations
            Uses 
        .INPUTS
            EditedAppAssoc.xml
    #>

    param() 

    if (! (Test-Path -Path  "$($PSScriptRoot)\..\..\..\EditedAppAssoc.xml")) {
        Write-Alert "Did not find EditedAppAssoc.xml"
        return
    }

    $path = "$($PSScriptRoot)\..\..\..\EditedAppAssoc.xml"
    dism /Online /Import-DefaultAppAssociations:$path
    Write-Info "Imported default apps"
    Write-Info "Removing cache, one moment..."
    Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    Write-Info "Restarting explorer.exe"
    Stop-Process -Name explorer -Force 
    Start-Process explorer
}

function Convert-DefaultAppAssociationsXML {

    <#
        .SYNOPSIS
            Alters DefaultAppsAssoc.xml
            Finds the Identifier (Extension)
            Replaces ProgId and ApplicationName with values from app_assoc.txt
        .NOTES
            The structure of the content of app_assoc.txt should be:
            Identifier;ProgId;ApplicationName (on each line)
            like: .pdf;Acrobat.Document.DC;Adobe Acrobat
        .INPUTS
            app_assoc.txt
            DefaultAppAssoc.xml
        .OUTPUTS
            EditedAppAssoc.xml
    #>

    if (! (Test-Path -Path "$($PSScriptRoot)\..\..\..\app_assoc.txt")) {
        Write-Error "Could not find app_assoc.txt, script stops here"       
        return
    }
    

    if (! (Test-Path -Path "$($PSScriptRoot)\..\..\..\DefaultAppAssoc.xml")) {
        Write-Error "Could not find DefaultAppAssoc.xml, script stops here"
        return
    }

    try {
        $default_list = Get-Content "$($PSScriptRoot)\..\..\..\app_assoc.txt"   
        
        $file = (Get-Content -Path "$($PSScriptRoot)\..\..\..\DefaultAppAssoc.xml")
        $xml = [xml] $file
    
        # assemble new xml document
        $edited_list = New-Object System.Collections.ArrayList
        # add first line 
        $edited_list.Add($file[0])
        $edited_list.Add("<$( $xml.DocumentElement.Name)>")
   
        $nodes = $xml.SelectNodes("//Association")    
        foreach ($node in $nodes) {
            $xmlElement = [System.Xml.XmlElement] $node
            $added = $false

            foreach ($line in $default_list) {
                $split = $line.Split(";")
                $Extension = $split[0]
                $ProgId = $split[1]
                $ApplicationName = $split[2]

                if ($xmlElement.Identifier -eq $Extension) {
                    $xmlElement.ProgId = $ProgId
                    $xmlElement.ApplicationName = $ApplicationName
                    $edited_list.Add($xmlElement.OuterXml)
                    $added = $true
                    break
                }
            }

            if (! $added) {
                $edited_list.Add($xmlElement.OuterXml)
            }
        }

        $edited_list.Add("</$( $xml.DocumentElement.Name)>")
        $edited_list | Out-File -FilePath "$($PSScriptRoot)\..\..\..\EditedAppAssoc.xml" 
        Write-Info "Created EditedAppAssoc.xml"
    }
    catch {
        Write-Alert "$($_)"
    }
}

<# Asks before setting this #>
function Confirm-SetDefaultApps {    

    $userInput = Read-Host "Please check if apps have been installed, continue with setting default apps? (Y/N)"

    if ($userInput.ToLower() -eq "y") {
        Export-DefaultAppAssociationsXML 
        Convert-DefaultAppAssociationsXML
        Import-DefaultAppAssociationXML
        Write-Info "Script completed"
    }
    else {
        Write-Info "Aborted by user"
    }
}

# start script
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\.."

Write-Info "--[Starting Default Apps @ $(Get-Date)]--" 

# asking user to continue
Confirm-SetDefaultApps