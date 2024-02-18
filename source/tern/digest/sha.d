/// Implementation of SHA digesters
module tern.digest.sha;

import tern.digest;

/**
 * Implementation of Secure Hash Algorithm (SHA) digester.
 *
 * SHA is a family of cryptographic hash functions used to generate a fixed-size hash value from
 * input data of variable length. The SHA family includes variants such as SHA-1, SHA-256, SHA-512,
 * SHA-224, and SHA-384, each with different bit lengths.
 *
 * Example:
 * ```d
 * import tern.digest.sha;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto sha1Hash = SHA1.hash(data);
 * ```
 */
public static @digester class SHA1
{
public:
static:
pure:
    /**
     * Computes the SHA-1 hash of the given byte array `data`.
     *
     * Params:
     *  data = Input byte array to compute the hash.
     *
     * Returns:
     *  SHA-1 hash value as a byte array.
     */
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA1)(data);
    }
}

/**
 * Implementation of Secure Hash Algorithm (SHA) digester.
 *
 * SHA is a family of cryptographic hash functions used to generate a fixed-size hash value from
 * input data of variable length. The SHA family includes variants such as SHA-1, SHA-256, SHA-512,
 * SHA-224, and SHA-384, each with different bit lengths.
 *
 * Example:
 * ```d
 * import tern.digest.sha;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto sha256Hash = SHA256.hash(data);
 * ```
 */
public static @digester class SHA256
{
public:
static:
pure:
    /**
     * Computes the SHA-256 hash of the given byte array `data`.
     *
     * Params:
     *  data = Input byte array to compute the hash.
     *
     * Returns:
     *  SHA-256 hash value as a byte array.
     */
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA256)(data);
    }
}

/**
 * Implementation of Secure Hash Algorithm (SHA) digester.
 *
 * SHA is a family of cryptographic hash functions used to generate a fixed-size hash value from
 * input data of variable length. The SHA family includes variants such as SHA-1, SHA-256, SHA-512,
 * SHA-224, and SHA-384, each with different bit lengths.
 *
 * Example:
 * ```d
 * import tern.digest.sha;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto sha512Hash = SHA512.hash(data);
 * ```
 */
public static @digester class SHA512
{
public:
static:
pure:
    /**
     * Computes the SHA-512 hash of the given byte array `data`.
     *
     * Params:
     *  data = Input byte array to compute the hash.
     *
     * Returns:
     *  SHA-512 hash value as a byte array.
     */
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA512)(data);
    }
}

/**
 * Implementation of Secure Hash Algorithm (SHA) digester.
 *
 * SHA is a family of cryptographic hash functions used to generate a fixed-size hash value from
 * input data of variable length. The SHA family includes variants such as SHA-1, SHA-256, SHA-512,
 * SHA-224, and SHA-384, each with different bit lengths.
 *
 * Example:
 * ```d
 * import tern.digest.sha;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto sha224Hash = SHA224.hash(data);
 * ```
 */
public static @digester class SHA224
{
public:
static:
pure:
    /**
     * Computes the SHA-224 hash of the given byte array `data`.
     *
     * Params:
     *  data = Input byte array to compute the hash.
     *
     * Returns:
     *  SHA-224 hash value as a byte array.
     */
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA224)(data);
    }
}   

/**
 * Implementation of Secure Hash Algorithm (SHA) digester.
 *
 * SHA is a family of cryptographic hash functions used to generate a fixed-size hash value from
 * input data of variable length. The SHA family includes variants such as SHA-1, SHA-256, SHA-512,
 * SHA-224, and SHA-384, each with different bit lengths.
 *
 * Example:
 * ```d
 * import tern.digest.sha;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto sha384Hash = SHA384.hash(data);
 * ```
 */
public static @digester class SHA384
{
public:
static:
pure:
    /**
     * Computes the SHA-384 hash of the given byte array `data`.
     *
     * Params:
     *  data = Input byte array to compute the hash.
     *
     * Returns:
     *  SHA-384 hash value as a byte array.
     */
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.sha;
        return digest!(std.digest.sha.SHA384)(data);
    }
}   