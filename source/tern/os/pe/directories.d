module tern.os.pe.directories;

import tern.os.pe;
import std.bitmanip;
import std.datetime;

public struct ExportTable
{
public:
final:
    RVA rva;
    alias rva this;
    uint size;

    uint flags;
    SysTime timestamp;
    ushort majorVersion;
    ushort minorVersion;
    RVA nameRva;
    uint ordinalBase;
    uint numAddresses;
    uint numNames;
    RVA addressesRva;
    RVA namesRva;
    RVA ordinalsRva;

    string name;
    ExportEntry[] entries;

    bool valid() => rva.raw != 0 && size != 0 && rva.offset + size < pe.optionalImage.imageBase + pe.data.length;

    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;

        size_t _position = pe.position;
        scope(exit) pe.position = _position;
        pe.position = rva.offset;

        if (!valid)
            return;

        flags = pe.read!uint;
        timestamp = SysTime.fromUnixTime(cast(ulong)pe.read!uint);
        majorVersion = pe.read!ushort;
        minorVersion = pe.read!ushort;
        nameRva = RVA(pe, pe.read!uint);
        ordinalBase = pe.read!uint;
        numAddresses = pe.read!uint;
        numNames = pe.read!uint;
        addressesRva = RVA(pe, pe.read!uint);
        namesRva = RVA(pe, pe.read!uint);
        ordinalsRva = RVA(pe, pe.read!uint);

        if (nameRva.raw != 0)
        {
            pe.position = nameRva.offset;
            name = pe.readString!char;
        }

        pe.position = namesRva.offset;
        foreach (i; 0..numNames)
        {
            size_t __position = pe.position;
            pe.position += i * uint.sizeof;
            pe.position = RVA(pe, pe.read!uint).offset;
            entries ~= ExportEntry(pe.readString!char);
            pe.position = __position;
        }

        pe.position = ordinalsRva.offset + (ordinalBase * ushort.sizeof);
        foreach (i; 0..numNames)
        {
            size_t __position = pe.position;
            pe.position += i * ushort.sizeof;
            ushort ordinal = pe.read!ushort;

            if (ordinal > numNames)
                ordinal = cast(ushort)(i + ordinalBase);

            pe.position = addressesRva.offset + (ordinal - ordinalBase) * uint.sizeof;
            RVA addr = RVA(pe, pe.read!(uint));
            if (addr.raw >= rva.raw && addr.raw < rva.raw + size)
            {
                pe.position = rva.offset;
                entries[i].forward = pe.readString!char;
            }
            else
                entries[i].rva = addr;

            pe.position = __position;
        }
    }
}

public struct ExportEntry
{
public:
final:
    /* size_t offset;
    PE pe; */

    string name;
    // Can only either have an address or a forward.
    RVA rva;
    string forward;
}

public struct ImportTable
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA rva;
    alias rva this;
    uint size;
    bool valid;

    ImportEntry[] entries;

    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
        valid = rva.raw != 0 && size != 0 && rva.offset + size < pe.optionalImage.imageBase + pe.data.length;

        size_t _position = pe.position;
        scope(exit) pe.position = _position;
        pe.position = rva.offset;

        if (rva.raw == 0 || size == 0 || rva.offset + size >= pe.optionalImage.imageBase + pe.data.length)
            return;

        foreach (i; 0..(size / 20))
        {
            ImportEntry entry = ImportEntry(pe);

            if (entry == ImportEntry.init)
                return;
            else
                entries ~= entry;
        }
    }
}

public struct ImportEntry
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA lookupRva;
    SysTime timestamp;
    uint forwarderChain;
    RVA nameRva;
    RVA addressRva;

    this(PE pe)
    {
        lookupRva = RVA(pe, pe.read!uint);
        timestamp = SysTime.fromUnixTime(cast(ulong)pe.read!uint);
        forwarderChain = pe.read!uint;
        nameRva = RVA(pe, pe.read!uint);
        addressRva = RVA(pe, pe.read!uint);
    }
}

public struct ImportLookup
{
public:
final:
    /* size_t offset;
    PE pe; */

    mixin(bitfields!(
        bool, "importByName", 1,
        ushort, "ordinalNumber", 16,
        ulong, "nameTableRva", 47,
    ));
}

public struct NameTable
{
public:
final:
    /* size_t offset;
    PE pe; */

    ushort hint;
    string name;
}

/// 32-bit MIPS
public struct FunctionEntryMIPS32
{
public:
final:
    /* size_t offset;
    PE pe; */

    uint beginVa;
    uint endVa;
    uint handler;
    uint handlerData;
    uint prologEndVa;
}

/// ARM, PowerPC, SH3 and SH4 Windows CE platforms
public struct FunctionEntryAPPC34
{
public:
final:
    /* size_t offset;
    PE pe; */

    uint beginVa;
    mixin(bitfields!(
        uint, "prologLen", 8,
        uint, "funcLen", 22,
        bool, "is32Bit", 1,
        bool, "hasHandler", 1
    ));
}

/// x64 and Itanium platforms
public struct FunctionEntryItanium64
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA beginRva;
    RVA endRva;
    RVA unwindRva;
}

public enum RelocBlockType : ubyte
{
    Absolute,
    High,
    Low,
    HighLow,
    HighAdj,
    MIPS_JmpAddr,
    ARM_Mov32,
    RISCV_High20,
    Thumb_Mov32 = 7,
    RISCV_Low12L = 7,
    RISCV_Low12S,
    LoongArch32_MarkLA = 8,
    LoongArch64_MarkLA = 8,
    MIPS_JmpAddr16,
    Dir64
}

public struct RelocTable
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA rva;
    alias rva this;
    uint size;
    bool valid;

    RelocBlock[] blocks;

    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
        valid = rva.raw != 0 && size != 0 && rva.offset + size < pe.optionalImage.imageBase + pe.data.length;

        size_t _position = pe.position;
        scope(exit) pe.position = _position;
        pe.position = rva.offset;

        if (!valid)
            return;

        while (pe.position < rva.offset + size)
        {
            RelocBlock block;
            block.rva = RVA(pe, pe.read!uint);
            block.size = pe.read!uint;

            foreach (i; 0..(((block.size > size ? size : block.size) - 8) / 2))
                block.entries ~= pe.read!RelocBlockEntry;

            blocks ~= block;
        }
    }
}

public struct RelocBlock
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA rva;
    alias rva this;
    uint size;
    RelocBlockEntry[] entries;
}

public struct RelocBlockEntry
{
public:
final:
    /* size_t offset;
    PE pe; */

    mixin(bitfields!(
        RelocBlockType, "type", 4,
        uint, "offset", 12
    ));
}

public struct ResourceTable
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA rva;
    alias rva this;
    uint size;
    bool valid;

    uint characteristics;
    SysTime timestamp;
    ushort majorVersion;
    ushort minorVersion;
    ushort numNames;
    ushort numIDs;

    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
        valid = rva.raw != 0 && size != 0 && rva.offset + size < pe.optionalImage.imageBase + pe.data.length;

        size_t _position = pe.position;
        scope(exit) pe.position = _position;
        pe.position = rva.offset;

        if (rva.raw == 0 || size == 0 || rva.offset + size >= pe.optionalImage.imageBase + pe.data.length)
            return;

        characteristics = pe.read!uint;
        timestamp = SysTime.fromUnixTime(cast(ulong)pe.read!uint);
        majorVersion = pe.read!ushort;
        minorVersion = pe.read!ushort;
        numNames = pe.read!ushort;
        numIDs = pe.read!ushort;
    }
}

public struct ResourceEntry
{
public:
final:
    /* size_t offset;
    PE pe; */

    union
    {
        uint nameOffset;
        uint id;
    }
    union
    {
        uint dataEntryOffset;
        uint subDirOffset;
    }
}

public struct ResourceDirectoryString
{
public:
final:
    /* size_t offset;
    PE pe; */

    wstring str;
}

public struct ResourceDataEntry
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA rva;
    alias rva this;
    uint size;
    uint codepage;
    uint reserved;

    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
        codepage = pe.read!uint;
        reserved = pe.read!uint;
    }
}

public struct Cor20Header
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA rva;
    alias rva this;
    uint size;
    bool valid;

    uint internalSize;
    ushort majorRuntimeVersion;
    ushort minorRuntimeVersion;
    CorMetadataTable metadata;
    uint flags;
    uint entryPointToken;
    // TODO: This should read actual tables.
    DataDirectory resources;
    DataDirectory strongNameSignature;
    DataDirectory codeManagerTable;
    DataDirectory vtableFixups;
    DataDirectory exportAddressTableJumps;
    DataDirectory managedNativeHeader;

    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
        valid = rva.raw != 0 && size != 0 && rva.offset + size < pe.optionalImage.imageBase + pe.data.length;

        size_t _position = pe.position;
        scope(exit) pe.position = _position;
        pe.position = rva.offset;

        if (rva.raw == 0 || size == 0 || rva.offset + size >= pe.optionalImage.imageBase + pe.data.length)
            return;

        internalSize = pe.read!uint;
        majorRuntimeVersion = pe.read!ushort;
        minorRuntimeVersion = pe.read!ushort;
        metadata = CorMetadataTable(pe);
        flags = pe.read!uint;
        entryPointToken = pe.read!uint;
        resources = pe.read!DataDirectory;
        strongNameSignature = pe.read!DataDirectory;
        codeManagerTable = pe.read!DataDirectory;
        vtableFixups = pe.read!DataDirectory;
        exportAddressTableJumps = pe.read!DataDirectory;
        managedNativeHeader = pe.read!DataDirectory;
    }
}

public struct CorMetadataTable
{
public:
final:
    /* size_t offset;
    PE pe; */

    RVA rva;
    alias rva this;
    uint size;
    bool valid;

    char[4] signature;
    ushort majorVersion;
    ushort minorVersion;
    uint reserved;
    //uint versionStringLength;
    string versionString;
    bool extraData;
    ubyte padding;
    ushort streams;

    // TODO: Read more metadata to chain.
    this(PE pe)
    {
        rva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
        valid = rva.raw != 0 && size != 0 && rva.offset + size < pe.optionalImage.imageBase + pe.data.length;

        size_t _position = pe.position;
        scope(exit) pe.position = _position;
        pe.position = rva.offset;

        if (rva.raw == 0 || size == 0 || rva.offset + size >= pe.optionalImage.imageBase + pe.data.length)
            return;

        signature = pe.read!(char[4]);
        majorVersion = pe.read!ushort;
        minorVersion = pe.read!ushort;
        reserved = pe.read!uint;
        uint length = pe.read!uint;
        versionString = pe.read!char(length);
        // 4-byte boundary
        pe.position += length + 12 % 4;
        extraData = pe.read!bool;
        padding = pe.read!ubyte;
        streams = pe.read!ushort;
    }
}

public enum GlobalFlags : uint
{
    None,
    HeapEnableTailCheck = 0x00000010,
    HeapEnableFreeCheck = 0x00000020,
    HeapValidateParameters = 0x00000040,
    HeapValidateAll = 0x00000080,
    PoolEnableTailCheck = 0x00000800,
    PoolEnableFreeCheck = 0x00001000,
    ApplicationVerifier = 0x01000000,
    UserStackTraceDb = 0x10000000
}

public enum ProcessAffinityMask : ulong
{
    Core0 = 0x0000000000000001UL,
    Core1 = 0x0000000000000002UL,
    Core2 = 0x0000000000000004UL,
    Core3 = 0x0000000000000008UL,
    Core4 = 0x0000000000000010UL,
    Core5 = 0x0000000000000020UL,
    Core6 = 0x0000000000000040UL,
    Core7 = 0x0000000000000080UL,
    Core8 = 0x0000000000000100UL,
    Core9 = 0x0000000000000200UL,
    Core10 = 0x0000000000000400UL,
    Core11 = 0x0000000000000800UL,
    Core12 = 0x0000000000001000UL,
    Core13 = 0x0000000000002000UL,
    Core14 = 0x0000000000004000UL,
    Core15 = 0x0000000000008000UL,
    Core16 = 0x0000000000010000UL,
    Core17 = 0x0000000000020000UL,
    Core18 = 0x0000000000040000UL,
    Core19 = 0x0000000000080000UL,
    Core20 = 0x0000000000100000UL,
    Core21 = 0x0000000000200000UL,
    Core22 = 0x0000000000400000UL,
    Core23 = 0x0000000000800000UL,
    Core24 = 0x0000000001000000UL,
    Core25 = 0x0000000002000000UL,
    Core26 = 0x0000000004000000UL,
    Core27 = 0x0000000008000000UL,
    Core28 = 0x0000000010000000UL,
    Core29 = 0x0000000020000000UL,
    Core30 = 0x0000000040000000UL,
    Core31 = 0x0000000080000000UL,
    AllCores_32 = 0x0000000100000000UL,
    Core32 = 0x0000000100000000UL,
    Core33 = 0x0000000200000000UL,
    Core34 = 0x0000000400000000UL,
    Core35 = 0x0000000800000000UL,
    Core36 = 0x0000001000000000UL,
    Core37 = 0x0000002000000000UL,
    Core38 = 0x0000004000000000UL,
    Core39 = 0x0000008000000000UL,
    Core40 = 0x0000010000000000UL,
    Core41 = 0x0000020000000000UL,
    Core42 = 0x0000040000000000UL,
    Core43 = 0x0000080000000000UL,
    Core44 = 0x0000100000000000UL,
    Core45 = 0x0000200000000000UL,
    Core46 = 0x0000400000000000UL,
    Core47 = 0x0000800000000000UL,
    Core48 = 0x0001000000000000UL,
    Core49 = 0x0002000000000000UL,
    Core50 = 0x0004000000000000UL,
    Core51 = 0x0008000000000000UL,
    Core52 = 0x0010000000000000UL,
    Core53 = 0x0020000000000000UL,
    Core54 = 0x0040000000000000UL,
    Core55 = 0x0080000000000000UL,
    Core56 = 0x0100000000000000UL,
    Core57 = 0x0200000000000000UL,
    Core58 = 0x0400000000000000UL,
    Core59 = 0x0800000000000000UL,
    Core60 = 0x1000000000000000UL,
    Core61 = 0x2000000000000000UL,
    Core62 = 0x4000000000000000UL,
    Core63 = 0x8000000000000000UL,
    AllCores_64 = 0xFFFFFFFFFFFFFFFFUL
}

public enum ProcessHeapFlags : uint
{
    None,
    NoSerialize = 0x00000001,
    GenerateExceptions = 0x00000004,
    ZeroMemory = 0x00000008,
    ReallocateInPlaceOnly = 0x00000010,
    NoSerializeDTV = 0x00000020,
    TailCheckingEnabled = 0x00000020,
    FreeCheckingEnabled = 0x00000040,
    EnableTerminationOnCorruption = 0x00000080,
    DecommitFreeBlock = 0x00000100,
    ValidateParameters = 0x00000200,
    ValidateAll = 0x00000400,
    Hotpatchable = 0x00001000,
    FastTermination = 0x00008000,
    LockBlocks = 0x00010000,
    LockAll = 0x00020000,
    LockNone = 0x00040000,
    AllFlags = 0xFFFFFFFF
}

/+ public struct LoadConfigTable
{
public:
final:
    /* size_t offset;
    PE pe; */
    
    RVA rva;
    alias rva this;
    uint size;

    uint characteristics;
    SysTime timestamp;
    ushort majorVersion;
    ushort minorVersion;
    GlobalFlags globalFlagsClear;
    GlobalFlags globalFlagsSet;
    uint critsecTimeout;
    ulong decommitFreeBlockThreshold;
    ulong decommitTotalFreeThreshold;
    /// x86 exclusive
    LockPrefixTable lockPrefixTable;
    ulong maxAllocSize;
    ulong maxVirtualSize;
    ProcessAffinityMask affinity;
    ProcessHeapFlags heapFlags;
    ushort csdVersion;
    ushort reserved;
    ulong editList;
    ulong securityCookie;
    /// x86 exclusive
    SEHandlerTable seHandlerTable;
    ulong numSEHandlers;
    ulong cfGuardCheckPointer;
    ulong cfGuardDispatchPointer;
    ulong cfGuardTable;
    ulong numCFGuardTable;
    uint guardFlags;
} +/

/* public struct AttributeCertificateEntry 
{
public:
final:
    uint dwLength;
    ushort wRevision;
    ushort wCertificateType;
    ubyte[] bCertificate;
} */