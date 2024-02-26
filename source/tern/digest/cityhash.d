/// Implementation of CityHash digester
module tern.digest.cityhash;

import tern.digest;
import tern.serialize;

/**
 * Implementation of CityHash digester.
 *
 * CityHash is a family of hash functions developed by Google.
 * It provides fast and strong hash functions for hash tables and checksums.
 *
 * Example:
 * ```d
 * import tern.digest.cityhash;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = CityHash.hash(data);
 * ```
 */
public static @digester class CityHash
{
public:
static:
pure:
    /**
    * Computes the CityHash digest of the given data.
    *
    * Params:
    *  data = The input byte array for which the CityHash digest is to be computed.
    *
    * Returns:
    *  A byte array representing the computed CityHash digest.
    */
    ubyte[] hash(ubyte[] data)
    {
        ulong seed = 0x9ae16a3b2f90404f;
        ulong m = 0xc6a4a7935bd1e995;
        ulong r = 47;
        ulong h = seed + (data.length * m);

        size_t i = 0;
        foreach_reverse (j; 0..(data.length / 8))
        {
            ulong k = data[i..i+8].deserialize!ulong();
            i += 8;
            k *= m;
            k ^= k >> r;
            k *= m;
            h ^= k;
            h *= m;
        }

        if (data.length % 8 != 0)
        {
            ulong k = 0;
            foreach (j; 0..(data.length % 8))
                k |= (data[i + j] << (8 * j));

            k *= m;
            k ^= k >> r;
            k *= m;
            h ^= k;
        }

        h ^= h >> r;
        h *= m;
        h ^= h >> r;

        return h.serialize!true();
    }
}