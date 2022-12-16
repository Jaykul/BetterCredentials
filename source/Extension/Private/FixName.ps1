filter FixName {
    [CmdletBinding()]
    param (
        [Alias("Filter", "Target")]
        [string]$Name,

        [string]$VaultName,

        [hashtable]$AdditionalParameters = @{},

        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    if ($InputObject) {
        $Name = $InputObject.Target
    }

    "FixName $Name $VaultName {$($AdditionalParameters.GetEnumerator().ForEach{ $_.Name + ": " + $_.Value } -join ', ')}" >> "$PSScriptRoot\vault.log"

    $Name -Replace ("^" + [Regex]::Escape(
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
        )
    ))
}