/// Implementation of Anura digester.
module tern.digest.anura;

// TODO: Fix?
import tern.digest;
import tern.digest.circe;
import tern.serialization;
import tern.algorithm;

/**
 * Implementation of Anura256 digester.
 *
 * Anura256 is a fast and efficient pseudo-fiestel block based block cipher 
 * that primarily works by shuffling data around and works with blocks of 64 bits.
 * It utilizes a 256-bit key for encryption and decryption.
 *
 * Example:
 * ```d
 * import tern.digest.anura;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * string key = "0123456789ABCDEF0123456789ABCDEF"; // Must be 32 bytes (256 bits)
 * Anura256.encrypt(data, key);
 * Anura256.decrypt(data, key);
 * ```
 */
public static @digester class Anura256
{
public:
static:
pure:
    /**
     * Encrypts the given data using Anura256 algorithm.
     *
     * Params:
     *  data = The data to be encrypted.
     *  key = The encryption key, must be 256 bits (32 bytes).
     */
    void encrypt(ref ubyte[] data, string key)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");

        key = cast(string)digest!Circe(cast(ubyte[])key[0..32]);
        ulong rola = (cast(ulong*)key.ptr)[1];
        ulong rolb = (cast(ulong*)key.ptr)[2];
        ulong rolc = (cast(ulong*)key.ptr)[3];
        ulong rold = (cast(ulong*)key.ptr)[4];

        ulong[8] set = [
            rola,
            rolb,
            rolc,
            rold,
            rola << rolb,
            rolb << rolc,
            rolc << rold,
            rold << rola,
        ];

        foreach (i; 0..(rola % 128))
        {
            size_t factor = ((set[i % 8] * i) % ((data.length / 16_384) | 2)) | 1;  
            for (size_t j = factor; j < data.length; j += factor)
                data.swap(j, j - factor);
        }

        void swap(ref ulong block)
        {
            uint left = (cast(uint*)&block)[0];
            (cast(uint*)&block)[0] = (cast(uint*)&block)[1];
            (cast(uint*)&block)[1] = left;
        }

        foreach (i; 0..4)
        {
            foreach (j, ref block; data.portionTo!(ulong))
            {
                size_t ri = ~j;
                size_t si = j % 8;
                block += (rola << si) ^ ri;
                block ^= (rolb << si) ^ ri;
                swap(block);
                block -= (rolc << si) ^ ri;
                block ^= (rold << si) ^ ri;
            }

            foreach (j, ref block; (cast(ulong[])data)[1..$])
                block ^= data[j];
        }
    }

    /**
     * Decrypts the given data using Anura256 algorithm.
     *
     * Params:
     *  data = The data to be decrypted.
     *  key = The decryption key, must be 256 bits (32 bytes).
     */
    void decrypt(ref ubyte[] data, string key)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");

        key = cast(string)digest!Circe(cast(ubyte[])key[0..32]);
        ulong rola = (cast(ulong*)key.ptr)[1];
        ulong rolb = (cast(ulong*)key.ptr)[2];
        ulong rolc = (cast(ulong*)key.ptr)[3];
        ulong rold = (cast(ulong*)key.ptr)[4];

        ulong[8] set = [
            rola,
            rolb,
            rolc,
            rold,
            rola << rolb,
            rolb << rolc,
            rolc << rold,
            rold << rola,
        ];

        if (data.length % 8 != 0)
            vacpp(data, 8);

        void swap(ref ulong block)
        {
            uint left = (cast(uint*)&block)[0];
            (cast(uint*)&block)[0] = (cast(uint*)&block)[1];
            (cast(uint*)&block)[1] = left;
        }

        foreach_reverse (i; 0..4)
        {
            foreach_reverse (j, ref block; (cast(ulong[])data)[1..$])
                block ^= data[j];

            foreach_reverse (j, ref block; cast(ulong[])data)
            {
                size_t ri = ~j;
                size_t si = j % 8;
                block ^= (rold << si) ^ ri;
                block += (rolc << si) ^ ri;
                swap(block);
                block ^= (rolb << si) ^ ri;
                block -= (rola << si) ^ ri;
            }
        }

        foreach_reverse (i; 0..(rola % 128))
        {
            size_t factor = ((set[i % 8] * i) % ((data.length / 16_384) | 2)) | 1;  
            for (size_t j = factor; j < data.length; j += factor)
                data.swap(j, j - factor);
        }

        unvacpp(data);
    }
}

/**
 * Implementation of Anura1024 digester.
 *
 * Anura1024 is a variant of Anura cipher that utilizes a 1024-bit key for encryption
 * and decryption.
 *
 * Example:
 * ```d
 * import tern.digest.anura;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * string key = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"; // Must be 128 bytes (1024 bits)
 * Anura1024.encrypt(data, key);
 * Anura1024.decrypt(data, key);
 * ```
 */
public static @digester class Anura1024
{
public:
static:
pure:
    /**
     * Encrypts the given data using Anura1024 algorithm.
     *
     * Params:
     *  data = The data to be encrypted.
     *  key = The encryption key, must be 1024 bits (128 bytes).
     */
    void encrypt(ref ubyte[] data, string key)
    {
        if (key.length != 128)
            throw new Throwable("Key is not 1024 bits!");

        key = cast(string)digest!Circe(cast(ubyte[])key[0..32], 0xFC2AB8FFFFF)~
            cast(string)digest!Circe(cast(ubyte[])key[32..64], 0xCCABB72DA)~
            cast(string)digest!Circe(cast(ubyte[])key[64..96], 0xABC0001700)~
            cast(string)digest!Circe(cast(ubyte[])key[96..128], 0x0000D7FFF);
        ulong rola = (cast(ulong*)key.ptr)[0] ^ (cast(ulong*)key.ptr)[1] | 32;
        ulong rolb = (cast(ulong*)key.ptr)[2] ^ (cast(ulong*)key.ptr)[3] | 32;
        ulong rolc = (cast(ulong*)key.ptr)[4] ^ (cast(ulong*)key.ptr)[5] | 32;
        ulong rold = (cast(ulong*)key.ptr)[6] ^ (cast(ulong*)key.ptr)[7] | 32;
        ulong roba = (cast(ulong*)key.ptr)[12] ^ (cast(ulong*)key.ptr)[8] | rola;
        ulong robb = (cast(ulong*)key.ptr)[13] ^ (cast(ulong*)key.ptr)[9] | rolb;
        ulong robc = (cast(ulong*)key.ptr)[14] ^ (cast(ulong*)key.ptr)[10] | rolc;
        ulong robd = (cast(ulong*)key.ptr)[15] ^ (cast(ulong*)key.ptr)[11] | rold;

        ulong[16] set = [
            rola,
            rolb,
            rolc,
            rold,
            roba,
            robb,
            robc,
            robd,
            rola ^ roba,
            rolb ^ robb,
            rolc ^ robc,
            rold ^ robd,
            rola * roba,
            rolb * robb,
            rolc * robc,
            rold * robd,
        ];

        vacpp(data, 8);

        foreach (i; 0..(roba % 128))
        {
            size_t factor = ((set[i % 16] * i) % ((data.length / 16_384) | 2)) | 1;  
            for (size_t j = factor; j < data.length; j += factor)
                data.swap(j, j - factor);
        }

        void swap(ref ulong block)
        {
            uint left = (cast(uint*)&block)[0];
            (cast(uint*)&block)[0] = (cast(uint*)&block)[1];
            (cast(uint*)&block)[1] = left;
        }

        foreach (i; 0..2)
        {
            foreach (j, ref block; cast(ulong[])data)
            {
                size_t ri = ~i;
                size_t si = i % 8;
                block += (rola << si) ^ ri;
                block ^= (robb << si) ^ ri;
                swap(block);
                block -= (rolc << si) ^ ri;
                block ^= (robd << si) ^ ri;
            }

            foreach (j, ref block; (cast(ulong[])data)[1..$])
                block ^= data.ptr[j - 1];
        }
    }

    /**
     * Decrypts the given data using Anura1024 algorithm.
     *
     * Params:
     *  data = The data to be decrypted.
     *  key = The decryption key, must be 1024 bits (128 bytes).
     */
    void decrypt(ref ubyte[] data, string key)
    {
        if (key.length != 128)
            throw new Throwable("Key is not 1024 bits!");

        key = cast(string)digest!Circe(cast(ubyte[])key[0..32], 0xFC2AB8FFFFF)~
            cast(string)digest!Circe(cast(ubyte[])key[32..64], 0xCCABB72DA)~
            cast(string)digest!Circe(cast(ubyte[])key[64..96], 0xABC0001700)~
            cast(string)digest!Circe(cast(ubyte[])key[96..128], 0x0000D7FFF);
        ulong rola = (cast(ulong*)key.ptr)[0] ^ (cast(ulong*)key.ptr)[1] | 32;
        ulong rolb = (cast(ulong*)key.ptr)[2] ^ (cast(ulong*)key.ptr)[3] | 32;
        ulong rolc = (cast(ulong*)key.ptr)[4] ^ (cast(ulong*)key.ptr)[5] | 32;
        ulong rold = (cast(ulong*)key.ptr)[6] ^ (cast(ulong*)key.ptr)[7] | 32;
        ulong roba = (cast(ulong*)key.ptr)[12] ^ (cast(ulong*)key.ptr)[8] | rola;
        ulong robb = (cast(ulong*)key.ptr)[13] ^ (cast(ulong*)key.ptr)[9] | rolb;
        ulong robc = (cast(ulong*)key.ptr)[14] ^ (cast(ulong*)key.ptr)[10] | rolc;
        ulong robd = (cast(ulong*)key.ptr)[15] ^ (cast(ulong*)key.ptr)[11] | rold;

        ulong[16] set = [
            rola,
            rolb,
            rolc,
            rold,
            roba,
            robb,
            robc,
            robd,
            rola ^ roba,
            rolb ^ robb,
            rolc ^ robc,
            rold ^ robd,
            rola * roba,
            rolb * robb,
            rolc * robc,
            rold * robd,
        ];

        if (data.length % 8 != 0)
            vacpp(data, 8);

        void swap(ref ulong block)
        {
            uint left = (cast(uint*)&block)[0];
            (cast(uint*)&block)[0] = (cast(uint*)&block)[1];
            (cast(uint*)&block)[1] = left;
        }

        foreach_reverse (i; 0..2)
        {
            foreach_reverse (j, ref b; (cast(ulong[])data)[1..$])
                b ^= data.ptr[j - 1];

            foreach_reverse (j, ref block; cast(ulong[])data)
            {
                size_t ri = ~i;
                size_t si = i % 8;
                block ^= (robd << si) ^ ri;
                block += (rolc << si) ^ ri;
                swap(block);
                block ^= (robb << si) ^ ri;
                block -= (rola << si) ^ ri;
            }
        }

        foreach_reverse (i; 0..(roba % 128))
        {
            size_t factor = ((set[i % 16] * i) % ((data.length / 16_384) | 2)) | 1;  
            size_t s = factor;
            for (; s < data.length; s += factor) { }
            s -= factor;
            for (; s >= factor; s -= factor)
                data.swap(s, s - factor);
        }

        unvacpp(data);
    }
}