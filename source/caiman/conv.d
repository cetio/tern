module caiman.conv;

import caiman.traits;
import caiman.meta;
import std.traits;
import std.conv;
import std.algorithm;
import caiman.memory;

public enum Endianness
{
    Native,
    LittleEndian,
    BigEndian
}

public:
static:
/**
 * Shallow clones a value.
 *
 * Params:
 *  val = The value to be shallow cloned.
 *
 * Returns:
 *  A shallow clone of the provided value.
 *
 * Example:
 * ```d
 * A a;
 * A b = a.dup();
 * ```
 */
pragma(inline)
@trusted T dup(T)(T val)
    if (!__traits(compiles, object.dup(val)))
{
    // Cloned when passed as a parameter
    return val;
}

/**
 * Deep clones a value.
 *
 * Params:
 *  val = The value to be deep cloned.
 *
 * Returns:
 *  A deep clone of the provided value.
 *
 * Example:
 * ```d
 * B a; // where B is a class containing indirection
 * B b = a.ddup();
 * ```
 */
pragma(inline)
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
            static if (!hasIndirections!(TypeOf!(T, field)))
                __traits(getMember, ret, field) = __traits(getMember, val, field);
            else
                __traits(getMember, ret, field) = __traits(getMember, val, field).ddup();
        }
        return ret;
    }
}

/// ditto
pragma(inline)
@trusted T ddup(T)(T arr)
    if (isArray!T && !isAssociativeArray!T)
{
    T ret;
    static foreach (u; arr)
        ret ~= u.ddup();
    return ret;
}

/// ditto
pragma(inline)
@trusted T ddup(T)(T arr)
    if (isAssociativeArray!T)
{
    T ret;
    static foreach (key, value; arr)
        ret[key.ddup()] = value.ddup();
    return ret;
}

/** 
 * Checks if `F` may be cast to `T`
 *
 * Params:
 *  F = Type to check if can convert from
 *  T = Type to check if can convert to
 *  EXPLICIT = Must be able to reinterpret cast? Defaults to false.
 */
public template canConv(F, T, bool EXPLICIT = false)
{
    enum canConv = 
    {
        static if (implements!(F, T))
            return true;

        static if (isArray!F || isArray!T)
        {
            static if (isAssociativeArray!F || isAssociativeArray!T)
                throw new Throwable("Conversions between associative arrays are not supported!");
            else static if (isStaticArray!F == isStaticArray!T)
                return !EXPLICIT && (isArray!F == isArray!T) && canConv!(ElementType!F, ElementType!T, EXPLICIT);
            else static if ((isStaticArray!F && (!is(ElementType!F == ubyte) && !is(ElementType!F == byte) && !isSomeChar(ElementType!F))))
                throw new Throwable("Casts from a static array to a non static array type must be from a byte type or char type, not "~F.stringof~"!");
        }

        static if (FieldNames!F.length > FieldNames!T.length)
            return false;

        static if (isOrganic!F && isOrganic!T)
        static foreach (i, field; FieldNames!F)
        {
            static if ((FieldNames!T.length <= i || FieldNames!T[i] != field || !is(TypeOf!(F, field) == TypeOf!(T, field))) && EXPLICIT)
                return false;
            else static if (!seqContains!(field, FieldNames!T) && !EXPLICIT)
                return false;
        }

        return is(F == T) || (isIntrinsicType!F && isIntrinsicType!T);
    }();
}

/**
 * Converts/casts `val` from type `F` to type `T`, returning ref if possible.
 *
 * Params:
 *  T = Type to convert/cast to.
 *  F = Type to convert/cast from.
 *  val = Value to convert/cast.
 */
pragma(inline)
@trusted auto ref T to(T, F)(ref F val)
{
    static if (isSomeString!T)
        return std.conv.to!string(val);
    else static if (isSomeString!F)
        return std.conv.to!F(val);
    else static if (canConv!(F, T, true))
        return val.reinterpret!T;
    else static if (canConv!(F, T))
        return val.conv!T;
    else
        throw new Throwable("Cannot convert or cast from type "~F.stringof~" to type "~T.stringof~"!");
}

pragma(inline)
@trusted auto ref T to(T, F)(F val)
{
    static if (isSomeString!T)
        return std.conv.to!string(val);
    else static if (isSomeString!F)
        return std.conv.to!F(val);
    else static if (canConv!(F, T, true))
        return val.reinterpret!T;
    else static if (canConv!(F, T))
        return val.conv!T;
    else
        throw new Throwable("Cannot convert or cast from type "~F.stringof~" to type "~T.stringof~"!");
}

/// ditto
pragma(inline)
@trusted auto ref T to(T, F)(F val, uint radix, LetterCase letterCase = LetterCase.upper)
{
    static if (isSomeString!T)
        return std.conv.to!string(val, radix, letterCase);
    else static if (isSomeString!F)
        return std.conv.to!F(val, radix, letterCase);
    else static if (canConv!(F, T, true))
        return val.reinterpret!T;
    else static if (canConv!(F, T))
        return val.conv!T;
    else
        throw new Throwable("Cannot convert or cast from type "~F.stringof~" to type "~T.stringof~"!");
}

/** 
 * Casts `val` of type `F` to type `T`, returning ref if possible.
 *
 * Params:
 *  T = Type to cast to.
 *  F = Type to cast from.
 *  val = Value to reinterpret cast.
 *
 * Returns: 
 *  `val` as `T`
 */
pragma(inline)
@trusted auto ref T reinterpret(T, F)(F val)
{
    static if (__traits(compiles, { T _ = cast(T)val; }))
        return cast(T)val;
    else
        return *cast(T*)&val;
}

/** 
 * Converts `val` of type `F` to type `T`, returning ref if possible.
 *
 * Params:
 *  T = Type to convert to.
 *  F = Type to convert from.
 *  val = Value to convert.
 *
 * Returns: 
 *  `val` as `T`
 */
pragma(inline)
@trusted auto ref T conv(T, F)(F val)
    if (!isArray!T && !isAssociativeArray!T)
{
    static if (isReferenceType!T)
        T ret = new T();
    else 
        T ret;
    static foreach (field; FieldNames!F)
    {
        static if (hasMember!(T, field))
            __traits(getMember, ret, field) = cast(TypeOf!(T, field))__traits(getMember, val, field);
    }
    return ret;
}

/// ditto
pragma(inline)
@trusted auto ref T conv(T : U[], U, F)(F val)
    if (isArray!T && !isAssociativeArray!T)
{
    static if (isStaticArray!T)
        T ret;
    else
        T ret = new U[val.length];
    foreach (i, u; val)
        ret[i] = u.to!U;
    return ret;
}

/**
* Swaps the endianness of the provided value, if applicable.
*
* Params:
*     val = The value to swap endianness.
*     endianness = The desired endianness.
*
* Returns:
*   The value with swapped endianness.
*/
@trusted T makeEndian(T)(T val, Endianness endianness)
{
    version (LittleEndian)
    {
        if (endianness == Endianness.BigEndian)
        {
            static if (is(T == class))
                (*cast(ubyte**)&val)[0..__traits(classInstanceSize, T)].reverse();
            else
                (cast(ubyte*)&val)[0..T.sizeof].reverse();
        }
    }
    else version (BigEndian)
    {
        if (endianness == Endianness.LittleEndian)
        {
            static if (is(T == class))
                (*cast(ubyte**)&val)[0..__traits(classInstanceSize, T)].reverse();
            else
                (cast(ubyte*)&val)[0..T.sizeof].reverse();
        }
    }
    return val;
}