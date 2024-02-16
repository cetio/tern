/// Implementation of Circe digester.
module caiman.digest.circe;

import caiman.digest;
import caiman.algorithm;
import caiman.serialization;

/** 
 * Implementation of Circe digester.
 *
 * Circe is a very fast and efficient key derivation algorithm designed for 256 bit keys.
 *
 * ```d
 * import caiman.digest.circe
 *
 * string key = "...";
 * ulong seed = 0xFF3CA9FF;
 * auto keyHash = Circe.hash(cast(ubyte)key, seed);
 */
public static @digester class Circe
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
        sachp(data, 32);

        foreach (block; data.portionTo!(ubyte[32]))
        {
            foreach (k; 0..32)
            {
                foreach (v; 0..32)
                {
                    dst[k] += block[k] ^ seed;
                    dst[31 - k] = cast(ubyte)(dst[31 - k] * block[v]);
                    dst[31 - k] ^= dst[k] & block[k];
                }
            }
        }
        return dst.dup;
    }
}