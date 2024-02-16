/// Implementation of ELFHash digester
module caiman.digest.elfhash;

import caiman.digest;
import caiman.object;

/**
 * Implementation of ELFHash digester.
 *
 * ELFHash is a non-cryptographic hash function used in some hash table implementations.
 * It produces a hash value that can be used for indexing into a hash table.
 *
 * Example:
 * ```d
 * import caiman.digest.elfhash;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = ELFHash.hash(data);
 * ```
 */
public static @digester class ELFHash
{
public:
static:
pure:
    /**
    * Computes the ELFHash digest of the given data.
    *
    * Params:
    *  data = The input byte array for which the ELFHash digest is to be computed.
    *
    * Returns:
    *  A byte array representing the computed ELFHash digest.
    */
    ubyte[] hash(ubyte[] data)
    {
        uint ret;
        foreach (b; data) 
        {
            ret = (ret << 4) + b;
            uint t = ret & 0xF0000000;
            if (t != 0)
                ret ^= t >> 24;
            ret &= ~t;
        }
        return ret.serialize!true();
    }
}