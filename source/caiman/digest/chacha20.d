/// ChaCha20 symmetric streaming encryption implementation using 256 bit keys.
module caiman.digest.chacha20;

/// ChaCha20 symmetric streaming encryption implementation using 256 bit keys.
// Credit: https://github.com/route616/chacha/blob/master/source/chacha.d
public static class ChaCha20
{
private:
static:
pure:
    private struct StructuredState 
    {
        enum uint[4] constants = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];
        ubyte[32] key = 0;
        uint counter = 0;
        ubyte[12] nonce = 0;
    }

    private union State 
    {
        StructuredState asStruct;
        uint[16] asInts;
        ubyte[64] asBytes;

        alias asStruct this;
    }

    uint rotateLeft(uint value, uint shift)
    {
        return (value << shift) | (value >> (32 - shift));
    }

    void quarterRound(ref uint[16] block, ubyte a, ubyte b, ubyte c, ubyte d)
    {
        block[a] += block[b]; block[d] = rotateLeft(block[d] ^ block[a], 16);
        block[c] += block[d]; block[b] = rotateLeft(block[b] ^ block[c], 12);
        block[a] += block[b]; block[d] = rotateLeft(block[d] ^ block[a], 8);
        block[c] += block[d]; block[b] = rotateLeft(block[b] ^ block[c], 7);
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
            throw new Throwable("Key is not 256 bits!");

        State state;
        state.key = cast(ubyte[32])(key[0..32]);
        state.nonce = nonce;
        state.counter = counter;

        State keyStream = void;
        ubyte currentByteOffset = 64;

        foreach (ref octal; data) 
        {
            if (currentByteOffset >= 64) 
            {
                keyStream = state;
                keyStream.asInts[] += innerRound(keyStream.asInts)[];
                state.counter++;
                currentByteOffset = 0;
            }

            octal ^= keyStream.asBytes[currentByteOffset];
            currentByteOffset++;
        }
    }
}