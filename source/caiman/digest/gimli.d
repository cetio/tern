module caiman.digest.gimli;

import caiman.digest;
import caiman.algorithm;
import caiman.object;

public static @digester class Gimli
{
public:
static:
pure:
    ubyte[] hash(ubyte[] data) 
    {
        sachp(data, 128);
        
        foreach (ref block; data.portionTo!(uint[4]))
        {
            foreach (r; 0..24)
            {
                for (uint col = 0; col < 4; ++col)
                    block[col] ^= block[col] >>> 24;

                block[0] += block[1];
                block[1] = block[1] << 9 | block[1] >>> 23;
                block[2] += block[3];
                block[3] = block[3] << 9 | block[3] >>> 23;
                block[1] ^= block[0];
                block[3] ^= block[2];
                block[0] += block[3];
                block[3] = block[3] << 2 | block[3] >>> 30;
                block[2] += block[1];
                block[1] = block[1] << 2 | block[1] >>> 30;
            }
        }
        return data;
    }
}