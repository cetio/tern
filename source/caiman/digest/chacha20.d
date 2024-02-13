/// ChaCha20 symmetric streaming encryption implementation using 256 bit keys.
module caiman.digest.chacha20;

/// ChaCha20 symmetric streaming encryption implementation using 256 bit keys.
public static class ChaCha20
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
    void crypt(ref ubyte[] data, string key, ubyte[12] nonce, uint counter = 0)
    {
        if (key.length != 32)
            throw new Throwable("Key must be 256 bits!");

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
}