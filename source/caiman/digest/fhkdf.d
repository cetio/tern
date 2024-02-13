/// Mira symmetric streaming encryption key derivation implementation.
module caiman.digest.fhkdf;

public static class FHKDF
{
public:
static:
pure:
    /** 
    * Derives a 256 bit key from `key`.
    *
    * Params:
    *   key = Key to hash and derive from.
    *   seed = Seed of the hash. (IV)
    *
    * Returns: 
    *  The new key derived from `key`
    *
    * Remarks:
    *  Does not validate the length of `key`
    */
    pragma(inline)
    string derive(string key, ulong seed)
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