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
pure @trusted T dup(T)(T val)
    if (!__traits(compiles, object.dup(val)))
{
    // Cloned when passed as a parameter
    return val;
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
    static foreach (u; arr)
        ret ~= u.ddup();
    return ret;
}

/// ditto
pure @trusted T ddup(T)(T arr)
    if (isAssociativeArray!T)
{
    T ret;
    static foreach (key, value; arr)
        ret[key.ddup()] = value.ddup();
    return ret;
}

/**
    Deep clones a value as another type.

    Params:
    - `A`: The type to deep clone as.
    - `val`: The value to be deep cloned.

    Example usage:
    ```d
    B a; // where B is a class containing indirection
    C b = a.ddupa!C();
    ```
*/
pure @trusted A ddupa(A, T)(T val)
    if (!isArray!A)
{
    static if (isPointer!A)
        A ret = val;
    else static if (is(A == class) || is(A == interface))
        A ret = new A();
    else 
        A ret;
    static foreach (field; FieldNameTuple!T)
    {
        static if (hasMember!(A, field))
        {
            static if (field != "" && !hasIndirections!(typeof(__traits(getMember, A, field))))
                __traits(getMember, ret, field) = cast(typeof(__traits(getMember, ret, field)))__traits(getMember, val, field);
            else static if (field != "")
                __traits(getMember, ret, field) = cast(typeof(__traits(getMember, ret, field)))__traits(getMember, val, field).ddup();
        }
    }
    return ret;
}