The Better Credentials Module
=============================

1. [A better Get-Credential command](#a-better-get-credential) (now cross-platform!)
2. [A SecretVault that stores secrets in the Windows Credential Vault](#a-windows-credential-vault-secretvault)
3. [A better CredentialAttribute](#a-better-credentialattribute) for your commands
4. [A PSTypeConverter for credential types](#a-credential-converter) that lets you cast PSCredential, NetworkCredential, and SqlCredential to each other

A Better Get-Credential
-----------------------

The `Get-Credential` command in BetterCredentials is a drop-in replacement for the built-in `Get-Credential` command, but with additional features:

1. Adds a `-Title` for the credential prompt (even in Windows PowerShell). _This feature was added to the built-in command after PowerShell 6._
2. Prompting for credentials `-Inline` in the console. _This was added via a preference variable to PowerShell 5, and is the only way to prompt for credentials after PowerShell 6._
3. Control over whether you get `-GenericCredentials` or `-Domain` credentials.
4. Caching credentials, using the `-Store` switch.
5. Support for SecretManagement, so you can store (and retrieve) credentials in your preferred vault!

Having BetterCredentials loaded will not interfere with code that was written using the built-in commands or attributes in PowerShell, except that _if you have already stored a credential_ that matches the `-Target` (or `-Username`, if no target is specified), it will be returned without prompting for a new one (unless you override with `-Force`).

A Windows Credential Vault SecretVault
--------------------------------------

New in BetterCredentials 5.0, we now have a `BetterCredentials.Extension`, which is a SecretManagement extension that allows you to store secrets in the Windows Credential Vault. Obviously, this vault only works on Windows, but BetterCredentials means you can keep working with the secrets you have in your Windows Credential vault, even as you modernize your scripts to use SecretManagement so they'll work anywhere, with any vault.

A Better CredentialAttribute
----------------------------

The `BetterCredentials.CredentialAttribute` is a drop-in replacement for the built-in `CredentialAttribute` that works in C# and adds the functionality for specifying the prompt, and for storing credentials in the Windows credential vault. So far, it does _not_ support SecretManagement.

The `BetterCredentialAttribute` is a script-based drop-in replacement for the built-in `CredentialAttribute` that only works in PowerShell, but supports SecretManagement and is cross-platform.

A PSTypeConverter for Credential Types
--------------------------------------

Now you can use PSCredential, NetworkCredential, and SqlCredential almost interchangably, and cast one to the other and back again. That is, not only can you explicitly cast credentials from one type to another, you can use the output of Get-Credential directly with .NET APIs that don't support PSCredential.

```PowerShell
    $cred = Get-Credential
    # Now you can cast explicitly, or just pass the credential to a .NET API that takes NetworkCredential or SqlCredential!
    $netCred = [System.Net.NetworkCredential]$cred
    $Sql1 = [System.Data.SqlClient.SqlConnection]::new("Server=Sql1;Database=Users", $cred)

    # and of course, if you have one of those, you can cast it to the other, back to PSCredential, and even use a NetworkCredential as a SqlCredential!
    $sqlCred = [System.Data.SqlClient.SqlCredential]$netCred
    $cred3 = [PSCredential]$SqlConnection.Credential
    $Sql2 = [System.Data.SqlClient.SqlConnection]::new("Server=Sql1;Database=Users", $netCred)
```

Note, since this is implemented as a PSTypeConverter, it only works in PowerShell code.

TO INSTALL:
===========

Use the PowerShellGet module included in PowerShell. Just run:

```posh
    Install-Module BetterCredentials -AllowClobber
```

The `-AllowClobber` switch is to allow the BetterCredentials module to do what it's designed to do: provide you a better, backwards compatible `Get-Credential` command, _clobbering_ the built-in version when the module's loaded.

Configuration
-------------

Since BetterCredentials 5 now supports SecretManagement, we have a few options that can be set with the `Set-BetterCredentialOption` command.

By default, if SecretManagement is installed, all secret vaults will be searched, and new credentials will be stored in your default secret vault. But if you want to, you can use `Set-BetterCredentialOption -VaultName <vaultName>` to specify a specific vault to use exclusively.

If you have SecretManagement installed, but don't want to use SecretManagement with BetterCredentials (that is, if you want to use the BetterCredentials Windows Credential Vault directly) you can use `Set-BetterCredentialOption -SkipSecretManagement` to force this.

NOTE: If you want backward compatibility with older versions of BetterCredentials, register a secret vault with these overrides, and make it your default vault...

```PowerShell
Register-SecretVault -Name CredentialManager -ModuleName BetterCredentials -VaultParameters @{
    Namespace = "MicrosoftPowerShell"
    VaultName = "user"
    Separator = "="
}
```

Managing Credentials
--------------------

As of version BetterCredentials 4.5, you can use the `Set-Credential` and `Remove-Credential` commands to explicitly store or remove credentials. NOTE: if you're using BetterCredentials with SecretManagement, these commands work with your configured secret vaults.

Once you've stored credentials in the vault, future requests for the same credential -- where you pass in a username (and optionally, a domain) will simply return the credentials without prompting. Because of this, there is also a `-Force` switch (alias: `-New`) which prevents loading and forces the prompt to be displayed. When you need to change a stored password, use both together:

    BetterCredentials\Get-Credential -Force -Store

Additionally, from 4.5 there are two commands for searching and/or testing for credentials in the vault: `Find-Credential` and `Test-Credential`...

Unattended Usage
----------------

When Get-Credential is called from a script running unattended, e.g. in a scheduled task, script execution will hang prompting for credentials if there is no credential in the vault corresponding to the given username. Normally one might execute `Get-Credential username -Store` to populate the credential vault prior to putting the scheduled task into production, but might also forget to do so. Since version 4.5 the new `Test-Credential` command solves the script hanging problem by returning a true or false value depending on whether a credential corresponding to the specified user name (or "Target") is currently stored in the vault.


##### NOTES

In my scripts and sample code, I try to use `BetterCredentials\Get-Credential` as a way to make sure that I'm invoking this overload of Get-Credential, but the idea is that you can simply import the BetterCredentials module in your profile and automatically get this overload whenever you're calling Get-Credential.

Although I've added a better Credential attribute, I haven't stepped on the `System.Management.Automation` namespace, so existing commands using PSCredential type won't use my definition -- you have to explicitly call `Get-Credential` or write a `ProxyCommand` using the `[BetterCredential()]` attribute.

Licensed under MIT license, see [License](LICENSE).