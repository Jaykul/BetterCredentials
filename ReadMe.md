The Better Credentials Module
=============================

The goal of BetterCredentials is to provide a completely backwards-compatible Get-Credential command that enhances the in-the-box Get-Credential by adding additional features which are missing from the built-in command. Specifically, storing credentials for automation, and providing more complete prompts with an explanation of what the credentials are for.

TO INSTALL:
===========

Use the PowerShellGet module included in WMF (PowerShell) 5, or the [PackageManagement Preview](http://www.microsoft.com/en-us/download/details.aspx?id=49186) for PowerShell 3 and 4.

Just run:

```posh
    Install-Module BetterCredentials -AllowClobber
```

The `-AllowClobber` switch is to allow the BetterCredentials module to do what it's designed to do: provide you a better, backwards compatible `Get-Credential` command, clobbering the built-in version.

Features
========

BetterCredentials is backwards compatible in the sense that having the module loaded will not break code that uses the built-in commands or attributes in PowerShell. You can, for instance, `Import-Module BetterCredentials` on your computer, and all scripts which call Get-Credential will automatically import stored credentials! Of course, if you write scripts or functions using the additional functionality to control the prompt messages or to -Store, then you have a dependency on BetterCredentials, and you should add: `#requires -Module BetterCredentials`.

Most of the features are available through _both_ the `Get-Credential` command and the `BetterCredentials.CredentialAttribute`, so once you've required the module, you can simply add the attribute to your Credential parameters to store (and load) credentials in the Windows Credential Vault, and control the prompt text, title, etc.

One final note, before we get into the details: BetterCredentials is a old module (from the era of PowerShell 2), and is consequently a Windows-only module. Parts of it could be ported to be cross-platform, but apart from the prompting (which I will try to get added to PowerShell 7.2) the rest of the functionality revolves around storing credentials in the Windows Credential Vault, so it's going to stay Windows-only.

Prompting
---------

The original motivation for writing BetterCredentials was to take advantage of some of the features of PowerShell's underlying credential API which are inexplicably ignored in the built-in `Get-Credential`, particularly to allow one-off prompting for passwords inline (that is, in the console, instead of via the credentials dialog), without having to resort to a configuration change.

You can use the `-Inline` switch to force prompting in the host instead of with a popup dialog, or even pass in a `-Password` value (secure string or not, I won't judge) which allows you to easily create credential objects without a prompt at all.

Additionally, you can set the `-Title` parameter to control the text that's show at the top of the prompt window, and even set the `-Description` parameter to add text in the prompt.


Storage
-------

Despite the fact that this feature arrived late in the life of BetterCredentials, clearly the best feature is the fact that it can store your passwords in the Windows Credential Manager (sometimes called the Vault), and retrive them on demand so you don't have to enter them over and over. The Windows Credential Manager is what's used by Internet Explorer and Remote Desktop to store passwords, and it keeps them safely encrypted to _your_ account and machine, and provides a user interface where they can be securely reviewed, deleted or even modified.

On our BetterCredentials\Get-Credential command, the `-Store` switch causes the returned credentials to be stored in the vault, and the `-Delete` switch makes sure they are not. As of version 4.5, you can also use the `Set-Credential` and `Remove-Credental` commands to explicitly store or remove credentials.

Once you've stored credentials in the vault, future requests for the same credential -- where you pass in a username (and optionally, a domain) will simply return the credentials without prompting. Because of this, there is also a `-Force` switch (alias: `-New`) which prevents loading and forces the prompt to be displayed. When you need to change a stored password, use both together:

    BetterCredentials\Get-Credential -Force -Store

Additionally, in 4.5 there are two commands for searching and/or testing for credentials in the vault: `Find-Credential` and `Test-Credential`...

Unattended Usage
----------------

When Get-Credential is called from a script running unattended, e.g. in a scheduled task, script execution will hang prompting for credentials if there is no credential in the vault corresponding to the given username. Normally one might execute `Get-Credential username -Store` to populate the credential vault prior to putting the scheduled task into production, but might also forget to do so. In version 4.5 the new `Test-Credential` command solves the script hanging problem by returning a true or false value depending on whether a credential corresponding to a user name is currently stored in the vault.

##### NOTES

In my scripts and sample code, I nearly always use `BetterCredentials\Get-Credential` as a way to make sure that I'm invoking this overload of Get-Credential, but the idea is that you can simply import the BetterCredentials module in your profile and automatically get this overload whenever you're calling Get-Credential.

Although I've added a better Credential attribute, I haven't stepped on the `System.Management.Automation` namespace, so the automatic prompting when you pass a user name to a `-Credential` attribute doesn't use my defintion -- you have to explicitly call `Get-Credential` or write a `ProxyCommand` using the `BetterCredentials.CredentialAttribute`.

Licensed under MIT license, see [License](LICENSE).