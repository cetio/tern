module caiman.meta.conv;

import caiman.meta.traits;
import caiman.meta.algorithm;
import std.traits;

template canCast(F, T, bool EXPLICIT = false)
{
    enum canCast = 
    {
        // TODO: Implement
        /* static if (isDynamicArray!F || isAssociativeArray!F || isPointer!F ||
            isDynamicArray!T || isAssociativeArray!T || isPointer!T) */

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

        return F == T || F.sizeof == T.sizeof;
    }();
}