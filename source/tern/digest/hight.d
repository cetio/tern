/// Implementation of HIGHT digester
module tern.digest.hight;

import tern.digest;
import tern.algorithm;
import tern.serialization;

/**
 * Implementation of HIGHT digester.
 *
 * HIGHT is a lightweight block cipher designed for low-resource environments.
 * It operates by encrypting or decrypting data using a 128-bit key and 64-bit
 * blocks.
 *
 * Example:
 * ```d
 * import tern.digest.hight;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5, 6, 7, 8];
 * string key = "1234567890123456";
 * HIGHT.encrypt(data, key);
 * ```
 */
public static @digester class HIGHT
{
public:
static:
pure:
    /**
    * Encrypts the given data using the HIGHT algorithm with the specified key.
    *
    * Params:
    *  data = Reference to the input byte array to be encrypted.
    *  key = The key used for encryption. Must be 128 bits (16 bytes) long.
    */
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

    /**
    * Decrypts the given data using the HIGHT algorithm with the specified key.
    *
    * Params:
    *  data = Reference to the input byte array to be decrypted.
    *  key = The key used for decryption. Must be 128 bits (16 bytes) long.
    */
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