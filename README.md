# PowerShell-Structure

PowerShell script structure

This is a structure for organizing a set of PowerShell modules, a custom way to organize and to help prevent naming collisions.
You can use this both inside and outside an $env:PSModulePath. See "How to use"  

- **/Modules** the place for modules (.psm1).  
  Modules could be imported with prefix via the Manifest file or without prefix via the Root.psm1 file.  
  When placed inside an $env:PSModulePath, these modules will auto-load when the PS naming convention is followed and Modules/Modules.psm1 is removed.

- **/Helpers** when more than one module needs functionality it can be stored/shared here.  
  Helpers can choose not to bother with official PS naming conventions (Get-Verb), to prevent naming collisions and be distinguishable.

- **/_Global** Global modules are auto-loaded when in an $env:PSModulePath and should follow naming conventions. They are never prefixed.

To use the Modules you can store orchestrated scripts in the scripts folder

- **/workflows/** Scripts that yield the modules in an orchestrated way

## Tested with

Pester version: 5.5.0  
PowerShell version: 5.1

## How to use

_Test script, use before importing anything_  
PS> Invoke-pester .\Root.Tests.ps1

_Loads modules with DefaultCommandPrefix, when prefix is set, the other functions need to be called with the prefix_  
PS> Import-Module .\Manifest.psd1

_Loads the underlying modules in the _Global and Modules directories_  
PS> Initialize-CGModules

_List all modules_  
PS> Get-CGModuleList

_List all global modules, these could be autoloaded in a $env:PSModulePath_  
PS> Get-CGGlobalList

_List all dependency modules_  
PS> Get-CGHelperList

_Removes and imports modules_  
PS> Restart-Initialization

## Included Scripts

**_Examples are without prefix_**

_Search inside Word Documents_  
PS> Search-InWordDoc -SearchKey "\<search string\>"

_Unzip all zipfiles into a seperate folder_  
PS> Expand-ZipFiles
