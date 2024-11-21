.$PSScriptRoot\..\..\Helpers\FileNameSupport\FileNameHelper.ps1

.$PSScriptRoot\Registry_ExportDefaultApps.ps1

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

    $content = (Get-Content -Path $FilePath)

    foreach ($line in $content) {
        $split = $line.Split(";")
        $Extension = $split[0]
        $RegType = $split[1]
        $ProgId = $split[2]

        if ($RegType -eq "fileext") {
            $KeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"

            if (-not (Test-Path $KeyPath)) {
                New-Item -Path $KeyPath -Force
                Write-Info "Created new registry key: $KeyPath"
            }

            $cuKey = "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$Extension\UserChoice"

            try {
                $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($cuKey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::FullControl)

                if ($null -eq $key) {
                    Write-Error "key is null: $KeyPath"      
                    
                    try {
                        # try something else
                        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($cuKey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)                    
                        $acl = $key.GetAccessControl()
                        $rule = New-Object System.Security.AccessControl.RegistryAccessRule([System.Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl", "Allow")
                        $acl.SetAccessRule($rule)
                        $key.SetAccessControl($acl)
                        $key.Close()
                    }
                    catch {
                        Write-Error "Could not change registry permissions"
                    }
                }
                else {
                    $key.SetValue("ProgId", $ProgId, [Microsoft.Win32.RegistryValueKind]::String) 
                    $key.Close() 
                    Write-Info "Set default app to $ProgId for $Extension"
                }
            }
            catch {
                Write-Error $_
            }

            #Start-Process powershell -ArgumentList "-NoExit", "-Command", "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice /v ProgId /t REG_SZ /d $ProgId /f" -Verb RunAs
            #Write-Info "Set default app to $ProgId for $Extension"
            try {
                Set-ItemProperty -Path $KeyPath -Name ProgId -Value $ProgId -Force -ErrorAction Stop        
            }
            catch {
                Write-Error "Could not change registry key $ProgId"
            }
            
        }
        elseif ($RegType -eq "protocol") {
            $KeyPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$Extension\UserChoice"
            if (-not (Test-Path $KeyPath)) {
                New-Item -Path $KeyPath -Force
                Write-Info "Created new registry key: $KeyPath"
            }
            Set-ItemProperty -Path $KeyPath -Name ProgId -Value $ProgId -Force
            Write-Info "Set default app to $ProgId for $Extension"

        }
        else {
            Write-Info "RegType must either be fileext or protocol, did nothing with $Extension"
        }
    }
}


Export-ModuleMember -Function Export-AllDefaultApps 
Export-ModuleMember -Function Export-RegistryHKCU 
Export-ModuleMember -Function Set-DefaultApps 
