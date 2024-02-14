module caiman.digest.hash.murmurhash;

import caiman.memory;
import caiman.serialization;

public static class MurmurHash
{
private:
static:
pure:
    uint rotl(uint a, uint b)
    {
        return (a << b) | (a >> (32 - b));
    }

public:
    ubyte[] hash(ubyte[] data, uint seed = 0)
    {
        enum uint c1 = 0xcc9e2d51;
        enum uint c2 = 0x1b873593;
        enum uint r1 = 15;
        enum uint r2 = 13;
        enum uint m = 5;
        enum uint n = 0xe6546b64;

        data ~= new ubyte[data.length + (uint.sizeof - (data.length % uint.sizeof))];

        uint hash = seed;
        foreach (k; cast(uint[])data)
        {
            k *= c1;
            k = rotl(k, r1);
            k *= c2;

            hash ^= k;
            hash = rotl(hash, r2);
            hash = hash * m + n;
        }

        hash ^= data.length * 4;

        hash ^= hash >> 16;
        hash *= 0x85ebca6b;
        hash ^= hash >> 13;
        hash *= 0xc2b2ae35;
        hash ^= hash >> 16;

        return hash.serialize!true();
    }
}