function Remove-Credential {
    <#
        .SYNOPSIS
            Remove a credential from the Windows Credential Manager (Vault)

        .DESCRIPTION
            Removes the credential for the specified target
    #>
    [Alias('rcred')]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline, Mandatory)]
        [string]$Target
    )

    process {
        if (!$SkipSecretManagement -and (Get-Command Microsoft.PowerShell.SecretManagement\Remove-Secret -ErrorAction SilentlyContinue)) {
            Microsoft.PowerShell.SecretManagement\Remove-Secret -Name "$CredentialPrefix$Target" @BetterCredentialsSecretManagementParameters
        } else {
            [BetterCredentials.Store]::Delete("$CredentialPrefix$Target")
        }
    }
}