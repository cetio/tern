/+ /// Maximally optimized sub-language intended for 
module caiman.lang.fleet;

import std.string;
import std.algorithm;
import caiman.core.state;
import std.ascii;
import std.array;
import std.conv;
import caiman.synth;
debug import std.stdio;

// TODO: Consolidate to macaw.x86?
private enum Register
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

private enum Segment
{
    SS,
    CS,
    DS,
    ES,
    FS,
    GS,
    None
}

private enum LocalFlags : ptrdiff_t
{
    None = 0,
    Vec128 = 1,
    Vec256 = 2,
    Float = 4,
    NeedsUnboxing = 8,
    Pointer = 16,
    Signed = 32,
    Wide1 = 64,
    Wide2 = 128,
    Wide4 = 256,
    Wide8 = 512,
}

// TODO: Fixed size arrays
private struct Local
{
private:
final:
pure:
    string type;
    string name;
    LocalFlags flags;
    ptrdiff_t size;
    Register register;
    Segment segment;
    ptrdiff_t offset;

    bool hasImmediate()
    {
        return size != 0 && register == Register.None;
    }
}

private enum OpCode : ptrdiff_t // ptrdiff_t to make Instruction align to ptrdiff_t
{
    MOV,
    CMOVG,
    CMOVGE,
    CMOVL,
    CMOVLE,
    CMOVE,
    CMOVNE,
    CMOVZ,
    CMOVNZ,
    CMOVPE,
    CMOVPO,
    ADD,
    SUB,
    MUL,
    DIV,
    POW,
    AND,
    ANDN,
    XOR,
    OR,
    POR,
    NOT,
    NEG,
    SHL,
    SHR,
    BSWAP,
    CMP,
    ABS,
    JMP,
    JG,
    JGE,
    JL,
    JLE,
    JE,
    JNE,
    JZ,
    JNZ,
    JPE,
    JPO,
    CALL,
    RET,
}

private struct Instruction
{
public:
final:
pure:
    OpCode opcode;
    Local[] locals;

    this(OpCode opcode, Local loc)
    {
        this.opcode = opcode;
        this.locals = [loc];
    }

    this(OpCode opcode, Local lhs, Local rhs)
    {
        this.opcode = opcode;
        this.locals = [lhs, rhs];
    }

    this(OpCode opcode, Local lhs, Local rhs, Local fhs)
    {
        this.opcode = opcode;
        this.locals = [lhs, rhs, fhs];
    }

    string toString() const
    {
        string ret;
        if (locals[0].flags == LocalFlags.None)
            ret ~= opcode.to!string.toLower()~' ';
        foreach (local; locals)
        {
            if (local.register == Register.None)
            {
                if (local.size == 1)
                    ret ~= "byte ";
                else if (local.size == 2)
                    ret ~= "word ";
                else if (local.size == 4)
                    ret ~= "dword ";
                else if (local.size == 8)
                    ret ~= "qword ";
                else if (local.size == 16)
                    ret ~= "dqword ";
                else if (local.size == 32)
                    ret ~= "qqword ";

                if (local.segment != Segment.None)
                    ret ~= local.segment.to!string.toLower()~":"~local.offset.to!string~", ";
                else
                    ret ~= local.offset.to!string~", ";
            }
            else
            {
                ret ~= local.register.to!string.toLower()~", ";
            }
        }
        return ret[0..$-2];
    }
}

private:
static:
pure:
immutable ptrdiff_t[string] integralTypes;
immutable ptrdiff_t[2][string] sseTypes;

shared static this()
{
    integralTypes = [
        "byte": 1,
        "ubyte": 1,
        "short": 2,
        "ushort": 2,
        "int": 4,
        "uint": 4,
        "long": 8,
        "ulong": 8,
        "ptrdiff_t": ptrdiff_t.sizeof,
        "bool": 1,
        "float": 4,
        "double": 8
    ];
    sseTypes = [
        "byte16": [16, LocalFlags.Wide1],
        "byte32": [32, LocalFlags.Wide1],
        "ubyte16": [16, LocalFlags.Wide1],
        "ubyte32": [32, LocalFlags.Wide1],
        "short8": [16, LocalFlags.Wide2],
        "short16": [32, LocalFlags.Wide2],
        "ushort8": [16, LocalFlags.Wide2],
        "ushort16": [32, LocalFlags.Wide2],
        "int4": [16, LocalFlags.Wide4],
        "int8": [32, LocalFlags.Wide4],
        "uint4": [16, LocalFlags.Wide4],
        "uint8": [32, LocalFlags.Wide4],
        "long2": [16, LocalFlags.Wide8],
        "long4": [32, LocalFlags.Wide8],
        "ulong2": [16, LocalFlags.Wide8],
        "ulong4": [32, LocalFlags.Wide8],
        "float4": [16, LocalFlags.Wide4],
        "float8": [32, LocalFlags.Wide4],
        "double2": [16, LocalFlags.Wide8],
        "double4": [32, LocalFlags.Wide8],
    ];
}

// TODO: Custom types
public template knight(string STR)
{
    public pure knight()
    {
        Register[70] rReserve;
        ptrdiff_t[6] sReserve; 
        Local[] locals;
        Instruction[] instructions;
        bool[string] noClear;

        static foreach (r; 1..71)
            rReserve[r - 1] = cast(Register)r;

        static foreach (s; 0..6)
            sReserve[s] = 0;

        // TODO: Free locals
        pure void snipe(string str, string root = null)
        {
            string[] words = str.split(' ');
            if (words.length == 0)
                return;

            if (!words[$-1].endsWith(';'))
                throw new Throwable("End of line not found, are you missing a semicolon?");

            foreach (type; integralTypes.keys)
            {
                if (words.length < 2 || words[0] != type)
                    continue;

                locals ~= Local(null, words.length >= 4 ? words[1] : words[1][0..$-1], LocalFlags.None, 0, Register.None, Segment.None, 0);
                noClear[locals[$-1].name] = true;
                if (words.length >= 4 && words[2] == "=")
                {
                    snipe(words[1..$].join(' '));
                    return;
                }
                break;
            }

            foreach (type; sseTypes.keys)
            {
                if (words.length < 2 || words[0] != type)
                    continue;

                locals ~= Local(null, words.length >= 4 ? words[1] : words[1][0..$-1], LocalFlags.None, 0, Register.None, Segment.None, 0);
                noClear[locals[$-1].name] = true;
                if (words.length >= 4 && words[2] == "=")
                {
                    snipe(words[1..$].join(' '));
                    return;
                }
                break;
            }

            if (words.length < 3)
                return;

            if (words[1] == "=")
            {
                if (root != null && (words[0] == root || words[2] == root))
                    noClear[root] = true;
                else
                    noClear[words[0]] = true;

                if (words.length > 3)
                    snipe(words[2..$].join(' '), words[0]);
            }
            else if (words[1][0] == '+' || words[1][0] == '-' || words[1][0] == '*' || words[1][0] == '/' ||
                words[1][0] == '^' || words[1][0] == '|' || words[1][0] == '&' || words[1] == "<<=" ||
                words[1] == ">>=" || words[1] == "<=" || words[1] == ">=" || words[1] == "==" || 
                words[1] == "!="/* || words[1] == "X=" */)
            {
                if (root != null && (words[0] == root || words[2] == root))
                {
                    noClear[root] = false;
                }  
                else
                {
                    noClear[words[0]] = false;
                    noClear[words[2]] = false;
                }

                if (words.length > 3)
                    snipe(words[2..$].join(' '), root);
            }
        }

        pure void parse(string str, Register root = Register.None)
        {
            string[] words = str.split(' ');
            if (words.length == 0)
                return;

            // TODO: Pointers & arrays
            //       Ref
            foreach (type; integralTypes.keys)
            {
                if (words.length < 2 || words[0] != type)
                    continue;

                foreach (register; rReserve)
                {
                    LocalFlags flags;
                    if (type.startsWith("float") || type.startsWith("double"))
                        flags |= LocalFlags.Float;
                    else if (type[0] != 'u')
                        flags |= LocalFlags.Signed;
                    if (type[$-1] == '*')
                        flags |= LocalFlags.Pointer;

                    if ((register >= Register.BH && integralTypes[type] == 1) ||
                        (register >= Register.BX && integralTypes[type] <= 2) ||
                        (register >= Register.EBX && integralTypes[type] <= 4) ||
                        (register >= Register.RBX && integralTypes[type] <= 8))
                    {
                        locals ~= Local(type, words.length >= 4 ? words[1] : words[1], flags, integralTypes[type], register, Segment.None, 0);
                        if (locals[$-1].name in noClear && !noClear[locals[$-1].name])
                            instructions ~= Instruction(OpCode.XOR, locals[$-1], locals[$-1]);

                        static foreach (r; 1..71)
                        {
                            if (cast(Register)r == locals[$-1].register)
                                rReserve[r - 1] = Register.None;
                        }

                        static foreach (s; 0..6)
                        {
                            if (cast(Segment)s == locals[$-1].segment)
                                sReserve[s] += locals[$-1].size;
                        }
                        
                        if (words.length >= 4 && words[2] == "=")
                            parse(words[1..$].join(' '));
                        break;
                    }
                }
            }

            foreach (type; sseTypes.keys)
            {
                if (words.length < 2 || words[0] != type)
                    continue;

                foreach (register; rReserve)
                {
                    LocalFlags flags = cast(LocalFlags)sseTypes[type][1] | (sseTypes[type][0] == 16 ? LocalFlags.Vec128 : LocalFlags.Vec256);
                    if (type.startsWith("float") || type.startsWith("double"))
                        flags |= LocalFlags.Float;
                    else if (type[0] != 'u')
                        flags |= LocalFlags.Signed;
                    if (type[$-1] == '*')
                        flags |= LocalFlags.Pointer;

                    if ((sseTypes[type][0] <= 16 && register >= Register.XMM0) ||
                        (sseTypes[type][0] <= 32 && register >= Register.YMM0))
                    {
                        locals ~= Local(type, words.length >= 4 ? words[1] : words[1], flags, integralTypes[type], register, Segment.None, 0);
                        if (locals[$-1].name in noClear && !noClear[locals[$-1].name])
                            instructions ~= Instruction(OpCode.XOR, locals[$-1], locals[$-1]);

                        static foreach (r; 1..71)
                        {
                            if (cast(Register)r == locals[$-1].register)
                                rReserve[r - 1] = Register.None;
                        }

                        static foreach (s; 0..6)
                        {
                            if (cast(Segment)s == locals[$-1].segment)
                                sReserve[s] += locals[$-1].size;
                        }
                        
                        if (words.length >= 4 && words[2] == "=")
                            parse(words[1..$].join(' '));
                        break;
                    }
                }
            }

            // TODO: Order of operations
            pure void parseArithmetic(string op)
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                if (root == Register.None)
                {
                    Local[] tlhs = locals.filter!(x => x.name == '_'~lhs[0].name).array;

                    if (tlhs.length == 0)
                        parse(lhs[0].type~" _"~lhs[0].name~" = "~lhs[0].name);
                    else
                        parse("_"~lhs[0].name~" = "~lhs[0].name);

                    lhs = tlhs.length == 0 ? [locals[$-1]] : tlhs;
                }
                else
                {
                    lhs = locals.filter!(x => x.register == root).array;
                }

                switch (op)
                {
                    case "+": instructions ~= Instruction(OpCode.ADD, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "-": instructions ~= Instruction(OpCode.SUB, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "*": instructions ~= Instruction(OpCode.MUL, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "/": instructions ~= Instruction(OpCode.DIV, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "^": instructions ~= Instruction(OpCode.XOR, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "|": instructions ~= Instruction(OpCode.POR, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "&": instructions ~= Instruction(OpCode.AND, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "~&": instructions ~= Instruction(OpCode.ANDN, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "<<": instructions ~= Instruction(OpCode.SHL, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case ">>": instructions ~= Instruction(OpCode.SHR, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "||": instructions ~= Instruction(OpCode.OR, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "&&": instructions ~= Instruction(OpCode.AND, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    case "~&&": instructions ~= Instruction(OpCode.ANDN, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]); break;
                    default: break;
                }

                if (words.length > 3)
                    parse(words[2..$].join(' '), root);
            }

            if (words.length >= 3 && words[0][0] == '~')
            {
                words[0] = words[0][1..$];
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;

                if (words[1][0] == '&')
                    words[1] = "~&"~words[1][1..$];
                else if (lhs.length != 0)
                {
                    Local[] trhs = locals.filter!(x => x.name == '_'~lhs[0].name).array;

                    if (trhs.length == 0)
                        parse(lhs[0].type~" _"~lhs[0].name~" = "~lhs[0].name);
                    else
                        parse("_"~lhs[0].name~" = "~lhs[0].name);

                    lhs = trhs.length == 0 ? [locals[$-1]] : trhs;
                    words[2] = lhs[0].name;
                    instructions ~= Instruction(OpCode.NOT, lhs[0]);
                }
            }

            if (words.length >= 3 && words[2][0] == '~')
            {
                words[2] = words[2][1..$];
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                if (words[1][0] == '&')
                    words[1] = "~&"~words[1][1..$];
                else if (rhs.length != 0)
                {
                    Local[] trhs = locals.filter!(x => x.name == '_'~rhs[0].name).array;

                    if (trhs.length == 0)
                        parse(rhs[0].type~" _"~rhs[0].name~" = "~rhs[0].name);
                    else
                        parse("_"~rhs[0].name~" = "~rhs[0].name);

                    rhs = trhs.length == 0 ? [locals[$-1]] : trhs;
                    words[2] = rhs[0].name;
                    instructions ~= Instruction(OpCode.NOT, rhs[0]);
                }
            }

            if (words.length >= 3 && words[1] == "=")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                if (lhs != rhs)
                    instructions ~= Instruction(OpCode.MOV, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]);
                
                if (words.length > 3)
                    parse(words[2..$].join(' '), lhs[0].register);
            }
            else if (words.length >= 3 && words[1] == "+=")
                parse(words[0]~" = "~words[0]~" + "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "-=")
                parse(words[0]~" = "~words[0]~" - "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "*=")
                parse(words[0]~" = "~words[0]~" * "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "/=")
                parse(words[0]~" = "~words[0]~" / "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "^=")
                parse(words[0]~" = "~words[0]~" ^ "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "&=")
                parse(words[0]~" = "~words[0]~" & "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "~&=")
                parse(words[0]~" = "~words[0]~" ~& "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "|=")
                parse(words[0]~" = "~words[0]~" | "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "^^=")
                parse(words[0]~" = "~words[0]~" ^^ "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "%=")
                parse(words[0]~" = "~words[0]~" % "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "<<=")
                parse(words[0]~" = "~words[0]~" << "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == ">>=")
                parse(words[0]~" = "~words[0]~" >> "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "&&=")
                parse(words[0]~" = "~words[0]~" && "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "~&&=")
                parse(words[0]~" = "~words[0]~" ~&& "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "||=")
                parse(words[0]~" = "~words[0]~" || "~ words[2..$].join(' '));
            else if (words.length >= 3 && words[1] == "+")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "-")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "*")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "/")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "^")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "&")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "~&")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "|")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "<<")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == ">>")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "&&")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "~&&")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "||")
                parseArithmetic(words[1]);
            else if (words.length >= 3 && words[1] == "==")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                instructions ~= Instruction(OpCode.CMP, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]);
                instructions ~= Instruction(OpCode.CMOVE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 1));
                instructions ~= Instruction(OpCode.CMOVNE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 0));
            }
            else if (words.length >= 3 && words[1] == "!=")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                instructions ~= Instruction(OpCode.CMP, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]);
                instructions ~= Instruction(OpCode.CMOVNE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 1));
                instructions ~= Instruction(OpCode.CMOVE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 0));
            }
            else if (words.length >= 3 && words[1] == ">")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                instructions ~= Instruction(OpCode.CMP, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]);
                instructions ~= Instruction(OpCode.CMOVG, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 1));
                instructions ~= Instruction(OpCode.CMOVLE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 0));
            }
            else if (words.length >= 3 && words[1] == ">=")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                instructions ~= Instruction(OpCode.CMP, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]);
                instructions ~= Instruction(OpCode.CMOVGE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 1));
                instructions ~= Instruction(OpCode.CMOVL, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 0));
            }
            else if (words.length >= 3 && words[1] == "<")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                instructions ~= Instruction(OpCode.CMP, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]);
                instructions ~= Instruction(OpCode.CMOVL, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 1));
                instructions ~= Instruction(OpCode.CMOVGE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 0));
            }
            else if (words.length >= 3 && words[1] == "<=")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                Local[] rhs = locals.filter!(x => x.name == words[2]).array;

                instructions ~= Instruction(OpCode.CMP, lhs[0], rhs.length == 0 ? Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong) : rhs[0]);
                instructions ~= Instruction(OpCode.CMOVLE, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 1));
                instructions ~= Instruction(OpCode.CMOVG, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, 0));
            }
            else if (words.length >= 3 && words[1] == "^^")
            {
                // TODO: AAAAAAA
            }
            else if (words.length >= 3 && words[1] == "%")
            {
                Local[] lhs = locals.filter!(x => x.name == words[0]).array;
                if (words[2].filter!(x => x.isDigit).array.length == words[2].length && (words[2].to!ulong > 0) && 
                    ((words[2].to!ulong & (words[2].to!ulong - 1)) == 0))
                {
                    instructions ~= Instruction(OpCode.AND, lhs[0], Local(null, null, LocalFlags.None, lhs[0].size, Register.None, Segment.None, words[2].to!ulong - 1));
                }
                // TODO: Modulo
            }
        }

        static foreach (line; STR.splitLines())
            snipe(line.strip);

        locals = null;
        static foreach (line; STR.splitLines())
            parse(simplifyEq(line.strip.length > 0 ? line.strip[0..$-1] : null));

        debug writeln(locals);
        debug writeln(instructions);
    }
} +/