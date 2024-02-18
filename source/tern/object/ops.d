module tern.object.ops;

import tern.traits;

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
    if (is(T == class) || isPointer!T)
{
    return val is null || *cast(void**)val is null;
}

T factory(T)()
{
    static if (isDynamicArray!T)
        return new T(0);
    else static if (isReferenceType!T)
        return new T();
    else 
        return T.init;
}