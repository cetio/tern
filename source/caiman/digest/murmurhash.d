/// Implementation of MurmurHash digester
module caiman.digest.murmurhash;

import caiman.memory;
import caiman.serialization;
import caiman.digest;

/**
 * Implementation of MurmurHash digester.
 *
 * MurmurHash is a non-cryptographic hash function suitable for general hash-based 
 * lookup. It provides fast and relatively good distribution of hash values.
 *
 * Example:
 * ```d
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = MurmurHash.hash(data);
 * ```
 */
public static @digester class MurmurHash
{
private:
static:
pure:
    uint rotl(uint a, uint b)
    {
        return (a << b) | (a >> (32 - b));
    }

public:
    /**
    * Computes the MurmurHash digest of the given data.
    *
    * Params:
    *  data = The input byte array for which the hash is to be computed.
    *  seed = An optional seed value used to initialize the hash function. Defaults to 0.
    *
    * Returns:
    *  An array of bytes representing the computed MurmurHash digest.
    */
    ubyte[] hash(ubyte[] data, uint seed = 0)
    {
        enum uint c1 = 0xcc9e2d51;
        enum uint c2 = 0x1b873593;
        enum uint r1 = 15;
        enum uint r2 = 13;
        enum uint m = 5;
        enum uint n = 0xe6546b64;

        sachp(data, 4);

        uint hash = seed;
        foreach (k; cast(uint[])data)
        {
            k *= c1;
            k = rotl(k, r1);
            k *= c2;

            hash ^= k;
            hash = rotl(hash, r2);
            hash = hash * m + n;
        }

        hash ^= data.length * 4;
        hash ^= hash >> 16;
        hash *= 0x85ebca6b;
        hash ^= hash >> 13;
        hash *= 0xc2b2ae35;
        hash ^= hash >> 16;

        return hash.serialize!true();
    }
}