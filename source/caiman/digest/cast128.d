/* module caiman.digest.cast128;

import caiman.digest;

public static @digester class CAST128
{
private:
static:
pure:
    uint rotl(uint a, uint b)
    {
        return (a << b) | (a >> (32 - b));
    }
    
    uint f1(uint x, uint k) 
    {
        return rotl(k + x, 7);
    }

public:
    void encrypt(ref ubyte[] data, string key) 
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        uint[] k = new uint[32];
        for (int i = 0; i < 16; i += 2) 
        {
            k[i] = (cast(uint)key[i] << 8) + cast(uint)key[i + 1];
            k[i + 1] = (cast(uint)key[i + 2] << 8) + cast(uint)key[i + 3];
        }

        data ~= new ubyte[8 - (data.length % 8)];
        ubyte[] result;

        foreach (i; 0 .. data.length / 8) {
            uint left = (cast(uint)data[i * 8] << 24) + (cast(uint)data[i * 8 + 1] << 16) + (cast(uint)data[i * 8 + 2] << 8) + cast(uint)data[i * 8 + 3];
            uint right = (cast(uint)data[i * 8 + 4] << 24) + (cast(uint)data[i * 8 + 5] << 16) + (cast(uint)data[i * 8 + 6] << 8) + cast(uint)data[i * 8 + 7];

            for (int round = 0; round < 8; ++round) {
                left ^= f1(right, k[4 * round]);
                right ^= f1(left, k[4 * round + 1]);
                left ^= f1(right, k[4 * round + 2]);
                right ^= f1(left, k[4 * round + 3]);
            }

            result ~= cast(ubyte)((left >> 24) & 0xFF);
            result ~= cast(ubyte)((left >> 16) & 0xFF);
            result ~= cast(ubyte)((left >> 8) & 0xFF);
            result ~= cast(ubyte)(left & 0xFF);
            result ~= cast(ubyte)((right >> 24) & 0xFF);
            result ~= cast(ubyte)((right >> 16) & 0xFF);
            result ~= cast(ubyte)((right >> 8) & 0xFF);
            result ~= cast(ubyte)(right & 0xFF);
        }

        data = result;
    }

    void decrypt(ref ubyte[] data, string key)
    {
        // Initialize key schedule
        uint[] k = new uint[32];
        for (int i = 0; i < 16; i += 2) {
            k[i] = (cast(uint)key[i] << 8) + cast(uint)key[i + 1];
            k[i + 1] = (cast(uint)key[i + 2] << 8) + cast(uint)key[i + 3];
        }

        ubyte[] result;

        foreach (i; 0 .. data.length / 8) {
            uint left = (cast(uint)data[i * 8] << 24) + (cast(uint)data[i * 8 + 1] << 16) + (cast(uint)data[i * 8 + 2] << 8) + cast(uint)data[i * 8 + 3];
            uint right = (cast(uint)data[i * 8 + 4] << 24) + (cast(uint)data[i * 8 + 5] << 16) + (cast(uint)data[i * 8 + 6] << 8) + cast(uint)data[i * 8 + 7];

            for (int round = 7; round >= 0; --round) {
                left ^= f1(right, k[4 * round + 3]);
                right ^= f1(left, k[4 * round + 2]);
                left ^= f1(right, k[4 * round + 1]);
                right ^= f1(left, k[4 * round]);
            }

            result ~= cast(ubyte)((left >> 24) & 0xFF);
            result ~= cast(ubyte)((left >> 16) & 0xFF);
            result ~= cast(ubyte)((left >> 8) & 0xFF);
            result ~= cast(ubyte)(left & 0xFF);
            result ~= cast(ubyte)((right >> 24) & 0xFF);
            result ~= cast(ubyte)((right >> 16) & 0xFF);
            result ~= cast(ubyte)((right >> 8) & 0xFF);
            result ~= cast(ubyte)(right & 0xFF);
        }

        data = result;
    }
} */