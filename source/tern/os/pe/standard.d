module tern.os.pe.standard;

import tern.os.pe;
import std.datetime;
import tern.serialization;
import tern.algorithm;

public struct DOSHeader 
{
public:
final:
    /* size_t offset;
    PE pe; */

    ushort magic;
    ushort cblp;
    ushort cp;
    ushort crlc;
    ushort cparhdr;
    ushort minalloc;
    ushort maxalloc;
    ushort ss;
    ushort sp;
    ushort csum;
    ushort ip;
    ushort cs;
    ushort lfarlc;
    ushort ovno;
    ushort[4] res;
    ushort oemid;
    ushort oeminfo;
    ushort[10] res2;
    uint lfanew;
    ubyte[] stub;

    this(PE pe)
    {
        magic = pe.read!ushort;
        cblp = pe.read!ushort;
        cp = pe.read!ushort;
        crlc = pe.read!ushort;
        cparhdr = pe.read!ushort;
        minalloc = pe.read!ushort;
        maxalloc = pe.read!ushort;
        ss = pe.read!ushort;
        sp = pe.read!ushort;
        csum = pe.read!ushort;
        ip = pe.read!ushort;
        cs = pe.read!ushort;
        lfarlc = pe.read!ushort;
        ovno = pe.read!ushort;
        res = pe.read!(ushort[4]);
        oemid = pe.read!ushort;
        oeminfo = pe.read!ushort;
        res2 = pe.read!(ushort[10]);
        lfanew = pe.read!uint;
        stub = pe.read!ubyte(lfanew - pe.position);
    }

    ubyte[] toBytes()
    {
        ubyte[] ret;
        
        ret ~= magic.serialize;
        ret ~= cblp.serialize;
        ret ~= cp.serialize;
        ret ~= crlc.serialize;
        ret ~= cparhdr.serialize;
        ret ~= minalloc.serialize;
        ret ~= maxalloc.serialize;
        ret ~= ss.serialize;
        ret ~= sp.serialize;
        ret ~= csum.serialize;
        ret ~= ip.serialize;
        ret ~= cs.serialize;
        ret ~= lfarlc.serialize;
        ret ~= ovno.serialize;
        ret ~= res.serialize;
        ret ~= oemid.serialize;
        ret ~= oeminfo.serialize;
        ret ~= res2.serialize;
        ret ~= lfanew.serialize;
        ret ~= stub.serialize;

        return ret;
    }
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
    /* size_t offset;
    PE pe; */

    char[4] magic;
    MachineType machine;
    ushort numSections; 
    SysTime timestamp;
    // Should always be zero.
    RVA symbolTableRva;
    uint numSymbols;
    // 0 for objects
    // TODO: Structures should avoid cross-references.
    ushort optionalHeaderSize;
    COFFCharacteristics characteristics;

    this(PE pe)
    {
        magic = pe.read!(char[4]);

        if (magic != "PE\0\0")
            return;

        machine = pe.read!MachineType;
        numSections = pe.read!ushort;
        timestamp = SysTime.fromUnixTime(cast(ulong)pe.read!uint);
        symbolTableRva = RVA(pe, pe.read!uint);
        numSymbols = pe.read!uint;
        optionalHeaderSize = pe.read!ushort;
        characteristics = pe.read!COFFCharacteristics;
    }

    void write(PE pe)
    {
        pe.write(magic);
        pe.write(machine);
        pe.write(numSections);
        pe.write(cast(uint)timestamp.toUnixTime);
        pe.write(symbolTableRva.raw);
        pe.write(numSymbols);
        pe.write(optionalHeaderSize);
        pe.write(characteristics);
    }
}

public enum SECCharacteristics : uint
{
    TypeNoPad = 0x00000008,
    CntCode = 0x00000020,
    CntInitializedData = 0x00000040,
    CntUninitializedData = 0x00000080,
    LnkOther = 0x00000100,
    LnkInfo = 0x00000200,
    LnkRemove = 0x00000800,
    LnkComdat = 0x00001000,
    GpRel = 0x00008000,
    MemPurgeable = 0x00020000,
    Mem16Bit = 0x00020000,
    MemLocked = 0x00040000,
    MemPreload = 0x00080000,
    Align1Bytes = 0x00100000,
    Align2Bytes = 0x00200000,
    Align4Bytes = 0x00300000,
    Align8Bytes = 0x00400000,
    Align16Bytes = 0x00500000,
    Align32Bytes = 0x00600000,
    Align64Bytes = 0x00700000,
    Align128Bytes = 0x00800000,
    Align256Bytes = 0x00900000,
    Align512Bytes = 0x00A00000,
    Align1024Bytes = 0x00B00000,
    Align2048Bytes = 0x00C00000,
    Align4096Bytes = 0x00D00000,
    Align8192Bytes = 0x00E00000,
    LnkNrelocOvfl = 0x01000000,
    MemDiscardable = 0x02000000,
    MemNotCached = 0x04000000,
    MemNotPaged = 0x08000000,
    MemShared = 0x10000000,
    MemExecute = 0x20000000,
    MemRead = 0x40000000,
    MemWrite = 0x80000000,
}

public struct Section
{
public:
final:
    /* size_t offset;
    PE pe; */
    
    RVA rva;
    alias rva this;
    uint size;

    string name;
    uint virtualSize;
    RVA virtualRva;
    RVA relocTableRva;
    RVA lineNumsRva;
    ushort numRelocs;
    ushort numLineNums;
    SECCharacteristics characteristics;

    ubyte[] data;
    RelocTable relocTable;

    this(PE pe)
    {
        name = pe.read!char(8);
        virtualSize = pe.read!uint;
        virtualRva = RVA(pe, pe.read!uint);
        size = pe.read!uint;
        rva = RVA(pe, pe.read!uint);
        relocTableRva = RVA(pe, pe.read!uint);
        lineNumsRva = RVA(pe, pe.read!uint);
        numRelocs = pe.read!ushort;
        numLineNums = pe.read!ushort;
        characteristics = pe.read!SECCharacteristics;

        size_t _position = pe.position;
        pe.position = rva.objective;

        data = pe.read!ubyte(size);

        pe.position = _position;
    }

    void write(PE pe)
    {
        pe.write(name~(new char[8 - name.length]));
        pe.write(virtualRva.raw);
        pe.write(virtualSize);
        pe.write(size);
        pe.write(rva.raw);
        pe.write(relocTableRva.raw);
        pe.write(lineNumsRva.raw);
        pe.write(numRelocs);
        pe.write(numLineNums);
        pe.write(characteristics);

        size_t _position = pe.position;
        pe.position = rva.objective;

        pe.write(data);

        pe.position = _position;
    }
}