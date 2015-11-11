The Better Credentials Module
=============================

The goal of BetterCredentials is to provide a completely backwards-compatible Get-Credential command that enhances the in-the-box Get-Credential by adding additional features which are missing from the built-in command. Specifically, storing credentials for automation, and providing more complete prompts with an explanation of what the credentials are for.

Prompting
---------

The original motivation for writing BetterCredentials was to take advantage of some of the features of PowerShell's underlying credential API which are inexplicably ignored in the built-in Get-Credential, particularly to allow one-off prompting for passwords inline (that is, in the console, instead of via the credentials dialog), without having to resort to a configuration change.

You can use the `-Inline` switch to force prompting in the host instead of with a popup dialog, or even pass in a `-Password` value (secure string or not, I won't judge) which allows you to easily create credential objects without a prompt at all.

Additionally, you can set the `-Title` parameter to control the text that's show at the top of the prompt window, and even set the `-Description` parameter to add text in the prompt.


Storage
-------

Despite the fact that this feature arrived late in the life of BetterCredentials, clearly the best feature is the fact that it can store your passwords in the Windows Credential Manager (sometimes called the Vault), and retrive them on demand so you don't have to enter them over and over. The Windows Credential Manager is what's used by Internet Explorer and Remote Desktop to store passwords, and it keeps them safely encrypted to _your_ account and machine, and provides a user interface where they can be securely reviewed, deleted or even modified.

On out BetterCredentials\Get-Credential command, the `-Store` switch causes the returned credentials to be stored in the vault, and the `-Delete` switch makes sure they are not.

Once you've stored credentials in the vault, future requests for the same credential (based on the domain and username) will simply return the credentials without prompting!


##### NOTES

I feel like I should apoligize for the clumsyness of `Get-Credential YourName -Delete`, and maybe some day I'll write a full set of `Get`, `Set`, `Remove` commands, but for now, there's only one command in this module, so that's how it is.