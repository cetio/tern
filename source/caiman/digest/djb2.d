/// Implementation of DJB2 digester
module caiman.digest.djb2;

import caiman.digest;
import caiman.object;

/**
 * Implementation of DJB2 digester.
 *
 * DJB2 is a widely used non-cryptographic hash function created by Daniel J. Bernstein.
 * It is simple, fast, and produces well-distributed hash values for various inputs.
 *
 * Example:
 * ```d
 * import caiman.digest.djb2;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = DJB2.hash(data);
 * ```
 */
public static @digester class DJB2
{
public:
static:
pure:
    /**
    * Computes the DJB2 hash digest of the given data.
    *
    * Params:
    *  data = The input byte array for which the DJB2 hash is to be computed.
    *
    * Returns:
    *  A byte array representing the computed DJB2 hash digest.
    */
    ubyte[] hash(ubyte[] data)
    {
        uint ret = 5381;
        foreach (b; data)
            ret = ((ret << 5) + ret) + b;
        return ret.serialize!true();
    }
}