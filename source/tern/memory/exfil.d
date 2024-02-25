module tern.memory.exfil;

import std.algorithm;

public enum Endianness
{
    Native,
    LittleEndian,
    BigEndian
}

public:
static:
@nogc:
pure:
@trusted ref ubyte[] getBytes(T)(T val)
{
    static if (is(T == class))
        (*cast(ubyte**)val)[0..__traits(classInstanceSize, T)];
    else
        (cast(ubyte*)&val)[0..T.sizeof];
}

/**
 * Swaps the endianness of the provided value, if applicable.
 *
 * Params:
 *  val = The value to swap endianness.
 *  endianness = The desired endianness.
 *
 * Returns:
 *  The value with swapped endianness.
 */
@trusted T makeEndian(T)(T val, Endianness endianness)
{
    version (LittleEndian)
    {
        if (endianness == Endianness.BigEndian)
        {
            static if (is(T == class))
                (*cast(ubyte**)val)[0..__traits(classInstanceSize, T)].reverse();
            else
                (cast(ubyte*)&val)[0..T.sizeof].reverse();
        }
    }
    else version (BigEndian)
    {
        if (endianness == Endianness.LittleEndian)
        {
            static if (is(T == class))
                (*cast(ubyte**)val)[0..__traits(classInstanceSize, T)].reverse();
            else
                (cast(ubyte*)&val)[0..T.sizeof].reverse();
        }
    }
    return val;
}