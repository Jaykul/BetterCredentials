function Set-BetterCredentialsOption {
    <#
        .SYNOPSIS
            Since BetterCredentials 5 now supports SecretManagement, we have a few options.
        .DESCRIPTION
            To avoid using SecretManagement, you can:

                Set-BetterCredentialOption -SkipSecretManagement -CredentialPrefix "WindowsPowerShell:user="

            If you have existing credentials you need to keep from BetterCredentials 4.x, but want to switch to using SecretManagement,
            register a compatible SecretVault, and then force BetterCredentials to use it:

                Register-SecretVault BetterCredentials -ModuleName BetterCredentials -VaultParameters @{ Prefix = "WindowsPowerShell:user=" }
                Set-BetterCredentialsOption -VaultName BetterCredentials

            If you want to make sure BetterCredentials only loads credentials stored by it, you can set it's CredentialPrefix.
            This means you can have BetterCredentials use _any_ SecretManagement vault, but only auto-load credentials that have the CredentialPrefix in front of the Target.
            That is, probably, only those that you have created using BetterCredential's `Get-Credential -Store` or `Set-Credential` or the attribute `[BetterCredentials.Credential(Store)]`

                Set-BetterCredentialsOption -CredentialPrefix "BetterCredentials:"

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(<#Rule#>'PSAvoidUsingPlainTextForPassword',<#Parameter#>'CredentialPrefix', Justification = 'Not a credential parameter')]
    [CmdletBinding()]
    param(
        # The name of the SecretVault to store credentials in.
        # By default, all secret vaults will be searched, and secrets will be stored in your default secret vault.
        # If you specify a name here, BetterCredentials will use that vault for saving, and will only search that vault.
        [Alias("Name")]
        [string]$VaultName,

        # A prefix to prepend to all secret names.
        # If you're storing credentials in a secret vault, you can use this to create a sort-of namespace for your credentials.
        # For compatibility with BetterCredentials 4.5 you could set this to "WindowsPowerShell:user="
        [AllowEmptyString()]
        [string]$CredentialPrefix,

        # Windows Only: if set, BetterCredentials will skip using SecretManagement.
        # On Linux, this is ignored.
        [switch]$SkipSecretManagement
    )
    if ($PSBoundParameters.ContainsKey("SkipSecretManagement")) {
        $Script:SkipSecretManagement = [bool]$SkipSecretManagement
    }
    if ($PSBoundParameters.ContainsKey("SecretVaultName")) {
        $Script:SecretManagementParameter = @{
            Vault = $VaultName
        }
    }
    if ($PSBoundParameters.ContainsKey("CredentialPrefix")) {
        $Script:CredentialPrefix = $CredentialPrefix
    }
}

$SkipSecretManagement = @(Get-Module Microsoft.PowerShell.SecretManagement -ListAvailable).Count -gt 0
$CredentialPrefix = ""
$SecretManagementParameter = @{}