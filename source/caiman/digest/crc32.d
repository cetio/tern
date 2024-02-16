/// Implementation of CRC32 digester
module caiman.digest.crc32;

import caiman.object;
import caiman.digest;

/**
 * Implementation of CRC32 digester.
 *
 * CRC32 (Cyclic Redundancy Check 32) is a widely used error-detecting code algorithm that
 * produces a 32-bit (4-byte) hash value. It is commonly used in network communications, storage 
 * systems, and other applications where data integrity is crucial.
 *
* Example:
* ```d
* import caiman.digest.crc;
*
* ubyte[] data = [1, 2, 3, 4, 5];
* auto hashValue = CRC32.hash(data);
* ```
 */
public static @digester class CRC32
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

    /**
     * Computes the CRC32 hash digest of the given data.
     *
     * Params:
     *  data = The input byte array for which the CRC32 hash is to be computed.
     *
     * Returns:
     *  A byte array representing the computed CRC32 hash digest.
     */
    ubyte[] hash(const(ubyte[]) data) 
    {
        uint crc =  0xFFFFFFFF;
        foreach (ubyte octet; data)
            crc = crcTable[(crc ^ octet) &  0xFF] ^ (crc >>  8);
        return (~crc).serialize!true(); 
    }
}