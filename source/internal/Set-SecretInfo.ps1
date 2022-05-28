function Set-SecretInfo {
    [CmdletBinding()]
    param (
        [string] $Name,
        [hashtable] $Metadata,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $null = $PSBoundParameters.Remove("Metadata")
    $Target = FixTarget @PSBoundParameters

    $Credential = [BetterCredentials.Store]::Load($Target, "Generic")

    # TODO: Use CRED_PRESERVE_CREDENTIAL_BLOB instead of loading the secret?
    # https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew
    $Type, $Description = $Credential.Description -Split " ", 2
    if ($Type -notin "PSCredential", "SecureString", "String", "Hashtable", "ByteArray") {
        $Type = "Unknown"
    }

    $Credential.Description = $Type + " " + ($Metadata | ConvertTo-Json @JsonOptions)
    [BetterCredentials.Store]::Save($Credential)
}

