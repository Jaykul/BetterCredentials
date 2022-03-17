#requires -Module @{ ModuleName = "ModuleBuilder"; ModuleVersion = "2.0" }
[CmdletBinding()]param()
Push-Location $PSScriptRoot
Build-Module .\source\internal\
Build-Module
Pop-Location