function Find-Credential {
    <#
        .Synopsis
            Searches stored credentials

        .Description
            Find-Credential is a wrapper around CredEnumerate
            It allows you to retrieve some or all credentials stored by BetterCredentials

            As of 5.0 it uses Get-SecretInfo if SkipSecretManagement isn't set

        .Example
            Find-Credential

            Returns all the stored BetterCredentials for the user
        .Example
            Find-Credential User@Example.org

            Filters credentials stored by BetterCredentials for User@Example.org
    #>
    [Alias('fdcred')]
    [CmdletBinding()]
    param(
        # A filter for the Target name. May contain an asterisk wildcard at the start OR at the end.
        [Alias("Target")]
        [String]$Filter = "*"
    )
    $Filter = "$CredentialPrefix$Filter"

    if (!$SkipSecretManagement -and (Get-Command Microsoft.PowerShell.SecretManagement\Get-SecretInfo -ErrorAction SilentlyContinue)) {
        try {
            Microsoft.PowerShell.SecretManagement\Get-SecretInfo $Filter @SecretManagementParameter |
                Microsoft.PowerShell.SecretManagement\Get-Secret
        } catch {}
    } else {
        try {
            [BetterCredentials.Store]::Find($Filter)
        } catch {}
    }
}