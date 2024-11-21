<# Adds timestamp and computername to name #>
function Get-DetailedName {
    param($Name) 
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss" 
    $csName = $((Get-ComputerInfo).CsName)    
    return $Name = "$($Name)_$($csName)_$($timestamp)"
}