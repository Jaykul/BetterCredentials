function Get-SecretInfo {
    <#
        This is the "list" function.
        SecretManagement's Get-SecretInfo calls this
        It passes -Filter * by default

    #>
    [CmdletBinding()]
    param (
        [string]$Filter = "*",
        [string]$VaultName,
        [hashtable]$AdditionalParameters
    )
    $Target = "BetterCredentials", $VaultName, $Filter -join "|"

    [BetterCredentials.Store]::Find($Target).ForEach({
        $Metadata = @{
            Description   = $_.Description
            Type          = $_.Type
            Persistance   = $_.Persistance
            LastWriteTime = $_.LastWriteTime
            Target        = $_.Target
            TargetAlias   = $_.TargetAlias
        }

        # WE shove the Type and Metadata into the Type, space separated
        # But credentials entered by others are unlikely to match this format

        $Type, $Description = $_.Description -Split " ", 2
        if (!($Type -as [Microsoft.PowerShell.SecretManagement.SecretType])) {
            $Type = "Unknown"
        } elseif ($Description) {
            # On PowerShell 5.x there's no -AsHashtable, so we'll just use objects..
            if ($MetadataObject = $Description | ConvertFrom-Json -ErrorAction SilentlyContinue) {
                $MetadataObject.psobject.properties.ForEach({
                    $Metadata[$_.name] = $_.value
                })
            }
        }

        # Assumes the Prefix doesn't have a "|" in it
        $Name = @($_.Target -split "\|", 3)[2]

        [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
            $Name,
            $Type,
            $VaultName,
            $Metadata
        )
    })
}
