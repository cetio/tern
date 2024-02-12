module caiman.stream.atomic_stream;

import caiman.stream.impl;
import caiman.typecons;
import caiman.serialization;
import caiman.conv;
import caiman.traits;

public enum Seek
{
    Start,
    Current,
    End
}

public class AtomicStream
{
public:
final:
shared:
    Atomic!(ubyte[]) data;
    Atomic!ptrdiff_t position;
    Atomic!Endianness endianness;

    shared this(T)(T data, Endianness endianness = Endianness.Native)
    {
        if (isArray!T)
            this.data = atomic(cast(ubyte[])data);
        else
            this.data = atomic(data.serialize());
        this.endianness = atomic(endianness);
    }

    @nogc T read(T)()
    {
        return *cast(T*)data[position..(position += T.sizeof)].ptr;
    }

    @nogc void write(T)(T val)
    {
        data[position..(position += T.sizeof)] = (cast(ubyte*)&val)[0..T.sizeof];
    }
}