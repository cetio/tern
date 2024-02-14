module caiman.digest.cipher.mira;

import core.simd;
import caiman.digest;
import caiman.digest.fhkdf;

public static class Mira256
{
public:
static:
pure:
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

public static class Mira512
{
public:
static:
pure:
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