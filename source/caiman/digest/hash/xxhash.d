module caiman.digest.hash.xxhash;

import caiman.serialization;

public static class xxHash
{
public:
static:
pure:
    ubyte[] hash(ubyte[] data)
    {
        const ulong prime1 = 11400714785074694791UL;
        const ulong prime2 = 14029467366897019727UL;
        const ulong prime3 = 1609587929392839161UL;
        const ulong prime4 = 9650029242287828579UL;
        const ulong prime5 = 2870177450012600261UL;

        ulong hash = data.length * prime5;
        foreach (b; data) 
        {
            hash += b * prime3;
            hash = (hash << 31) | (hash >> 33);
            hash *= prime2;
        }
        
        hash = (~hash) + (data.length * prime1);
        hash = (hash ^ (hash >> 27)) * prime1 + prime4;
        hash = (hash ^ (hash >> 31)) * prime1;
        return (hash ^ (hash >> 33)).serialize!true();
    }
}