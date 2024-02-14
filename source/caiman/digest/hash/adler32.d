module caiman.digest.hash.adler32;

public static class Adler32
{
public:
static:
pure:
    enum MOD_ADLER = 65521;

    /**
     * Computes the Adler-32 checksum for the given data.
     * 
     * Parameters:
     *     data - The input data for which the checksum is to be computed.
     * 
     * Returns:
     *     An array of 4 ubytes representing the Adler-32 checksum.
     */
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