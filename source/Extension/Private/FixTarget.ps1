filter FixTarget {
    [CmdletBinding()]
    param (
        [Alias("Filter")]
        [string]$Name = "*",

        [string]$VaultName,

        [hashtable]$AdditionalParameters = @{},

        # Ignored -- just for ease of extra splatting
        [hashtable]$Metadata,
        # Ignored -- just for ease of extra splatting
        [object]$Secret
    )

    "FixTarget: $Name, $VaultName, {$($AdditionalParameters.GetEnumerator().ForEach{ $_.Name + ": " + $_.Value } -join ', ')}" >> "$PSScriptRoot\vault.log"

    -join @(
        if ($AdditionalParameters.ContainsKey("Namespace")) {
            $AdditionalParameters["Namespace"]
            ":"
        } else {
            "BetterCredentials"
            "|"
        }

        if ($AdditionalParameters.ContainsKey("VaultName")) {
            $AdditionalParameters["VaultName"]
        } else {
            $VaultName
        }

        if ($AdditionalParameters.ContainsKey("Separator")) {
            $AdditionalParameters["Separator"]
        } else {
            "|"
        }

        $Name
    )
}