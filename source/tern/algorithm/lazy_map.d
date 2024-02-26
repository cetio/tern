/// Lazy map-based range (mutate on function)
module tern.algorithm.lazy_map;

import tern.traits;
import std.range.primitives : isInputRange;
import std.conv;

public struct LazyMap(alias F, T)
    if (isForward!T)
{
    T array;
    alias array this;
    
public:
final:
    string toString()
    {
        return this[0..length].to!string;
    }
    
pure:
    size_t length;

    this(T arr)
    {
        array = arr;
        length = array.length;
    }

    T opSlice(ptrdiff_t start, ptrdiff_t end)
    {
        T slice;
        foreach (ref u; array)
        {
            slice ~= opIndex(start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        return F(array[index]);
        throw new Throwable("Lazy filter index out of bounds!");
    }

    size_t opDollar()
    {
        return length;
    }
}