@{

# Script module or binary module file associated with this manifest.
RootModule = 'BetterCredentials.psm1'

# Version number of this module.
ModuleVersion = '5.0'

# ID used to uniquely identify this module
GUID = 'd63b6487-26db-49ca-b282-e69a256c23cc'

# Author of this module
Author = 'Joel Bennett'

# Company or vendor of this module
CompanyName = 'HuddledMasses.org'

# Copyright statement for this module
Copyright = '(c) 2014-2020 Joel Bennett. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A (compatible) major upgrade for Get-Credential, including support for storing credentials in Windows Credential Manager, and for specifying the full prompts when asking for credentials, etc.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = '5.1'

RequiredModules = @()
RequiredAssemblies = @()
ScriptsToProcess = @()
TypesToProcess = @()
FormatsToProcess = @()
NestedModules = @()
CmdletsToExport = @()
VariablesToExport = @()
DscResourcesToExport = @()

# Functions to export from this module
FunctionsToExport = 'Get-Credential','Find-Credential','Set-Credential', 'Remove-Credential','Test-Credential'
AliasesToExport = @('gcred', 'scred', 'rcred', 'tcred', 'fdcred')

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @('CredentialManagement.cs','BetterCredentials.psm1','BetterCredentials.psd1','about_bettercredentials.help.txt', 'LICENSE')

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Credential','Get-Credential','Vault','Storage')

        # A URL to the license for this module.
        LicenseUri = 'http://opensource.org/licenses/MIT'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Jaykul/BetterCredentials'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
            5.0 Added some cast operators that are compatible with, but better than the built-in options.

            - By default, Find and Test now search only credentials added by BetterCredentials.
                To get the previous behavior, you need to provide the -AllCredentials switch


            4.5 Release adds a lot of functionality to the module, allowing enumeration and deletion, etc.

            - Add Test-Credential for explicitly checking whether a credential is already stored
            - Add Set-Credential for explicitly storing or updating stored credentials
            - Add Remove-Credential for clearing stored credentials
            - Add Find-Credential to search stored credentials
        '
    } # End of PSData hashtable
} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

