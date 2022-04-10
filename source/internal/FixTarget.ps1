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

    -join @(
        if ($AdditionalParameters.ContainsKey("ModuleName")) {
            $AdditionalParameters["ModuleName"]
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