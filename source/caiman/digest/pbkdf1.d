module caiman.digest.pbkdf1;

public:
static:
public static class PBKDF1
{
public:
static:
    string derive(string key, ubyte[8] seed, uint rounds, string function(ubyte[]) hash)
    {
        string ret = hash((cast(ubyte[])key)~seed);
        for(uint i = 1; i < rounds; i++)
            ret = hash(cast(ubyte[])ret);
        
        return ret;
    }
}
