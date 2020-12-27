// Portions Copyright (c) Microsoft Corporation
// Copyright (c) 2014, Joel Bennett
// Licensed under MIT license

using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;
using FILETIME = System.Runtime.InteropServices.ComTypes.FILETIME;

namespace BetterCredentials
{
    using System.Management.Automation;
    using System.Security;

    public enum CredentialType : uint
    {
        None = 0,
        Generic = 1,
        DomainPassword = 2,
        DomainCertificate = 3,
        DomainVisiblePassword = 4,
        GenericCertificate = 5,
        DomainExtended = 6,
        Maximum = 7,
        MaximumEx = 1007
    }

    public enum PersistanceType : uint
    {
        Session = 1,
        LocalComputer = 2,
        Enterprise = 3
    }

    public static class SecureStringHelper
    {
        // Methods
        public static SecureString CreateSecureString(string plainString)
        {
            var result = new SecureString();
            if (!string.IsNullOrEmpty(plainString))
            {
                foreach (var c in plainString.ToCharArray())
                {
                    result.AppendChar(c);
                }
            }
            result.MakeReadOnly();
            return result;
        }

        public static SecureString CreateSecureString(IntPtr ptrToString, int length = 0)
        {
            string password = length > 0
                ? Marshal.PtrToStringUni(ptrToString, length)
                : Marshal.PtrToStringUni(ptrToString);
            return CreateSecureString(password);
        }

        public static string CreateString(SecureString secureString)
        {
            string str;
            IntPtr zero = IntPtr.Zero;
            if ((secureString == null) || (secureString.Length == 0))
            {
                return string.Empty;
            }
            try
            {
                zero = Marshal.SecureStringToBSTR(secureString);
                str = Marshal.PtrToStringBSTR(zero);
            }
            finally
            {
                if (zero != IntPtr.Zero)
                {
                    Marshal.ZeroFreeBSTR(zero);
                }
            }
            return str;
        }
    }

    public static class IntPtrHelpers
    {
        public static IntPtr Increment(this IntPtr ptr, int cbSize)
        {
            return new IntPtr(ptr.ToInt64() + cbSize);
        }

        public static IntPtr Increment<T>(this IntPtr ptr)
        {
            return ptr.Increment(Marshal.SizeOf(typeof(T)));
        }

        public static T ElementAt<T>(this IntPtr ptr, int index)
        {
            var offset = Marshal.SizeOf(typeof(T))*index;
            var offsetPtr = ptr.Increment(offset);
            return (T)Marshal.PtrToStructure(offsetPtr, typeof(T));
        }
    }

    public static class Store
    {
        private static string FixTarget(string target)
        {
            if (!target.Contains(":"))
            {
                if (target.Contains("="))
                {
                    target = "MicrosoftPowerShell:" + target;
                }
                else
                {
                    target = "MicrosoftPowerShell:user=" + target;
                }
            }
            return target;
        }

        public static PSObject[] Find(string filter = "", bool fix = true)
        {
            uint count = 0;
            int Flag = 0;
            IntPtr credentialArray = IntPtr.Zero;
            PSObject[] output = null;

            if (string.IsNullOrEmpty(filter))
            {
                filter = null;
                Flag = 1;
            }
            else if(fix)
            {
                filter = FixTarget(filter);
            }

            NativeMethods.PSCredentialMarshaler helper = new NativeMethods.PSCredentialMarshaler();

            if (NativeMethods.CredEnumerate(filter, Flag, out count, out credentialArray))
            {
                IntPtr cred = IntPtr.Zero;
                output = new PSObject[count];
                for (int n = 0; n < count; n++)
                {
                    cred = credentialArray.ElementAt<IntPtr>(n);
                    output[n] = (PSObject)helper.MarshalNativeToManaged(cred);
                }
                helper.CleanUpNativeData(credentialArray);
            }
            else
            {
                // only throw the exception when it's not just a failure to find the credential
                int error = Marshal.GetLastWin32Error();
                if (error != (int) NativeMethods.CREDErrorCodes.ERROR_NOT_FOUND)
                {
                    throw new Win32Exception(error);
                }
            }
            return output;
        }

        public static void Save(PSObject credential)
        {
            var cred = credential.BaseObject as PSCredential;
            if (cred == null)
            {
                throw new ArgumentException("Credential object does not contain a PSCredential", "credential");
            }

            if (!NativeMethods.CredWrite(credential, 0))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }

        public static void Delete(string target, CredentialType type = CredentialType.Generic, bool fix = true)
        {
            if (fix) {
                target = FixTarget(target);
            }
            if (!NativeMethods.CredDelete(target, type, 0))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }

        public static PSObject Get(string target, bool fix = true)
        {
            PSObject cred = null;
            if (fix)
            {
                target = FixTarget(target);
            }

            if (!NativeMethods.CredFindBestCredential(target, CredentialType.Generic, 0, out cred))
            {
                // only throw the exception when it's not just a failure to find the credential
                int error = Marshal.GetLastWin32Error();
                if (error != (int) NativeMethods.CREDErrorCodes.ERROR_NOT_FOUND )
                {
                    throw new Win32Exception(error);
                }
            }

            return cred;
        }


        public static PSObject Load(string target, CredentialType type = CredentialType.Generic, bool fix = true)
        {
            PSObject cred = null;
            if (fix)
            {
                target = FixTarget(target);
            }

            if (!NativeMethods.CredRead(target, type, 0, out cred))
            {
                // only throw the exception when it's not just a failure to find the credential
                int error = Marshal.GetLastWin32Error();
                if ( error != (int) NativeMethods.CREDErrorCodes.ERROR_NOT_FOUND )
                {
                    throw new Win32Exception(error);
                }
            }

            return cred;
        }

    }

    /// <summary>
    /// Defines the attribute used to designate a cmdlet parameter as one that
    /// should accept credentials.
    /// </summary>
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = false)]
    public sealed class CredentialAttribute : ArgumentTransformationAttribute
    {
        public bool MandatoryPassword { get; set; } = false;
        public bool Save { get; set; } = false;
        public string Title { get; set; } = "PowerShell credential request";
        public string Prompt { get; set; } = "Enter your credentials.";
        public string Domain { get; set; } = string.Empty;
        public string Target { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public PSCredentialTypes AllowedCredentialTypes { get; set; }
        public PSCredentialUIOptions Options { get; set; }

        /// <summary>
        /// Transforms the input data to an PSCredential.
        /// </summary>
        /// <param name="engineIntrinsics">
        /// The engine APIs for the context under which the transformation is being
        /// made.
        /// </param>
        /// <param name="inputData">
        /// If Null, the transformation prompts for both Username and Password
        /// If a string, the transformation uses the input for a username, and prompts
        ///    for a Password
        /// If already an PSCredential, the transform does nothing.
        /// </param>
        /// <returns>An PSCredential object representing the inputData.</returns>
        public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        {
            PSCredential cred = null;
            string userName = null;
            bool shouldPrompt = false;

            if ((engineIntrinsics == null) ||
                (engineIntrinsics.Host == null) ||
                (engineIntrinsics.Host.UI == null))
            {
                throw new ArgumentNullException(nameof(engineIntrinsics));
            }

            if (inputData == null)
            {
                shouldPrompt = true;
            }
            else
            {
                // System.Console.WriteLine($"Converting {inputData}");
                // Try to coerce the input as an PSCredential
                if (!LanguagePrimitives.TryConvertTo<PSCredential>(inputData, out cred))
                {
                    // System.Console.WriteLine($"Treating '{inputData}' as user name");
                    shouldPrompt = true;
                    // Try to coerce the username from the string
                    if (!LanguagePrimitives.TryConvertTo(inputData, out userName))
                    {
                        throw new ArgumentNullException("userName");
                    }
                }
            }

            if (shouldPrompt && Save)
            {
                if (!string.IsNullOrEmpty(Target))
                {
                    // System.Console.WriteLine($"Loading Target: {Target}");
                    try {
                        cred = BetterCredentials.Store.Load(Target, CredentialType.Generic, false).BaseObject as PSCredential;
                        shouldPrompt = false;
                    } catch {}

                }
                else if (!string.IsNullOrEmpty(userName))
                {
                    // System.Console.WriteLine($"Loading UserName: {userName}");
                    try {
                        cred = BetterCredentials.Store.Load(userName).BaseObject as PSCredential;
                        shouldPrompt = false;
                    } catch {}
                }
            }

            if (shouldPrompt)
            {
                // System.Console.WriteLine($"Prompting {userName}");
                cred = engineIntrinsics.Host.UI.PromptForCredential(
                    Title,
                    Prompt,
                    userName,
                    Domain,
                    AllowedCredentialTypes,
                    Options);
            }

            if (MandatoryPassword && cred.Password.Length == 0)
            {
                throw new ArgumentNullException("password");
            }

            if (Save)
            {
                // System.Console.WriteLine($"Saving {cred.UserName}");
                var storeCred = new PSObject(cred);

                if (!string.IsNullOrEmpty(Target)) {
                    // System.Console.WriteLine($"Setting Target: {Target}");
                    storeCred.Properties.Add(new PSNoteProperty("Target", Target));
                }
                if (!string.IsNullOrEmpty(Description)) {
                    storeCred.Properties.Add(new PSNoteProperty("Description", Description));
                }

                // System.Console.WriteLine($"Saving {storeCred}");
                BetterCredentials.Store.Save(storeCred);
            }
            return cred;
        }

        /// <summary/>
        public override bool TransformNullOptionalParameters { get { return false; } }
    }


    public class NativeMethods
    {
        public enum CREDErrorCodes
        {
            NO_ERROR = 0,
            ERROR_NOT_FOUND = 1168,
            ERROR_NO_SUCH_LOGON_SESSION = 1312,
            ERROR_INVALID_PARAMETER = 87,
            ERROR_INVALID_FLAGS = 1004,
            ERROR_BAD_USERNAME = 2202,
            SCARD_E_NO_READERS_AVAILABLE = (int)(0x8010002E - 0x100000000),
            SCARD_E_NO_SMARTCARD = (int)(0x8010000C - 0x100000000),
            SCARD_W_REMOVED_CARD = (int)(0x80100069 - 0x100000000),
            SCARD_W_WRONG_CHV = (int)(0x8010006B - 0x100000000)
        }

        [DllImport("Advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredRead(string target, CredentialType type, int reservedFlag,
            [MarshalAs(UnmanagedType.CustomMarshaler, MarshalTypeRef = typeof(PSCredentialMarshaler))]
            out PSObject credentialout);

        [DllImport("Advapi32.dll", EntryPoint = "CredWriteW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredWrite([In]
            [MarshalAs(UnmanagedType.CustomMarshaler, MarshalTypeRef = typeof(PSCredentialMarshaler))]
            PSObject userCredential, [In] UInt32 flags);

        [DllImport("advapi32.dll", EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredDelete(string target, CredentialType type, int flags);

        [DllImport("Advapi32.dll", EntryPoint = "CredFree", SetLastError = true)]
        public static extern bool CredFree([In] IntPtr cred);

        [DllImport("advapi32.dll", EntryPoint = "CredEnumerateW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredEnumerate(string filter, int flag, out uint count, out IntPtr pCredentials);

        [DllImport("advapi32.dll", EntryPoint = "CredFindBestCredentialW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredFindBestCredential(string target, CredentialType type, int reservedFlag,
            [MarshalAs(UnmanagedType.CustomMarshaler, MarshalTypeRef = typeof(PSCredentialMarshaler))]
            out PSObject credentialout);

        [DllImport("ole32.dll")]
        public static extern void CoTaskMemFree(IntPtr ptr);


        public class PSCredentialMarshaler : ICustomMarshaler
        {
            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            private class NATIVECREDENTIAL
            {
                public UInt32 Flags;
                public CredentialType Type = CredentialType.Generic;
                public string TargetName;
                public string Comment;
                public FILETIME LastWritten;
                public UInt32 CredentialBlobSize;
                public IntPtr CredentialBlob;
                public PersistanceType Persist = PersistanceType.Enterprise;
                public UInt32 AttributeCount;
                public IntPtr Attributes;
                public string TargetAlias;
                public string UserName;
            }

            public void CleanUpManagedData(object ManagedObj)
            {
                // Nothing to do since all data can be garbage collected.
            }

            public void CleanUpNativeData(IntPtr pNativeData)
            {
                if (pNativeData == IntPtr.Zero)
                {
                    return;
                }
                CredFree(pNativeData);
            }

            public int GetNativeDataSize()
            {
                return Marshal.SizeOf(typeof(NATIVECREDENTIAL));
            }

            public IntPtr MarshalManagedToNative(object obj)
            {
                PSCredential credential;
                PSObject credo = obj as PSObject;
                if (credo != null)
                {
                    credential = credo.BaseObject as PSCredential;
                }
                else
                {
                    credential = obj as PSCredential;
                }

                if (credential == null)
                {
                    Console.WriteLine("Error: Can't convert!");
                    return IntPtr.Zero;
                }
                var nCred = new NATIVECREDENTIAL()
                    {
                        UserName = credential.UserName,
                        CredentialBlob = Marshal.SecureStringToCoTaskMemUnicode(credential.Password),
                        CredentialBlobSize = (uint)credential.Password.Length * 2,
                        TargetName = "MicrosoftPowerShell:user=" + credential.UserName,
                        Type = CredentialType.Generic,
                        Persist = PersistanceType.Enterprise
                    };

                if (credo != null)
                {
                    foreach (var m in credo.Members)
                    {
                        switch (m.Name)
                        {
                            case "Target":
                                if (m.Value != null)
                                    nCred.TargetName = m.Value.ToString();
                                break;
                            case "TargetAlias":
                                if (m.Value != null)
                                    nCred.TargetAlias = m.Value.ToString();
                                break;
                            case "Type":
                                if (m.Value != null)
                                    nCred.Type = (CredentialType)m.Value;
                                break;
                            case "Persistence":
                                if (m.Value != null)
                                    nCred.Persist = (PersistanceType)m.Value;
                                break;
                            case "Description":
                                if (m.Value != null)
                                    nCred.Comment = m.Value.ToString();
                                break;
                            case "LastWriteTime":
                                // ignored
                                break;
                        }
                    }
                }

                // System.Console.WriteLine($"Marshalling Target '{nCred.TargetName}' UserName: '{nCred.UserName}'");
                IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf(nCred));
                Marshal.StructureToPtr(nCred, ptr, false);
                return ptr;
            }

            public object MarshalNativeToManaged(IntPtr pNativeData)
            {
                if (pNativeData == IntPtr.Zero)
                {
                    return null;
                }

                var ncred = (NATIVECREDENTIAL)Marshal.PtrToStructure(pNativeData, typeof(NATIVECREDENTIAL));

                var securePass = (ncred.CredentialBlob == IntPtr.Zero) ? new SecureString()
                                : SecureStringHelper.CreateSecureString(ncred.CredentialBlob, (int)(ncred.CredentialBlobSize)/2);

                var credEx = new PSObject(new PSCredential(ncred.UserName ?? "-", securePass));

                credEx.Members.Add(new PSNoteProperty("Target", ncred.TargetName));
                credEx.Members.Add(new PSNoteProperty("TargetAlias", ncred.TargetAlias));
                credEx.Members.Add(new PSNoteProperty("Type", (CredentialType)ncred.Type));
                credEx.Members.Add(new PSNoteProperty("Persistence", (PersistanceType)ncred.Persist));
                credEx.Members.Add(new PSNoteProperty("Description", ncred.Comment));
                credEx.Members.Add(new PSNoteProperty("LastWriteTime", DateTime.FromFileTime((((long)ncred.LastWritten.dwHighDateTime) << 32) + ncred.LastWritten.dwLowDateTime)));

                return credEx;
            }

            public static ICustomMarshaler GetInstance(string cookie)
            {
                return new PSCredentialMarshaler();
            }
        }
    }
}
