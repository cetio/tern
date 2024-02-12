module caiman.crypto.mira;

import caiman.crypto.lon;
import std.parallelism;
import core.simd;

pragma(inline)
public void mira_encrypt(ref ubyte[] data, string key)
{
    key = hash(key);
    ulong a = (cast(ulong*)&key[0])[0];
    ulong b = (cast(ulong*)&key[0])[1];
    ulong c = (cast(ulong*)&key[0])[2];
    ulong d = (cast(ulong*)&key[0])[3];
    ptrdiff_t rlen = data.length - (data.length % 16);

    /* foreach (i; 0..data.length)
    {
        ptrdiff_t ii = cast(ptrdiff_t)(((c << i) & (d << i)) % data.length);
        ubyte b0 = data[i];
        data[i] = data[ii];
        data[ii] = b0;
    } */

    foreach (r; 0..3)
    {
        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            ulong ri = ~i;
            *vptr ^= (a << (i % 8)) ^ ri; 
            *vptr ^= (b << (i % 8)) ^ ri;
            *vptr ^= (c << (i % 8)) ^ ri; 
            *vptr ^= (d << (i % 8)) ^ ri;
            vptr += 1;
        }

        foreach (i, ref _b; parallel(data[rlen..$]))
        {
            ptrdiff_t ri = ~i;
            _b ^= (a << (i % 8)) ^ ri;
            _b ^= (b << (i % 8)) ^ ri;
            _b ^= (c << (i % 8)) ^ ri;
            _b ^= (d << (i % 8)) ^ ri;
        }

        a ^= r;
        b ^= r;
        c ^= r;
        d ^= r;
    }

    /* foreach (i; 0..data.length)
    {
        if (i != 0)
            data[i] ^= data[i - 1];
    } */
}

pragma(inline)
public void mira_decrypt(ref ubyte[] data, string key)
{
    key = hash(key);
    ulong a = (cast(ulong*)&key[0])[0];
    ulong b = (cast(ulong*)&key[0])[1];
    ulong c = (cast(ulong*)&key[0])[2];
    ulong d = (cast(ulong*)&key[0])[3];
    ptrdiff_t rlen = data.length - (data.length % 16);

    foreach_reverse (r; 0..3)
    {
        ulong2* vptr = cast(ulong2*)data.ptr;
        foreach (i; 0..(data.length / 16))
        {
            ulong ri = ~i;
            *vptr ^= (a << (i % 8)) ^ ri; 
            *vptr ^= (b << (i % 8)) ^ ri;
            *vptr ^= (c << (i % 8)) ^ ri; 
            *vptr ^= (d << (i % 8)) ^ ri;
            vptr += 1;
        }

        foreach (i, ref _b; data[rlen..$])
        {
            ulong ri = ~i;
            _b ^= (a << (i % 8)) ^ ri;
            _b ^= (b << (i % 8)) ^ ri;
            _b ^= (c << (i % 8)) ^ ri;
            _b ^= (d << (i % 8)) ^ ri;
        }

        a ^= r;
        b ^= r;
        c ^= r;
        d ^= r;
    }
}