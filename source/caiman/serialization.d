/// General-purpose binary serializer and deserializer for arbitrary data types
module caiman.serialization;

import caiman.traits;
import caiman.conv;

public:
static:
pure:
@trusted ubyte[] serialize(bool RAW = false, T)(T val)
{
    static if (isArray!T)
    {
        ubyte[] bytes;
        static if (!RAW)
            bytes ~= val.length.serialize;
            
        foreach (u; val)
            bytes ~= u.serialize;
        return bytes;
    }
    else static if (is(T == class))
    {
        ubyte[] bytes;
        foreach (field; FieldNameTuple!T)
            bytes ~= __traits(getMember, val, field).serialize;
        return bytes;
    }
    else
    {
        return (cast(ubyte*)&val)[0..T.sizeof].dup;
    }
}

@trusted deserialize(T, B)(B bytes)
    if ((isDynamicArray!B || isStaticArray!B) && (is(ElementType!B == ubyte) || is(ElementType!B == byte)))
{
    static if (isReferenceType!T)
    {
        static if (isArray!T)
            T ret = new T(0);
        else
            T ret = new T();
    }
    else
        T ret;
    ptrdiff_t offset;
    static if (isArray!T)
    {
        static if (isDynamicArray!T && !isImmutable!(ElementType!T))
        {
            ptrdiff_t length = deserialize!ptrdiff_t(bytes[offset..(offset += ptrdiff_t.sizeof)]);
            ret = new T(length);
        }
        else
        {
            ptrdiff_t length = Length!T;
        }

        if (bytes.length < length * ElementType!T.sizeof)
            bytes ~= new ubyte[(length * ElementType!T.sizeof) - bytes.length];

        foreach (i; 0..length)
        static if (!isImmutable!(ElementType!T))
            ret[i] = bytes[offset..(offset += ElementType!T.sizeof)].deserialize!(ElementType!T);
        else
            ret ~= bytes[offset..(offset += ElementType!T.sizeof)].deserialize!(ElementType!T);

        return ret;
    }
    else static if (is(T == class))
    {
        if (bytes.length < __traits(classInstanceSize))
            bytes ~= new ubyte[__traits(classInstanceSize) - bytes.length];

        foreach (field; FieldNameTuple!T)
            __traits(getMember, ret, field) = deserialize!(TypeOf!(T, field))(bytes[offset..(offset += TypeOf!(T, field).sizeof)]);
        return ret;
    }
    else
    {
        if (bytes.length < T.sizeof)
            bytes ~= new ubyte[T.sizeof - bytes.length];

        return *cast(T*)&bytes[offset];
        //return *cast(T*)(bytes[offset..(offset += T.sizeof)].ptr);
    }
}

void sachp(ref ubyte[] data, ptrdiff_t size)
{
    data ~= new ubyte[size - (data.length % size)];
}

void vacpp(ref ubyte[] data, ptrdiff_t size)
{
    if (size < 8 || size > 2 ^^ 24)
        throw new Throwable("Invalid vacpp padding size!");

    ptrdiff_t margin = size - (data.length % size) + size;
    data ~= new ubyte[margin];
    data[$-5..$] = cast(ubyte[])"VacPp";
    data[$-8..$-5] = margin.serialize!true()[0..3];
}

void unvacpp(ref ubyte[] data) 
{
    if (data.length < 8)
        throw new Throwable("Invalid data length for vacpp!");

    if (data[$-5..$] != cast(ubyte[])"VacPp")
        throw new Throwable("Invalid padding signature in vacpp!");

    uint margin = data[$-8..$-5].deserialize!uint();
    data = data[0..(data.length - margin)];
}