module caiman.digest.fnv1;

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
ulong fnv1(ubyte[] data) 
{
    enum OFFSETBASIS = 14695981039346656037;
    enum PRIME = 1099511628211;

    ulong hash = OFFSETBASIS;
    foreach (b; data) 
    {
        hash ^= b;
        hash *= PRIME;
    }
    return hash;
}