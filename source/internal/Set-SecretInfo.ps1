function Set-SecretInfo {
    [CmdletBinding()]
    param (
        [string] $Name,
        [hashtable] $Metadata,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    Write-Error "Not implemented"

    $Name = $AdditionalParameters["Prefix"] + $Name

    # TODO: Use CRED_PRESERVE_CREDENTIAL_BLOB instead of loading the secret
    # https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew
    $Credential = [BetterCredentials.Store]::Load($Name, "Generic")

    $Type, $Description = $_.Description -Split " ", 2
    if (!($Type -as [Microsoft.PowerShell.SecretManagement.SecretType])) {
        $Type = "Unknown"
    }
    $Credential.Description = $Type + " " + $Metadata | ConvertTo-Json -Compress -Depth 99
    [BetterCredentials.Store]::Save($Credential)
}
