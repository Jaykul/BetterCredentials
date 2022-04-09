function Remove-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Prefix = "$($AdditionalParameters.Prefix)"
    $Name = "$Prefix$Name"

    [BetterCredentials.Store]::Delete($Name, "Generic")
}
