.$PSScriptRoot\..\..\Helpers\FileNameSupport\FileNameHelper.ps1

enum RegistryDefaultAppKey { 
    # HKEY_CURRENT_USER\Software\Classes
    HKCU_Software_Classes   
    # HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts
    HKCU_Explorer_FileExts
    # HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations
    HKCU_Assoc_UrlAssoc
}

function Export-AllDefaultAppsTxt {

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

    Export-DefaultAppsTxt -RKey ([RegistryDefaultAppKey]::HKCU_Software_Classes) -OutputFile $OutputFile
    Export-DefaultAppsTxt -RKey ([RegistryDefaultAppKey]::HKCU_Explorer_FileExts) -OutputFile $OutputFile
    Export-DefaultAppsTxt -RKey ([RegistryDefaultAppKey]::HKCU_Assoc_UrlAssoc) -OutputFile $OutputFile
}

function Export-DefaultAppsTxt {

    <#
        .SYNOPSIS
            Export default applications that have been set
    #>

    param(
        [Parameter(Mandatory=$True)]
        [RegistryDefaultAppKey] $RKey,
        $OutputFile
    )

    if (!$PSBoundParameters.ContainsKey('OutputPath')) {
        $OutputFile = "$HOME\DefaultAppAssociations.txt"
    }    

    $basePath = $null
    $entries = New-Object System.Collections.ArrayList

    switch($RKey) {
        HKCU_Software_Classes {
            $basePath = "HKCU:\Software\Classes"
        }
        HKCU_Explorer_FileExts {
            $basePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
        }
        HKCU_Assoc_UrlAssoc {
            $basePath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations"
        }
    }

    if ($null -eq $basePath) {
        return
    }

    
    # iterate over each extension
    Get-ChildItem -Path $basePath | ForEach-Object {
        
        $extension = $_.PSChildName
        $entries.Add("Key: $extension") | Out-Null
        $keyPath = "$basePath\$extension\UserChoice"
        $entries.Add("Registry path: $basePath\$extension") | Out-Null

        # Write-Host $keyPath
        if (Test-Path -Path $keyPath) {
            $assoc = Get-ItemProperty -Path $keyPath       
            $entries.Add("ProgId: $($assoc.Progid)") | Out-Null  
        }
        else {
            $entries.Add("ProgId: Not Set") | Out-Null
        }
        $entries.Add("`n" ) | Out-Null                         
    }

    $entries | Out-File -Append -FilePath $OutputFile | Out-Null
}

function Export-RegistryHKCU {
    <#
        .SYNOPSIS
        Export Entire registry
    #>

    [CmdletBinding()]
    param(
        $FilePath
    )

    if (!$PSBoundParameters.ContainsKey('FilePath')) {
        $FilePath = "$HOME\$(Get-DetailedName -Name "Registry_Backup").reg"
    }
    else {
        $FilePath = "$FilePath\$(Get-DetailedName -Name "Registry_Backup").reg"
    }

    $process = Start-Process -FilePath "reg.exe" -ArgumentList "export HKCU $($FilePath) /y" -PassThru 
    Write-Host "Exporting registry to $($FilePath), please wait..." 
    $process | Wait-Process 
    Write-Output "Registry export completed."
}

function Set-RegistryPermission {
    param (
        [string]$rootKey,
        [string]$key,
        [System.Security.Principal.SecurityIdentifier]$sid = 'S-1-5-32-545', # <-- admin,  S-1-5-32-545 = SID for Users group
        [bool]$recurse = $true
    )

    # Escalate privileges
    $import = '[DllImport("ntdll.dll")] public static extern int RtlAdjustPrivilege(ulong a, bool b, bool c, ref bool d);'
    $ntdll = Add-Type -MemberDefinition $import -Name NtDll -PassThru
    $privileges = @{ SeTakeOwnership = 9; SeBackup = 17; SeRestore = 18 }
    foreach ($i in $privileges.Values) {
        $null = $ntdll::RtlAdjustPrivilege($i, 1, 0, [ref]0)
    }

    # Function to get key permissions
    function Get-KeyPermissions {
        param (
            [string]$rootKey,
            [string]$key,
            [System.Security.Principal.SecurityIdentifier]$sid,
            [bool]$recurse,
            [int]$recurseLevel = 0
        )

        # Enable inheritance of permissions
        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetAccessRuleProtection($false, $false)
        $regKey = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($key, 'ReadWriteSubTree', 'TakeOwnership')        
        $regKey.SetAccessControl($acl)

        # Take ownership of the key            
        $acl.SetOwner($sid)
        $regKey.SetAccessControl($acl)
        Write-Info "New owner ($sid) for key ($key)"

        # Change permissions for the current key and propagate to subkeys
        if ($recurseLevel -eq 0) {
            $regKey = $regKey.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($sid, 'FullControl', 'ContainerInherit', 'None', 'Allow')
            $acl.ResetAccessRule($rule)
            $regKey.SetAccessControl($acl)
        }

        # Recursively repeat for subkeys
        if ($recurse) {
            foreach ($subKey in $regKey.OpenSubKey('').GetSubKeyNames()) {
                Get-KeyPermissions $rootKey ($key + '\' + $subKey) $sid $recurse ($recurseLevel + 1)
            }
        }
    }

    Get-KeyPermissions $rootKey $key $sid $recurse
}

Export-ModuleMember -Function Export-DefaultAppsTxt
Export-ModuleMember -Function Export-AllDefaultAppsTxt
Export-ModuleMember -Function Export-RegistryHKCU
Export-ModuleMember -Function Set-RegistryPermission
