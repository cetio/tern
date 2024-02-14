module caiman.digest.hash.crc32;

import caiman.serialization;

public static class CRC32
{
public:
static:
pure:
    const uint[256] crcTable;

    shared static this()
    {
        uint[256] _crcTable;
        uint poly =  0xEDB88320;
        for (uint i =  0; i <  256; ++i) 
        {
            uint crc = i;
            for (uint j =  0; j <  8; ++j) 
            {
                if (crc &  1)
                    crc = (crc >>  1) ^ poly;
                else
                    crc = crc >>  1;
            }
            _crcTable[i] = crc;
        }
        crcTable = _crcTable;
    }

    ubyte[] hash(const(ubyte[]) data) 
    {
        uint crc =  0xFFFFFFFF;
        foreach (ubyte octet; data)
            crc = crcTable[(crc ^ octet) &  0xFF] ^ (crc >>  8);
        return (~crc).serialize!true(); 
    }
}