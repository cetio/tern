/// Implementation of Gimli digester
module caiman.digest.gimli;

import caiman.digest;
import caiman.algorithm;
import caiman.object;

/**
 * Implementation of Gimli digester.
 *
 * Gimli is a cryptographic permutation designed for speed and security. It operates
 * by applying a series of operations to the input data, including bitwise XOR, addition,
 * and rotation.
 *
 * Example:
 * ```d
 * import caiman.digest.gimli;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = Gimli.hash(data);
 * ```
 */
public static @digester class Gimli
{
public:
static:
pure:
    /**
    * Computes the Gimli hash digest of the given data.
    *
    * Params:
    *  data = The input byte array for which the Gimli hash is to be computed.
    *
    * Returns:
    *  A byte array representing the computed Gimli hash digest.
    */
    ubyte[] hash(ubyte[] data) 
    {
        sachp(data, 128);
        
        foreach (ref block; data.portionTo!(uint[4]))
        {
            foreach (r; 0..24)
            {
                for (uint col = 0; col < 4; ++col)
                    block[col] ^= block[col] >>> 24;

                block[0] += block[1];
                block[1] = block[1] << 9 | block[1] >>> 23;
                block[2] += block[3];
                block[3] = block[3] << 9 | block[3] >>> 23;
                block[1] ^= block[0];
                block[3] ^= block[2];
                block[0] += block[3];
                block[3] = block[3] << 2 | block[3] >>> 30;
                block[2] += block[1];
                block[1] = block[1] << 2 | block[1] >>> 30;
            }
        }
        return data;
    }
}