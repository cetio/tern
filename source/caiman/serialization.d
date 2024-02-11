/// Utilities for serializing and deserializing arbitrary data types
module caiman.serialization;

public:
static:
pure:
@trusted ubyte[] deserialize(T)(T val)
{
    static if (isArray!T)
    {
        ubyte[] bytes;
        bytes ~= val.length.deserialize;
        foreach (u; val)
            bytes ~= u.deserialize;
        return bytes;
    }
    else static if (is(T == class))
    {
        ubyte[] bytes;
        foreach (field; FieldNameTuple!T)
            bytes ~= __traits(getMember, T, field).deserialize;
        return bytes;
    }
    else
    {
        return (cast(ubyte*)&val)[0..T.sizeof];
    }
}

@trusted serialize(T)(ubyte[] bytes)
{
    
}