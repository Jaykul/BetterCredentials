function Test-SecretVault {
    [CmdletBinding()]
    param (
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    # I don't know if this is right, but I think it proves CredMan works
    [BetterCredentials.Store]::Find("*").Count -gt 0
}
