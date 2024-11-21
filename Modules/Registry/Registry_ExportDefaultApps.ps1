
enum RegistryDefaultAppKey { 
    # HKEY_CURRENT_USER\Software\Classes
    HKCU_Software_Classes   
    # HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts
    HKCU_Explorer_FileExts
    # HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations
    HKCU_Assoc_UrlAssoc
}

function Export-DefaultApps {

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
