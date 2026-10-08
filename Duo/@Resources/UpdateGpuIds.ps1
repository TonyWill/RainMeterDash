$ErrorActionPreference = 'Stop'
try {
    $root = Split-Path -Parent $MyInvocation.MyCommand.Path
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class DxgiGpuIds {
    [StructLayout(LayoutKind.Sequential)]
    public struct LUID { public uint LowPart; public int HighPart; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DXGI_ADAPTER_DESC {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string Description;
        public uint VendorId;
        public uint DeviceId;
        public uint SubSysId;
        public uint Revision;
        public UIntPtr DedicatedVideoMemory;
        public UIntPtr DedicatedSystemMemory;
        public UIntPtr SharedSystemMemory;
        public LUID AdapterLuid;
    }

    [ComImport, Guid("2411e7e1-12ac-4ccf-bd14-9798e8534dc0"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIAdapter {
        void SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        void SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        void GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        void GetParent(ref Guid riid, out IntPtr ppParent);
        [PreserveSig] int EnumOutputs(uint Output, out IntPtr ppOutput);
        void GetDesc(out DXGI_ADAPTER_DESC pDesc);
        [PreserveSig] int CheckInterfaceSupport(ref Guid InterfaceName, out long pUMDVersion);
    }

    [ComImport, Guid("7b7166ec-21c7-44ae-b21a-c9ae321ae369"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIFactory {
        void SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        void SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        void GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        void GetParent(ref Guid riid, out IntPtr ppParent);
        [PreserveSig] int EnumAdapters(uint Adapter, out IDXGIAdapter ppAdapter);
        [PreserveSig] int MakeWindowAssociation(IntPtr WindowHandle, uint Flags);
        [PreserveSig] int GetWindowAssociation(out IntPtr pWindowHandle);
        [PreserveSig] int CreateSwapChain([MarshalAs(UnmanagedType.IUnknown)] object pDevice, IntPtr pDesc, out IntPtr ppSwapChain);
        [PreserveSig] int CreateSoftwareAdapter(IntPtr Module, out IDXGIAdapter ppAdapter);
    }

    [DllImport("dxgi.dll")]
    static extern int CreateDXGIFactory(ref Guid riid, out IDXGIFactory ppFactory);

    public static string[] Find() {
        var iid = new Guid("7b7166ec-21c7-44ae-b21a-c9ae321ae369");
        IDXGIFactory factory;
        int hr = CreateDXGIFactory(ref iid, out factory);
        if (hr < 0) throw new Exception("CreateDXGIFactory " + hr);
        string iris = null;
        string nvidia = null;
        ulong irisMax = 0;
        ulong nvidiaMax = 0;
        for (uint i = 0; i < 16; i++) {
            IDXGIAdapter adapter;
            hr = factory.EnumAdapters(i, out adapter);
            if (hr < 0) break;
            DXGI_ADAPTER_DESC d;
            adapter.GetDesc(out d);
            if (d.VendorId == 0x1414) continue;
            string luid = "0x" + d.AdapterLuid.LowPart.ToString("x8");
            if (d.VendorId == 0x8086 && iris == null) {
                iris = luid;
                irisMax = (ulong)d.SharedSystemMemory;
            }
            if (d.VendorId == 0x10DE && nvidia == null) {
                nvidia = luid;
                nvidiaMax = (ulong)d.DedicatedVideoMemory;
            }
        }
        if (iris == null || nvidia == null) {
            throw new Exception("missing adapter iris=" + iris + " nvidia=" + nvidia);
        }
        if (irisMax < 1) irisMax = 1;
        if (nvidiaMax < 1) nvidiaMax = 1;
        return new string[] { iris, nvidia, irisMax.ToString(), nvidiaMax.ToString() };
    }
}
'@
    $ids = [DxgiGpuIds]::Find()
    $iris = $ids[0]
    $nvidia = $ids[1]
    $irisMax = $ids[2]
    $nvidiaMax = $ids[3]
    $path = Join-Path $root 'Gpu.lua'
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $text = [System.IO.File]::ReadAllText($path, $utf8)
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }
    $updated = [regex]::Replace($text, '(?m)^local IRIS = "0x[0-9a-f]+"', ('local IRIS = "' + $iris + '"'))
    $updated = [regex]::Replace($updated, '(?m)^local NVIDIA = "0x[0-9a-f]+"', ('local NVIDIA = "' + $nvidia + '"'))
    $updated = [regex]::Replace($updated, '(?m)^local IRIS_MAX = \d+', ('local IRIS_MAX = ' + $irisMax))
    $updated = [regex]::Replace($updated, '(?m)^local NVIDIA_MAX = \d+', ('local NVIDIA_MAX = ' + $nvidiaMax))
    $updated = [regex]::Replace($updated, 'luid_0x00000000_0x[0-9a-f]+', ('luid_0x00000000_' + $iris))
    if ($updated -ne $text) {
        [System.IO.File]::WriteAllText($path, $updated, $utf8)
    }
    Write-Output ('ok Iris=' + $iris + ' NVIDIA=' + $nvidia)
} catch {
    Write-Output 'fail'
    exit 1
}
