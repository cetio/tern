/// Implementation of RIPEMD digester.
module tern.digest.ripemd;

import tern.digest;

/**
 * Implementation of RIPEMD digester.
 *
 * RIPEMD (RACE Integrity Primitives Evaluation Message Digest) is a family of
 * cryptographic hash functions developed in the early 1990s. RIPEMD is designed
 * as an alternative to the then-popular MD4 and MD5 algorithms. It produces a
 * 160-bit hash value, which is commonly represented as a 40-digit hexadecimal number.
 *
 * Example:
 * ```d
 * import tern.digest.ripemd;
 * 
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = RIPEMD.hash(data);
 * ```
 */
public static @digester class RIPEMD
{
public:
static:
pure:
    /**
     * Computes the RIPEMD hash digest of the given data.
     *
     * Params:
     *  data = The input byte array for which the RIPEMD hash is to be computed.
     *
     * Returns:
     *  A byte array representing the computed RIPEMD hash digest.
     */
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.ripemd;
        return digest!(std.digest.ripemd.RIPEMD160)(data);
    }
}