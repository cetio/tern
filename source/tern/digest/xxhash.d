/// Implementation of XXHash digester.
module tern.digest.xxhash;

import tern.serialization;
import tern.digest;

/**
 * Implementation of XXHash digester.
 *
 * XXHash is an extremely fast non-cryptographic hash algorithm, which offers
 * excellent distribution, especially for small keys and values. It is designed
 * for speed and efficiency on both little-endian and big-endian machines.
 *
 * Example:
 * ```d
 * import tern.digest.xxhash;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = XXHash.hash(data);
 * ```
 */
public static @digester class XXHash
{
public:
static:
pure:
    /**
     * Computes the XXHash digest of the given data.
     *
     * Params:
     *  data = The input byte array for which the XXHash is to be computed.
     *
     * Returns:
     *  A byte array representing the computed XXHash digest.
     */
    ubyte[] hash(ubyte[] data)
    {
        const ulong prime1 = 11_400_714_785_074_694_791;
        const ulong prime2 = 14_029_467_366_897_019_727;
        const ulong prime3 = 1_609_587_929_392_839_161;
        const ulong prime4 = 9_650_029_242_287_828_579;
        const ulong prime5 = 2_870_177_450_012_600_261;

        ulong hash = data.length * prime5;
        foreach (b; data) 
        {
            hash += b * prime3;
            hash = (hash << 31) | (hash >> 33);
            hash *= prime2;
        }
        
        hash = (~hash) + (data.length * prime1);
        hash = (hash ^ (hash >> 27)) * prime1 + prime4;
        hash = (hash ^ (hash >> 31)) * prime1;
        return (hash ^ (hash >> 33)).serialize!true();
    }
}