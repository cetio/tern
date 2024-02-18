module tern.digest.tea;

import tern.digest;
import tern.algorithm;
import tern.object;

public static @digester class TEA
{
public:
static:
pure:
    void encrypt(ref ubyte[] data, string key) 
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        uint[4] k = *cast(uint[4]*)key.ptr;
        uint delta = 0x9E3779B9;
        uint rounds = 32;
        uint sum = 0;
        uint k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3];

        vacpp(data, 8);
        
        for (size_t i = 0; i < data.length; i += 8) 
        {
            auto block = data[i .. i + 8].ptr;
            uint v0 = *cast(uint*)block;
            uint v1 = *cast(uint*)(block + 4);
            sum = 0;

            for (uint j = 0; j < rounds; ++j) 
            {
                sum += delta;
                v0 += (((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1));
                v1 += (((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3));
            }

            *cast(uint*)block = v0;
            *cast(uint*)(block + 4) = v1;
        }
    }

    void decrypt(ref ubyte[] data, string key) 
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        uint[4] k = *cast(uint[4]*)key.ptr;
        uint delta = 0x9E3779B9;
        uint rounds = 32;
        uint sum;
        uint k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3];

        if (data.length % 8 != 0)
            vacpp(data, 8);

        for (size_t i = 0; i < data.length; i += 8) 
        {
            auto block = data[i .. i + 8].ptr;
            uint v0 = *cast(uint*)block;
            uint v1 = *cast(uint*)(block + 4);
            sum = delta << 5;

            for (uint j = 0; j < rounds; ++j) 
            {
                v1 -= (((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3));
                v0 -= (((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1));
                sum -= delta;
            }

            *cast(uint*)block = v0;
            *cast(uint*)(block + 4) = v1;
        }

        unvacpp(data);
    }
}

public static @digester class XTEA 
{
public:
static:
pure:
    void encrypt(ref ubyte[] data, string key) 
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        int[4] k = *cast(int[4]*)key.ptr;
        int delta = 0x9E3779B9;
        int rounds = 32;
        int sum = 0;

        vacpp(data, 8);

        for (size_t i = 0; i < data.length; i += 8) 
        {
            auto block = data[i .. i + 8].ptr;
            int v0 = *cast(int*)block;
            int v1 = *cast(int*)(block + 4);
            sum = 0;

            for (int j = 0; j < rounds; ++j) 
            {
                sum += delta;
                v0 += (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + k[(sum >> 11) & 3]);
                v1 += (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + k[sum & 3]);
            }

            *cast(int*)block = v0;
            *cast(int*)(block + 4) = v1;
        }
    }

    void decrypt(ref ubyte[] data, string key) 
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        int[4] k = *cast(int[4]*)key.ptr;
        int delta = 0x9E3779B9;
        int rounds = 32;
        int sum;

        if (data.length % 8 != 0)
            vacpp(data, 8);

        for (size_t i = 0; i < data.length; i += 8) 
        {
            auto block = data[i .. i + 8].ptr;
            int v0 = *cast(int*)block;
            int v1 = *cast(int*)(block + 4);
            sum = delta << 5;

            for (int j = 0; j < rounds; ++j) 
            {
                v1 -= (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + k[sum & 3]);
                v0 -= (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + k[(sum >> 11) & 3]);
                sum -= delta;
            }

            *cast(int*)block = v0;
            *cast(int*)(block + 4) = v1;
        }

        unvacpp(data);
    }
}

public static @digester class XXTEA 
{
public:
static:
pure:
    void encrypt(ref ubyte[] data, string key) 
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        int[4] k = *cast(int[4]*)key.ptr;
        int delta = 0x9E3779B9;
        int rounds = 32;
        int sum = 0;

        vacpp(data, 8);

        for (size_t i = 0; i < data.length; i += 8) 
        {
            auto block = data[i..(i + 8)].ptr;
            int v0 = *cast(int*)block;
            int v1 = *cast(int*)(block + 4);
            sum = 0;

            for (int j = 0; j < rounds; ++j) 
            {
                sum += delta;
                v0 += (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + k[(sum >> 11) & 3]);
                v1 += (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + k[sum & 3]);
            }

            *cast(int*)block = v0;
            *cast(int*)(block + 4) = v1;
        }
    }

    void decrypt(ref ubyte[] data, string key) 
    {
        if (key.length != 16)
            throw new Throwable("Key is not 128 bits!");

        int[4] k = *cast(int[4]*)key.ptr;
        int delta = 0x9E3779B9;
        int rounds = 32;
        int sum;

        if (data.length % 8 != 0)
            vacpp(data, 8);

        for (size_t i = 0; i < data.length; i += 8) 
        {
            auto block = data[i .. i + 8].ptr;
            int v0 = *cast(int*)block;
            int v1 = *cast(int*)(block + 4);
            sum = delta << 5;

            for (int j = 0; j < rounds; ++j) 
            {
                v1 -= (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + k[sum & 3]);
                v0 -= (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + k[(sum >> 11) & 3]);
                sum -= delta;
            }

            *cast(int*)block = v0;
            *cast(int*)(block + 4) = v1;
        }

        unvacpp(data);
    }
}