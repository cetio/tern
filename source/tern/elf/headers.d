module tern.elf.headers;

public enum EIKind : ubyte
{
    Invalid,
    x86,
    x64
}

public enum Endian : ubyte
{
    Invalid,
    Little,
    Big
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

public struct FormatHeader
{
    uint magic;
    EIKind kind;
    Endian endian;
    ubyte eiversion;
    OSABI osabi;
    ubyte exabi;
    ubyte[7] pad;
}

public struct ObjectHeader
{
    ObjectKind kind;
    Architecture arch;
    uint eiversion;
    ulong entryAddr;
    ulong headerAddr;
    ulong sectionAddr;
}