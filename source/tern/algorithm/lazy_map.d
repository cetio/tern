/// Lazy map-based range (mutate on function)
module tern.algorithm.lazy_map;

import tern.traits;
import tern.blit : loadLength;
import std.conv;

public struct LazyMap(alias F, T)
    if (isForward!T && isCallable!F)
{
    T _array;
    alias _array this;
    
public:
final:
    string toString()
    {
        return this[0..length].to!string;
    }
    
pure:
    size_t length;

    T array()
    {
        return this[0..length];
    }

    this(T arr)
    {
        _array = arr;
        length = _array.loadLength;
    }

    T opSlice(ptrdiff_t start, ptrdiff_t end)
    {
        T slice;
        foreach (ref u; _array)
        {
            slice ~= opIndex(start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        return F(_array[index]);
        throw new Throwable("Lazy filter index out of bounds!");
    }

    size_t opDollar()
    {
        return length;
    }
}