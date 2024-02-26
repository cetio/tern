/// Lazy filter-based range (destroy on function)
module tern.algorithm.lazy_filter;

import tern.traits;
import std.conv;

public struct LazyFilter(alias F, T)
    if (isForward!T)
{
    T array;
    alias array this;

private:
final:
    size_t _length = -1;

public:
    string toString()
    {
        return this[0..length].to!string;
    }

pure:
    this(T arr)
    {
        array = arr;
    }

    size_t length()
    {
        if (_length != -1)
            return _length;

        _length = 0;
        foreach (u; array)
        {
            if (F(u))
                _length++;
        }
        return _length;
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

    auto opSliceAssign(A)(A ahs, ptrdiff_t start, ptrdiff_t end) 
    {
        T slice;
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
        foreach (ref u; array)
        {
            if (F(u) && index <= 0)
                return u;
            else
                index--;
        }
        throw new Throwable("Lazy filter index out of bounds!");
    }

    auto opIndexAssign(A)(A ahs, ptrdiff_t index) 
    {
        foreach (ref u; array)
        {
            if (F(u) && index <= 0)
                return u = ahs;
            else
                index--;
        }
        throw new Throwable("Lazy filter index out of bounds!");
    }

    size_t opDollar()
    {
        return length;
    }
}