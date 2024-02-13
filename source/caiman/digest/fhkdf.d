/// Mira symmetric streaming encryption key hash algorithm implementation.
module caiman.digest.fhkdf;

public static class FHKDF
{
public:
static:
pure:
    /** 
    * Hashes a 256 bit key.
    *
    * Params:
    *   key = Source string to be hashed.
    *   seed = Seed of the hash. (IV)
    *
    * Returns: 
    *  The hash of `key` as a 256 bit string.
    *
    * Remarks:
    *  Does not validate the length of `key`
    */
    pragma(inline)
    string hash(string key, ulong seed)
    {
        char[32] dst;
        foreach (k; 0..32)
        {
            foreach (v; 0..32)
            {
                dst[k] += key[k] ^ seed;
                dst[31 - k] = cast(char)(dst[31 - k] * key[v]);
                dst[31 - k] ^= dst[k] & key[k];
            }
        }
        return cast(string)dst.dup;
    }
}