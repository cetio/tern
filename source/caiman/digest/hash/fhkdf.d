module caiman.digest.hash.fhkdf;

public static class FHKDF
{
public:
static:
pure:
    /** 
    * Derives a 256 bit key from `data`.
    *
    * Params:
    *   data = Data to hash and derive from.
    *   seed = Seed of the hash. (IV)
    *
    * Returns: 
    *  The new key derived from `data`
    *
    * Remarks:
    *  Does not validate the length of `data`
    */
    pragma(inline)
    ubyte[] hash(ubyte[] data, ulong seed = 0)
    {
        ubyte[32] dst;
        foreach (k; 0..32)
        {
            foreach (v; 0..32)
            {
                dst[k] += data[k] ^ seed;
                dst[31 - k] = cast(ubyte)(dst[31 - k] * data[v]);
                dst[31 - k] ^= dst[k] & data[k];
            }
        }
        return dst.dup;
    }
}