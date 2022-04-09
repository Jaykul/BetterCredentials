# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

Describe "BetterCredentials.Extensions" -tags CI {
    BeforeAll {
        $ModuleName = "BetterCredentials.Extension"
        $VaultName = "BetterCredentialsTestVault"
        $PSModulePath = $Env:PSModulePath
        $Env:PSModulePath = "$(Convert-Path ..)$([IO.Path]::PathSeparator)$PSModulePath"
        Remove-Module BetterCredentials, $ModuleName -ErrorAction SilentlyContinue
        Import-Module -Name BetterCredentials
        Import-Module -Name Microsoft.PowerShell.SecretManagement
        Import-Module (Get-Module BetterCredentials | Split-Path | Join-Path -ChildPath "$ModuleName\$ModuleName.psd1")

        $PSDefaultParameterValues, $DPV = @{}, $PSDefaultParameterValues

        Get-Command -mo BetterCredentials.Extension -ParameterName VaultName | ForEach-Object {
            $PSDefaultParameterValues[($_.Name + ":VaultName")]            = $VaultName
            $PSDefaultParameterValues[($_.Name + ":AdditionalParameters")] = @{ Prefix = "${VaultName}|" }
        }
        # Register-SecretVault $VaultName -ModuleName $ModuleName -VaultParameters @{ Prefix = "${VaultName}|" }
        # Set-BetterCredentialsOption $VaultName
        # Set-SecretVaultDefault $VaultName
    }

    AfterAll {
        # Remove-Module $ModuleName
        $PSDefaultParameterValues = $DPV
        # Unregister-SecretVault -Name $VaultName -ErrorAction Ignore
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
            [System.Net.NetworkCredential]::new('', ($cred.Password)).Password | Should -BeExactly $randomSecret
        }

        It "Verifies enumerating PSCredential type from $ModuleName vault" {
            $credInfo = Get-SecretInfo -Filter TestVaultCred -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $credInfo.Name | Should -BeExactly "TestVaultCred"
            $credInfo.Type | Should -BeExactly "PSCredential"
            $credInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing PSCredential type from $ModuleName vault" {
            Remove-Secret -Name TestVaultCred -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            Get-Secret -Name TestVaultCred -Vault $VaultName -ErrorAction Stop | Should -BeNullOrEmpty
        }
    }

    Describe VerifySecureStringType {

        BeforeAll {
            $randomSecret = [System.IO.Path]::GetRandomFileName()
            $secureStringToWrite = ConvertTo-SecureString $randomSecret -AsPlainText -Force
        }

        It "Verifies writing SecureString type to $ModuleName vault" {
            Set-Secret -Name TestVaultSecureStr -Secret $secureStringToWrite -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
        }

        It "Verifies reading SecureString type from $ModuleName vault" {
            $ss = Get-Secret -Name TestVaultSecureStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            [System.Net.NetworkCredential]::new('', $ss).Password | Should -BeExactly $randomSecret
        }

        It "Verifies enumerating SecureString type from $ModuleName vault" {
            $ssInfo = Get-SecretInfo -Filter TestVaultSecureStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $ssInfo.Name | Should -BeExactly "TestVaultSecureStr"
            $ssInfo.Type | Should -BeExactly "SecureString"
            $ssInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing SecureString type from $ModuleName vault" {
            Remove-Secret -Name TestVaultSecureStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            Get-Secret -Name TestVaultSecureStr -Vault $VaultName -ErrorAction Stop | Should -BeNullOrEmpty
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
            [System.Net.NetworkCredential]::new('', $str).Password | Should -BeExactly "HelloTestVault"
        }

        It "Verifies enumerating string type from $ModuleName vault" {
            $strInfo = Get-SecretInfo -Filter TestVaultStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $strInfo.Name | Should -BeExactly "TestVaultStr"
            $strInfo.Type | Should -BeExactly "String"
            $strInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing string type from $ModuleName vault" {
            Remove-Secret -Name TestVaultStr -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            Get-Secret -Name TestVaultStr -Vault $VaultName -ErrorAction Stop | Should -BeNullOrEmpty
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
            $blobInfo = Get-SecretInfo -Filter TestVaultBlob -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $blobInfo.Name | Should -BeExactly "TestVaultBlob"
            $blobInfo.Type | Should -BeExactly "ByteArray"
            $blobInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing byte[] type from $ModuleName vault" {
            Remove-Secret -Name TestVaultBlob -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            Get-Secret -Name TestVaultBlob -Vault $VaultName -ErrorAction Stop | Should -BeNullOrEmpty
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
            $ht = Get-Secret -Name TestVaultHT -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $ht.Blob.Count | Should -Be 2
            $ht.Str | Should -BeExactly "Hi"
        }

        It "Verifies enumerating Hashtable type from $ModuleName vault" {
            $htInfo = Get-SecretInfo -Filter TestVaultHT -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            $htInfo.Name | Should -BeExactly "TestVaultHT"
            $htInfo.Type | Should -BeExactly "Hashtable"
            $htInfo.VaultName | Should -BeExactly $VaultName
        }

        It "Verifies removing Hashtable type from $ModuleName vault" {
            Remove-Secret -Name TestVaultHT -Vault $VaultName -ErrorVariable err
            $err.Count | Should -Be 0
            Get-Secret -Name TestVaultHT -Vault $VaultName -ErrorAction Stop | Should -BeNullOrEmpty
        }
    }
}
