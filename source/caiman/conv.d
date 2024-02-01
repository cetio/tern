module caiman.conv;

import caiman.meta.traits;
import caiman.meta.algorithm;
import std.traits;

/** 
 * Checks if `F` may be cast to `T`
 *
 * Params:
 *  F = Type to check if can cast from
 *  T = Type to check if can cast to
 *  EXPLICIT = Must be able to reinterpret cast? Defaults to false.
 */
public template canConv(F, T, bool EXPLICIT = false)
{
    enum canConv = 
    {
        // TODO: Implement
        static if (isDynamicArray!F || isPointer!F || isDynamicArray!T || isPointer!T)
            return canConv!(ElementType!F, ElementType!T, EXPLICIT);
        else static if (isAssociativeArray!F || isAssociativeArray!T)
            throw new Throwable("Conversions between associative arrays are not supported!");

        static if (FieldNames!F.length > FieldNames!T.length)
            return false;

        static if (isOrganic!F && isOrganic!T)
        static foreach (i, field; FieldNames!F)
        {
            static if (FieldNames!T[i] != field && EXPLICIT)
                return false;
            else static if (!seqContains!(field, FieldNames!T) && !EXPLICIT)
                return false;
        }

        return is(F == T) || (isIntrinsicType!F && isIntrinsicType!T);
    }();
}

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
    static if (!hasIndirections!T || (isPointer!T || wrapsIndirection!T))
        return val;
    else
    {
        static if (isReferenceType!T)
            T ret = new T();
        else 
            T ret;
        static foreach (field; FieldNames!T)
        {
            static if (!hasIndirections!(typeof(__traits(getMember, T, field))))
                __traits(getMember, ret, field) = __traits(getMember, val, field);
            else
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
@trusted T to(T, F)(F val)
    if (!isArray!T)
{
    static if (isReferenceType!T)
        T ret = new T();
    else 
        T ret;
    static foreach (field; FieldNames!T)
    {
        static if (hasMember!(T, field))
        {
            static if (!hasIndirections!(TypeOf!(T, field)))
                __traits(getMember, ret, field) = cast(TypeOf!(T, field))__traits(getMember, val, field);
            else
                __traits(getMember, ret, field) = cast(TypeOf!(T, field))__traits(getMember, val, field).ddup();
        }
    }
    return ret;
}