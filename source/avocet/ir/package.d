module avocet.ir;

/+ module avocet.ir;

import std.string;
import std.algorithm;

private enum
{
    INIT,
    MOV,
    CMP,
    CONV,
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    SMUL,
    SDIV,
    XOR,
    AND,
    OR,
    NOT,
    NEG,
    SHL,
    SHR,
    CALL,
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
    RET,
    INT,
    FENCE,
    ABS,
    POW,
    SQRT,
    SIN,
    COS,
    TAN,
    ROUND,
    TRUNC,
    SLEEP,
    FREE,
}

private enum TypeFlags
{
    None = 0,
    Vec128 = 1,
    Vec256 = 2,
    Float = 4,
    Wide1 = 8,
    Wide2 = 16,
    Wide4 = 32,
    Wide8 = 64,
    HKT = 256,
    Pointer = 512,
    Signed = 1024,
}

/**
 * Example:
 * ```d
 * module package.module;
 *
 * struct type
 * {
 *     int field;
 * }
 * 
 * int function()
 * {
 *     init type a, type;       // type a = type();
 *     // init type a
 *     // call a, type
 *     mov int b, a.field;     // int b = a.field;
 *     ret b;              // return b;
 * }
 * ```
 */
private struct Instruction
{
public:
final:
align(8):
    int opcode;
    Local[] locals;
}

/// ditto
private struct Local
{
public:
final:
align(8):
    string name;
    Type type;
    union
    {
        ubyte[] data;
        ulong immediate;
    }
}

/// ditto
private struct Type 
{
public:
final:
    string name;
    ptrdiff_t size;
    TypeFlags flags;
    Local[] fields;
}

/// ditto
private struct Function
{
private:
final:
    string name;
    Instruction[] instructions;
    Local[] locals;
}

/// ditto
private struct Module
{
private:
final:
    string name;
    Type[] types;
    Local[] fields;
    Function[] funcs;
}

private:
static:
Module globalModule()
{
    Module mod;
    mod.types ~= Type("byte", 1, TypeFlags.Signed, null);
    mod.types ~= Type("ubyte", 1, TypeFlags.None, null);
    mod.types ~= Type("short", 2, TypeFlags.Signed, null);
    mod.types ~= Type("ushort", 2, TypeFlags.None, null);
    mod.types ~= Type("int", 4, TypeFlags.Signed, null);
    mod.types ~= Type("uint", 4, TypeFlags.None, null);
    mod.types ~= Type("long", 8, TypeFlags.Signed, null);
    mod.types ~= Type("ulong", 8, TypeFlags.None, null);
    mod.types ~= Type("nint", 8, TypeFlags.None, null);
    mod.types ~= Type("void", 1, TypeFlags.None, null);
    return mod;
}

public:
Function parse(string str)
{
    Module mod = globalModule;
    Function func;
    foreach (line; str.splitLines().map!(x => x[0..x.indexOf(';')]))
    {
        string[] words = line.split(' ');
        switch (words[0])
        {
            case "init":
                if (words.length <= 3)
                {
                    if (!mod.types.canFind!(x => x.name == words[1]))
                        func.instructions ~= Instruction(INIT, func.locals.find!(x => x.name == words[1]));
                    else
                    {
                        func.locals ~= Local(words[2], mod.types.find!(x => x.name == words[1])[0]);
                        func.instructions ~= Instruction(INIT, func.locals.find!(x => x.name == words[2]));
                    }
                }
                else if (words.length > 3)
                {
                    foreach (ref i; 0..words.length)
                    {
                        string word = words[i];
                        if (mod.types.canFind!(x => x.name == word))
                        {
                            string name = words[++i][0..$-1]; 
                            func.locals ~= Local(name, mod.types.find!(x => x.name == word)[0]);
                            func.instructions ~= Instruction(INIT, func.locals.find!(x => x.name == name));
                        }
                        //else
                            //func.instructions ~= Instruction(INIT, func.locals.find!(x => x.name == word[0..$-1]));
                    }

                }
                break;
            default:
                assert(0);
        }
    }
    return func;
} +/