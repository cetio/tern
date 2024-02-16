/// Implementation of Adler-32 digester
module caiman.digest.adler32;

import caiman.digest;

/**
 * Implementation of Adler-32 digester.
 *
 * Adler-32 is a checksum algorithm which was developed by Mark Adler and
 * published in 1995. It is used to detect accidental changes to data.
 * Adler-32 is created by calculating two 16-bit checksums for a given
 * stream of bytes and concatenating them.
 *
 * Example:
 * ```d
 * import caiman.digest.adler32;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = Adler32.hash(data);
 * ```
 */
public static @digester class Adler32
{
private:
static:
pure:
    enum MOD_ADLER = 65_521;

public:
    /**
    * Computes the Adler-32 hash digest of the given data.
    *
    * Params:
    *  data = The input byte array for which the Adler-32 hash is to be computed.
    *
    * Returns:
    *  A byte array representing the computed Adler-32 hash digest.
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