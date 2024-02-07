module caiman.stack_array;

import caiman.experimental.stack_allocator;
import std.conv;

public struct StackArray(T)
{
private:
final:
    T[] arr;

public:
    string toString() const
    {
        return arr.to!string;
    }

@nogc:
    this(ptrdiff_t length)
    {
        arr = stackNew!(T[])(length);
    }

    size_t length() const => arr.length;
    const(T)* ptr() const => arr.ptr;

    bool empty()
    {
        return length == 0;
    }

    T opIndex(size_t index) const
    {
        return arr[index];
    }

    ref T opIndex(size_t index)
    {
        return arr[index];
    }

    auto opSlice(size_t from, size_t to) const
    {
        return arr[from..to];
    }

    ref auto opSlice(size_t from, size_t to)
    {
        return arr[from..to];
    }

    void opSliceAssign(T[] slice, size_t from, size_t to)
    {
        import std.stdio;
        arr[from..to] = slice;
    }

    auto opDollar() const
    {
        return arr.length;
    }

    T[] opDollar(string op)() const
    {
        static if (op == "front")
            return arr[0 .. 1];
        else static if (op == "back")
            return arr[$-1 .. $];
        else
            static assert(0, "Unknown opDollar operation");
    }

    T front() const
    {
        return arr[0];
    }

    T back() const
    {
        return arr[$-1];
    }

    void popFront()
    {
        if (arr.length != 0)
            stackResizeBeneath(arr, arr.length - 1);
    }

    void popBack()
    {
        if (arr.length != 0)
            stackResize(arr, arr.length - 1);
    }

    T opOpAssign(string op)(T val) 
        if (op == "~") 
    {
        if (arr is null)
            arr = stackNew!(T[])(1);
        else
            stackResize(arr, arr.length + 1);
        arr[$-1] = val;
        return val;
    }

    ~this()
    {
        destroy(arr);
    }
}