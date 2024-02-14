module caiman.digest.ripemd;

import caiman.digest;

public static @digester class RIPEMD
{
public:
static:
pure:
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.ripemd;
        return digest!(std.digest.ripemd.RIPEMD160)(data);
    }
}