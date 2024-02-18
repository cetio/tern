/// Implementation of Salsa20 digester
module tern.digest.salsa20;

import tern.digest;
import tern.digest.circe;

/**
 * Implementation of Salsa20 digester.
 *
 * Salsa20 is a stream cipher designed to be highly efficient and secure. It operates 
 * on 512-bit (64-byte) blocks and accepts a 256-bit (32-byte) key and a 64-bit (8-byte) 
 * nonce.
 *
 * Example:
 * ```d
 * import tern.digest.salsa20;
 *
 * ubyte[] data = [1, 2, 3, 4, 5];
 * string key = "my_secret_key"; // Must be exactly 256 bits (32 bytes) in length.
 * ubyte[8] nonce = [0, 0, 0, 0, 0, 0, 0, 0]; // Must be exactly 64 bits (8 bytes) in length.
 * Salsa20.encrypt(data, key, nonce);
 * ```
 */
public static @digester class Salsa20
{
private:
static:
    void quarterRound(ref uint[16] block, uint a, uint b, uint c, uint d)
    {
        block[a] += block[b]; block[d] = (block[d] ^ block[a]) << 7 | (block[d] ^ block[a]) >>> (32 - 7);
        block[c] += block[d]; block[b] = (block[b] ^ block[c]) << 9 | (block[b] ^ block[c]) >>> (32 - 9);
        block[a] += block[b]; block[d] = (block[d] ^ block[a]) << 13 | (block[d] ^ block[a]) >>> (32 - 13);
        block[c] += block[d]; block[b] = (block[b] ^ block[c]) << 18 | (block[b] ^ block[c]) >>> (32 - 18);
    }

    uint[16] innerRound(ref uint[16] block)
    {
        foreach (i; 0 .. 10) 
        {
            quarterRound(block, 0, 4, 8, 12);
            quarterRound(block, 1, 5, 9, 13);
            quarterRound(block, 2, 6, 10, 14);
            quarterRound(block, 3, 7, 11, 15);
            quarterRound(block, 0, 5, 10, 15);
            quarterRound(block, 1, 6, 11, 12);
            quarterRound(block, 2, 7, 8, 13);
            quarterRound(block, 3, 4, 9, 14);
        }
        return block;
    }

public:
    /**
    * Encrypts the given byte array `data`
    *
    * Params:
    *  data: Reference to the input byte array to be encrypted.
    *  key: The encryption key. Must be exactly 256 bits (32 bytes) in length.
    *  nonce: The nonce value. Must be exactly 64 bits (8 bytes) in length.
    */
    void encrypt(ref ubyte[] data, string key, ubyte[8] nonce, uint counter = 0)
    {
        if (key.length != 32)
            throw new Throwable("Key must be 256 bits!");

        key = cast(string)Circe.hash(cast(ubyte[])key);

        uint[16] state;
        state[0..4] = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];
        state[4..12] = *cast(uint[8]*)key.ptr;
        state[12..14] = counter;
        state[14..16] = cast(uint[2])nonce;

        uint[16] keyStream;
        ubyte offset = 64;

        foreach (ref octet; data) 
        {
            if (offset >= 64) 
            {
                keyStream = state.dup;
                innerRound(keyStream);
                // Counter
                state[12]++;
                offset = 0;
            }

            octet ^= (cast(ubyte[64])keyStream)[offset];
            offset++;
        }
    }

    /**
    * Decrypts the given byte array `data`
    *
    * Params:
    *  data: Reference to the input byte array to be encrypted.
    *  key: The encryption key. Must be exactly 256 bits (32 bytes) in length.
    *  nonce: The nonce value. Must be exactly 64 bits (8 bytes) in length.
    */
    void decrypt(ref ubyte[] data, string key, ubyte[8] nonce, uint counter = 0) => encrypt(data, key, nonce, counter);
}
