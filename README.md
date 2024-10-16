# PowerShell-Structure

PowerShell script structure

This is a basic structure for organizing a set of PowerShell modules, like a custom way to organize.
If the structure is kept outside an $env:PSModulePath you can use prefixes to avoid naming collisions. See "How to use"

- **/Modules** the place for modules to avoid naming collisions when used outside an: $env:PSModulePath  
  Modules could be imported with prefix. Inside an $env:PSModulePath, these modules will auto-load when the PS naming convention is followed.

- **/Dependencies** when more than one module needs functionality it can be stored/shared here.  
  Dependencies can choose not to bother with official PS naming conventions, to prevent naming collisions and be distinguishable.

- **/Global** modules should follow auto-load naming convention.  
  Global modules should/could be auto-loaded and should follow naming conventions.

## Tested with

Pester version: 5.5.0  
PowerShell version: 7.3.8

## How to use

_Test script, use before importing anything_  
PS> Invoke-pester .\Root.Tests.ps1

_Loads DefaultCommandPrefix, when prefix is set, the other functions need to be called with the prefix_  
PS> Import-Module .\Manifest.psd1

_Loads the underlying modules in the Global and Modules directories_  
PS> Initialize-Modules # does not work outside $env:PSModulePath  
( PS> Initialize-\<PREFIX\>Modules )

_List all modules with prefix_  
PS> Get-ModuleList # ( Get-CGModuleList )

_List all global modules, these should be autoloaded in a $env:PSModulePath_  
PS> Get-GlobalList

_List all dependency modules_  
PS> Get-DependencyList

_Removes and imports modules_  
PS> Restart-Initialization

## Included Scripts

**_Examples are without prefix_**

_Search inside Word Documents_
PS> Search-InWordDoc -SearchKey "\<search string\>"

_Unzip all zipfiles into a seperate folder_
PS> Expand-ZipFiles
