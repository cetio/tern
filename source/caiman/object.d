module caiman.object;

import caiman.traits;
import caiman.meta;

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

/// ditto
pragma(inline)
@trusted T dup(T)(T val)
    if (__traits(compiles, object.dup(val)))
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
        static if (isReferenceType!T)
            T ret = new T();
        else 
            T ret;
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

/**
 * Checks if `val` is actually a valid, non-null class, and has a valid vtable.
 *
 * Params:
 *  val = The value to check if null.
 *
 * Returns:
 *  True if `val` is null or has an invalid vtable.
 */
@trusted bool isNull(T)(auto ref T val)
    if (is(T == class))
{
    return val is null || *cast(void**)val is null;
}

/// Generates a mixin for doing standard `using` behavior (from languages like C#)
public template using(T, string name)
{
    enum using = 
    {
        static if (seqContains!("close", FunctionNames!T))
        {
            static assert(Parameters!(TypeOf!(T, "close")).length == 0, "Close function expected to have no parameters!");

            return (fullyQualifiedName!T~" "~name~";
                scope (exit) "~name~".close();");
        }
        else static if (seqContains!("dispose", FunctionNames!T))
        {
            static assert(Parameters!(TypeOf!(T, "close")).length == 0, "Dispose function expected to have no parameters!");

            return fullyQualifiedName!T~" "~name~";
                scope (exit) "~name~".dispose();";
        }
        else
            return fullyQualifiedName!T~" "~name~";
                scope (exit) destroy("~name~")";
    }();
}