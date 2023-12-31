# PowerShell-Structure
PowerShell script structure

This is a basic structure for organizing a set of PowerShell modules, like a custom way to organize.

- **/Modules** the place for prefixed modules to avoid naming collisions.  
Modules should be imported with prefix and only import modules from dependencies or global, this is the main set of modules.

- **/Dependencies** when more than one module needs functionality it can be stored here.  
Dependencies can choose not to bother with naming conventions, to prevent naming collisions and be distinguishable.

- **/_Global** modules should follow auto-load naming convention.  
Global modules should/could be auto-loaded and should follow naming conventions.
  

## Tested with
Pester version: 5.5.0  
PowerShell version: 7.3.8   

## How to use
*Test script, use before importing anything*  
PS> Invoke-pester .\Root.Tests.ps1

*Loads DefaultCommandPrefix, when prefix is set, the other functions need to be called with the prefix*  
PS> Import-Module .\Manifest.psd1   

*Prefix is omitted here, but loads the underlying modules in the Global and Modules directories*  
PS> Initialize-Modules 
( PS> Initialize-\<PREFIX\>Modules )

*List all modules with prefix*  
PS> Get-ModuleList # ( Get-CGModuleList )

*List all global modules, these should be autoloaded in a $env:PSModulePath*  
PS> Get-GlobalList

*List all dependency modules*  
PS> Get-DependencyList 

*Removes and imports modules*  
PS> Restart-Initialization


## Included Scripts
***Examples are without prefix***   

*Search inside Word Documents*
PS> Search-InWordDoc -SearchKey "\<search string\>"   

*Unzip all zipfiles into a seperate folder*
PS> Expand-ZipFiles
