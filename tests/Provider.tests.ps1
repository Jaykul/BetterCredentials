# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Describe "Test Microsoft.PowerShell.SecretManagement module" -tags CI {
    BeforeAll {
        $PSModulePath = $Env:PSModulePath
        $Env:PSModulePath = "$(Convert-Path ..)$([IO.Path]::PathSeparator)$PSModulePath"
        Remove-Module Microsoft.PowerShell.SecretManagement, BetterCredentials* -ErrorAction SilentlyContinue
        Import-Module -Name Microsoft.PowerShell.SecretManagement
        $ModuleName = "BetterCredentials"
        $VaultName = "BetterCredentialsTestVault"
        Register-SecretVault $VaultName -ModuleName $ModuleName -VaultParameters @{ Prefix = "${VaultName}|" }
        Set-BetterCredentialsOption $VaultName
        Set-SecretVaultDefault $VaultName
    }

    AfterAll {
        # Remove-Module BetterCredentials
        Unregister-SecretVault -Name $VaultName -ErrorAction Ignore
        $Env:PSModulePath = $PSModulePath
    }

    Describe VerifyPSCredentialType {

        BeforeAll {
            $randomSecret = [System.IO.Path]::GetRandomFileName()
        }

        It "Verifies writing PSCredential to $ModuleName vault" {
            $cred = [pscredential]::new('UserName', (ConvertTo-SecureString $randomSecret -AsPlainText -Force))
            Set-Secret -Name TestVaultCred -Secret $cred -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
        }

        It "Verifies reading PSCredential type from $ModuleName vault" {
            $cred = Get-Secret -Name TestVaultCred -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $cred.UserName | Should -BeExactly "UserName"
            $cred.GetNetworkCredential().Password | Should -BeExactly $randomSecret
        }

        It "Verifies enumerating PSCredential type from $ModuleName vault" {
            $credInfo = Get-SecretInfo -Name TestVaultCred -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $credInfo.Name | Should -BeExactly "TestVaultCred"
            $credInfo.Type | Should -BeExactly "PSCredential"
            $credInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing PSCredential type from $ModuleName vault" {
            Remove-Secret -Name TestVaultCred -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            { Get-Secret -Name TestVaultCred -Vault $VaultName -ErrorAction Stop } | Should -Throw `
                -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretManagement.GetSecretCommand'
        }
    }

    Describe VerifySecureStringType {

        BeforeAll {
            $randomSecret = [System.IO.Path]::GetRandomFileName()
            $secureStringToWrite = ConvertTo-SecureString $randomSecret -AsPlainText -Force
        }

        It "Verifies writing SecureString type to $ModuleName vault" {
            Set-Secret -Name TestVaultSecureStr -Secret $secureStringToWrite `
                -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
        }

        It "Verifies reading SecureString type from $ModuleName vault" {
            $ss = Get-Secret -Name TestVaultSecureStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            [System.Net.NetworkCredential]::new('', $ss).Password | Should -BeExactly $randomSecret
        }

        It "Verifies enumerating SecureString type from $ModuleName vault" {
            $ssInfo = Get-SecretInfo -Name TestVaultSecureStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $ssInfo.Name | Should -BeExactly "TestVaultSecureStr"
            $ssInfo.Type | Should -BeExactly "SecureString"
            $ssInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing SecureString type from $ModuleName vault" {
            Remove-Secret -Name TestVaultSecureStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            { Get-Secret -Name TestVaultSecureStr -Vault $VaultName -ErrorAction Stop } | Should -Throw `
                -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretManagement.GetSecretCommand'
        }

        It "Verifies SecureString write with alternate parameter set" {
            Set-Secret -Name TestVaultSecureStrA -SecureStringSecret $secureStringToWrite `
                -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
        }

        It "Verifies SecureString read from alternate parameter set" {
            $ssRead = Get-Secret -Name TestVaultSecureStrA -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            [System.Net.NetworkCredential]::new('', $ssRead).Password | Should -BeExactly $randomSecret
        }

        It "Verifes SecureString remove from alternate parameter set" {
            { Remove-Secret -Name TestVaultSecureStrA -Vault $VaultName -ErrorVariable err } | Should -Not -Throw
            $err.Count | Should -Be 0
        }
    }

    Describe VerifyStringType {

        It "Verifies writing string type to $ModuleName vault" {
            Set-Secret -Name TestVaultStr -Secret "HelloTestVault" -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
        }

        It "Verifies reading string type from $ModuleName vault" {
            $str = Get-Secret -Name TestVaultStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            ($str -is [SecureString]) | Should -BeTrue

            $str = Get-Secret -Name TestVaultStr -Vault $VaultName -AsPlainText -ErrorVariable err
            $err.Count | Should -Be 0
            $str | Should -BeExactly "HelloTestVault"
        }

        It "Verifies enumerating string type from $ModuleName vault" {
            $strInfo = Get-SecretInfo -Name TestVaultStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $strInfo.Name | Should -BeExactly "TestVaultStr"
            $strInfo.Type | Should -BeExactly "String"
            $strInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing string type from $ModuleName vault" {
            Remove-Secret -Name TestVaultStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            { Get-Secret -Name TestVaultStr -Vault $VaultName -ErrorAction Stop } | Should -Throw `
                -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretManagement.GetSecretCommand'
        }
    }

    Describe VerifyByteArrayType {

        It "Verifies writing byte[] type to $ModuleName vault" {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes("TestVaultHelloStr")
            Set-Secret -Name TestVaultBlob -Secret $bytes -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
        }

        It "Verifies reading byte[] type from $ModuleName vault" {
            $blob = Get-Secret -Name TestVaultBlob -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            [System.Text.Encoding]::UTF8.GetString($blob) | Should -BeExactly "TestVaultHelloStr"
        }

        It "Verifies enumerating byte[] type from $ModuleName vault" {
            $blobInfo = Get-SecretInfo -Name TestVaultBlob -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $blobInfo.Name | Should -BeExactly "TestVaultBlob"
            $blobInfo.Type | Should -BeExactly "ByteArray"
            $blobInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing byte[] type from $ModuleName vault" {
            Remove-Secret -Name TestVaultBlob -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            { Get-Secret -Name TestVaultBlob -Vault $VaultName -ErrorAction Stop } | Should -Throw `
                -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretManagement.GetSecretCommand'
        }
    }

    Describe VerifyHashType {

        BeforeAll {
            $randomSecretA = [System.IO.Path]::GetRandomFileName() -replace "\..*"
            $randomSecretB = [System.IO.Path]::GetRandomFileName() -replace "\..*"
        }

        It "Verifies writing Hashtable type to $ModuleName vault" {
            $ht = @{
                Blob   = ([byte[]] @(1, 2))
                Str    = "Hi"
            }
            Set-Secret -Name TestVaultHT -Vault $VaultName -Secret $ht -ErrorVariable err
            $err.Count | Should -Be 0
        }

        It "Verifies reading Hashtable type from $ModuleName vault" {
            $ht = Get-Secret -Name TestVaultHT -Vault $VaultName -AsPlainText -ErrorVariable err
            $err.Count | Should -Be 0
            $ht.Blob.Count | Should -Be 2
            $ht.Str | Should -BeExactly "Hi"
        }

        It "Verifies enumerating Hashtable type from $ModuleName vault" {
            $htInfo = Get-SecretInfo -Name TestVaultHT -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $htInfo.Name | Should -BeExactly "TestVaultHT"
            $htInfo.Type | Should -BeExactly "Hashtable"
            $htInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing Hashtable type from $ModuleName vault" {
            Remove-Secret -Name TestVaultHT -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            { Get-Secret -Name TestVaultHT -Vault $VaultName -ErrorAction Stop } | Should -Throw `
                -ErrorId 'GetSecretNotFound,Microsoft.PowerShell.SecretManagement.GetSecretCommand'
        }
    }
}
