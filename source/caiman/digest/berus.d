module caiman.digest.berus;

import std.conv;
import caiman.serialization;
import caiman.digest;

public static @digester class Berus
{
private:
static:
pure:
    enum BLOCK_SIZE = 32;
    enum OPS_LIMIT = 6;

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
                block[i] -= block[i - 1];
        }

        for (uint i = 0; i < OPS_LIMIT; i++)
            compress();

        return block[0..8].serialize!true();
    }
}