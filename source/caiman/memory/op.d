/// Advanced and lightning fast hardware-accelerated memory operations
module caiman.memory.op;

import std.traits;
import core.simd;

public:
static:
pure:
@nogc:
/**
    Shallow clones a value.

    Params:
       val = The value to be shallow cloned.

    Returns:
        A shallow clone of the provided value.

    Example usage:
    ```d
    A a;
    A b = a.dup();
    ```
*/
@trusted T dup(T)(T val)
    if (!__traits(compiles, object.dup(val)))
{
    // Cloned when passed as a parameter
    return val;
}

/**
    Deep clones a value.

    Params:
       val = The value to be deep cloned.

    Returns:
        A deep clone of the provided value.

    Example usage:
    ```d
    B a; // where B is a class containing indirection
    B b = a.ddup();
    ```
*/
@trusted T ddup(T)(T val)
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
@trusted T ddup(T)(T arr)
    if (isArray!T && !isAssociativeArray!T)
{
    T ret;
    static foreach (u; arr)
        ret ~= u.ddup();
    return ret;
}

/// ditto
@trusted T ddup(T)(T arr)
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
       A = The type to deep clone as.
       val = The value to be deep cloned.

    Example usage:
    ```d
    B a; // where B is a class containing indirection
    C b = a.ddupa!C();
    ```
*/
@trusted A ddupa(A, T)(T val)
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

/** 
 * Extracts a `uint` from an arbitrarily sized byte array.
 *
 * Params:
 *   bytes = The bytes to extract a `uint` from.
 *
 * Returns: A uint derived from `bytes`
 */
 // TODO: Remove this?
@trusted uint drip(ubyte[] bytes) 
{
    uint ret = 0;
    foreach_reverse (ubyte b; bytes)
        ret = (ret << 8) | b;
    return ret;
}

/** 
 * Copies all data from `src` to `dest` within range `0..length`
 *
 * Params:
 *   src = Data source pointer.
 *   dest = Data destination pointer.
 *   length = Length of data to be copied.
 */
@trusted void copy(void* src, void* dest, ptrdiff_t length)
{
    switch (length & 15)
    {
        case 0:
            foreach_reverse (j; 0..(length / 16))
                (cast(ulong2*)dest)[j] = (cast(ulong2*)src)[j];
            break;
        case 8:
            foreach_reverse (j; 0..(length / 8))
                (cast(ulong*)dest)[j] = (cast(ulong*)src)[j];
            break;
        case 4:
            foreach_reverse (j; 0..(length / 4))
                (cast(uint*)dest)[j] = (cast(uint*)src)[j];
            break;
        case 2:
            foreach_reverse (j; 0..(length / 2))
                (cast(ushort*)dest)[j] = (cast(ushort*)src)[j];
            break;
        default:
            foreach_reverse (j; 0..length)
                (cast(ubyte*)dest)[j] = (cast(ubyte*)src)[j];
            break;
    }
}

/** 
 * Sets all bytes at `dest` to `val` within range `0..length`
 *
 * Params:
 *   dest = Data destination pointer.
 *   length = Length of data to be copied.
 *   val = Value to set all bytes to.
 */
@trusted void memset(void* dest, ptrdiff_t length, ubyte val)
{
    switch (length & 15)
    {
        case 0:
            foreach_reverse (j; 0..(length / 16))
                (cast(ulong2*)dest)[j] = cast(ulong2)val;
            break;
        case 8:
            foreach_reverse (j; 0..(length / 8))
                (cast(ulong*)dest)[j] = cast(ulong)val;
            break;
        case 4:
            foreach_reverse (j; 0..(length / 4))
                (cast(uint*)dest)[j] = cast(uint)val;
            break;
        case 2:
            foreach_reverse (j; 0..(length / 2))
                (cast(ushort*)dest)[j] = cast(ushort)val;
            break;
        default:
            foreach_reverse (j; 0..length)
                (cast(ubyte*)dest)[j] = cast(ubyte)val;
            break;
    }
}