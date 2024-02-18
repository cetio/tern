/// Implementation of MurmurHash digester
module tern.digest.murmurhash;

import tern.memory;
import tern.object;
import tern.digest;
import core.bitop;

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
    enum C1 = 0xcc9e2d51;
    enum C2 = 0x1b873593;
    enum R1 = 15;
    enum R2 = 13;
    enum M = 5;
    enum N = 0xe6546b64;

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
        sachp(data, 4);

        uint hash = seed;
        foreach (k; cast(uint[])data)
        {
            k *= C1;
            k = rol(k, R1);
            k *= C2;

            hash ^= k;
            hash = rol(hash, R2);
            hash = hash * M + N;
        }

        hash ^= data.length * 4;
        hash ^= hash >> 16;
        hash *= 0x85ebca6b;
        hash ^= hash >> 13;
        hash *= 0xC2b2ae35;
        hash ^= hash >> 16;

        return hash.serialize!true();
    }
}