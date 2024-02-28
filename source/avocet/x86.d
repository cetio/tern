module avocet.x86;

// TODO: Improve inference

import tern.exception;
import tern.string;
import std.bitmanip;
import std.conv;

public static class X86
{
private:
static:
    package enum Register
    {
        None,
        BH,
        BL,
        CH,
        CL,
        DH,
        DL,
        AX,
        BX,
        CX,
        DI,
        SI,
        DX,
        EBX,
        ECX,
        EDI,
        ESI,
        EDX,
        RBX,
        RCX,
        RDI,
        RSI,
        RDX,
        R8,
        R9,
        R10,
        R11,
        R12,
        R13,
        R14,
        R15,
        XMM0,
        XMM1,
        XMM2,
        XMM3,
        XMM4,
        XMM5,
        XMM6,
        XMM7,
        XMM8,
        XMM9,
        XMM10,
        XMM11,
        XMM12,
        XMM13,
        XMM14,
        XMM15,
        YMM0,
        YMM1,
        YMM2,
        YMM3,
        YMM4,
        YMM5,
        YMM6,
        YMM7,
        YMM8,
        YMM9,
        YMM10,
        YMM11,
        YMM12,
        YMM13,
        YMM14,
        YMM15
    }

    package enum Segment
    {
        SS,
        CS,
        DS,
        ES,
        FS,
        GS,
        None
    }

    private enum Mode : ubyte
    {
        Memory = 0b00,
        Offset8 = 0b01,
        Offset32 = 0b10,
        Register = 0b11
    }

    private struct ModRM
    {
    public:
    final:
        union
        {
            ubyte b;
            struct
            {
                mixin(bitfields!(
                    ubyte, "reg", 3,
                    ubyte, "rm", 3,
                    Mode, "mode", 2,
                ));
            }
        }
        alias b this;

        this(ubyte reg, ubyte rm, Mode mode)
        {
            this.reg = reg;
            this.rm = rm;
            this.mode = mode;
            import std.stdio;
            writeln(b.to!string(16));
        }
    }

    // Directly encoded instructions
    // +r instructions
    immutable ubyte[][string] idre;
    // Mod R/M byte instructions
    // \r \0 instructions
    immutable ubyte[][string] imrm;
    // 8-bit registers
    immutable size_t[string] r8;
    // 16-bit registers
    immutable size_t[string] r16;
    // 32-bit registers
    immutable size_t[string] r32;
    // 64-bit registers
    immutable size_t[string] r64;
    // 128-bit registers
    immutable size_t[string] r128;
    // 256-bit registers
    immutable size_t[string] r256;
    // Encodings for registers,
    // rax-rsp for example would span the first 8,
    // r8-r15 would span the next 8
    // Mod R/M encodings should use the last 8 no matter what
    immutable ubyte[] encoding;
    // All rex prefixes encoded, 
    // Same layout as encoding (first 8 last 8)
    immutable ubyte[] rex;
    // Segment memory access prefixes
    immutable ubyte[] segments;
    
public:
    shared static this()
    {
        idre = [
            "mov r8, imm8": [0xB0],
            "mov r16, imm16": [0xB8],
            "mov r32, imm32": [0xB8],
            "mov r64, imm64": [0xB8],
        ];
        imrm = [
            "mov r/m8, imm8": [0xC6],
            "mov r/m16, imm16": [0xC7],
            "mov r/m32, imm32": [0xC7],
            "mov r/m64, imm32": [0xC7],
            "mov r/m8, r8": [0x88],
            "mov r/m16, r16": [0x89],
            "mov r/m32, r32": [0x89],
            "mov r/m64, r64": [0x89],
            "mov r8, r/m8": [0x8A],
            "mov r16, r/m16": [0x8B],
            "mov r32, r/m32": [0x8B],
            "mov r64, r/m64": [0x8B],
            "add r/m8, imm8": [0x80],
            "add r/m16, imm16": [0x81],
            "add r/m32, imm32": [0x81],
            "add r/m64, imm32": [0x81],
            "add r/m16, imm8": [0x83],
            "add r/m32, imm8": [0x83],
            "add r/m64, imm8": [0x83],
            "add r/m8, r8": [0x00],
            "add r/m16, r16": [0x01],
            "add r/m32, r32": [0x01],
            "add r/m64, r64": [0x01],
            "add r8, r/m8": [0x02],
            "add r16, r/m16": [0x03],
            "add r32, r/m32": [0x03],
            "add r64, r/m64": [0x03],
            "mul r/m8": [0xF6],
            "mul r/m16": [0xF7],
            "mul r/m32": [0xF7],
            "mul r/m64": [0xF7],
        ];
        r8 = [
            "ah": 0,
            "al": 1,
            "bh": 2,
            "bl": 3,
            "ch": 4,
            "cl": 5,
            "dh": 6,
            "dl": 7,
            "r8b": 8,
            "r9b": 9,
            "r10b": 10,
            "r11b": 11,
            "r12b": 12,
            "r13b": 13,
            "r14b": 14,
            "r15b": 15,
        ];
        r16 = [
            "ax": 0,
            "bx": 1,
            "cx": 2,
            "dx": 3,
            "sp": 4,
            "bp": 5,
            "di": 6,
            "si": 7,
            "r8w": 8,
            "r9w": 9,
            "r10w": 10,
            "r11w": 11,
            "r12w": 12,
            "r13w": 13,
            "r14w": 14,
            "r15w": 15
        ];
        r32 = [
            "eax": 0,
            "ebx": 1,
            "ecx": 2,
            "edx": 3,
            "esp": 4,
            "ebp": 5,
            "edi": 6,
            "esi": 7,
            "r8d": 8,
            "r9d": 9,
            "r10d": 10,
            "r11d": 11,
            "r12d": 12,
            "r13d": 13,
            "r14d": 14,
            "r15d": 15,
        ];
        r64 = [
            "rax": 0,
            "rbx": 1,
            "rcx": 2,
            "rdx": 3,
            "rsp": 4,
            "rbp": 5,
            "rsi": 6,
            "rdi": 7,
            "r8": 8,
            "r9": 9,
            "r10": 10,
            "r11": 11,
            "r12": 12,
            "r13": 13,
            "r14": 14,
            "r15": 15,
    /*       "dr0",
            "dr1",
            "dr2",
            "dr3",
            "dr4",
            "dr5",
            "dr6",
            "dr7",
            "cr0",
            "cr1",
            "cr2",
            "cr3",
            "cr4",
            "cr5",
            "cr6",
            "cr7",
            "cr8" */
        ];
        r128 = [
            "xmm0": 0,
            "xmm1": 1,
            "xmm2": 2,
            "xmm3": 3,
            "xmm4": 4,
            "xmm5": 5,
            "xmm6": 6,
            "xmm7": 7,
            "xmm8": 8,
            "xmm9": 9,
            "xmm10": 10,
            "xmm11": 11,
            "xmm12": 12,
            "xmm13": 13,
            "xmm14": 14,
            "xmm15": 15,
        ];
        r256 = [
            "ymm0": 0,
            "ymm1": 1,
            "ymm2": 2,
            "ymm3": 3,
            "ymm4": 4,
            "ymm5": 5,
            "ymm6": 6,
            "ymm7": 7,
            "ymm8": 8,
            "ymm9": 9,
            "ymm10": 10,
            "ymm11": 11,
            "ymm12": 12,
            "ymm13": 13,
            "ymm14": 14,
            "ymm15": 15,
        ];
        encoding = [
            0b000, // a
            0b011, // b
            0b001, // c
            0b010, // d
            0b100, // sp
            0b101, // bp
            0b110, // si
            0b111,  // di
            // Encodings for Mod R/M
            0b000, // r8
            0b001, // r9
            0b010, // r10
            0b011, // r11
            0b100, // r12
            0b101, // r13
            0b110, // r14
            0b111  // r15
        ];
        rex = [
            /* 0b01000000, // rax
            0b01000011, // rbx
            0b01000001, // rcx
            0b01000010, // rdx
            0b01000110, // rsi
            0b01000111, // rdi
            0b01000101, // rbp
            0b01000100, // rsp
            0b01001000, // r8
            0b01001001, // r9
            0b01001010, // r10
            0b01001011, // r11
            0b01001100, // r12
            0b01001101, // r13
            0b01001110, // r14
            0b01001111  // r15 */
            0x48,
            0x48,
            0x48,
            0x48,
            0x48,
            0x48,
            0x48,
            0x48,
            0x49,
            0x49,
            0x49,
            0x49,
            0x49,
            0x49,
            0x49,
            0x49,
        ];
        segments = [
            0x2e, // cs
            0x36, // ss
            0x3e, // ds
            0x26, // es
            0x64, // fs
            0x65 // gs
        ];
    }

    ubyte[] assemble(string str)
    {
        ubyte[] assembly;
        foreach (tinst; str.splitLines())
        {
            tinst = tinst.strip();
            if (tinst.length == 0)
                continue;

            ubyte segment;
            ubyte[] data;
            size_t[] regind;
            string[] regstr;
            bool needsEncoding;

            string[] parts = tinst.split(" ");
            string inst = parts[0];
            size_t memSize = size_t.max;
            size_t immSize = size_t.max;

            string[] literals = tinst[(inst.length + 1)..$].split(", ");
            // First pass, registers (so we can know memory/immediate sizes)
            foreach (i; 0..literals.length)
            {
                string literal = literals[i];
                if (literal in r8)
                {
                    if (i == 0)
                        needsEncoding = true;

                    memSize = 8;
                    immSize = 8;
                }
                else if (literal in r16)
                {
                    if (i == 0)
                        needsEncoding = true;

                    memSize = 16;
                    immSize = 16;
                }
                else if (literal in r32)
                {
                    if (i == 0)
                        needsEncoding = true;

                    memSize = 32;
                    immSize = 32;
                }
                else if (literal in r64)
                {
                    if (i == 0)
                        needsEncoding = true;

                    memSize = 64;
                    immSize = 64;
                }
                else if (literal in r128)
                {
                    if (i == 0)
                        needsEncoding = true;

                    memSize = 128;
                    immSize = 128;
                }
                else if (literal in r256)
                {
                    if (i == 0)
                        needsEncoding = true;

                    memSize = 256;
                    immSize = 256;
                }
            }
            // Second pass, doing all the actual parsing
            foreach (i; 0..literals.length)
            {
                string literal = literals[i];
                if (literal in r8)
                {
                    regind ~= r8[literal];
                    regstr ~= literal;
                    inst ~= " r8,";
                }
                else if (literal in r16)
                {
                    regind ~= r16[literal];
                    regstr ~= literal;
                    inst ~= " r16,";
                }
                else if (literal in r32)
                {
                    regind ~= r32[literal];
                    regstr ~= literal;
                    inst ~= " r32,";
                }
                else if (literal in r64)
                {
                    regind ~= r64[literal];
                    regstr ~= literal;
                    inst ~= " r64,";
                }
                else if (literal in r128)
                {
                    regind ~= r128[literal];
                    regstr ~= literal;
                    inst ~= " r128,";
                }
                else if (literal in r256)
                {
                    regind ~= r256[literal];
                    regstr ~= literal;
                    inst ~= " r256,";
                }
                else if (literal.canFind('['))
                {
                    if (!literal.endsWith(']'))
                        raise("Expected memory operand, found literal with missing closing bracket!", tinst, literal);

                    if (literal.startsWith("byte "))
                    {
                        if (memSize < 8)
                            raise("Explicit size of '8' cannot fit into inferred size of '"~memSize.to!string~"'", tinst, literal);

                        memSize = 8;
                        immSize = 8;
                        literal = literal[5..$];
                    }
                    else if (literal.startsWith("word "))
                    {
                        if (memSize < 16)
                            raise("Explicit size of '16' cannot fit into inferred size of '"~memSize.to!string~"'", tinst, literal);

                        memSize = 16;
                        literal = literal[5..$];
                    }
                    else if (literal.startsWith("dword "))
                    {
                        if (memSize < 32)
                            raise("Explicit size of '32' cannot fit into inferred size of '"~memSize.to!string~"'", tinst, literal);

                        memSize = 32;
                        literal = literal[6..$];
                    }
                    else if (literal.startsWith("qword "))
                    {
                        if (memSize < 64)
                            raise("Explicit size of '64' cannot fit into inferred size of '"~memSize.to!string~"'", tinst, literal);

                        memSize = 64;
                        literal = literal[6..$];
                    }
                    else if (literal.startsWith("dqword "))
                    {
                        raise("Unsupported explicit 128-bit size!", tinst, literal);
                        if (memSize < 256)
                            raise("Explicit size of '128' cannot fit into inferred size of '"~memSize.to!string~"'", tinst, literal);

                        memSize = 128;
                        literal = literal[7..$];
                    }
                    else if (literal.startsWith("qqword "))
                    {
                        raise("Unsupported explicit 256-bit size!", tinst, literal);
                        if (memSize < 128)
                            raise("Explicit size of '256' cannot fit into inferred size of '"~memSize.to!string~"'", tinst, literal);

                        memSize = 256;
                        literal = literal[7..$];
                    }

                    if (literal.startsWith("cs:"))
                    {
                        literal = literal[3..$];
                        segment = segments[0];
                    }
                    else if (literal.startsWith("ss:"))
                    {
                        literal = literal[3..$];
                        segment = segments[1];
                    }
                    else if (literal.startsWith("ds:"))
                    {
                        literal = literal[3..$];
                        segment = segments[2];
                    }
                    else if (literal.startsWith("es:"))
                    {
                        literal = literal[3..$];
                        segment = segments[3];
                    }
                    else if (literal.startsWith("fs:"))
                    {
                        literal = literal[3..$];
                        segment = segments[4];
                    }
                    else if (literal.startsWith("gs:"))
                    {
                        literal = literal[3..$];
                        segment = segments[5];
                    }

                    if (memSize == size_t.max)
                        raise("Unable to infer size of address, add an integer type to explicitly define size!", tinst, literal);

                    size_t address = literal[1..$-1].to!size_t;
                    data ~= (cast(ubyte*)&address)[0..size_t.sizeof];
                    inst ~= " r/m"~memSize.to!string~",";
                }
                else if (literal.endsWith(']'))
                {
                    raise("Expected memory operand, found literal with missing opening bracket!", tinst, literal);
                }
                else
                {
                    if (literal.startsWith("byte "))
                    {
                        if (memSize < 8)
                            raise("Explicit size of '8' cannot fit into inferred size of '"~immSize.to!string~"'", tinst, literal);

                        immSize = 8;
                        literal = literal[5..$];
                    }
                    else if (literal.startsWith("word "))
                    {
                        if (memSize < 16)
                            raise("Explicit size of '16' cannot fit into inferred size of '"~immSize.to!string~"'", tinst, literal);

                        immSize = 16;
                        literal = literal[5..$];
                    }
                    else if (literal.startsWith("dword "))
                    {
                        if (memSize < 32)
                            raise("Explicit size of '32' cannot fit into inferred size of '"~immSize.to!string~"'", tinst, literal);

                        immSize = 32;
                        literal = literal[6..$];
                    }
                    else if (literal.startsWith("qword "))
                    {
                        if (memSize < 64)
                            raise("Explicit size of '64' cannot fit into inferred size of '"~immSize.to!string~"'", tinst, literal);

                        immSize = 64;
                        literal = literal[6..$];
                    }
                    else if (literal.startsWith("dqword "))
                    {
                        raise("Unsupported explicit 128-bit size!", tinst, literal);
                        if (memSize < 256)
                            raise("Explicit size of '128' cannot fit into inferred size of '"~immSize.to!string~"'", tinst, literal);

                        immSize = 128;
                        literal = literal[7..$];
                    }
                    else if (literal.startsWith("qqword "))
                    {
                        raise("Unsupported explicit 256-bit size!", tinst, literal);
                        if (memSize < 128)
                            raise("Explicit size of '256' cannot fit into inferred size of '"~immSize.to!string~"'", tinst, literal);

                        immSize = 256;
                        literal = literal[7..$];
                    }

                    if (literal.endsWith("h"))
                    {
                        bool isHex(string s)
                        {
                            foreach (char c; s)
                            {
                                if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')))
                                    return false;
                            }
                            return true;
                        }

                        if (!isHex(literal[0..$-1]))
                            raise("Undefined symbol, expected hexadecimal literal!", tinst, literal);

                        if (immSize == 8)
                        {
                            data ~= literal[0..$-1].to!byte(16);
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else if (immSize == 16)
                        {
                            ushort imm = literal[0..$-1].to!ushort(16);
                            data ~= (cast(ubyte*)&imm)[0..ushort.sizeof];
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else if (immSize == 32)
                        {
                            uint imm = literal[0..$-1].to!uint(16);
                            data ~= (cast(ubyte*)&imm)[0..uint.sizeof];
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else if (immSize == 64)
                        {
                            ulong imm = literal[0..$-1].to!ulong(16);
                            data ~= (cast(ubyte*)&imm)[0..ulong.sizeof];
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else
                        {
                            raise("Unable to infer size of immediate, add an integer type to explicitly define size!", tinst, literal);
                        }
                    }
                    else
                    {
                        if (!isNumeric(literal[0..$]))
                            raise("Undefined symbol, expected decimal literal!", tinst, literal);

                        if (immSize == 8)
                        {
                            data ~= literal[0..$].to!byte;
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else if (immSize == 16)
                        {
                            ushort imm = literal[0..$].to!ushort;
                            data ~= (cast(ubyte*)&imm)[0..ushort.sizeof];
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else if (immSize == 32)
                        {
                            uint imm = literal[0..$].to!uint;
                            data ~= (cast(ubyte*)&imm)[0..uint.sizeof];
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else if (immSize == 64)
                        {
                            ulong imm = literal[0..$].to!ulong;
                            data ~= (cast(ubyte*)&imm)[0..ulong.sizeof];
                            inst ~= " imm"~immSize.to!string~",";
                        }
                        else
                        {
                            raise("Unable to infer size of immediate, add an integer type to explicitly define size!", tinst, literal);
                        }
                    }
                }
            }
            inst = inst[0..$-1];
            
        assemble:
            if (inst in idre)
            {
                ubyte[] opcode = cast(ubyte[])idre[inst];
                if (needsEncoding)
                    opcode[$-1] |= encoding[regind[0]];

                if (segment != 0)
                    assembly ~= segment;
                else if (regind.length != 0)
                {
                    if (regstr[0] in r64)
                        assembly ~= rex[regind[0]];
                    else if (regstr[0][0] == 'r')
                        assembly ~= 0x41; // 64-bit lower prefix
                    if (regstr[0] in r16)
                        assembly ~= 0x66; // 16-bit operation prefix
                }

                assembly ~= opcode;
                assembly ~= data;
            }
            else if (inst in imrm)
            {
                ubyte[] opcode = cast(ubyte[])imrm[inst];
                if (needsEncoding)
                {
                    if (regstr[0] in r64)
                        assembly ~= rex[regind[0]];
                    else if (regstr[0][0] == 'r')
                        assembly ~= 0x41; // 64-bit lower prefix
                    if (regstr[0] in r16)
                        assembly ~= 0x66; // 16-bit operation prefix

                    assembly ~= opcode;
                    assembly ~= ModRM(encoding[(regind[0] % 8) + 8], 0, Mode.Register);
                    assembly ~= data;
                }
                else
                {
                    if (segment != 0)
                        assembly ~= segment;

                    assembly ~= opcode;
                    assembly ~= ModRM(0b101, 0, Mode.Memory);
                    assembly ~= data;
                }
            }
            else
            {
                bool canPass(string str1, string str2) 
                {
                    string[] literals1 = str1.split(", ");
                    string[] literals2 = str2.split(", ");
                    foreach (i; 0..literals1.length)
                    {
                        if (literals2[i].replace("r/m", "r") != literals1[i])
                            return false;
                    }
                    return true;
                }

                string findClosestMatch() 
                {
                    long minDistance = int.max;
                    string closestMatch;

                    foreach (key; idre.keys~imrm.keys) 
                    {
                        long distance = levenshteinDistance(inst, key);
                        if (distance < minDistance) 
                        {
                            minDistance = distance;
                            closestMatch = key;
                        }
                    }

                    return closestMatch;
                }

                string closestMatch = findClosestMatch();
                if (canPass(inst, closestMatch))
                {
                    inst = closestMatch;
                    goto assemble;
                }
                else
                {
                    raise("Undefined instruction '"~inst~"', did you mean '"~closestMatch~"'?");
                }
            }
        }
        return assembly;
    }
}