#requires -Module @{ ModuleName = "ModuleBuilder"; ModuleVersion = "2.0" }
[CmdletBinding()]param()
Push-Location $PSScriptRoot
Build-Module .\source\
Pop-Location