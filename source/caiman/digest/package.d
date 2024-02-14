/** 
 * Digests for many different cryptography algorithms
 *
 * Good practice states that all encryptions happen in place with a `ref ubyte[]` as first param \
 * and hashing happens with a `ubyte[]` as first param.
 */
module caiman.digest;

public import caiman.digest.cipher;
public import caiman.digest.hash;

import caiman.traits;
import caiman.serialization;

/**
 * Digests arguments by the given provider `T` \
 * `T` must either have a `encrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function.
 *  - If `T` has an encrypt function present, the output will be the output of the encryption function.
 */
public auto digest(T, ARGS...)(ARGS args)
    if (hasMember!(T, "encrypt"))
{
    return T.encrypt(args);
}

/**
 * Ingests arguments by the given provider `T` \
 * `T` must either have a `decrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function serialized as a string.
 *  - If `T` has a decrypt function present, the output will be the output of the decryption function.
 */
public auto ingest(T, ARGS...)(ARGS args)
    if (hasMember!(T, "decrypt"))
{
    return T.decrypt(args);
}

/**
 * Digests arguments by the given provider `T` \
 * `T` must either have a `encrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function.
 *  - If `T` has an encrypt function present, the output will be the output of the encryption function.
 */
public auto digest(T, ARGS...)(ARGS args)
    if (hasMember!(T, "hash"))
{
    return T.hash(args);
}

/**
 * Ingests arguments by the given provider `T` \
 * `T` must either have a `decrypt` or `hash` function present.
 *
 * Remarks:
 *  - If `T` has a hash function present, the output will be the output of the hash function serialized as a string.
 *  - If `T` has a decrypt function present, the output will be the output of the decryption function.
 */
public auto ingest(T, ARGS...)(ARGS args)
    if (hasMember!(T, "hash"))
{
    import std.digest;
    return (serialize!true(T.hash(args))).toHexString();
}