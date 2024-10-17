# PowerShell-Structure

PowerShell script structure

This is a basic structure for organizing a set of PowerShell modules, like a custom way to organize.
You can use this both inside and outside an $env:PSModulePath. See "How to use"

- **/Modules** the place for modules.  
  Modules could be imported with prefix via the Manifest file or without prefix via the Root.psm1 file. Inside an $env:PSModulePath, these modules will auto-load when the PS naming convention is followed and Modules.psm1 is removed.

- **/Dependencies** when more than one module needs functionality it can be stored/shared here.  
  Dependencies can choose not to bother with official PS naming conventions, to prevent naming collisions and be distinguishable.

- **/Global** Global modules are auto-loaded when in an $env:PSModulePath and should follow naming conventions. They are never prefixed.

## Tested with

Pester version: 5.5.0  
PowerShell version: 7.3.8

## How to use

_Test script, use before importing anything_  
PS> Invoke-pester .\Root.Tests.ps1

_Loads DefaultCommandPrefix, when prefix is set, the other functions need to be called with the prefix_  
PS> Import-Module .\Manifest.psd1

_Loads the underlying modules in the Global and Modules directories_  
PS> Initialize-CGModules

_List all modules_  
PS> Get-CGModuleList

_List all global modules, these could be autoloaded in a $env:PSModulePath_  
PS> Get-CGGlobalList

_List all dependency modules_  
PS> Get-CGDependencyList

_Removes and imports modules_  
PS> Restart-Initialization

## Included Scripts

**_Examples are without prefix_**

_Search inside Word Documents_  
PS> Search-InWordDoc -SearchKey "\<search string\>"

_Unzip all zipfiles into a seperate folder_  
PS> Expand-ZipFiles
