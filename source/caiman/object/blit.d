/// Blitting of data from one type to another, cloning, and more
module caiman.object.blit;

import caiman.traits;

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
 * A b = a.sdup();
 * ```
 */
pragma(inline)
@trusted T sdup(T)(T val)
    if (!isArray!T && !isAssignableTo!(T, Object))
{
    return val;
}

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
 * A b = a.sdup();
 * ```
 */
pragma(inline)
@trusted T sdup(T)(T val)
    if (isArray!T || isAssignableTo!(T, Object))
{
    return object.dup(val);
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
        T ret = factory!T;
        static foreach (field; FieldNames!T)
        {
            static if (isMutable!(TypeOf!(T, field)))
            {
                static if (!hasIndirections!(TypeOf!(T, field)))
                    __traits(getMember, ret, field) = __traits(getMember, val, field);
                else
                    __traits(getMember, ret, field) = __traits(getMember, val, field).ddup();
            }
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
 * Blits all members or array elements onto another value.
 * 
 * Params:
 *  lhs = Side to have values blitted to.
 *  rhs = Side to have values blitted from.
 */
@trusted void blit(T, F)(auto ref F lhs, T rhs)
    if ((!isIntrinsicType!F && !isIntrinsicType!T) || (isArray!T && isArray!F && !isAssociativeArray!T))
{
    static if (isArray!F && isArray!T)
    {
        if (!rhs.length == lhs.length)
            throw new Throwable("Cannot blit rhs to lhs when sizes do not match!");

        foreach (i, u; rhs)
            lhs[i] = cast(ElementType!F)u;
    }
    else
    {
        static foreach (field; FieldNames!F)
        {
            static if (hasMember!(T, field) && !isImmutable!(TypeOf!(T, field)) && !isImmutable!(TypeOf!(F, field)))
                __traits(getMember, lhs, field) = cast(TypeOf!(F, field))__traits(getMember, rhs, field);
        }
    }
}