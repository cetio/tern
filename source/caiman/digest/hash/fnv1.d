module caiman.digest.hash.fnv1;

import caiman.serialization;

public static class FNV1
{
public:
static:
pure:
    /**
    * Hashes `data` using FNV1.
    *
    * Params:
    *  data = Data to be hashed.
    *
    * Returns:
    *  Hash of `data`
    */
    ubyte[] hash(ubyte[] data) 
    {
        enum OFFSETBASIS = 14695981039346656037;
        enum PRIME = 1099511628211;

        ulong hash = OFFSETBASIS;
        foreach (b; data) 
        {
            hash ^= b;
            hash *= PRIME;
        }
        return hash.serialize!true();
    }
}