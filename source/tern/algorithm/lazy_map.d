module tern.algorithm.lazy_map;

import tern.traits;
import tern.object : loadLength;
import std.conv;

/// Lazy map-based range implementation.
public struct LazyMap(alias F, T)
    if (isForward!T && isCallable!F)
{
    T _range;
    alias _range this;
    
public:
final:
    string toString()
    {
        return this[0..length].to!string;
    }
    
pure:
    size_t length;

    /// Gets the internally held range after predication.
    T range()
    {
        if (length == 0)
            return T.init;
            
        return this[0..length];
    }

    this(T range)
    {
        _range = range;
        length = _range.loadLength;
    }

    T opSlice(ptrdiff_t start, ptrdiff_t end)
    {
        T slice;
        foreach (ref u; _range)
        {
            slice ~= opIndex(start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        return F(_range[index]);
        throw new Throwable("Lazy filter index out of bounds!");
    }

    size_t opDollar()
    {
        return length;
    }
}