/// Implementation of Circe digester
module tern.digest.circe;

// TODO: This is not cryptographically secure
import tern.digest;
import tern.algorithm;
import tern.serialization;

/** 
 * Implementation of Circe digester.
 *
 * Circe is a very fast and efficient key derivation algorithm designed for 256 bit keys.
 *
 * ```d
 * import tern.digest.circe
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
        if (data.length != 32)
            throw new Throwable("Circe only operates on 32 bytes of data (256 bits!)");
            
        ubyte[32] dst;
        foreach (k; 0..32)
        {
            foreach (v; 0..32)
            {
                dst[v] -= data[k] ^= seed;
                dst[31 - k] *= data[31 - v];
                dst[31 - k] -= dst[k] &= data[k];
            }
        }
        return dst.dup;
    }
}