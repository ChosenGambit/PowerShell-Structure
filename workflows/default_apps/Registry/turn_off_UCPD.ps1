<#




# AFter

Set-Service -Name UCPD -StartupType Automatic​

Enable-ScheduledTask -TaskName "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity"

#>