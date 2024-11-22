.$PSScriptRoot\..\..\Helpers\FileNameSupport\FileNameHelper.ps1

.$PSScriptRoot\Registry_ExportDefaultApps.ps1

.$PSScriptRoot\Registry_Permission.ps1

function Export-RegistryHKCU {
    <#
        .SYNOPSIS
        Export Entire registry
    #>

    [CmdletBinding()]
    param(
        $Path
    )

    if (!$PSBoundParameters.ContainsKey('Path')) {
        $FilePath = "$HOME\$(Get-DetailedName -Name "Registry_Backup").reg"
    }
    else {
        $FilePath = "$Path\$(Get-DetailedName -Name "Registry_Backup").reg"
    }

    $process = Start-Process -FilePath "reg.exe" -ArgumentList "export HKCU $($FilePath) /y" -PassThru 
    Write-Host "Exporting registry to $($FilePath), please wait..." 
    $process | Wait-Process 
    Write-Output "Registry export completed."
}

function Export-AllDefaultApps {

    <#
        .SYNOPSIS
        Export list of all default apps set in Windows
    #>

    param(
        $OutputPath
    )

    if (!$PSBoundParameters.ContainsKey('OutputPath')) {
        $OutputFile = "$HOME\DefaultAppAssociations.txt"
    }            

    New-Item -Path $OutputFile -ItemType File -Force

    Export-DefaultApps -RKey ([RegistryDefaultAppKey]::HKCU_Software_Classes) -OutputFile $OutputFile
    Export-DefaultApps -RKey ([RegistryDefaultAppKey]::HKCU_Explorer_FileExts) -OutputFile $OutputFile
    Export-DefaultApps -RKey ([RegistryDefaultAppKey]::HKCU_Assoc_UrlAssoc) -OutputFile $OutputFile
}

function Set-DefaultApps {

    <#
        .SYNOPSIS
            Set default apps from file
        .NOTES
            The structure of the content of file should be:
            Identifier;registryType;ProgId (on each line)
            like: .pdf;fileext;Acrobat.Document.DC

            RegistryType can be: fileext or protocol
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        $FilePath
    ) 

    try {
        $content = (Get-Content -Path $FilePath -ErrorAction Stop) 
    }
    catch {
        Write-Error $_.Exception.Message
    }    

    foreach ($line in $content) {
        $split = $line.Split(";")
        $Extension = [string] $split[0]
        $RegType = [string] $split[1]
        $ProgId = [string] $split[2]

        # Change default program for file extension
        if ($RegType -eq "fileext") {
            $FullKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"
            $subKey = "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"                    
        }
        # Change default program for protocol
        elseif ($RegType -eq "protocol") {
            $FullKeyPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Extension\UserChoice"
            $subKey = "Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Extension\UserChoice"
        }
        else {
            Write-Info "RegType must either be fileext or protocol, did nothing with $Extension"
        }

        if ($null -ne $subKey -and $null -ne $FullKeyPath) {

            # create register key because it didn't exist at all
            if (-not (Test-Path $FullKeyPath)) {
                New-Item -Path $FullKeyPath -Force
                Write-Info "Created new registry key: $FullKeyPath"
            }      

            # set ownership to user group and change default app
            try {                                            
                Set-RegistryPermission -rootKey 'CurrentUser' -key $subKey 
                Set-ItemProperty -Path $FullKeyPath -Name ProgId -Value "$ProgId" -Force -ErrorAction Stop   
                Write-Info "Registry key $FullKeyPath ProgId set to $ProgId"  
            }
            catch {
                Write-Alert "Could not change registry key $Extension ; $RegType ; $ProgId"
                Write-Error $_
            }  

            # set ownership to system (local system)
            try {                
                Revoke-RegistryPermission -rootKey 'CurrentUser' -key $subKey 
            }
             catch {
                Write-Alert "Could not revoke registry permissions $Extension ; $RegType ; $ProgId"
                Write-Error $_
            }  
        }
        else {
            Write-Alert "KeyPath or subKey were not set, nothing happend"
        }
    }
}

Export-ModuleMember -Function Export-AllDefaultApps 
Export-ModuleMember -Function Export-RegistryHKCU 
Export-ModuleMember -Function Set-DefaultApps 
