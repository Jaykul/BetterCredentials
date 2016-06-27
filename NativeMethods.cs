// Copyright (c) 2014, Joel Bennett
// Licensed under MIT license
using System;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;
using FILETIME = System.Runtime.InteropServices.ComTypes.FILETIME;

namespace CredentialManagement
{
   using System.Management.Automation;
   using System.Security;

   public enum CredentialType : uint
   {
       None = 0,
       Generic = 1,
       DomainPassword = 2,
       DomainCertificate = 3,
       DomainVisiblePassword = 4
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

   public static class Store
   {

       public static PSObject Load(string target, CredentialType type = CredentialType.Generic)
       {
           PSObject cred;
           NativeMethods.CredRead(FixTarget(target), type, 0, out cred);

           return cred;
       }

       public static bool Test(string filter)
       {
           uint count;
           IntPtr pCredentials;
           bool foundCredential = NativeMethods.CredEnumerate(FixTarget(filter), 0, out count, out pCredentials);
           return foundCredential;
       }

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

       public static NativeMethods.CREDErrorCodes Save(PSObject credential)
       {
           var cred = credential.BaseObject as PSCredential;
           if (cred == null)
           {
               throw new ArgumentException("Credential object does not contain a PSCredential");
           }

           if (!NativeMethods.CredWrite(credential, 0))
           {
               return (NativeMethods.CREDErrorCodes)Marshal.GetLastWin32Error();
           }
           else return NativeMethods.CREDErrorCodes.NO_ERROR;
       }

       public static NativeMethods.CREDErrorCodes Delete(string target, CredentialType type = CredentialType.Generic)
       {
           if (!NativeMethods.CredDelete(FixTarget(target), type, 0))
           {
               return (NativeMethods.CREDErrorCodes)Marshal.GetLastWin32Error();
           }
           else return NativeMethods.CREDErrorCodes.NO_ERROR;
       }
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

               var credEx = new PSObject(new PSCredential(ncred.UserName, securePass));

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
