function Remove-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Name = $AdditionalParameters["Prefix"] + $Name

    [BetterCredentials.Store]::Delete($Name, "Generic")
}
