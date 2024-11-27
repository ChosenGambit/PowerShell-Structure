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

Export-ModuleMember -Function Export-DefaultAppsTxt
Export-ModuleMember -Function Export-AllDefaultAppsTxt
Export-ModuleMember -Function Export-RegistryHKCU
