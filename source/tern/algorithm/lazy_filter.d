/// Lazy filter-based range (destroy on function)
module tern.algorithm.lazy_filter;

import tern.traits;
import std.conv;

public struct LazyFilter(alias F, T)
    if (isForward!T && isCallable!F)
{
    T _array;
    alias _array this;

private:
final:
    size_t _length = -1;

public:
    string toString()
    {
        return this[0..length].to!string;
    }

pure:
    T array()
    {
        return this[0..length];
    }

    this(T arr)
    {
        _array = arr;
    }

    size_t length()
    {
        if (_length != -1)
            return _length;

        _length = 0;
        foreach (u; _array)
        {
            if (F(u))
                _length++;
        }
        return _length;
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

    auto opSliceAssign(A)(A ahs, ptrdiff_t start, ptrdiff_t end) 
    {
        T slice;
        foreach (ref u; _array)
        {
            slice ~= opIndex(ahs[start], start++);        

            if (start >= end)
                break;
        }
        return slice;
    }

    ref auto opIndex(ptrdiff_t index)
    {
        foreach (ref u; _array)
        {
            if (F(u) && index-- <= 0)
                return u;
        }
        throw new Throwable("Lazy filter index out of bounds!");
    }

    auto opIndexAssign(A)(A ahs, ptrdiff_t index) 
    {
        foreach (ref u; _array)
        {
            if (F(u) && index-- <= 0)
                return u = ahs;
        }
        throw new Throwable("Lazy filter index out of bounds!");
    }

    size_t opDollar()
    {
        return length;
    }
}