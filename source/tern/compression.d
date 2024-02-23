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