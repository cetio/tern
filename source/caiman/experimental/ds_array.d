/**
 * Thin wrapper around `caiman.experimental.ds_allocator` that allows for allocating a dynamic array in the data segment. \
 * Provides all normal behavior of dynamic arrays.
 */
module caiman.experimental.ds_array;

import caiman.experimental.ds_allocator;
import std.conv;

/**
 * Thin wrapper around `caiman.experimental.ds_allocator` that allows for allocating a dynamic array in the data segment. \
 * Provides all normal behavior of dynamic arrays.
 */
public struct DSArray(T)
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
    void reserve(uint r0 = __LINE__, string r1 = __TIMESTAMP__, string r2 = __FILE_FULL_PATH__, string r3 = __FUNCTION__, string r4 = __MODULE__)(ptrdiff_t length)
    {
        if (arr is null)
            arr = dsNew!(T[], r0, r1, r2, r3, r4)(1);
        else
            dsResize(arr, length);
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
            dsResizeBeneath(arr, arr.length - 1);
    }

    void popBack()
    {
        if (arr.length != 0)
            dsResize(arr, arr.length - 1);
    }

    T opOpAssign(string op, uint r0 = __LINE__, string r1 = __TIMESTAMP__, string r2 = __FILE_FULL_PATH__, string r3 = __FUNCTION__, string r4 = __MODULE__)(T val) 
        if (op == "~") 
    {
        if (arr is null)
            arr = dsNew!(T[], r0, r1, r2, r3, r4)(1);
        else
            dsResize(arr, arr.length + 1);
        arr[$-1] = val;
        return val;
    }

    ~this()
    {
        destroy(arr);
    }
}

unittest 
{
    auto dsArray = DsArray!int(5);

    assert(dsArray.length == 5);
    assert(!dsArray.empty);

    dsArray[0] = 1;
    dsArray[1] = 2;
    assert(dsArray[0] == 1);
    assert(dsArray[1] == 2);

    assert(dsArray.front == 1);
    assert(dsArray.back == 0);

    dsArray.popFront();
    assert(dsArray.front == 2);
    dsArray.popBack();

    dsArray ~= 1;
    dsArray ~= 2;
    assert(dsArray.length == 5);
    assert(dsArray[$-1] == 2);
}