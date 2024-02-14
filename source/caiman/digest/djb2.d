module caiman.digest.djb2;

import caiman.digest;
import caiman.serialization;

public static @digester class DJB2
{
public:
static:
pure:
    ubyte[] hash(ubyte[] data)
    {
        uint ret = 5381;
        foreach (b; data)
            ret = ((ret << 5) + ret) + b;
        return ret.serialize!true();
    }
}