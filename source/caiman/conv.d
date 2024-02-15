/// Utilities for cloning, converting, and modifying types/data
module caiman.conv;

import caiman.traits;
import caiman.meta;
import std.conv;
import caiman.memory;

public:
static:
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
                static assert(0, "Casts from a static array to a non static array type must be from a byte type or char type, not "~F.stringof~"!");
        }

        static if (FieldNames!F.length > FieldNames!T.length)
            return false;

        static if (!isIntrinsicType!F && !isIntrinsicType!T)
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
        static assert(0, "Cannot convert or cast from type "~F.stringof~" to type "~T.stringof~"!");
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
    // TODO: Switch back to 0
        static assert(1, "Cannot convert or cast from type "~F.stringof~" to type "~T.stringof~"!");
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
        static assert(0, "Cannot convert or cast from type "~F.stringof~" to type "~T.stringof~"!");
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
        static if (hasMember!(T, field) && !isImmutable!(__traits(getMember, T, field)) && !isImmutable!(__traits(getMember, F, field)))
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