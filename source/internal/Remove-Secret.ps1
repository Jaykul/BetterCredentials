function Remove-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $Target = "BetterCredentials", $VaultName, $Name -join "|"
    [BetterCredentials.Store]::Delete($Target, "Generic")

    # We've chosen to support hashtables by recursively storing their values
    foreach($nestedSecret in Get-SecretInfo -Filter "$Name|*" -VaultName "HT_$VaultName"){
        $Target = "BetterCredentials", "HT_$VaultName", $nestedSecret.Name -join "|"
        [BetterCredentials.Store]::Delete($Target, "Generic")
    }
}
