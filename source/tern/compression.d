module tern.compression;

import std.traits;
import std.conv;

public:
static:
pure:
ubyte[] varEncode(T)(T val)
    if (isIntegral!T)
{
    if (val == 0)
        return [0];

    val <<= 3;
    ubyte[] bytes;
    while (val > 0)
    {
        bytes ~= cast(ubyte)(val & 0xFF);
        val >>= 8;
    }
    // Encode the number of bytes to read after this as the first 3 bits
    bytes[0] |= ((bytes.length - 1) & 0b0000_0111);
    return bytes;
}

ulong varDecode(ubyte[] bytes)
{
    ulong ret;
    // Extract the number of bytes used to represent the value from the first byte
    ubyte numBytes = (bytes[0] & 0b0000_0111) + 1;
    foreach_reverse (b; bytes[1..numBytes])
        ret = (ret << 8) | b;
    ret = (ret << 8) | bytes[0];
    return ret >> 3;
}

ubyte[3] compress(uint val)
{
    assert(val <= 49_939_965, "Value '"~val.to!string~"' out of legal compression range!");

    ubyte[3] ret;
    foreach (ubyte x; 0..ubyte.max)
    {
        foreach (ubyte y; 0..ubyte.max)
        {
            foreach (ubyte z; 0..63)
            {
                if (x ^^ 3 + y ^^ 2 + z == val)
                    return [x, y, z];
                else if ((x ^^ 3 + y ^^ 2 + z) * 2 == val)
                    return [x, y, cast(ubyte)(z | 64)];
                else if ((x ^^ 3 + y ^^ 2 + z) * 3 == val)
                    return [x, y, cast(ubyte)(z | 128)];
            }
        }
    }
    assert(0, val.to!string);
}

uint decompress(ubyte[3] xyz)
{
    if (xyz[2] & 128)
        return (xyz[0] ^^ 3 + xyz[1] ^^ 2 + (xyz[2] & ~128)) * 3;
    else if (xyz[2] & 64)
        return (xyz[0] ^^ 3 + xyz[1] ^^ 2 + (xyz[2] & ~64)) * 2;
    else
        return xyz[0] ^^ 3 + xyz[1] ^^ 2 + xyz[2];
}