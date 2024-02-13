/// Mira symmetric streaming encryption implementation using 256 bit keys.
module caiman.digest.mira256;

import core.simd;
import caiman.digest.fhkdf;

/// Mira symmetric streaming encryption implementation using 256 bit keys.
public static class Mira256
{
public:
static:
pure:
    public string getSaneKeyHash(ubyte[] data, string key, ulong seed, out ptrdiff_t numShuffles)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");

        key = FHKDF.hash(key, seed);
        ulong a = (cast(ulong*)&key[0])[0];
        ulong b = (cast(ulong*)&key[0])[1];
        ulong c = (cast(ulong*)&key[0])[2];
        ulong d = (cast(ulong*)&key[0])[3];

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

    public void encrypt(ref ubyte[] data, string key, ulong seed = 0)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");

        key = FHKDF.hash(key, seed);
        ulong a = (cast(ulong*)key.ptr)[0];
        ulong b = (cast(ulong*)key.ptr)[1];
        ulong c = (cast(ulong*)key.ptr)[2];
        ulong d = (cast(ulong*)key.ptr)[3];

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

    public void decrypt(ref ubyte[] data, string key, ulong seed = 0)
    {
        if (key.length != 32)
            throw new Throwable("Key is not 256 bits!");
            
        key = FHKDF.hash(key, seed);
        ulong a = (cast(ulong*)&key[0])[0];
        ulong b = (cast(ulong*)&key[0])[1];
        ulong c = (cast(ulong*)&key[0])[2];
        ulong d = (cast(ulong*)&key[0])[3];

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