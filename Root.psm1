enum ModuleInvocation {
    Import
    Remove
    List
}

enum ModuleType {
    Global
    Helpers
    Prefixed    
}

$Initialized = $False

<#
.SYNOPSIS    
    Main module initializer   
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Initialize-Modules {        

    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$False)]
        [bool]$CommandPrefixCheck = $False
    )    

    BEGIN { 
    
        if ($PSBoundParameters['Verbose']) {
            $VerbosePreference = "Continue"
        } else {
            $VerbosePreference = "SilentlyContinue"
        }       

        $script:Initialized = $True

        # Load _Global without prefix, to make sure every module can use it

        $Results = Invoke-OnModules -Invocation ([ModuleInvocation]::Import) -ModuleType ([ModuleType]::Global) -WithCommandPrefix $False

        # Check Command Prefix obligation
        if ($CommandPrefixCheck) {
            $CommandPrefix = Get-CommandPrefix
            Write-Info "CommandPrefix found is $($CommandPrefix)"
            if ($CommandPrefix -eq $False) {
                Write-Error "This function must be called with a command prefix. Try to Import the manifest instead (Import-Module Manifest.psd1)."
                return
            }
        }               

        Write-Info "Import main modules"      
        $Results = Invoke-OnModules -Invocation ([ModuleInvocation]::Import) -ModuleType ([ModuleType]::Prefixed)
    }

    PROCESS { }

    END { }
}

<#
.SYNOPSIS    
    Main module remover   
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Remove-Modules {

    BEGIN {

        Write-Neutral "Trying to remove modules"
        
        Invoke-OnModules -Invocation ([ModuleInvocation]::Remove) -ModuleType ([ModuleType]::Prefixed)
        Invoke-OnModules -Invocation ([ModuleInvocation]::Remove) -ModuleType ([ModuleType]::Helpers)                 
        Invoke-OnModules -Invocation ([ModuleInvocation]::Remove) -ModuleType ([ModuleType]::Global)

        $script:Initialized = $False
    }

    PROCESS {

    }

    END {
    
    }
}

<#
.SYNOPSIS    
    Remove all modules and Initialize them again
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Restart-Initialization {
    Remove-Modules
    Initialize-Modules
}

<#
## Returns true if command prefix is found
#>
function Get-CommandPrefix {
    $mod = Get-Module -Name $MyInvocation.MyCommand.Module.Name
    if ($mod.Prefix -eq $null -or $mod.Prefix -eq '') {        
        return $False
    }
    return $mod.Prefix
}

<#
.SYNOPSIS    
    Output the global and prefixed modules from the Modules and _Global directories
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Get-ModuleList {
    
    [CmdletBinding()]
    param(
        [bool]$WithGlobals = $True
    )

    $global:WriteOutput = $True

    if ($PSBoundParameters['Verbose']) {
        $VerbosePreference = "Continue"
    } else {
        $VerbosePreference = "SilentlyContinue"
    }    

    # Print modules of this file (Root)
    $ModuleName = $MyInvocation.MyCommand.ModuleName
    $Module = Get-Module -Name $moduleName 
    $ExportedFunctions = $module.ExportedCommands.Values

    # this file
    Write-Neutral "Module $($Module.Name) has functions:"
    foreach($Function in $ExportedFunctions) {
        $FunctionNameWithPrefix = Add-Prefix -FunctionName $Function.Name -Prefix $Module.Prefix
        Write-Info " - $($FunctionNameWithPrefix) "
    }

    #_Global dir
    if ($WithGlobals -eq $True) {
        Invoke-OnModules -Invocation ([ModuleInvocation]::List) -ModuleType ([ModuleType]::Global)
    }

    # Modules dir
    Invoke-OnModules -Invocation ([ModuleInvocation]::List) -ModuleType ([ModuleType]::Prefixed)

    $global:WriteOutput = $False
}

<#
.SYNOPSIS    
    Output the modules in the _Global directory   
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Get-GlobalList {
    
    [CmdletBinding()]
    param()

    if ($PSBoundParameters['Verbose']) {
        $VerbosePreference = "Continue"
    } else {
        $VerbosePreference = "SilentlyContinue"
    }

    Invoke-OnModules -Invocation ([ModuleInvocation]::List) -ModuleType ([ModuleType]::Global)
}

<#
.SYNOPSIS    
    Output the modules in the Helpers directory   
    This will import all modules beforehand to be able to read them properly
.DESCRIPTION        
.INPUTS
.OUTPUTS
.EXAMPLE
.LINK
.NOTES
#>
function Get-HelperList {

    if ($PSBoundParameters['Verbose']) {
        $VerbosePreference = "Continue"
    } else {
        $VerbosePreference = "SilentlyContinue"
    }

    Inititialize-Helpers
    Invoke-OnModules -Invocation ([ModuleInvocation]::List) -ModuleType ([ModuleType]::Helpers)
}

Export-ModuleMember -Function Initialize-Modules
Export-ModuleMember -Function Remove-Modules
Export-ModuleMember -Function Restart-Initialization
Export-ModuleMember -Function Get-CommandPrefix
Export-ModuleMember -Function Get-ModuleList
Export-ModuleMember -Function Get-HelperList
Export-ModuleMember -Function Get-GlobalList

<# ######################################################
##
## Unexported, private part
##
########################################################>

function Inititialize-Helpers {
    # Load Helpers
    Invoke-OnModules -Invocation ([ModuleInvocation]::Import) -ModuleType ([ModuleType]::Helpers) -WithCommandPrefix $False -DisableNameChecking $True
    #Write-Alert "Initializing these Helpers directly is not recommended"
}



<#
## Invoke on modules, either Import, Remove or List
#>
function Invoke-OnModules {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [ModuleInvocation]$Invocation,  # either Import, Remove or List
        [Parameter(Mandatory=$True)]
        [ModuleType]$ModuleType,
        [bool]$WithCommandPrefix = $True,
        [bool]$DisableNameChecking = $False
    )

    $SuccesCounter = 0
    $ErrorCounter = 0

    $CurrentDirectory = Split-Path -Parent $PSCommandPath
    $OmitGlobalWriting = $False

    # load accordingly
    switch($ModuleType) {
        Global {
            $SearchPath = "$($CurrentDirectory)`\_Global"
            $OmitGlobalWriting = $True # global write functions not available anymore
        }
        Helpers {
            $SearchPath = "$($CurrentDirectory)`\Helpers"
        }
        Prefixed {
            $SearchPath = "$($CurrentDirectory)`\Modules"
        }
    }

    Write-Verbose "SearchPath = $($SearchPath)"
    
    # load command prefix which has been set at manifest
    $CommandPrefix = $False
    if ($WithCommandPrefix) {
        $CommandPrefix = Get-CommandPrefix    
    }
              
    $Modules = Get-ChildItem -Path $SearchPath -File -Filter "*.psm1" -Recurse

    foreach ($ModulePath in $Modules) {
            
        Write-Verbose "Found:      $($ModulePath.FullName)"            

        # Try loading module for global use
        try {
            switch($Invocation) {
                Import {

                    $params = @{
                        Name = $ModulePath.FullName
                        Global = $True
                        Force = $True
                    }

                    if ($CommandPrefix -ne $False) {
                        $params['Prefix'] = $CommandPrefix
                    }

                    if ($DisableNameChecking -ne $False) {
                        $params['DisableNameChecking'] = $True
                    }

                    Import-Module @params
                    Write-Success "Imported module $($ModulePath.FullName). Prefix: $($CommandPrefix)"
                    $SuccesCounter++                        
                        
                }
                Remove {                    
                    Remove-Module -Name $ModulePath.BaseName -ErrorAction SilentlyContinue 
                    if ($OmitGlobalWriting -ne $True) {
                        Write-Info "Removed module $($ModulePath.FullName)"
                    }
                    $SuccesCounter++                
                }
                List {  
                    $OmitGlobalWriting = $True
                    Write-ModuleInfo -FileInfo $ModulePath
                }
            }                
        }
        catch {
            Write-Error $_.Exception.Message
            $ErrorCounter++
        }        
    }

    if ($OmitGlobalWriting -ne $True) {
        Write-Status "Success: #$($SuccesCounter), Error: #$($ErrorCounter)"
    }
}

<#
# Adds prefix to a functionname, for displaying purpose
#>
function Add-Prefix {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$FunctionName,
        [string]$Prefix
    )
    $Split = $FunctionName.Split("-")
    $WithPrefix = ""
    if ($Split.Count -eq 1) {
        $WithPrefix = "$($Prefix)$($Split[0])"
    }
    elseif ($Split.Count -eq 2) { 
        $WithPrefix = "$($Split[0])-$($Prefix)$($Split[1])"
    }
    elseif ($Split.Count -gt 2) { 
         $WithPrefix = "$($Split[0])-$($Prefix)$($Split[1])"
         for ($i = 2; $i -lt $Split.Count; $i++) {
            $WithPrefix = $WithPrefix+"-$($Split[$i])"
         }
    }
    else {
        $WithPrefix = $FunctionName
    }
    return $WithPrefix
}

function Write-ModuleInfo {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [System.IO.FileInfo]$FileInfo
    )

    if ($script:Initialized) {                                              
        $Module = Get-Module -Name $FileInfo.BaseName
        Write-Neutral "Module $($Module.Name) has functions:"
        foreach ($CommandKey in $Module.ExportedCommands.Keys) {
            Write-Info " - $($CommandKey) "
        }                            
    }
    else {
        if ($CommandPrefix) {
            Write-Info "Use command: `"Initialize-$($CommandPrefix)Modules`" first"    
        }
        else {
            Write-Info "Use command: `"Initialize-Modules`" first"
        }                                    
    }
}


