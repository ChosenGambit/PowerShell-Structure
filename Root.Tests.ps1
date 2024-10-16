# Need Pester v4 or v5
# Install-Module -Name Pester -Force -SkipPublisherCheck

Describe "Initialize-Modules" {

    BeforeAll {
        cd $PSScriptRoot
        Import-Module -Name Pester -RequiredVersion 5.5.0
    }

    Context "Before loading manifest" {
        It 'Initialize-CGModules should not be invokable'{
            { Initialize-CGModules } | Should -Throw
        }
    }
    
    Context "After loading manifest" {

        BeforeAll {
            Import-Module ".\Manifest.psd1"
        }

        It 'Initialize-CGModules should now be invokable'{
            { Initialize-CGModules } | Should -Not -Throw
        }

        It 'CommandPrefix should be set'{
             Get-CGCommandPrefix | Should -Be "CG"
        }
    }

    Context "Checking the imported modules" {

        BeforeAll {
            $global:WriteOutput = $True          
        }
		
		It 'Should list global modules'{
             Get-CGGlobalList | Should -Contain ' - Write-Alert '
        }

        It 'Should list prefixed modules'{
             Get-CGModuleList | Should -Contain ' - Disable-CGSystemWake '
        }

        #It 'Should list dependency modules' {
        #     Get-CGDependencyList | Should -Contain ' - Initialize-Profile '
        #}

        AfterAll {
            $global:WriteOutput = $False
        }
    }

    AfterAll {   
        Get-CGModuleList                  
        Remove-CGModules
        Remove-Module "Manifest"
    }
}