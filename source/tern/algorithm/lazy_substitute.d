module tern.algorithm.lazy_substitute;

import tern.traits;
import tern.blit : loadLength, loadSlice, storeElem, storeSlice;
import std.conv;

public struct LazySubstitute(A, B, C)
    if (isForward!A && isIndexable!A && isCallable!F)
{
    A range;
    alias range this;
    
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

    this(A range, B from, C to)
    {
        range = range;
        length = range.loadLength;
        this.from = from;
        this.to = to;
    }

    A opSlice(ptrdiff_t start, ptrdiff_t end)
    {
        A slice;
        foreach (ref u; range)
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
        foreach (ref u; range)
        {
            slice ~= opIndex(ahs[start], start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        if (range[index] == from)
            return range.storeElem(to, index);
        else
            return range[index];
    }

    auto opIndexAssign(T)(T ahs, ptrdiff_t index) 
    {
        return range.storeElem(ahs, index);
    }

    size_t opDollar()
    {
        return length;
    }
}