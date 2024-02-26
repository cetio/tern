module tern.algorithm.lazy_substitute;

import tern.traits;
import tern.blit : loadLength, loadSlice, storeElem, storeSlice;
import std.conv;

public struct LazySubstitute(A, B, C)
    if (isForward!A && isIndexable!A && isCallable!F)
{
    A array;
    alias array this;
    
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

    this(A arr, B from, C to)
    {
        array = arr;
        length = array.loadLength;
        this.from = from;
        this.to = to;
    }

    A opSlice(ptrdiff_t start, ptrdiff_t end)
    {
        A slice;
        foreach (ref u; array)
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
        foreach (ref u; array)
        {
            slice ~= opIndex(ahs[start], start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        if (array[index] == from)
            return array.storeElem(to, index);
        else
            return array[index];
    }

    auto opIndexAssign(T)(T ahs, ptrdiff_t index) 
    {
        return array.storeElem(ahs, index);
    }

    size_t opDollar()
    {
        return length;
    }
}