module caiman.mira;

import std.parallelism;
import core.simd;
import std.algorithm;

public static class Mira
{
private:
static:
    pragma(inline)
    string hash(string src)
    {
        char[32] dst;
        foreach (k; 0..32)
        {
            foreach (v; 0..32)
            {
                dst[k] += src[k];
                dst[31 - k] = cast(char)(dst[31 - k] * src[v]);
                dst[31 - k] ^= dst[k] & src[k];
            }
        }
        return cast(string)dst.dup;
    }

    pragma(inline)
    string hash(string src, ptrdiff_t seed)
    {
        char[32] dst;
        foreach (k; 0..32)
        {
            foreach (v; 0..32)
            {
                dst[k] += src[k] ^ seed;
                dst[31 - k] = cast(char)(dst[31 - k] * src[v]);
                dst[31 - k] ^= dst[k] & src[k];
            }
        }
        return cast(string)dst.dup;
    }

public:
    public string getSaneKeyHash(ubyte[] data, string key, ptrdiff_t seed = 0)
    {
        key = hash(key, seed);
        ulong a = (cast(ulong*)&key[0])[0];
        ulong b = (cast(ulong*)&key[0])[1];
        ulong c = (cast(ulong*)&key[0])[2];
        ulong d = (cast(ulong*)&key[0])[3];
        key = hash(key, (a + b + c + d) % ((data.length / 4096) | 2));
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

    pragma(inline)
    public void encrypt(ref ubyte[] data, string key, ptrdiff_t seed = 0)
    {
        key = hash(key, seed);
        ulong a = (cast(ulong*)&key[0])[0];
        ulong b = (cast(ulong*)&key[0])[1];
        ulong c = (cast(ulong*)&key[0])[2];
        ulong d = (cast(ulong*)&key[0])[3];
        ptrdiff_t rlen = data.length - (data.length % 16);

        ptrdiff_t e = (a + b + c + d) % ((data.length / 4096) | 2);
        for (ptrdiff_t i = e; i < data.length; i += e)
        {
            ubyte b0 = data[i];
            data[i] = data[i - 1];
            data[i - 1] = b0;
        }

        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            ulong ri = ~i;
            ptrdiff_t si = i % 8;
            *vptr ^= (a << si) ^ ri; 
            *vptr ^= (b << si) ^ ri;
            *vptr ^= (c << si) ^ ri; 
            *vptr ^= (d << si) ^ ri;
            vptr += 1;
        }

        foreach (i, ref _b; parallel(data[rlen..$]))
        {
            ptrdiff_t ri = ~i;
            ptrdiff_t si = i % 8;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
        }

        /* foreach (i; 0..data.length)
        {
            if (i != 0)
                data[i] ^= data[i - 1];
        } */
    }

    pragma(inline)
    public void decrypt(ref ubyte[] data, string key, ptrdiff_t seed = 0)
    {
        key = hash(key, seed);
        ulong a = (cast(ulong*)&key[0])[0];
        ulong b = (cast(ulong*)&key[0])[1];
        ulong c = (cast(ulong*)&key[0])[2];
        ulong d = (cast(ulong*)&key[0])[3];
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
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            ulong ri = ~i;
            ptrdiff_t si = i % 8;
            _b ^= (a << si) ^ ri;
            _b ^= (b << si) ^ ri;
            _b ^= (c << si) ^ ri;
            _b ^= (d << si) ^ ri;
        }

        ptrdiff_t e = (a + b + c + d) % ((data.length / 4096) | 2);
        ptrdiff_t s = e;
        for (; s < data.length; s += e) { }
        s -= e;
        for (; s >= e; s -= e)
        {
            ubyte b0 = data[s];
            data[s] = data[s - 1];
            data[s - 1] = b0;
        }
    }
}
