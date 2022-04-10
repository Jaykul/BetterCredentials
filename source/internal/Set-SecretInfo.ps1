function Set-SecretInfo {
    [CmdletBinding()]
    param (
        [string] $Name,
        [hashtable] $Metadata,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    Write-Error "Not implemented"

    $Target = FixTarget @PSBoundParameters

    # TODO: Use CRED_PRESERVE_CREDENTIAL_BLOB instead of loading the secret?
    # https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew
    $Credential = [BetterCredentials.Store]::Load($Target, "Generic")

    $Type, $Description = $_.Description -Split " ", 2
    if ($Type -notin "PSCredential", "SecureString", "String", "Hashtable", "ByteArray") {
        $Type = "Unknown"
    }
    $Credential.Description = $Type + " " + $Metadata | ConvertTo-Json -Compress -Depth 99
    [BetterCredentials.Store]::Save($Credential)
}
