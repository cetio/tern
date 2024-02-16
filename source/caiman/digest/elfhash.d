module caiman.digest.elfhash;

import caiman.digest;
import caiman.object;

public static @digester class ELFHash
{
public:
static:
pure:
    ubyte[] hash(ubyte[] data)
    {
        uint ret;
        foreach (b; data) 
        {
            ret = (ret << 4) + b;
            uint t = ret & 0xF0000000;
            if (t != 0)
                ret ^= t >> 24;
            ret &= ~t;
        }
        return ret.serialize!true();
    }
}