function Get-SecretInfo {
    <#
        This is the "list" function.
        SecretManagement's Get-SecretInfo calls this
        It passes -Filter * by default

    #>
    [CmdletBinding()]
    param (
        [string]$Filter,
        [string]$VaultName,
        [hashtable]$AdditionalParameters
    )
    $Prefix = "$($AdditionalParameters["Prefix"])"
    $Filter = "$Prefix$Filter"

    [BetterCredentials.Store]::Find($Filter).ForEach({
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

        # If there's a prefix, strip it off the Name
        $Name = if ($Prefix) {
            $_.Target -replace "^$([regex]::Escape($Prefix))"
        } else {
            $_.Target
        }
        [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
            $Name,
            $Type,
            $VaultName,
            $Metadata
        )
    })
}
