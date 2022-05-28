function Register-BetterCredentialVault {
    <#
        .SYNOPSIS
            Register our SecretManagement vault, and set it as the vault for the BetterCredentials commands.
        .EXAMPLE
            Register-BetterCredentialVault -Name BCVault
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(<#Rule#>'PSAvoidUsingPlainTextForPassword',<#Parameter#>'CredentialPrefix', Justification = 'Not a credential parameter')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(<#Rule#>'PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to register. Defaults to 'BetterCredentials'.
        [Alias('VaultName')]
        [string]$Name = 'BetterCredentials',

        # If set, the vault will be created to store credentials in the same way as BetterCredentials 4.x
        [switch]$BackwardCompatible,

        # A description that is included in the vault registry information.
        [string]$Description,

        # Allows overwriting an existing registered extension vault with the same name.
        [switch]$AllowClobber,

        # Make the new extension vault the default vault for the current user.
        [switch]$DefaultVault,

        # Pass through the SecretVaultInfo object if it's successfully registered.
        [switch]$PassThru
    )
    $PSBoundParameters['Name'] = $Name

    $null = $PSBoundParameters.Remove("CredentialPrefix")

    if ($BackwardCompatible) {
        $null = $PSBoundParameters.Remove("BackwardCompatible")
        $null = $PSBoundParameters.Add("VaultParameters", @{
            Namespace = "MicrosoftPowerShell"
            VaultName = "user"
            Separator = "="
        })
    }

    if ($Script:BetterCredentialsSecretManagementParameters.ContainsKey("AdditionalParameters")) {
        $PSBoundParameters["VaultParameters"].GetEnumerator().ForEach({
            $Script:BetterCredentialsSecretManagementParameters["AdditionalParameters"][$_.Key] = $_.Value
        })
    } else {
        Register-SecretVault -ModuleName BetterCredentials @PSBoundParameters
        $Script:BetterCredentialsSecretManagementParameters["Vault"] = $Name
    }

}