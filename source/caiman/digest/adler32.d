module caiman.digest.adler32;

public static class Adler32
{
public:
static:
pure:
    enum MOD_ADLER = 65521;

    ubyte[] hash(ubyte[] data) 
    {
        int a = 1, b = 0;
        foreach (_b; data) 
        {
            a = (a + _b) % MOD_ADLER;
            b = (b + a) % MOD_ADLER;
        }

        return [cast(ubyte)((b >> 8) & 0xFF), cast(ubyte)(b & 0xFF),
                cast(ubyte)((a >> 8) & 0xFF), cast(ubyte)(a & 0xFF)];
    }
}