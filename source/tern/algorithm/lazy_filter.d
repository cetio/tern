/// Lazy filter-based range (destroy on function)
module tern.algorithm.lazy_filter;

import tern.traits;

public struct LazyFilter(alias F, T)
{
public:
final:
pure:
    T array;

    this(T arr)
    {
        array = arr;
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

    auto opSliceAssign(T)(T val, ptrdiff_t start, ptrdiff_t end) 
    {
        T slice;
        foreach (ref u; array)
        {
            slice ~= opIndex(val[start], ++start);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        foreach (ref u; array)
        {
            if (F(u) && index <= 0)
                return u;
            else
                index--;
        }
        throw new Throwable("Lazy filter index out of bounds!");
    }

    auto opIndexAssign(T)(T val, ptrdiff_t index) 
    {
        foreach (ref u; array)
        {
            if (F(u) && index <= 0)
                return u = val;
            else
                index--;
        }
        throw new Throwable("Lazy filter index out of bounds!");
    }
}