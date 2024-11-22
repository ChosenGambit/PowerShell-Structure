
# Function to take ownership and set permissions
function Set-RegistryPermission {
    param (
        [string]$rootKey,
        [string]$key,
        [System.Security.Principal.SecurityIdentifier]$sid = 'S-1-5-32-545', # SID for Users group
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

        # Take ownership of the key
        $regKey = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($key, 'ReadWriteSubTree', 'TakeOwnership')
        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($sid)
        $regKey.SetAccessControl($acl)

        # Enable inheritance of permissions
        $acl.SetAccessRuleProtection($false, $false)
        $regKey.SetAccessControl($acl)

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


function Revoke-RegistryPermission {
    param (
        [string]$rootKey,
        [string]$key,
        [System.Security.Principal.SecurityIdentifier]$sid = 'S-1-5-32-545', # SID for Users group
        [bool]$recurse = $true
    )

    # Function to reset key permissions
    function Reset-KeyPermissions {
        param (
            [string]$rootKey,
            [string]$key,
            [System.Security.Principal.SecurityIdentifier]$sid,
            [bool]$recurse,
            [int]$recurseLevel = 0
        )

        $systemSid = "S-1-5-18"

        # Open the registry key
        $regKey = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($key, 'ReadWriteSubTree', 'TakeOwnership')


        # Recursively reset permissions for subkeys
        # if ($recurse) {
        #     foreach ($subKey in $regKey.GetSubKeyNames()) {
        #         Reset-KeyPermissions $rootKey ($key + '\' + $subKey) $sid $recurse ($recurseLevel + 1)
        #     }
        # }

        $acl = $regKey.GetAccessControl()

        # Remove the access rule for the specified SID
        $acl.Access | ForEach-Object {
            if ($_.IdentityReference -eq $sid -or $_.IdentityReference -eq "BUILTIN\Users") {
                $acl.RemoveAccessRule($_)
                Write-Info "Remove access for $($_.IdentityReference) at: $key"
            }
        }

        # Set the owner back to SYSTEM
        $systemSid = New-Object System.Security.Principal.SecurityIdentifier($systemSid)
        $acl.SetOwner($systemSid)
        $regKey.SetAccessControl($acl)
    }

    Reset-KeyPermissions $rootKey $key $sid $recurse
}

