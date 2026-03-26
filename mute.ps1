$className = "AudioCore_" + [guid]::NewGuid().ToString("N")

$code = @"
using System;
using System.Runtime.InteropServices;

public class $className {
    [DllImport("ole32.dll", ExactSpelling = true)]
    public static extern int CoCreateInstance(ref Guid rclsid, IntPtr pUnkOuter, int dwClsContext, ref Guid riid, out IntPtr ppv);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int GetDefaultAudioEndpointDelegate(IntPtr instance, int dataFlow, int role, out IntPtr ppEndpoint);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int ActivateDelegate(IntPtr instance, ref Guid iid, int dwClsCtx, IntPtr pActivationParams, out IntPtr ppInterface);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int SetMuteDelegate(IntPtr instance, int bMute, IntPtr pguidEventContext);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    delegate int GetMuteDelegate(IntPtr instance, out int pbMute);

    public static void Execute() {
        IntPtr pEnumerator = IntPtr.Zero;
        IntPtr pDevice = IntPtr.Zero;
        IntPtr pVolume = IntPtr.Zero;

        try {
            Guid CLSID_MMDeviceEnumerator = new Guid("BCDE0395-E52F-467C-8E3D-C4579291692E");
            Guid IID_IMMDeviceEnumerator = new Guid("A95664D2-9614-4F35-A746-DE8DB63617E6");

            if (CoCreateInstance(ref CLSID_MMDeviceEnumerator, IntPtr.Zero, 1, ref IID_IMMDeviceEnumerator, out pEnumerator) != 0) return;

            IntPtr vtableEnumerator = Marshal.ReadIntPtr(pEnumerator);
            IntPtr pGetDefaultAudioEndpoint = Marshal.ReadIntPtr(vtableEnumerator, 4 * IntPtr.Size);
            GetDefaultAudioEndpointDelegate getDefaultAudioEndpoint = (GetDefaultAudioEndpointDelegate)Marshal.GetDelegateForFunctionPointer(pGetDefaultAudioEndpoint, typeof(GetDefaultAudioEndpointDelegate));

            if (getDefaultAudioEndpoint(pEnumerator, 0, 0, out pDevice) != 0) return;

            IntPtr vtableDevice = Marshal.ReadIntPtr(pDevice);
            IntPtr pActivate = Marshal.ReadIntPtr(vtableDevice, 3 * IntPtr.Size);
            ActivateDelegate activate = (ActivateDelegate)Marshal.GetDelegateForFunctionPointer(pActivate, typeof(ActivateDelegate));

            Guid IID_IAudioEndpointVolume = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");
            if (activate(pDevice, ref IID_IAudioEndpointVolume, 23, IntPtr.Zero, out pVolume) != 0) return;

            IntPtr vtableVolume = Marshal.ReadIntPtr(pVolume);
            IntPtr pGetMute = Marshal.ReadIntPtr(vtableVolume, 15 * IntPtr.Size);
            GetMuteDelegate getMute = (GetMuteDelegate)Marshal.GetDelegateForFunctionPointer(pGetMute, typeof(GetMuteDelegate));

            int isMuted = 0;
            if (getMute(pVolume, out isMuted) != 0) return;

            if (isMuted == 0) {
                IntPtr pSetMute = Marshal.ReadIntPtr(vtableVolume, 14 * IntPtr.Size);
                SetMuteDelegate setMute = (SetMuteDelegate)Marshal.GetDelegateForFunctionPointer(pSetMute, typeof(SetMuteDelegate));
                setMute(pVolume, 1, IntPtr.Zero);
            }
        } catch {
            // 静默处理所有异常
        } finally {
            if (pVolume != IntPtr.Zero) Marshal.Release(pVolume);
            if (pDevice != IntPtr.Zero) Marshal.Release(pDevice);
            if (pEnumerator != IntPtr.Zero) Marshal.Release(pEnumerator);
        }
    }
}
"@

Add-Type -TypeDefinition $code
Invoke-Expression "[$className]::Execute()"