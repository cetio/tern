module caiman.digest.hight;

import caiman.digest;
import caiman.range;
import caiman.serialization;

public static @digester class HIGHT
{
private:
static:
pure:
    ubyte[8] encryptBlock(ubyte[8] data, ubyte[16] key) 
    {
        ushort[16] roundKeys;
        for (int i = 0; i < 16; i++)
            roundKeys[i] = key[i] << 8 | key[i >= 15 ? 0 : i + 1];
        
        ushort l = data[0] << 8 | data[1];
        ushort r = data[2] << 8 | data[3];
        ushort t;
        
        foreach (i; 0..16)
        {
            r ^= ((l << 1) + (l >> 15) + roundKeys[i]) & 0xFFFF;
            t = l;
            l = r;
            r = t;
        }
        
        t = l;
        l = r;
        r = t;
        
        ubyte[8] block;
        block[0] = cast(ubyte)(l >> 8);
        block[1] = cast(ubyte)(l & 0xFF);
        block[2] = cast(ubyte)(r >> 8);
        block[3] = cast(ubyte)(r & 0xFF);
        
        return block;
    }

    ubyte[8] decryptBlock(ubyte[8] block, ubyte[16] key)
    {
        ushort[16] roundKeys;
        for (int i = 0; i < 16; i++)
            roundKeys[i] = key[i] << 8 | key[i >= 15 ? 0 : i + 1];
        
        ushort l = block[0] << 8 | block[1];
        ushort r = block[2] << 8 | block[3];
        ushort t;
        
        t = l;
        l = r;
        r = t;
        
        foreach_reverse (i; 0..16)
        {
            t = r;
            r = l;
            l = t;
            r ^= ((l << 1) + (l >> 15) + roundKeys[i]) & 0xFFFF;
        }
        
        ubyte[8] data;
        data[0] = cast(ubyte)(l >> 8);
        data[1] = cast(ubyte)(l & 0xFF);
        data[2] = cast(ubyte)(r >> 8);
        data[3] = cast(ubyte)(r & 0xFF);
        
        return data;
    }

public:
    void encrypt(ref ubyte[] data, string key)
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");
            
        vacpp(data, 8);

        ushort[16] roundKeys;
        for (int i = 0; i < 16; i++)
            roundKeys[i] = key[i] << 8 | key[i >= 15 ? 0 : i + 1];
        
        foreach (ref block; data.portionTo!(ubyte[8]))
        {
            ushort l = block[0] << 8 | block[1];
            ushort r = block[2] << 8 | block[3];
            ushort t;
        
            foreach (i; 0..16)
            {
                r ^= ((l << 1) + (l >> 15) + roundKeys[i]) & 0xFFFF;
                t = l;
                l = r;
                r = t;
            }
        
            t = l;
            l = r;
            r = t;
        
            block[0] = cast(ubyte)(l >> 8);
            block[1] = cast(ubyte)(l & 0xFF);
            block[2] = cast(ubyte)(r >> 8);
            block[3] = cast(ubyte)(r & 0xFF);
        }
    }

    void decrypt(ref ubyte[] data, string key)
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        if (data.length % 8 != 0)
            vacpp(data, 8);

        ushort[16] roundKeys;
        for (int i = 0; i < 16; i++)
            roundKeys[i] = key[i] << 8 | key[i >= 15 ? 0 : i + 1];
        
        foreach (ref block; data.portionTo!(ubyte[8]))
        {
            ushort l = block[0] << 8 | block[1];
            ushort r = block[2] << 8 | block[3];
            ushort t;
        
            t = l;
            l = r;
            r = t;
        
            foreach_reverse (i; 0..16)
            {
                t = r;
                r = l;
                l = t;
                r ^= ((l << 1) + (l >> 15) + roundKeys[i]) & 0xFFFF;
            }
        
            block[0] = cast(ubyte)(l >> 8);
            block[1] = cast(ubyte)(l & 0xFF);
            block[2] = cast(ubyte)(r >> 8);
            block[3] = cast(ubyte)(r & 0xFF);
        }

        data = data[0..$-16];
        unvacpp(data);
    }
}