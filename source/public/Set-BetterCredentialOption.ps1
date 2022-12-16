function Set-BetterCredentialOption {
    <#
        .SYNOPSIS
            Since BetterCredentials 5 now supports SecretManagement, we have a few options.
        .DESCRIPTION
            BetterCredentials options allow you to avoid SecretManagement, be compatible with older versions, or filter the credentials from other vaults.

            If you need backward compatibility with older versions of BetterCredentials, register a secret vault with three overrides:

            PS C:\> Register-SecretVault -Name CredentialManager -ModuleName BetterCredentials -VaultParameters @{
                Namespace = "MicrosoftPowerShell"
                VaultName = "user"
                Separator = "="
            }

        .EXAMPLE
            Set-BetterCredentialOption -SkipSecretManagement

            Allows you to work only with the Windows Credential Vault, and skip SecretManagement

        .EXAMPLE
            Set-BetterCredentialOption -VaultName CredentialManager

            Allows you to specify a single specific SecretManagement Vault for BetterCredentials to use.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(<#Rule#>'PSAvoidUsingPlainTextForPassword',<#Parameter#>'CredentialPrefix', Justification = 'Not a credential parameter')]
    [CmdletBinding()]
    param(
        # The name of the SecretVault to store credentials in.
        # By default, all secret vaults will be searched, and secrets will be stored in your default secret vault.
        # If you specify a name here, BetterCredentials will use that vault for saving, and will only search that vault.
        [Alias("Name")]
        [string]$VaultName,

        # Windows Only: if set, BetterCredentials will skip using SecretManagement.
        # If $IsMacOS or $IsLinux, this is ignored.
        [switch]$SkipSecretManagement
    )

    if ($PSBoundParameters.ContainsKey("VaultName")) {
        if ($Script:BetterCredentialsSecretManagementParameters.ContainsKey("AdditionalParameters")) {
            $Script:BetterCredentialsSecretManagementParameters["AdditionalParameters"]["VaultName"] = $VaultName
        } else {
            $Script:BetterCredentialsSecretManagementParameters["Vault"] = $VaultName
        }
    } else {
        $VaultName = if ($Script:BetterCredentialsSecretManagementParameters.ContainsKey("Vault")) {
            $Script:BetterCredentialsSecretManagementParameters["Vault"]
        } elseif ($Script:BetterCredentialsSecretManagementParameters.ContainsKey("AdditionalParameters")) {
            $Script:BetterCredentialsSecretManagementParameters["AdditionalParameters"]["VaultName"]
        }
    }

    if ($PSBoundParameters.ContainsKey("SkipSecretManagement")) {
        $Script:SkipSecretManagement = [bool]$SkipSecretManagement
        if ($Script:SkipSecretManagement -and -not $IsLinux -and -not $IsMacOS) {
            # Import our Extension to clobber SecretManagement
            $script:ImplementationModule = "BetterCredentials.Extension"
            Import-Module $PSScriptRoot\BetterCredentials.Extension\BetterCredentials.Extension.psd1

            # If we're skipping SecretManagement, we need to provide AdditionalParameters instead:
            if ($VaultName) {
                $Script:BetterCredentialsSecretManagementParameters["AdditionalParameters"] = @{
                    VaultName = $VaultName
                }
            }

            $null = $Script:BetterCredentialsSecretManagementParameters.Remove("Vault")
        } else {
            # Import SecretManagement to clobber our Extension
            $script:ImplementationModule = "Microsoft.PowerShell.SecretManagement"
            Import-Module $ImplementationModule -Force

            $null = $Script:BetterCredentialsSecretManagementParameters.Remove("AdditionalParameters")
            if ($VaultName) {
                $Script:BetterCredentialsSecretManagementParameters["Vault"] = $VaultName
            }
        }
    }

}

$Script:BetterCredentialsSecretManagementParameters = @{}

Set-BetterCredentialOption -SkipSecretManagement:(@(Get-Module "Microsoft.PowerShell.SecretManagement" -ListAvailable).Count -gt 0)
