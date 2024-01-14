/// Provides advanced shallow and deep cloning support
module caiman.mem.ddup;

import std.traits;
import std.meta;

public:
static:
/**
    Shallow clones a value.

    Params:
    - `val`: The value to be shallow cloned.

    Returns:
        A shallow clone of the provided value.

    Example usage:
        ```d
        A a;
        A b = a.dup();
        ```
*/
pure @nogc @trusted T dup(T)(T val)
    if (!isArray!T && !isAssociativeArray!T)
{
    // Cloned when passed as a parameter
    return val;
}

/// ditto
pure @trusted T dup(T)(T arr)
    if (isArray!T && !isAssociativeArray!T)
{
    T ret;
    foreach (u; arr)
        ret ~= u.dup();
    return ret;
}

/// ditto
pure @trusted T dup(T)(T arr)
    if (isAssociativeArray!T)
{
    T ret;
    foreach (key, value; arr)
        ret[key.dup()] = value.dup();
    return ret;
}

/**
    Deep clones a value.

    Params:
    - `val`: The value to be deep cloned.

    Returns:
        A deep clone of the provided value.

    Example usage:
        ```d
        B a; // where B is a class containing indirection
        B b = a.ddup();
        ```
*/
pure @trusted T ddup(T)(T val)
    if (!isArray!T && !isAssociativeArray!T)
{
    static if (!hasIndirections!T)
        return val;
    else
    {
        static if (isPointer!T)
            T ret = val;
        else static if (is(T == class) || is(T == interface))
            T ret = new T();
        else 
            T ret;
        static foreach (field; FieldNameTuple!T)
        {
            static if (field != "" && !hasIndirections!(typeof(__traits(getMember, T, field))))
                __traits(getMember, ret, field) = __traits(getMember, val, field);
            else static if (field != "")
                __traits(getMember, ret, field) = __traits(getMember, val, field).ddup();
        }
        return ret;
    }
}

/// ditto
pure @trusted T ddup(T)(T arr)
    if (isArray!T && !isAssociativeArray!T)
{
    T ret;
    foreach (u; arr)
        ret ~= u.ddup();
    return ret;
}

/// ditto
pure @trusted T ddup(T)(T arr)
    if (isAssociativeArray!T)
{
    T ret;
    foreach (key, value; arr)
        ret[key.ddup()] = value.ddup();
    return ret;
}

pure @trusted T drip(T, U)(U val)
{
    T ret;
    (cast(ubyte*)&ret)[0..U.sizeof] = (cast(ubyte*)&val)[0..U.sizeof];
    return ret;
}