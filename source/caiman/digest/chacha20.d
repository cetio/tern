/// Implementation of ChaCha20 digester.
module caiman.digest.chacha20;

import caiman.digest;
import caiman.digest.circe;

/**
 * Implementation of ChaCha20 digester.
 *
 * ChaCha20 is a symmetric encryption algorithm designed to provide both high performance 
 * and high security. It operates on 512-bit (64-byte) blocks and accepts a 256-bit (32-byte) 
 * key and a 96-bit (12-byte) nonce.
*
* Example:
* ```d
* import caiman.digest.chacha20;
*
* ubyte[] data = [1, 2, 3, 4, 5];
* string key = "my_secret_key"; // Must be exactly 256 bits (32 bytes) in length.
* ubyte[12] nonce = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // Must be exactly 96 bits (12 bytes) in length.
* uint counter = 0;
* ChaCha20.encrypt(data, key, nonce, counter);
* ```
 */
public static @digester class ChaCha20
{
private:
static:
    void quarterRound(ref uint[16] block, uint a, uint b, uint c, uint d)
    {
        block[a] += block[b]; block[d] = (block[d] ^ block[a]) >>> 16;
        block[c] += block[d]; block[b] = (block[b] ^ block[c]) >>> 12;
        block[a] += block[b]; block[d] = (block[d] ^ block[a]) >>> 8;
        block[c] += block[d]; block[b] = (block[b] ^ block[c]) >>> 7;
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
     *  nonce: The nonce value. Must be exactly 96 bits (12 bytes) in length.
     *  counter: The initial counter value. Defaults to 0.
     */
    void encrypt(ref ubyte[] data, string key, ubyte[12] nonce, uint counter = 0)
    {
        if (key.length != 32)
            throw new Throwable("Key must be 256 bits!");

        key = cast(string)Circe.hash(cast(ubyte[])key);

        uint[16] state;
        state[0..4] = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];
        state[4..12] = *cast(uint[8]*)key.ptr;
        state[12..13] = counter;
        state[13..16] = cast(uint[3])nonce;

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
     *  nonce: The nonce value. Must be exactly 96 bits (12 bytes) in length.
     *  counter: The initial counter value. Defaults to 0.
     */
    void decrypt(ref ubyte[] data, string key, ubyte[12] nonce, uint counter = 0) => encrypt(data, key, nonce, counter);
}