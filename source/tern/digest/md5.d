/// Implementation of MD5 digester.
module tern.digest.md5;

import tern.digest;

/** 
 * Implementation of MD5 digester.
 *
 * MD5 (Message Digest Algorithm 5) is a widely used cryptographic hash function that produces
 * a 128-bit (16-byte) hash value. It is commonly used for checksums and cryptographic 
 * applications, although it is not recommended for security purposes due to vulnerabilities.
 *
 * Example:
 * ```d
 * import tern.digest.md5;
 *
 * ubyte[] data = [1, 2, 3, 4, 5];
 * auto hashValue = MD5.hash(data);
 * ```
 */
public static @digester class MD5
{
public:
static:
pure:
    /**
     * Computes the MD5 hash digest of the given data.
     *
     * Params:
     *  data = The input byte array for which the MD5 hash is to be computed.
     *
     * Returns:
     *  A byte array representing the computed MD5 hash digest.
     */
    auto hash(ubyte[] data)
    {
        import std.digest;
        import std.digest.md;
        return digest!(std.digest.md.MD5)(data);
    }
}