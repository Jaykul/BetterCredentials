Add-Type -Path $PSScriptRoot\BetterCredentials.cs
<#
    The Credential Manager Vault, exposed to SecretManagement and automation.

    TO BE CLEAR:
    - This module does not change the level of security of your Credential Manager Vault, which is encrypted by Windows to your user account (and by default, to your local machine).
    - It is similar to the built-in `cmdkey` utility, but object-oriented and integrated with PowerShell SecretManagement.
    - Credentials in your Windows Credential Manager are encrypted, but anyone with access to your Windows user account can read them. There is no _additional_ access prompt or password required.
    - Credentials can be backed up via the Credential Manager, but are not backed up by Windows or OneDrive.


    In order to support multiple named "vaults" this extension module supports an AdditionalParameter "Prefix" which we prefix on credential names for filtering and retrieving.

    In order to cram support for non-credential secrets in, we store the Type as the first word in the description.
#>