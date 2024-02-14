module caiman.digest.hash.md5;

public static class MD5
{
public:
static:
pure:
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.md;
        return digest!(std.digest.md.MD5)(data);
    }
}