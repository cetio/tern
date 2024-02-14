module caiman.digest.cityhash;

import caiman.digest;
import caiman.serialization;

public static @digester class CityHash
{
public:
static:
pure:
    ubyte[] hash(ubyte[] data)
    {
        ulong seed = 0x9ae16a3b2f90404f;
        ulong m = 0xc6a4a7935bd1e995;
        ulong r = 47;

        ulong h = seed + (data.length * m);

        size_t i = 0;
        foreach_reverse (j; 0..(data.length / 8))
        {
            ulong k = data[i..i+8].deserialize!ulong();
            i += 8;
            k *= m;
            k ^= k >> r;
            k *= m;
            h ^= k;
            h *= m;
        }

        if (data.length % 8 != 0)
        {
            ulong k = 0;
            foreach (j; 0..(data.length % 8))
                k |= (data[i + j] << (8 * j));
                
            k *= m;
            k ^= k >> r;
            k *= m;
            h ^= k;
        }

        h ^= h >> r;
        h *= m;
        h ^= h >> r;

        return h.serialize!true();
    }
}