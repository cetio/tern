module caiman.object.ops;

import caiman.traits;

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