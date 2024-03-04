module tern.algorithm.lazy_filter;

// TODO: Barter?
import tern.traits;
import std.conv;

/// Lazy filter-based range implementation.
public struct LazyFilter(alias F, T)
    if (isForward!T && isCallable!F)
{
    T _range;
    alias _range this;

private:
final:
    size_t _length = -1;

public:
    string toString()
    {
        return this[0..length].to!string;
    }

pure:
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
    }

    size_t length()
    {
        if (_length != -1)
            return _length;

        _length = 0;
        foreach (u; _range)
        {
            if (F(u))
                _length++;
        }
        return _length;
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

    auto opSliceAssign(A)(A ahs, ptrdiff_t start, ptrdiff_t end) 
    {
        T slice;
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
        foreach (ref u; _range)
        {
            if (F(u) && index-- <= 0)
                return u;
        }
        throw new Throwable("Lazy filter index out of bounds!");
    }

    auto opIndexAssign(A)(A ahs, ptrdiff_t index) 
    {
        foreach (ref u; _range)
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