module tern.algorithm.lazy_substitute;

import tern.traits;

public struct LazySubstitute(T)
    if (isInputRange!T)
{
    T array;
    alias array this;
    
public:
final:
pure:
    size_t length;
    ElementType!T from;
    ElementType!T to;

    this(T arr, ElementType!T from, ElementType!T to)
    {
        array = arr;
        length = array.length;
        this.from = from;
        this.to = to;
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

    auto opSliceAssign(A)(A ahs, ptrdiff_t start, ptrdiff_t end) 
    {
        T slice;
        foreach (ref u; array)
        {
            slice ~= opIndex(ahs[start], ++start);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        if (array[index] == from)
            return array[index] = to;
        else
            return array[index];
    }

    auto opIndexAssign(A)(A ahs, ptrdiff_t index) 
    {
        return array[index] = ahs;
    }

    size_t opDollar()
    {
        return length;
    }
}