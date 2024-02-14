module caiman.digest.cipher.rc4;

import caiman.serialization;

public static class RC4
{
public:
static:
pure:
    void encrypt(ref ubyte[] data, string key) 
    {
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
        foreach (ref b; data) {
            i = (i + 1) % 256;
            j = (j + S[i]) % 256;
            S[i] = S[i] ^ S[j];
            S[j] = S[i] ^ S[j];
            S[i] = S[i] ^ S[j];
            b ^= S[(S[i] + S[j]) % 256];
        }
    }

    void decrypt(ref ubyte[] data, string key) => encrypt(data, key);
}