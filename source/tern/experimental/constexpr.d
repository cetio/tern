/// Thin wrapper around `tern.experimental.ds_allocator` that allows for allocating a type in the data segment.
module tern.experimental.constexpr;

import tern.experimental.ds_allocator;
import tern.traits;
import tern.object;

/// Allocates `T` in the data segment when `T` is *not* a dynamic array, this is used identically to `T` normally.
public struct constexpr(T, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__)
    if (!isDynamicArray!T)
{
    T value = dsNew!(T, R0, R1, R2, R3);
    alias value this;

public:
final:
    auto opAssign(T)(T ahs)
    {
        static if (isIntrinsicType!T && !isArray!T)
            value = ahs;
        else
            value.blit(ahs);
        return this;
    }

    auto opAssign(T)(T ahs) shared
    {
        static if (isIntrinsicType!T && !isArray!T)
            value = ahs;
        else
            value.blit(ahs);
        return this;
    }

    string toString() const
    {
        return value.to!string;
    }

    string toString() const shared
    {
        return value.to!string;
    }
}

/** 
 * Allocates `T` in the data segment when `T` is a dynamic array, this is used identically to `T` normally.
 *
 * Remarks:
 *  Does not provide an initializer, must reserve initially.
 */
public struct constexpr(T : U[], U)
    if (isDynamicArray!T)
{
private:
final:
    T arr;

public:
final:
    string toString() const
    {
        return arr.to!string;
    }

@nogc:
    void reserve(uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__)(size_t length)
    {
        if (arr is null)
            arr = dsNew!(T, R0, R1, R2, R3)(length);
        else
            dsResize(arr, length);
    }

    size_t length() const => arr.length;
    const(U)* ptr() const => arr.ptr;

    bool empty()
    {
        return length == 0;
    }

    U opIndex(size_t index) const
    {
        return arr[index];
    }

    ref U opIndex(size_t index)
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

    void opSliceAssign(T slice, size_t from, size_t to)
    {
        import std.stdio;
        arr[from..to] = slice;
    }

    auto opDollar() const
    {
        return arr.length;
    }

    T opDollar(string op)() const
    {
        static if (op == "front")
            return arr[0 .. 1];
        else static if (op == "back")
            return arr[$-1 .. $];
        else
            static assert(0, "Unknown opDollar operation");
    }

    ref auto opAssign(T)(T val)
    {
        arr = val;
        return this;
    }

    U front() const
    {
        return arr[0];
    }

    U back() const
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

    U opOpAssign(string op, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__)(U val)
        if (op == "~") 
    {
        if (arr is null)
            arr = dsNew!(T, R0, R1, R2, R3)(1);
        else
            dsResize(arr, arr.length + 1);
        arr[$-1] = val;
        return val;
    }
}

unittest 
{
    constexpr!(int[]) dsArray;
    dsArray.reserve(5);

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

pragma(inline)
constexpr!T constexpr(T)(T val)
{
    return constexpr!T(val);
}