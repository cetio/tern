module tern.os.elf;

import tern.object : Endianness;

public enum EIKind : ubyte
{
    Invalid,
    x86,
    x64
}

public enum OSABI : ubyte
{
    SystemV,
    HPUX,
    NetBSD,
    Linux,
    GNUHard,
    Solaris = 0x6,
    AIX,
    IRIX,
    FreeBSD,
    Tru64,
    NovellModesto,
    OpenBSD,
    OpenVMS,
    NonStopKernel,
    AROS,
    FenixOS,
    NuxiCloudABI,
    StratusOpenVOS
}

public enum ObjectKind : ushort
{
    None,
    Relocatable,
    Executable,
    Shared,
    Core,
}

public enum Architecture : ushort
{
    None = 0x0,
    WE32100 = 0x1,
    SPARC = 0x2,
    X86 = 0x3,
    M68K = 0x4,
    M88K = 0x5,
    MCU = 0x6,
    I80860 = 0x7,
    MIPS = 0x8,
    S370 = 0x9,
    RS3000LE = 0xa,
    HPPA_RISC = 0x0f,
    I80960 = 0x13,
    POWERPC = 0x14,
    POWERPC64 = 0x15,
    S390 = 0x16,
    SPU = 0x17,
    SPC = 0x17,
    V800 = 0x24,
    FR20 = 0x25,
    RH32 = 0x26,
    RCE,
    ARM,
    DigitalAlpha,
    SuperH,
    SPARC9,
    TriCoreEmbedded,
    ArgonautRISC,
    H8300,
    H8300H,
    H8S,
    H8500,
    IA64,
    MIPSX,
    ColdFire,
    M68HC12,
    MMA,
    PCP,
    nCPURISC,
    NDR1,
    StarCore,
    ME16,
    ST100,
    TinyJ,
    X86_64,
    DSP,
    PDP10,
    PDP11,
    FX66,
    ST9P,
    ST7,
    MC68H16,
    MC68H11,
    MC68H08,
    MC68H05,
    SVx,
    ST19,
    VAX,
    Axis,
    Infineon,
    Element14,
    LSILogic = 0x4f,
    TMS320C6000 = 0x8c,
    E2K = 0xaf,
    Z80 = 0xdc,
    RISCV = 0xf3,
    BerkeleyPF = 0xf7,
    WDC65C816 = 0x101,
    LoongArch = 0x102
}

public enum PHKind : uint
{
    Null,
    Loadable,
    Dynamic,
    Interpreted,
    Note,
    SHLib,
    ProgramHeader,
    TLS
}

public enum PHFlags : uint
{
    Executable = 1 << 0,
    Writeable = 1 << 1,
    Readable = 1 << 2,

    ReadWriteable = Writeable | Readable,
    ReadWriteExecutable = Executable | ReadWriteable
}

public enum SHKind : uint
{
    Null,
    Data,
    Symbols,
    Strings,
    RelocationAN,
    Hash,
    Dynamic,
    Note,
    NoData,
    Relocation,
    SHLib,
    DynamicSymbols,
    Ctors,
    Dtors,
    PCtors,
    Group,
    EXTSymbols,
    Types
}

public enum SHFlags : uint
{
    Writable = 1 << 0,
    Alloc = 1 << 1,
    Executable = 1 << 2,
    Merge = 1 << 3,
    Strings = 1 << 4,
    Link = 1 << 5,
    Order = 1 << 6,
    NonConforming = 1 << 7,
    Group = 1 << 8,
    TLS = 1 << 9
}

public struct FormatHeader
{
public:
final:
    uint magic;
    EIKind kind;
    Endianness endianness;
    ubyte eiversion;
    OSABI osabi;
    ubyte exabi;
    ubyte[7] pad;
}

public struct ObjectHeader64
{
public:
final:
    ObjectKind kind;
    Architecture arch;
    uint eiversion;
    ulong entrypoint;
    ulong progHeaderAddr;
    ulong secHeaderAddr;
    uint flags;
    ushort size;
    ushort phEntrySize;
    ushort phEntryCount;
    ushort shEntrySize;
    ushort shEntryCount;
    ushort shNameIndex;
}

public struct ObjectHeader32
{
public:
final:
    ObjectKind kind;
    Architecture arch;
    uint eiversion;
    uint entrypoint;
    uint progHeaderAddr;
    uint secHeaderAddr;
    uint flags;
    ushort size;
    ushort phEntrySize;
    ushort phEntryCount;
    ushort shEntrySize;
    ushort shEntryCount;
    ushort shNameIndex;
}

public struct ProgramHeader64
{
public:
final:
    PHKind kind;
    PHFlags flags;
    ulong offset;
    ulong rva;
    ulong physAddr;
    ulong fileSize;
    ulong memorySize;
    ulong alignment;
}

public struct ProgramHeader32
{
public:
final:
    PHKind kind;
    uint offset;
    uint rva;
    uint physAddr;
    uint fileSize;
    uint memorySize;
    PHFlags flags;
    uint alignment;
}

public struct SectionHeader64
{
public:
final:
    uint nameOffset;
    SHKind kind;
    SHFlags flags;
    uint pad;
    ulong addr;
    ulong offset;
    ulong size;
    uint link;
    uint info;
    ulong alignment;
    ulong entrySize;
}

public struct SectionHeader32
{
public:
final:
    uint nameOffset;
    SHKind kind;
    SHFlags flags;
    uint addr;
    uint offset;
    uint size;
    uint link;
    uint info;
    uint alignment;
    uint entrySize;
}