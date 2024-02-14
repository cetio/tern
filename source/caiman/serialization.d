/// Utilities for serializing and deserializing arbitrary data types
module caiman.serialization;

import caiman.traits;

public:
static:
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
        ptrdiff_t length = deserialize!ptrdiff_t(bytes[offset..(offset += ptrdiff_t.sizeof)]);
        static if (isDynamicArray!T && !isImmutable!(ElementType!T))
            ret = new T(length);

        foreach (i; 0..length)
        static if (!isImmutable!(ElementType!T))
            ret[i] = bytes[offset..(offset += ElementType!T.sizeof)];
        else
            ret ~= bytes[offset..(offset += ElementType!T.sizeof)];

        return ret;
    }
    else static if (is(T == class))
    {
        foreach (field; FieldNameTuple!T)
            __traits(getMember, ret, field) = deserialize!(TypeOf!(T, field))(bytes[offset..(offset += TypeOf!(T, field).sizeof)]);
        return ret;
    }
    else
    {
        return *cast(T*)&bytes[offset];
        //return *cast(T*)(bytes[offset..(offset += T.sizeof)].ptr);
    }
}