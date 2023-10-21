<#
.SYNOPSIS    
    Disables settings that can wake Windows 11 from sleep/hibernation
.DESCRIPTION        
    Disables right for the system to wake up on itself
        - Disables fast startup
        - Disables wake timer rights in power plans
        - Disables rights of devices that can wake the system 
        - Disables maintenance wake up
        - Disables tasks (scheduler) that can wake the system
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Disable-SystemWake {

    [CmdletBinding()]
    param(
        [bool]$OmitDisablingFastStartUp = $False,
        [bool]$OmitDisablingPowerWake = $False,
        [bool]$OmitDisablingHardwareWake = $False,
        [bool]$OmitDisablingMaintenanceWake = $False,
        [bool]$OmitDisablingScheduledWake = $False
    )
    
    BEGIN {
        
        if (!$OmitDisablingFastStartUp) { 
            Write-Neutral 'Trying to turn off fast startup in registry'
            Disable-FastStartUp 
        }
         
        if (!$OmitDisablingPowerWake) { 
            Write-Neutral 'Trying to turn off wake timers in power configuration'
            Disable-PowerWake
        }
                         
        if (!$OmitDisablingHardwareWake) { 
            Write-Neutral 'Trying to turn off devices that can wake the system up'
            Disable-HardwareWake 
        }
       
       
        if (!$OmitDisablingMaintenanceWake) {
            Write-Neutral 'Trying to turn off maintenance wake up'
            Disable-MaintenanceWake 
        }
           
        
        if (!$OmitDisablingScheduledWake) { 
            Write-Neutral 'Trying to disabled scheduled tasks that can wake the system up'
            Disable-ScheduledWake 
        }
    }

    PROCESS {

    }

    END {
    
    }

}

Export-ModuleMember -Function Disable-SystemWake


<# 
## Fast startup 
#>
function Disable-FastStartUp {

    # Turn off fast startup
    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64);
        $key = $reg.OpenSubKey('SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Power', $true)
        if ($key.GetValue('HiberbootEnabled') -ne 0) {
            $key.SetValue('HiberbootEnabled', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
            Write-Success "Set to 0: $($key)" 
        }
        Write-Info "Already set to 0: $($key)"    
    }
    catch {
        Write-Error "Error: $($_) (Try with Administrator rights and wider ExecutionPolicy)"
    }
}

<# 
## Power 
#>
function Disable-PowerWake {
 
    $waketimers = powercfg -list | Select-String 'GUID'
 
    if ($waketimers -ne $null) {
        foreach($waketimer in $waketimers) {
            try {
                $guid = $waketimer -replace '^.*:\s+(\S+?)\s+.*$', '$1'
                powercfg -setdcvalueindex $guid SUB_SLEEP RTCWAKE 0 # battery
                powercfg -setacvalueindex $guid SUB_SLEEP RTCWAKE 0 # plugged in power
                Write-Success "$($waketimer) set to 0"
             }
            catch {
                  Write-Error "Error: $($_)"
            }
        }
    }
}

<# 
## Hardware 
#>
function Disable-HardwareWake { 
    
    $devices = powercfg -devicequery wake_armed
 
    # Iterate over devices
    if ($devices -ne $null) {
        foreach ($device in $devices) {
            if ($device -inotmatch 'NONE' -and $device -ne $null -and $device -ne '') {
                Write-Info "Found device: $($device)"
                try {
                    powercfg -devicedisablewake $device
                    Write-Success "Disabled waking for: $($device)"
                }
                catch {
                    Write-Error "Failed disabling waking for: $($device)"
                }
            }
            else {
                Write-Info 'No devices found that can wake the system up'
            }
        }
    }
}

<# 
## Maintenance 
#>
function Disable-MaintenanceWake {
 
    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64);
        $key = $reg.OpenSubKey('SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Schedule\\Maintenance', $true)
        if ($key.GetValue('WakeUp') -ne 0) {
            $key.SetValue('WakeUp', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
            Write-Success "Set to 0: $($key)" 
        }
        Write-Info "Already set to 0: $($key)"      
    }
    catch {
        Write-Error "Error: $($_) (Try with Administrator rights and wider ExecutionPolicy)"
    }
}

<# 
## Scheduled 
#>
function Disable-ScheduledWake {
         
    $tasks = Get-ScheduledTask | Where-Object {$_.Settings.WakeToRun -eq $true -and $_.State -ne 'Disabled'}
 
    if ($tasks -ne $null) {
        foreach ($task in $tasks) {  
            try {
                $task.Settings.WakeToRun = $false
                $task | Set-ScheduledTask
                Write-Success "Task succesfully changed: $($task)"
            }
            catch {
                Write-Error "Error while trying to change Task: $($task)"
            }
        }
    }
    else {
        Write-Info 'No tasks found in the scheduler that have to right to start up the computer'
    }
}
