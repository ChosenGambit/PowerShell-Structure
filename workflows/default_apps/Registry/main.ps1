[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Import-Module $PSScriptRoot\..\..\..\Root.psm1
Initialize-Modules
$global:WriteOutput = $True
$global:WriteToLogFile = $True
$global:LogFilePath = "$PSScriptRoot\..\..\..\.."
Write-Info "--[Starting Turning off UCPD Script @ $(Get-Date)]--" 

# First we turn of UCPD and reboot
# Disable: User Choice Protection Driver (UCPD)
try {
    Set-Service -Name UCPD -StartupType Disabled
    Write-Info "Service UCPD disabled"
}
catch {
    Write-Error "Error Disabling Service UCPD: $_"
}

# Disable scheduled task to enable the ucpd
try {
    Disable-ScheduledTask -TaskName "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity"
    Write-Info "Scheduled UCPD velocity disabled"
}
catch {
    Write-Error "Error Disabling UCPD Scheduled Task: $_"
}

#Continu after reboot
# Define the script path and task name
$scriptPath = "$PSScriptRoot\edit_registry.ps1"
$taskName = "CG_Edit_Registry_Script4"

try {
    $ourTask = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    if ($ourTask) {
        Unregister-ScheduledTask -TaskName $ourTask -Confirm:$false 
    }    
}
catch {
    Write-Info "No task found with name: $taskName"
}

# Create a scheduled task to run the script after reboot
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoExit -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(60) #-AtStartup 
# $trigger.StartBoundary = [DateTime]::Now.AddSeconds(10).ToString("yyyy-MM-dd'T'HH:mm:ss")
# $trigger.EndBoundary = [DateTime]::Now.AddMinutes(3).ToString("yyyy-MM-dd'T'HH:mm:ss")
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel "Highest"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Compatibility Win8 #-DeleteExpiredTaskAfter (New-TimeSpan -Seconds 30) 
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

$ourTask = Get-ScheduledTask -TaskName $taskName 
$OurTask.Triggers[0].StartBoundary = [DateTime]::Now.AddSeconds(60).ToString("yyyy-MM-dd'T'HH:mm:ss")
$OurTask.Triggers[0].EndBoundary = [DateTime]::Now.AddMinutes(30).ToString("yyyy-MM-dd'T'HH:mm:ss")
$OurTask.Settings.AllowHardTerminate = $True
$OurTask.Settings.DeleteExpiredTaskAfter = 'PT0S'
$OurTask.Settings.ExecutionTimeLimit = 'PT1H'
$OurTask.Settings.volatile = $False
$OurTask | Set-ScheduledTask

Write-Info "Going to reboot ... "
Write-Host -ForegroundColor DarkMagenta "Press Control+C to cancel rebooting, but doing so will still run the next script in 60 seconds"
Write-Host -ForegroundColor Yellow "Do not remove USB device when script is run from it"
$sleep = 5
while ($sleep -gt 0) {    
    #Write-BigWord -RandomColors "letter" -Word "$sleep" -ForegroundColorZero "DarkGray" -BackgroundColorZero "Black"
    Write-BigWord -RandomColors "letter" -Word "$sleep" -ForegroundColorZero "Black" -BackgroundColorZero "DarkGray"
    Start-Sleep -Seconds 1
    $sleep--
} 
Write-BigWord -Word "Rebooting now" -BackgroundColorZero "Black" -ForegroundColorOne "Red" -BackgroundColorOne "Red" 
Start-Sleep -Seconds 1

#Reboot the system
Restart-Computer -Force