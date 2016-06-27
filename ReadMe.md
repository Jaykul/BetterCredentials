The Better Credentials Module
=============================

The goal of BetterCredentials is to provide a completely backwards-compatible Get-Credential command that enhances the in-the-box Get-Credential by adding additional features which are missing from the built-in command. Specifically, storing credentials for automation, and providing more complete prompts with an explanation of what the credentials are for.

TO INSTALL:
===========

Use the PowerShellGet module included in WMF (PowerShell) 5, or the [PackageManagement Preview](http://www.microsoft.com/en-us/download/details.aspx?id=49186) for PowerShell 3 and 4.

Just run:

    Install-Module BetterCredentials

Features
========

Prompting
---------

The original motivation for writing BetterCredentials was to take advantage of some of the features of PowerShell's underlying credential API which are inexplicably ignored in the built-in Get-Credential, particularly to allow one-off prompting for passwords inline (that is, in the console, instead of via the credentials dialog), without having to resort to a configuration change.

You can use the `-Inline` switch to force prompting in the host instead of with a popup dialog, or even pass in a `-Password` value (secure string or not, I won't judge) which allows you to easily create credential objects without a prompt at all.

Additionally, you can set the `-Title` parameter to control the text that's show at the top of the prompt window, and even set the `-Description` parameter to add text in the prompt.


Storage
-------

Despite the fact that this feature arrived late in the life of BetterCredentials, clearly the best feature is the fact that it can store your passwords in the Windows Credential Manager (sometimes called the Vault), and retrive them on demand so you don't have to enter them over and over. The Windows Credential Manager is what's used by Internet Explorer and Remote Desktop to store passwords, and it keeps them safely encrypted to _your_ account and machine, and provides a user interface where they can be securely reviewed, deleted or even modified.

On out BetterCredentials\Get-Credential command, the `-Store` switch causes the returned credentials to be stored in the vault, and the `-Delete` switch makes sure they are not.

Once you've stored credentials in the vault, future requests for the same credential -- where you pass in a username (and optionally, a domain) will simply return the credentials without prompting. Because of this, there is also a `-Force` switch (alias: `-New`) which prevents loading and forces the prompt to be displayed. When you need to change a stored password, use both together:

    BetterCredentials\Get-Credential -Force -Store


Unattended Usage
----------------

When Get-Credential is called from a script running unattended, e.g. in a scheduled task, script execution will hang prompting for credentials if there is no credential in the vault corresponding to the given username. Normally one might execute `Get-Credential username -Store` to populate the credential vault prior to putting the scheduled task into production, but might also forget to do so. `Test-Credential username` solves the script hanging problem by returning a true or false value depending on whether a credential corresponding to `username` is currently stored in the vault. False values can be used to invoke error handling as needed.


##### NOTES

In my scripts and sample code, I nearly always use `BetterCredentials\Get-Credential` as a way to make sure that I'm invoking this overload of Get-Credential, but the idea is that you can simply import the BetterCredentials module in your profile and automatically get this overload whenever you're calling Get-Credential. Of course, I haven't (yet) overloaded the [Credential] transform attribute, so the automatic prompting when you pass a user name to a `-Credential` attribute doesn't use my module -- you have to explicitly call `Get-Credential`.

I feel like I should apoligize for the clumsyness of `Get-Credential YourName -Delete`, and maybe some day I'll write a full set of `Get`, `Set`, `Remove` commands, but for now, there's only one command in this module, so that's how it is.

Licensed under MIT license, see [License](LICENSE).
