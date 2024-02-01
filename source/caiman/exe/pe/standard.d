module caiman.exe.pe.standard;

public struct DOSHeader 
{
public:
final:
    ushort e_magic;
    ushort e_cblp;
    ushort e_cp;
    ushort e_crlc;
    ushort e_cparhdr;
    ushort e_minalloc;
    ushort e_maxalloc;
    ushort e_ss;
    ushort e_sp;
    ushort e_csum;
    ushort e_ip;
    ushort e_cs;
    ushort e_lfarlc;
    ushort e_ovno;
    ushort[4] e_res;
    ushort e_oemid;
    ushort e_oeminfo;
    ushort[10] e_res2;
    uint e_lfanew;
}

public enum MachineType : ushort
{
    Unknown = 0x0,
    Alpha = 0x184,
    Alpha64 = 0x284,
    AM33 = 0x1d3,
    AMD64 = 0x8664,
    ARM = 0x1c0,
    ARM64 = 0xaa64,
    ARMNT = 0x1c4,
    AXP64 = 0x284,
    EBC = 0xebc,
    I386 = 0x14c,
    IA64 = 0x200,
    LoongArch32 = 0x6232,
    LoongArch64 = 0x6264,
    M32R = 0x9041,
    MIPS16 = 0x266,
    MIPSFPU = 0x366,
    MIPSFPU16 = 0x466,
    PowerPC = 0x1f0,
    PowerPCFP = 0x1f1,
    R4000 = 0x166,
    RISCV32 = 0x5032,
    RISCV64 = 0x5064,
    RISCV128 = 0x5128,
    SH3 = 0x1a2,
    SH3DSP = 0x1a3,
    SH4 = 0x1a6,
    SH5 = 0x1a8,
    Thumb = 0x1c2,
    WCEMIPSv2 = 0x169
}

public enum COFFCharacteristics : ushort
{
    RelocsStripped = 0x0001,
    Executable = 0x0002,
    LineNumsStripped = 0x0004,
    LocalSymsStripped = 0x0008,
    AggressiveTrim = 0x0010,
    LargeAddressAware = 0x0020,
    ReversedLO = 0x0080,
    x32 = 0x0100,
    DebugStripped = 0x0200,
    Removable = 0x0400,
    Net = 0x0800,
    System = 0x1000,
    Dll = 0x2000,
    SystemOnly = 0x4000,
    ReversedHI = 0x8000
}

public struct COFFHeader
{
public:
final:
    uint magic;
    MachineType machine;
    ushort numberOfSections; 
    uint timeDateStamp;
    uint pointerToSymbolTable;
    uint numberOfSymbols;
    // 0 for objects
    ushort sizeOfOptionalHeader;
    COFFCharacteristics characteristics;
}

public enum SECCharacteristics : uint
{
    TypeNoPad           = 0x00000008,
    CntCode             = 0x00000020,
    CntInitializedData  = 0x00000040,
    CntUninitializedData= 0x00000080,
    LnkOther            = 0x00000100,
    LnkInfo             = 0x00000200,
    LnkRemove           = 0x00000800,
    LnkComdat           = 0x00001000,
    GpRel               = 0x00008000,
    MemPurgeable        = 0x00020000,
    Mem16Bit            = 0x00020000,
    MemLocked           = 0x00040000,
    MemPreload          = 0x00080000,
    Align1Bytes         = 0x00100000,
    Align2Bytes         = 0x00200000,
    Align4Bytes         = 0x00300000,
    Align8Bytes         = 0x00400000,
    Align16Bytes        = 0x00500000,
    Align32Bytes        = 0x00600000,
    Align64Bytes        = 0x00700000,
    Align128Bytes       = 0x00800000,
    Align256Bytes       = 0x00900000,
    Align512Bytes       = 0x00A00000,
    Align1024Bytes      = 0x00B00000,
    Align2048Bytes      = 0x00C00000,
    Align4096Bytes      = 0x00D00000,
    Align8192Bytes      = 0x00E00000,
    LnkNrelocOvfl       = 0x01000000,
    MemDiscardable      = 0x02000000,
    MemNotCached        = 0x04000000,
    MemNotPaged         = 0x08000000,
    MemShared           = 0x10000000,
    MemExecute          = 0x20000000,
    MemRead             = 0x40000000,
    MemWrite            = 0x80000000,
}

public struct Section
{
public:
final:
    char[8] name;
    uint virtualSize;
    uint virtualAddress;
    uint sizeOfRawData;
    uint pointerToRawData;
    uint pointerToRelocations;
    uint pointerToLinenumbers;
    ushort numberOfRelocations;
    ushort numberOfLinenumbers;
    SECCharacteristics characteristics;
}