module tern.os.pe.optional;

import tern.os.pe;
import std.typecons;

public enum ImageType : ushort
{
    Object,
    ROM = 0x107,
    PE32 = 0x10b,
    PE64 = 0x20b
}

public enum Subsystem : ushort
{
    Unknown = 0,
    Native = 1,
    WindowsGUI = 2,
    WindowsCUI = 3,
    Os2CUI = 5,
    PosixCUI = 7,
    NativeWindows = 8,
    WindowsCEGUI = 9,
    EFIApp = 10,
    EFIBootDriver = 11,
    EFIRuntimeDriver = 12,
    EFIROM = 13,
    Xbox = 14,
    WindowsBootApp = 16
}

public enum DllCharacteristics : ushort
{
    None = 0,
    HighEntropyVA = 0x0020,
    DynamicBase = 0x0040,
    ForceIntegrity = 0x0080,
    NXCompat = 0x0100,
    NoIsolation = 0x0200,
    NoSEH = 0x0400,
    NoBind = 0x0800,
    AppContainer = 0x1000,
    WDMDriver = 0x2000,
    GuardCF = 0x4000,
    TerminalServerAware = 0x8000
}

public struct OptionalImage
{
public:
final:
    /* size_t offset;
    PE pe; */

    // All unset if optionalHeaderSize == 0!
    // magic
    ImageType type;
    ubyte majorLinkerVersion;
    ubyte minorLinkerVersion;
    uint codeSize;
    uint dataSize;
    uint bssSize;
    RVA entryPointRva;
    RVA codeRva;
    // PE32 only!
    RVA dataRva;
    // All below unset if type == ImageType.ROM!
    //    I have no idea where that information came from and I presume it to be false.
    // Assumes that this image is ImageType.PE64.
    ulong imageBase;
    uint sectionAlignment;
    uint fileAlignment;
    ushort majorOSVersion;
    ushort minorOSVersion;
    ushort majorImageVersion;
    ushort minorImageVersion;
    ushort majorSubsystemVersion;
    ushort minorSubsystemVersion;
    uint win32Version;
    uint imageSize;
    uint headersSize;
    uint checksum;
    Subsystem subsystem;
    DllCharacteristics dllCharacteristics;
    ulong stackReserveSize;
    ulong stackCommitSize;
    ulong heapReserveSize;
    ulong heapCommitSize;
    uint loaderFlags;
    uint numDirectories;

    ExportTable exportTable;
    ImportTable importTable;
    ResourceTable resourceTable;
    //ExceptionTable exceptionTable;
    //CertificateTable certTable;
    RelocTable relocTable;
    //DebugData debugData;
    DataDirectory globalPointer;
    //TLSTable tlsTable;
    //LoadConfigTable loadCfgTable;
    DataDirectory boundImport;
    DataDirectory importAddrTable;
    //DelayImportDesc delayImportDesc;
    Cor20Header cor20Header;

    this(PE pe)
    {
        if (pe.coffHeader.optionalHeaderSize == 0)
        {
            type = ImageType.Object;
            return;
        }

        type = pe.read!ImageType;

        if (type == ImageType.PE32 || type == ImageType.ROM)
        {
            majorLinkerVersion = pe.read!ubyte;
            minorLinkerVersion = pe.read!ubyte;
            codeSize = pe.read!uint;
            dataSize = pe.read!uint;
            bssSize = pe.read!uint;
            entryPointRva = RVA(pe, pe.read!uint);
            codeRva = RVA(pe, pe.read!uint);
            dataRva = RVA(pe, pe.read!uint);
            imageBase = cast(ulong)pe.read!uint;
            sectionAlignment = pe.read!uint;
            fileAlignment = pe.read!uint;
            majorOSVersion = pe.read!ushort;
            minorOSVersion = pe.read!ushort;
            majorImageVersion = pe.read!ushort;
            minorImageVersion = pe.read!ushort;
            majorSubsystemVersion = pe.read!ushort;
            minorSubsystemVersion = pe.read!ushort;
            win32Version = pe.read!uint;
            imageSize = pe.read!uint;
            headersSize = pe.read!uint;
            checksum = pe.read!uint;
            subsystem = pe.read!Subsystem;
            dllCharacteristics = pe.read!DllCharacteristics;
            stackReserveSize = cast(ulong)pe.read!uint;
            stackCommitSize = cast(ulong)pe.read!uint;
            heapReserveSize = cast(ulong)pe.read!uint;
            heapCommitSize = cast(ulong)pe.read!uint;
            loaderFlags = pe.read!uint;
            numDirectories = pe.read!uint;
        }
        else if (type == ImageType.PE64)
        {
            majorLinkerVersion = pe.read!ubyte;
            minorLinkerVersion = pe.read!ubyte;
            codeSize = pe.read!uint;
            dataSize = pe.read!uint;
            bssSize = pe.read!uint;
            entryPointRva = RVA(pe, pe.read!uint);
            codeRva = RVA(pe, pe.read!uint);
            imageBase = pe.read!ulong;
            sectionAlignment = pe.read!uint;
            fileAlignment = pe.read!uint;
            majorOSVersion = pe.read!ushort;
            minorOSVersion = pe.read!ushort;
            majorImageVersion = pe.read!ushort;
            minorImageVersion = pe.read!ushort;
            majorSubsystemVersion = pe.read!ushort;
            minorSubsystemVersion = pe.read!ushort;
            win32Version = pe.read!uint;
            imageSize = pe.read!uint;
            headersSize = pe.read!uint;
            checksum = pe.read!uint;
            subsystem = pe.read!Subsystem;
            dllCharacteristics = pe.read!DllCharacteristics;
            stackReserveSize = pe.read!ulong;
            stackCommitSize = pe.read!ulong;
            heapReserveSize = pe.read!ulong;
            heapCommitSize = pe.read!ulong;
            loaderFlags = pe.read!uint;
            numDirectories = pe.read!uint;
        }
    }
}

public struct DataDirectory
{
public:
final:
    /* size_t offset;
    PE pe; */
    
    RVA rva;
    alias rva this;
    uint size;

    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
    }
}