/// Implementation of Mira digesters, internally backed by `caiman.digest.fhkdf`
module caiman.digest.mira;

import core.simd;
import caiman.digest;
import caiman.digest.fhkdf;

/**
 * Implementation of Mira256 digester, internally backed by `caiman.digest.fhkdf`
 *
 * Mira is an incredibly fast stream encryption algorithm based on shuffling and vector
 * xor operations on data.
 *
 * Example:
 * ```d
 * string key = "SpWc5m7uednxBqV2YrKk83tZ6UayFEPRSpWc5m7uednxBqV2YrKk83tZ6UayFEPR";
 * ubyte[] data = cast(ubyte[])"Hello World!";
 * Mira256.encrypt(data, key);
 * Mira256.decrypt(data, key);
 */
public static @digester class Mira256
{
public:
static:
pure:
    /**
    * Computes a sane hash value of the key and calculates the number of shuffles.
    *
    * This method takes an input byte array `data`, a string `key`, an unsigned long `seed`, 
    * and returns a string representing the sane hash value of the key. Additionally, it 
    * outputs the number of shuffles performed during the operation.
    *
    * Params:
    *  data = The input byte array.
    *  key = The encryption key as a string. Must be either 256 or 512 bits.
    *  seed = An unsigned long value used as a seed for the hashing operation.
    *  numShuffles = An output parameter representing the number of shuffles performed during the operation.
    *
    * Returns:
    *  A string representing the sane hash value of the key.
    */
    string getSaneKeyHash(ubyte[] data, string key, ulong seed, out ptrdiff_t numShuffles)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");

        ubyte[] keyFront = digest!FHKDF(cast(ubyte[])key, seed);
        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];

        for (ptrdiff_t s; s < data.length; s += (a + b + c + d) % ((data.length / 16_384) | 2))
            numShuffles++;

        string sane;
        foreach (_c; key)
        {
            if (_c <= ubyte.max / 2)
                sane ~= 'a' + (_c % 26);
            else
                sane ~= '0' + (_c % 10);
        }
        return sane;
    }

    /**
    * Encrypts the given byte array `data`
    *
    * This method encrypts the data using the Mira algorithm with the specified encryption `key`
    * and an optional `seed` value. The encryption is done in place.
    *
    * Params:
    *  data = Reference to the byte array to be encrypted.
    *  key = The encryption key as a string. Must be either 256 or 512 bits.
    *  seed = An optional seed value used for encryption. Defaults to 0.
    */
    void encrypt(ref ubyte[] data, string key, ulong seed = 0)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");

        ubyte[] keyFront = digest!FHKDF(cast(ubyte[])key, seed);
        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];

        ptrdiff_t rlen = data.length - (data.length % 16);
        ptrdiff_t e = (a + b + c + d) % ((data.length / 16_384) | 2);

        for (ptrdiff_t i = e; i < data.length; i += e)
        {
            ubyte b0 = data[i];
            data[i] = data[i - e];
            data[i - e] = b0;
        }

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            *vptr += e;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            _b += e;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
        }
    }

    /**
    * Decrypts the given byte array `data`
    *
    * This method decrypts the data using the Mira algorithm with the specified decryption `key`
    * and an optional `seed` value. The decryption is done in place.
    *
    * Params:
    *  data = Reference to the byte array to be decrypted.
    *  key = The decryption key as a string. Must be either 256 or 512 bits.
    *  seed = An optional seed value used for decryption. Defaults to 0.
    */
    void decrypt(ref ubyte[] data, string key, ulong seed = 0)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");
            
        ubyte[] keyFront = digest!FHKDF(cast(ubyte[])key, seed);
        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];

        ptrdiff_t e = (a + b + c + d) % ((data.length / 16_384) | 2);
        ptrdiff_t rlen = data.length - (data.length % 16);

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            *vptr -= e;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
            _b -= e;
        }

        ptrdiff_t s = e;
        for (; s < data.length; s += e) { }
        s -= e;
        for (; s >= e; s -= e)
        {
            ubyte b0 = data[s];
            data[s] = data[s - e];
            data[s - e] = b0;
        }
    }
}

/**
 * Implementation of Mira512 digester, internally backed by `caiman.digest.fhkdf`
 *
 * Mira is an incredibly fast stream encryption algorithm based on shuffling and vector
 * xor operations on data.
 *
 * Example:
 * ```d
 * string key = "SpWc5m7uednxBqV2YrKk83tZ6UayFEPRSpWc5m7uednxBqV2YrKk83tZ6UayFEPR";
 * ubyte[] data = cast(ubyte[])"Hello World!";
 * Mira512.encrypt(data, key);
 * Mira512.decrypt(data, key);
 */
public static @digester class Mira512
{
public:
static:
pure:
    /**
    * Computes a sane hash value of the key and calculates the number of shuffles.
    *
    * This method takes an input byte array `data`, a string `key`, an unsigned long `seed`, 
    * and returns a string representing the sane hash value of the key. Additionally, it 
    * outputs the number of shuffles performed during the operation.
    *
    * Params:
    *  data = The input byte array.
    *  key = The encryption key as a string. Must be either 256 or 512 bits.
    *  seed = An unsigned long value used as a seed for the hashing operation.
    *  numShuffles = An output parameter representing the number of shuffles performed during the operation.
    *
    * Returns:
    *  A string representing the sane hash value of the key.
    */
    string getSaneKeyHash(ubyte[] data, string key, ulong seed, out ptrdiff_t numShuffles)
    {
        if (key.length != 64)
            throw new Throwable("Key is not 512 bits!");

        ubyte[] keyFront = digest!FHKDF(cast(ubyte[])key[0..32], seed);
        ubyte[] keyBack = digest!FHKDF(cast(ubyte[])key[32..64], seed);

        ulong ap = (cast(ulong*)keyBack.ptr)[0];
        ulong bp = (cast(ulong*)keyBack.ptr)[1];
        ulong cp = (cast(ulong*)keyBack.ptr)[2];
        ulong dp = (cast(ulong*)keyBack.ptr)[3];

        for (ptrdiff_t s; s < data.length; s += (ap + bp + cp + dp) % ((data.length / 16_384) | 2))
            numShuffles++;

        string sane;
        foreach (_c; keyFront~keyBack)
        {
            if (_c <= ubyte.max / 2)
                sane ~= 'a' + (_c % 26);
            else
                sane ~= '0' + (_c % 10);
        }
        return sane;
    }

    /**
    * Encrypts the given byte array `data`
    *
    * This method encrypts the data using the Mira algorithm with the specified encryption `key`
    * and an optional `seed` value. The encryption is done in place.
    *
    * Params:
    *  data = Reference to the byte array to be encrypted.
    *  key = The encryption key as a string. Must be either 256 or 512 bits.
    *  seed = An optional seed value used for encryption. Defaults to 0.
    */
    void encrypt(ref ubyte[] data, string key, ulong seed = 0)
    {
        if (key.length != 64)
            throw new Throwable("Key is not 512 bits!");

        ubyte[] keyFront = digest!FHKDF(cast(ubyte[])key[0..32], seed);
        ubyte[] keyBack = digest!FHKDF(cast(ubyte[])key[32..64], seed);

        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];
        ulong ap = (cast(ulong*)keyBack.ptr)[0];
        ulong bp = (cast(ulong*)keyBack.ptr)[1];
        ulong cp = (cast(ulong*)keyBack.ptr)[2];
        ulong dp = (cast(ulong*)keyBack.ptr)[3];

        ptrdiff_t rlen = data.length - (data.length % 16);
        ptrdiff_t e = (ap + bp + cp + dp) % ((data.length / 16_384) | 2);

        for (ptrdiff_t i = e; i < data.length; i += e)
        {
            ubyte b0 = data[i];
            data[i] = data[i - e];
            data[i - e] = b0;
        }

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            *vptr += e;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            _b += e;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
        }
    }

    /**
    * Decrypts the given byte array `data`
    *
    * This method decrypts the data using the Mira algorithm with the specified decryption `key`
    * and an optional `seed` value. The decryption is done in place.
    *
    * Params:
    *  data = Reference to the byte array to be decrypted.
    *  key = The decryption key as a string. Must be either 256 or 512 bits.
    *  seed = An optional seed value used for decryption. Defaults to 0.
    */
    void decrypt(ref ubyte[] data, string key, ulong seed = 0)
    {
        if (key.length != 64)
            throw new Throwable("Key is not 512 bits!");
        
        ubyte[] keyFront = digest!FHKDF(cast(ubyte[])key[0..32], seed);
        ubyte[] keyBack = digest!FHKDF(cast(ubyte[])key[32..64], seed);
        
        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];
        ulong ap = (cast(ulong*)keyBack.ptr)[0];
        ulong bp = (cast(ulong*)keyBack.ptr)[1];
        ulong cp = (cast(ulong*)keyBack.ptr)[2];
        ulong dp = (cast(ulong*)keyBack.ptr)[3];

        ptrdiff_t rlen = data.length - (data.length % 16);
        ptrdiff_t e = (ap + bp + cp + dp) % ((data.length / 16_384) | 2);

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            *vptr -= e;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
            _b -= e;
        }

        ptrdiff_t s = e;
        for (; s < data.length; s += e) { }
        s -= e;
        for (; s >= e; s -= e)
        {
            ubyte b0 = data[s];
            data[s] = data[s - e];
            data[s - e] = b0;
        }
    }
}