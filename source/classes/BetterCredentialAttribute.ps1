using namespace System.Management.Automation

# [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = false)]
class BetterCredentialAttribute : ArgumentTransformationAttribute {
    [bool]$MandatoryPassword = $false
    [bool]$Save = $false
    [string]$Target = [NullString]::Value
    [string]$Domain = [NullString]::Value
    [string]$Title = "PowerShell credential request"
    [string]$Message = "Enter your credentials."

    [object] Transform([EngineIntrinsics]$engineIntrinsics, [object]$inputData) {
        [PSCredential]$Credential = $null
        [string]$userName = $null
        [bool]$shouldPrompt = $false

        if (($null -eq $engineIntrinsics) -or ($null -eq $engineIntrinsics.Host) -or ($null -eq $engineIntrinsics.Host.UI)) {
            throw [ArgumentNullException]::new("engineIntrinsics")
        }

        if ($null -eq $inputData) {
            $shouldPrompt = $true;
        } else {
            # Try to coerce the input as an PSCredential
            $Credential = $inputData -as [PSCredential]

            # Try to coerce the username from the string
            if ($null -eq $Credential) {
                $shouldPrompt = $true;
                $userName = $inputData -as [string]
            }
        }

        if ($shouldPrompt) {
            $Splat = @{
                Title = $this.Title
                Description = $this.Message
                Store = $this.Save
            }
            if ($UserName) { $Splat['UserName'] = $userName }
            if ($this.Domain) { $Splat['Domain'] = $this.Domain }
            if ($this.Target) { $Splat['Target'] = $this.Target }

            $Credential = BetterCredentials\Get-Credential @Splat
        }

        if ($this.MandatoryPassword -and $Credential.Password.Length -eq 0) {
            throw "The password is mandatory"
        }

        return $Credential;
    }
}