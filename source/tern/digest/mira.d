/// Implementation of Mira digesters
module tern.digest.mira;

import core.simd;
import tern.digest;
import tern.digest.circe;

/**
 * Implementation of Mira256 digester, internally backed by `tern.digest.circe`
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

        ubyte[] keyFront = digest!Circe(cast(ubyte[])key, seed);
        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];

        size_t rlen = data.length - (data.length % 16);
        size_t factor = ((a + b + c + d) % ((data.length / 16_384) | 2)) | 1;

        for (size_t i = factor; i < data.length; i += factor)
        {
            ubyte b0 = data[i];
            data[i] = data[i - factor];
            data[i - factor] = b0;
        }

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            size_t ri = ~i;
            size_t si = i % 8;
            *vptr += factor;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            size_t ri = ~i;
            size_t si = i % 8;
            _b += factor;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
        }

        for (size_t i = factor; i < data.length; i += factor)
        {
            ubyte b0 = data[i];
            data[i] = data[i - factor];
            data[i - factor] = b0;
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
            
        ubyte[] keyFront = digest!Circe(cast(ubyte[])key, seed);
        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];

        size_t factor = ((a + b + c + d) % ((data.length / 16_384) | 2)) | 1;
        size_t rlen = data.length - (data.length % 16);

        size_t s = factor;
        for (; s < data.length; s += factor) { }
        s -= factor;
        for (; s >= factor; s -= factor)
        {
            ubyte b0 = data[s];
            data[s] = data[s - factor];
            data[s - factor] = b0;
        }

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            size_t ri = ~i;
            size_t si = i % 8;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            *vptr -= factor;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            size_t ri = ~i;
            size_t si = i % 8;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
            _b -= factor;
        }

        s = factor;
        for (; s < data.length; s += factor) { }
        s -= factor;
        for (; s >= factor; s -= factor)
        {
            ubyte b0 = data[s];
            data[s] = data[s - factor];
            data[s - factor] = b0;
        }
    }
}

/**
 * Implementation of Mira512 digester, internally backed by `tern.digest.circe`
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

        ubyte[] keyFront = digest!Circe(cast(ubyte[])key[0..32], seed);
        ubyte[] keyBack = digest!Circe(cast(ubyte[])key[32..64], seed);

        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];
        ulong ap = (cast(ulong*)keyBack.ptr)[0];
        ulong bp = (cast(ulong*)keyBack.ptr)[1];
        ulong cp = (cast(ulong*)keyBack.ptr)[2];
        ulong dp = (cast(ulong*)keyBack.ptr)[3];

        size_t rlen = data.length - (data.length % 16);
        size_t factor = ((ap + bp + cp + dp) % ((data.length / 16_384) | 2)) | 1;

        for (size_t i = factor; i < data.length; i += factor)
        {
            ubyte b0 = data[i];
            data[i] = data[i - factor];
            data[i - factor] = b0;
        }

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            size_t ri = ~i;
            size_t si = i % 8;
            *vptr += factor;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            size_t ri = ~i;
            size_t si = i % 8;
            _b += factor;
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
        
        ubyte[] keyFront = digest!Circe(cast(ubyte[])key[0..32], seed);
        ubyte[] keyBack = digest!Circe(cast(ubyte[])key[32..64], seed);
        
        ulong a = (cast(ulong*)keyFront.ptr)[0];
        ulong b = (cast(ulong*)keyFront.ptr)[1];
        ulong c = (cast(ulong*)keyFront.ptr)[2];
        ulong d = (cast(ulong*)keyFront.ptr)[3];
        ulong ap = (cast(ulong*)keyBack.ptr)[0];
        ulong bp = (cast(ulong*)keyBack.ptr)[1];
        ulong cp = (cast(ulong*)keyBack.ptr)[2];
        ulong dp = (cast(ulong*)keyBack.ptr)[3];

        size_t rlen = data.length - (data.length % 16);
        size_t factor = ((ap + bp + cp + dp) % ((data.length / 16_384) | 2)) | 1;

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            size_t ri = ~i;
            size_t si = i % 8;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            *vptr -= factor;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            size_t ri = ~i;
            size_t si = i % 8;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
            _b -= factor;
        }

        size_t s = factor;
        for (; s < data.length; s += factor) { }
        s -= factor;
        for (; s >= factor; s -= factor)
        {
            ubyte b0 = data[s];
            data[s] = data[s - factor];
            data[s - factor] = b0;
        }
    }
}