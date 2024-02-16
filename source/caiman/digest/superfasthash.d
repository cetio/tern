/// Implementation of SuperFastHash digester
module caiman.digest.superfasthash;

import caiman.object;
import caiman.digest;

/**
 * Implementation of SuperFastHash digester.
 *
 * SuperFastHash is a non-cryptographic hash function designed for fast hash calculations
 * on small data blocks. It is commonly used in applications where speed is critical.
 *
 * Example:
 * ```d
 * import caiman.digest.superfasthash;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = SuperFastHash.hash(data);
 * ```
 */
public static @digester class SuperFastHash
{
public:
static:
pure:
    /**
    * Computes the SuperFastHash digest of the given data.
    *
    * Params:
    *  data = The input byte array for which the SuperFastHash is to be computed.
    *
    * Returns:
    *  A byte array representing the computed SuperFastHash digest.
    */
    ubyte[] hash(ubyte[] data)
    {
        ptrdiff_t index = 0;
        ptrdiff_t digest = data.length;

        foreach_reverse (n; 0..(data.length >> 2)) 
        {
            digest += (data[index++] | (data[index++] << 8));
            digest ^= (digest << 16) ^ ((data[index++] | (data[index++] << 8)) << 11);
            digest += digest >> 11;
        }

        switch (data.length & 3) {
            case 3:
                digest += (data[index++] | (data[index++] << 8));
                digest ^= (digest << 16);
                digest ^= (data[index++] << 18);
                digest += digest >> 11;
                break;
            case 2:
                digest += (data[index++] | (data[index++] << 8));
                digest ^= (digest << 11);
                digest += digest >> 17;
                break;
            default:
                digest += data[index++];
                digest ^= (digest << 10);
                digest += digest >> 1;
                break;
        }

        digest ^= (digest << 3);
        digest += digest >> 5;
        digest ^= (digest << 4);
        digest += digest >> 17;
        digest ^= (digest << 25);
        digest += digest >> 6;

        return digest.serialize!true();
    }
}