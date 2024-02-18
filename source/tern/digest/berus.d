/// Implementation of Berus digester
module tern.digest.berus;

import std.conv;
import tern.object;
import tern.digest;

/**
 * Implementation of Berus digester.
 *
 * Berus is a modified Argon2 designed for lightweight and low-resource
 * environments. It operates by dividing the input data into blocks, applying a series
 * of operations, including XOR and addition, and then compressing the result.
 *
 * Example:
 * ```d
 * import tern.digest.berus;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * ubyte[] salt = [6, 7, 8, 9, 10];
 * auto hashValue = Berus.hash(data, salt);
 * ```
 */
public static @digester class Berus
{
private:
static:
pure:
    enum BLOCK_SIZE = 32;
    enum OPS_LIMIT = 14;

public:
    /**
    * Computes the Berus digest of the given data.
    * 
    * Params:
    *  data - The data to be hashed.
    *  salt - The salt to be used in the hashing process.
    * 
    * Returns:
    *  The hashed result as an array of ubytes.
    */
    ubyte[] hash(ubyte[] data, ubyte[] salt) 
    {
        ulong[BLOCK_SIZE] block;

        foreach (i, ref b; block)
            b += data[i % data.length];

        foreach (i, b; data)
            block[i % BLOCK_SIZE] ^= b;

        foreach (i, b; salt)
            block[(i + BLOCK_SIZE / 2) % BLOCK_SIZE] ^= b;

        void compress()
        {
            ulong F(ulong x, ulong y) 
            {
                return (x + y) * (x ^ y);
            }

            foreach (i; 0..BLOCK_SIZE / 4) 
            {
                block[i * 4] = F(block[i * 4], block[i * 4 + 1]);
                block[i * 4 + 1] = F(block[i * 4 + 1], block[i * 4 + 2]);
                block[i * 4 + 2] = F(block[i * 4 + 2], block[i * 4 + 3]);
                block[i * 4 + 3] = F(block[i * 4 + 3], block[i * 4]);
            }

            foreach (i; 0..BLOCK_SIZE) 
                block[i] ^= block[(i + 1) % BLOCK_SIZE];

            foreach_reverse (i; 1..BLOCK_SIZE) 
                block[i] += block[i - 1];
        }

        for (uint i = 0; i < OPS_LIMIT; i++)
            compress();

        return block[0..8].serialize!true();
    }
}