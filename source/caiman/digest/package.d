/// Digests and ingests for various cryptography algorithms
module caiman.digest;

import std.meta;
import caiman.traits;
import caiman.object;
import caiman.meta;

public enum digester;

public alias isDigest(T) = Alias!(seqContains!(digester, __traits(getAttributes, T)));
public alias isEncryptingDigest(T) = Alias!(isDigest!T && hasStaticMember!(T, "encrypt"));
public alias isHashingDigest(T) = Alias!(isDigest!T && hasStaticMember!(T, "hash"));

/* public class Digest(T, IV...)
    if (isDigest!T)
{
protected:
final:
    ubyte[] data;
    IV iv;

public:
    this(IV iv)
    {
        this.iv = iv;
    }

    auto digest(T)(ptrdiff_t count = 1)
    {
        T[] ret;
        foreach (i; 0..count)
            ret ~= deserialize!T(serialize!true(digest(T.sizeof * count)));
        return ret;
    }

    auto digest(ptrdiff_t size)
    {
        scope (exit) data = data[size..$];
        static if (isEncryptingDigest!T)
            return T.encrypt(*cast(ubyte[]*)data[0..size], iv);
        else static if (isHashingDigest!T)
            return T.hash(data[0..size], iv);
    }

    auto digest(ARGS...)(ptrdiff_t size, ARGS args)
    {
        auto data = this.data[0..size];
        static if (isEncryptingDigest!T)
            return T.encrypt(data, args);
        else static if (isHashingDigest!T)
            return T.hash(*cast(ubyte[]*)data[0..size], args);
    }

    auto ingest(T)(ptrdiff_t count = 1)
    {
        T[] ret;
        foreach (i; 0..count)
            ret ~= deserialize!T(serialize!true(ingest(T.sizeof * count)));
        return ret;
    }

    auto ingest(ptrdiff_t size)
    {
        auto data = this.data[0..size];
        scope (exit) data = data[size..$];
        static if (isEncryptingDigest!T)
            return T.decrypt(*cast(ubyte[]*)data[0..size], iv);
        else static if (isHashingDigest!T)
            return (serialize!true(T.hash(data[0..size], iv))).toHexString();
    }

    auto ingest(ARGS...)(ptrdiff_t size, ARGS args)
    {
        static if (isEncryptingDigest!T)
            return T.decrypt(*cast(ubyte[]*)data[0..size], args);
        else static if (isHashingDigest!T)
            return (serialize!true(T.hash(data[0..size], args))).toHexString();
    }

    void devour(ubyte[] data)
    {
        this.data ~= data;
    }

    void drop(ptrdiff_t size)
    {
        data = data[size..$];
    }
} */

public:
static:
/**
 * Digests arguments by the given provider `T`
 * `T` must either have a `encrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function.
 *  - If `T` has an encrypt function present, the output will be the output of the encryption function.
 */
public auto digest(T, ARGS...)(ARGS args)
    if (isEncryptingDigest!T)
{
    return T.encrypt(args);
}

/**
 * Ingests arguments by the given provider `T`  
 * `T` must either have a `decrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function serialized as a string.
 *  - If `T` has a decrypt function present, the output will be the output of the decryption function.
 */
public auto ingest(T, ARGS...)(ARGS args)
    if (isEncryptingDigest!T)
{
    return T.decrypt(args);
}

/**
 * Digests arguments by the given provider `T`  
 * `T` must either have a `encrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function.
 *  - If `T` has an encrypt function present, the output will be the output of the encryption function.
 */
public auto digest(T, ARGS...)(ARGS args)
    if (isHashingDigest!T)
{
    return T.hash(args);
}

/**
 * Ingests arguments by the given provider `T`  
 * `T` must either have a `decrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function serialized as a string.
 *  - If `T` has a decrypt function present, the output will be the output of the decryption function.
 */
public auto ingest(T, ARGS...)(ARGS args)
    if (isHashingDigest!T)
{
    return (serialize!true(T.hash(args))).toHexString();
}

string toHexString(ubyte[] data) 
{
    char hexDigit(ubyte value) 
    {
        return value < 10 ? cast(char)('0' + value) : cast(char)('A' + (value - 10));
    }

    string ret;
    foreach (b; data) 
    {
        ret ~= hexDigit(b >> 4);
        ret ~= hexDigit(b & 0x0F);
    }
    return ret;
}

