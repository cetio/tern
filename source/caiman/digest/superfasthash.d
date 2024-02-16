module caiman.digest.superfasthash;

import caiman.object;
import caiman.digest;

public static @digester class SuperFastHash
{
public:
static:
pure:
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