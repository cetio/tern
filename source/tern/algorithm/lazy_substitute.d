/// Lazy substitute-based _range (replace on state.)
module tern.algorithm.lazy_substitute;

import tern.traits;
import tern.blit : loadLength, loadSlice, storeElem, storeSlice;
import std.conv;

/// Lazy substitute-based _range implementation.
public struct LazySubstitute(A, B, C)
    if (isForward!A && isIndexable!A && isCallable!F)
{
    A _range;
    alias _range this;
    
public:
final:
    string toString()
    {
        return this[0..length].to!string;
    }
    
pure:
    size_t length;
    B from;
    C to;

    /// Gets the internally held range after predication.
    T range()
    {
        if (length == 0)
            return T.init;
            
        return this[0..length];
    }
    
    this(A _range, B from, C to)
    {
        _range = _range;
        length = _range.loadLength;
        this.from = from;
        this.to = to;
    }

    A opSlice(ptrdiff_t start, ptrdiff_t end)
    {
        A slice;
        foreach (ref u; _range)
        {
            slice ~= opIndex(start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    auto opSliceAssign(T)(T ahs, ptrdiff_t start, ptrdiff_t end) 
    {
        A slice;
        foreach (ref u; _range)
        {
            slice ~= opIndex(ahs[start], start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        if (_range[index] == from)
            return _range.storeElem(to, index);
        else
            return _range[index];
    }

    auto opIndexAssign(T)(T ahs, ptrdiff_t index) 
    {
        return _range.storeElem(ahs, index);
    }

    size_t opDollar()
    {
        return length;
    }
}