/// Implementation of RC4 digester
module tern.digest.rc4;

import tern.serialization;
import tern.digest;
import tern.digest.circe;

/**
 * Implementation of RC4 digester.
 *
 * RC4 (Rivest Cipher 4) is a stream cipher algorithm widely used in various cryptographic 
 * applications. It operates by generating a pseudorandom stream of bits (keystream) based on 
 * a secret key, which is then XORed with the plaintext to produce the ciphertext.
 *
* Example:
* ```d
* import tern.digest.rc4;
* 
* ubyte[] data = [1, 2, 3, 4, 5];
* string key = "my_secret_key";
* RC4.encrypt(data, key);
* ```
 */
public static @digester class RC4
{
public:
static:
pure:
    /**
     * Encrypts the given byte array `data`
     *
     * Params:
     *  data = Reference to the input byte array to be encrypted.
     *  key = The encryption key.
     */
    void encrypt(ref ubyte[] data, string key) 
    {        
        if (key.length != 32)
            throw new Throwable("Key must be 256 bits!");

        key = cast(string)Circe.hash(cast(ubyte[])key);
        ubyte[256] S;
        ubyte[256] T;

        for (ubyte i = 0; i < 256; ++i) 
        {
            S[i] = i;
            T[i] = cast(ubyte)key[i % key.length];
        }

        ubyte j = 0;
        for (ubyte i = 0; i < 256; ++i) 
        {
            j = (j + S[i] + T[i]) % 256;
            S[i] = S[i] ^ S[j];
            S[j] = S[i] ^ S[j];
            S[i] = S[i] ^ S[j];
        }

        ubyte i = 0;
        j = 0;
        foreach (ref b; data) 
        {
            i = (i + 1) % 256;
            j = (j + S[i]) % 256;
            S[i] = S[i] ^ S[j];
            S[j] = S[i] ^ S[j];
            S[i] = S[i] ^ S[j];
            b ^= S[(S[i] + S[j]) % 256];
        }
    }

    /**
     * Decrypts the given byte array `data`
     *
     * Params:
     *  data = Reference to the input byte array to be decrypted.
     *  key = The decryption key.
     */
    void decrypt(ref ubyte[] data, string key) => encrypt(data, key);
}