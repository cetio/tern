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

public template to(T)
{

}