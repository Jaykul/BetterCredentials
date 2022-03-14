using namespace System.Management.Automation

# [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = false)]
class BetterCredentialAttribute : ArgumentTransformationAttribute {
    [bool]$MandatoryPassword = $false
    [bool]$Save = $false
    [string]$Title = "PowerShell credential request"
    [string]$Prompt = "Enter your credentials."
    [string]$Domain = ""

    [PSCredentialTypes]$AllowedCredentialTypes = "Generic, Domain"
    [PSCredentialUIOptions]$Options = "Default"

    [object] Transform([EngineIntrinsics]$engineIntrinsics, [object]$inputData) {
        [PSCredential]$Credential = $null
        [string]$userName = $null;
        [bool]$shouldPrompt = $false;


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
            $Credential = $engineIntrinsics.Host.UI.PromptForCredential(
                $this.Title,
                $this.Prompt,
                $userName,
                $this.Domain,
                $this.AllowedCredentialTypes,
                $this.Options);
        }

        if ($this.MandatoryPassword -and $Credential.Password.Length -eq 0) {
            throw "The password is mandatory"
        }

        if ($this.Store) {
            [BetterCredentials.Store]::Save($Credential)
        }

        return $Credential;
    }
}