/// Lazy map-based range (mutate on function)
module tern.algorithm.lazy_map;

import tern.traits;
import std.range.primitives;

public struct LazyMap(alias F, T)
    if (isInputRange!T)
{
    T array;
    alias array this;
    
public:
final:
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
            slice ~= opIndex(++start);        

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
}