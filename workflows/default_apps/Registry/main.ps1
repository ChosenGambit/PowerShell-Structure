<#

    Makes use of third party PS Script:
    https://github.com/DanysysTeam/PS-SFTA
    https://github.com/DanysysTeam/PS-SFTA/archive/refs/heads/master.zip

#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\..\.."
Write-Info "--[Starting Default Apps Workflow Script @ $(Get-Date)]--" 

function Confirm-SetDefaultApps {    

    $userInput = Read-Host "Please check if apps have been installed, continue with setting default apps? (Y/N)"

    if ($userInput.ToLower() -eq "y") {        

        $FileName = "PS-SFTA.zip"
        $PS_SFTA_github = "https://github.com/ChosenGambit/PS-SFTA/archive/refs/heads/master.zip"       
        $DependenciesPath = "$PSScriptRoot\..\..\..\..\Dependencies"
        $FullZipPath = "$DependenciesPath\$FileName"
        $unzippedPath = "PS-SFTA-master"
        #$PS_SFTA_commits = "https://api.github.com/repos/DanysysTeam/PS-SFTA/commits"

        if (! (Test-Path -Path "$DependenciesPath\$FileName")) {
            Write-Info "Downloading PS-SFTA"
            Invoke-WebRequest -Uri $PS_SFTA_github -OutFile $FullZipPath                        
        }

        Start-Sleep -Seconds 2

        if (! (Test-Path -Path "$DependenciesPath\$unzippedPath")) {
            Write-Info "Extracting PS-SFTA"
            Expand-Archive -Path $FullZipPath -DestinationPath $DependenciesPath -Force -ErrorAction Continue
        }        

        Start-Sleep -Seconds 2

        Export-RegistryHKCU -FilePath "$($PSScriptRoot)\..\..\..\.."

        # load thirdparty script
        Write-Info "Loading PS-SFTA"
        .$("$DependenciesPath\$unzippedPath\SFTA.ps1")
                
        # read text file
        try {
            Write-Info "Loading def_app_reg.txt"
            $content = (Get-Content -Path "$PSScriptRoot\..\..\..\..\def_app_reg.txt" -ErrorAction Stop) 
        }
        catch {
            Write-Error "Could not open def_app_reg.txt"
            return
        }    

        # iterate over each line
        foreach ($line in $content) {
            $split = $line.Split(";")
            $Extension = [string] $split[0]
            $RegType = [string] $split[1]
            $ProgId = [string] $split[2]

            # Change default program for file extension                        
            if ($RegType -eq "fileext") {
                Write-Info "Extension: Trying to set $ProgId to $Extension"
                try {
                    $FullKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"
                    $ExtensionKeyPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"

                    # create register key is it does not exist
                    if (-not (Test-Path $FullKeyPath)) {
                        New-Item -Path $FullKeyPath -Force
                        Write-Info "Created new registry key: $FullKeyPath"
                    }   

                    Set-RegistryPermission -rootKey 'CurrentUser' -key $ExtensionKeyPath 
                    Set-FTA -ProgId $ProgId -Extension $Extension -Verbose
                }
                catch {
                    Write-Error $_
                }                
            }
            # Change default program for protocol
            elseif ($RegType -eq "protocol") {
                Write-Info "Protocol: Trying to set $ProgId to $Extension"
                try {
                    
                    $FullKeyPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Extension\UserChoice"
                    $ExtensionKeyPath = "Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Extension\UserChoice"

                    # create register key is it does not exist
                    if (-not (Test-Path $FullKeyPath)) {
                        New-Item -Path $FullKeyPath -Force
                        Write-Info "Created new registry key: $FullKeyPath"
                    }   
                    
                    Set-RegistryPermission -rootKey 'CurrentUser' -key $ExtensionKeyPath 
                    Set-PTA -ProgId $ProgId -Protocol $Extension -Verbose
                }
                catch {
                    Write-Error $_
                }
                
            }
            else {
                Write-Info "RegType must either be fileext or protocol, did nothing with $Extension"
            }            
        }

        # output status quo
        Write-Status "Current registry settings: "
        foreach ($line in $content) {
            $split = $line.Split(";")
            $Extension = [string] $split[0]
            $RegType = [string] $split[1]
            $ProgId = [string] $split[2]
            
            if ($RegType -eq "fileext") {
                Write-Status " --> $Extension = $(Get-FTA -Extension $Extension)"
            }
            # Change default program for protocol
            elseif ($RegType -eq "protocol") {
                Write-Status " --> $Extension = $(Get-PTA -Protocol $Extension)"
            }
        }

        [System.GC]::Collect()
    }
    else {
        Write-Info "Aborted by user"
    }
}

Confirm-SetDefaultApps

@("Goodbye !", "Bye Bye !", "Thank you !") | Get-Random | Write-BigWord -RandomColors "letter"

