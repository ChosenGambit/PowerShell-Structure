enum ModuleInvocation {
    Import
    Remove
    List
}

enum ModuleType {
    Global
    Dependencies
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
        [bool]$OmitCommandPrefixCheck = $True
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
        if (!$OmitCommandPrefixCheck) {
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
        Invoke-OnModules -Invocation ([ModuleInvocation]::Remove) -ModuleType ([ModuleType]::Dependencies)                 
        Invoke-OnModules -Invocation ([ModuleInvocation]::Remove) -ModuleType ([ModuleType]::Global)

        $script:Initialized = $False
    }

    PROCESS {

    }

    END {
    
    }
}

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

function Get-ModuleList {
    
    [CmdletBinding()]
    param()

    if ($PSBoundParameters['Verbose']) {
        $VerbosePreference = "Continue"
    } else {
        $VerbosePreference = "SilentlyContinue"
    }

    Invoke-OnModules -Invocation ([ModuleInvocation]::List) -ModuleType ([ModuleType]::Prefixed)
}

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
# Will also initialize dependencies into the PS Session
#>
function Get-DependencyList {

    if ($PSBoundParameters['Verbose']) {
        $VerbosePreference = "Continue"
    } else {
        $VerbosePreference = "SilentlyContinue"
    }

    Inititialize-Dependencies
    Invoke-OnModules -Invocation ([ModuleInvocation]::List) -ModuleType ([ModuleType]::Dependencies)
}

Export-ModuleMember -Function Initialize-Modules
Export-ModuleMember -Function Remove-Modules
Export-ModuleMember -Function Restart-Initialization
Export-ModuleMember -Function Get-CommandPrefix
Export-ModuleMember -Function Get-ModuleList
Export-ModuleMember -Function Get-DependencyList
Export-ModuleMember -Function Get-GlobalList

<# ######################################################
##
## Unexported, private part
##
########################################################>

function Inititialize-Dependencies {
    # Load dependencies
    Invoke-OnModules -Invocation ([ModuleInvocation]::Import) -ModuleType ([ModuleType]::Dependencies) -WithCommandPrefix $False -DisableNameChecking $True
    #Write-Alert "Initializing these dependencies directly is not recommended"
}

<#
## Invoke on modules
#>
function Invoke-OnModules {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [ModuleInvocation]$Invocation,
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
        Dependencies {
            $SearchPath = "$($CurrentDirectory)`\Dependencies"
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
                    if ($script:Initialized) {                                              
                        $Module = Get-Module -Name $ModulePath.BaseName
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
                        return
                    }
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


