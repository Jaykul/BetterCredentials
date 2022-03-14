class CredentialConverter : System.Management.Automation.PSTypeConverter {
    [bool] CanConvertFrom([PSObject]$psSourceValue, [Type]$destinationType) {
        Write-Debug "CanConvertFrom PSOBJECT $($psSourceValue.UserName) of type [$($psSourceValue.PSTypeNames -join '],[')] to $($destinationType.FullName)"
        return $psSourceValue.PSTypeNames.Contains("System.Management.Automation.PSCredential") -or
        $psSourceValue.PSTypeNames.Contains("System.Net.NetworkCredential") -or
        $psSourceValue.PSTypeNames.Contains("System.Data.SqlClient.SqlCredential")
    }

    [bool] CanConvertFrom([object]$sourceValue, [Type]$destinationType) {
        $psSourceValue = ([PSObject]$sourceValue)
        Write-Debug "CanConvertFrom OBJECT $($psSourceValue.UserName) of type [$($psSourceValue.PSTypeNames -join '],[')] to $($destinationType.FullName)"
        return $psSourceValue.PSTypeNames.Contains("System.Management.Automation.PSCredential") -or
        $psSourceValue.PSTypeNames.Contains("System.Net.NetworkCredential") -or
        $psSourceValue.PSTypeNames.Contains("System.Data.SqlClient.SqlCredential") -and
        $destinationType.FullName -in "System.Management.Automation.PSCredential", "System.Net.NetworkCredential", "System.Data.SqlClient.SqlCredential"
    }

    [bool] CanConvertTo([object]$sourceValue, [Type]$destinationType) {
        $psSourceValue = ([PSObject]$sourceValue)
        Write-Debug "CanConvertTo OBJECT $($psSourceValue.UserName) of type [$($psSourceValue.PSTypeNames -join '],[')] to $($destinationType.FullName)"

        return $psSourceValue.PSTypeNames.Contains("System.Management.Automation.PSCredential") -or
        $psSourceValue.PSTypeNames.Contains("System.Net.NetworkCredential") -or
        $psSourceValue.PSTypeNames.Contains("System.Data.SqlClient.SqlCredential") -and
        $destinationType.FullName -in "System.Management.Automation.PSCredential", "System.Net.NetworkCredential", "System.Data.SqlClient.SqlCredential"
    }

    [object] ConvertFrom([PSObject]$psSourceValue, [Type]$destinationType, [IFormatProvider]$formatProvider, [bool]$ignoreCase) {
        Write-Debug "ConvertFrom PSObject $($psSourceValue.UserName) of type [$($psSourceValue.PSTypeNames -join '],[')] to $($destinationType.FullName)"
        if ($result = $psSourceValue -is $destinationType) {
            return $result
        }

        if ($psSourceValue.Domain) {
            $domain = $psSourceValue.Domain
            $username = $psSourceValue.UserName
        } else {
            $domain, $username = $psSourceValue.UserName -split "\\"
            if ($domain -and -not $username) {
                $username, $domain = $domain, ""
            }
        }

        # SqlCredential
        if ($psSourceValue.UserId) {
            $username = $psSourceValue.UserId
        }

        [SecureString]$password = if ($psSourceValue.SecurePassword) {
            $psSourceValue.SecurePassword.Copy() # SqlCredential and NetworkCredential
        } else {
            $psSourceValue.Password.Copy() # PSCredential
        }

        switch ($destinationType.FullName) {
            "System.Management.Automation.PSCredential" {
                if ($domain) {
                    $username = $domain + "\" + $username
                }
                $result = [System.Management.Automation.PSCredential]::new($username, $password)
            }
            "System.Net.NetworkCredential" {
                $result = [System.Net.NetworkCredential]::new($username, $password)
                if ($domain) {
                    $result.Domain = $domain
                }
            }
            "System.Data.SqlClient.SqlCredential" {
                $null = $password.MakeReadOnly()
                $result = [System.Data.SqlClient.SqlCredential]::new($userName, $password)
                if ($domain) {
                    $result | Add-Member -NotePropertyName Domain -NotePropertyValue $domain
                }
            }
            default {
                throw [System.ArgumentException]::new("Can't convert $($psSourceValue) of type $($psSourceValue.GetType().Fullname) to $($destinationType.FullName)")
            }
        }
        return $result
    }

    [object] ConvertFrom([object]$sourceValue, [Type]$destinationType, [IFormatProvider]$formatProvider, [bool]$ignoreCase) {
        $psSourceValue = ([PSObject]$sourceValue)
        Write-Debug "ConvertFrom Object $($psSourceValue.UserName) of type [$($psSourceValue.PSTypeNames -join '],[')] to $($destinationType.FullName)"
        return $this.ConvertFrom(([PSObject]$sourceValue), $destinationType, $formatProvider, $ignoreCase)
    }

    [object] ConvertTo([object]$sourceValue, [Type]$destinationType, [IFormatProvider]$formatProvider, [bool]$ignoreCase) {
        $psSourceValue = ([PSObject]$sourceValue)
        Write-Debug "ConvertTo Object $($psSourceValue.UserName) of type [$($psSourceValue.PSTypeNames -join '],[')] to $($destinationType.FullName)"
        return $this.ConvertFrom(([PSObject]$sourceValue), $destinationType, $formatProvider, $ignoreCase)
    }
}

Update-TypeData -TypeName 'System.Management.Automation.PSCredential' -TypeConverter 'CredentialConverter' -ErrorAction SilentlyContinue
Update-TypeData -TypeName 'System.Net.NetworkCredential' -TypeConverter 'CredentialConverter' -ErrorAction SilentlyContinue
Update-TypeData -TypeName 'System.Data.SqlClient.SqlCredential' -TypeConverter 'CredentialConverter' -ErrorAction SilentlyContinue