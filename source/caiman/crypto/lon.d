module caiman.crypto.lon;

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