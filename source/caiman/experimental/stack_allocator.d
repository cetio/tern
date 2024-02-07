/// A collection of very unsafe but very powerful stack allocators
module caiman.experimental.stack_allocator;

import caiman.traits;
import std.traits;
import std.range;
import std.conv;
import caiman.memory;
import caiman.experimental.monitor;

private pure string generateCases()
{
    string str = "switch (size) {";
    static foreach (i; iota(0, 10_000, ptrdiff_t.sizeof))
    {
        str ~= "case "~i.to!string~":
        static ubyte["~i.to!string~"] data;
        *cast(ptrdiff_t*)&data = size;
        static T arr;
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(void**)&arr)[1] = cast(void*)&data + ptrdiff_t.sizeof;
        return arr;";
    }
    str ~= "default: assert(0); }";
    return str;
}

public:
static:
@nogc:
/**
 * Creates an array of type `T` on the stack with a specified initial length.
 * 
 * Params:
 *  T = The element type of the array.
 *  length = The initial length of the array.
 *
 * Returns:
 *  A new array of type `T`
 */
T stackNew(T : U[], U)(ptrdiff_t length)
{
    enum elem = cast(ptrdiff_t)(U.sizeof * 1.5) + (cast(ptrdiff_t)(U.sizeof * 1.5) == 8 ? 0 : (ptrdiff_t.sizeof - (cast(ptrdiff_t)(U.sizeof * 1.5) % ptrdiff_t.sizeof)));
    const ptrdiff_t size = elem * length + ptrdiff_t.sizeof;
    mixin(generateCases);
}

/**
 * Resizes a previously allocated array on the stack to the specified length.
 * 
 * Params:
 *  T = The array type.
 *  arr = The array to be resized.
 *  length = The new length of the array.
 *
 * Remarks:
 *  No validation is done that `arr` was previously allocated with `stackNew`, stay vigilant.
 */
void stackResize(T : U[], U)(ref T arr, ptrdiff_t length)
{
    const ptrdiff_t size = U.sizeof * length;
    const ptrdiff_t curSize = *cast(ptrdiff_t*)(cast(void*)arr.ptr - ptrdiff_t.sizeof);
    if (curSize >= size)
    {
        enum elem = cast(ptrdiff_t)(U.sizeof * 1.5) + (cast(ptrdiff_t)(U.sizeof * 1.5) == ptrdiff_t.sizeof ? 0 : (ptrdiff_t.sizeof - (cast(ptrdiff_t)(U.sizeof * 1.5) % ptrdiff_t.sizeof)));
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(ptrdiff_t*)arr.ptr)[-1] = elem * length + ptrdiff_t.sizeof;
    }
    else
    {
        T tarr = stackNew!T(length);
        copy(arr.ptr, tarr.ptr, size);
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(void**)&arr)[1] = cast(void*)tarr.ptr;
    }
}

/**
 * Resizes a previously allocated array on the stack to the specified length from beneath.
 * New elements will become [0..length] (or removed.)
 * 
 * Params:
 *  T = The array type.
 *  arr = The array to be resized.
 *  length = The new length of the array.
 *
 * Remarks:
 *  No validation is done that `arr` was previously allocated with `stackNew`, stay vigilant.
 */
void stackResizeBeneath(T : U[], U)(ref T arr, ptrdiff_t length)
{
    enum elem = cast(ptrdiff_t)(U.sizeof * 1.5) + (cast(ptrdiff_t)(U.sizeof * 1.5) == ptrdiff_t.sizeof ? 0 : (ptrdiff_t.sizeof - (cast(ptrdiff_t)(U.sizeof * 1.5) % ptrdiff_t.sizeof)));
    const ptrdiff_t size = U.sizeof * length;
    const ptrdiff_t curSize = *cast(ptrdiff_t*)(cast(void*)arr.ptr - ptrdiff_t.sizeof);
    const ptrdiff_t offset = U.sizeof * cast(ptrdiff_t)((curSize - (curSize - (cast(ptrdiff_t)(U.sizeof * 1.5) == ptrdiff_t.sizeof ? 0 : (ptrdiff_t.sizeof - (cast(ptrdiff_t)(U.sizeof * 1.5) % ptrdiff_t.sizeof))))) / 1.5);
    if (curSize >= size)
    {
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(void**)&arr)[1] += offset;
        (cast(ptrdiff_t*)arr.ptr)[-1] = size;
    }
    else
    {
        T tarr = stackNew!T(length);
        copy(cast(void*)arr.ptr + offset, tarr.ptr, size);
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(void**)&arr)[1] = cast(void*)tarr.ptr;
    }
}

/**
 * Allocates `T` on the stack, this will just create `T` normally for value types.
 *
 * Params:
 *   T = The type to be allocated.
 *
 * Returns:
 *   A new instance of `T` allocated on the stack.
 *
 * Example:
 *   ```d
 *   B a = stackNew!B;
 *   writeln(a); // caiman.main.B
 *   ```
 */
T stackNew(T, ARGS...)(ARGS args)
    if (!is(T : U[], U))
{
    static if (isValueType!T)
    {
        static if (hasCtor!T)
            T ret = T(args);
        else
            T ret;
        return ret;
    }
    else
    {
        static ubyte[__traits(classInstanceSize, T)] bytes;
        foreach (field; FieldNames!T)
        {
            auto init = __traits(getMember, T, field).init;
            ptrdiff_t offset = __traits(getMember, T, field).offsetof;
            bytes[offset..(offset + TypeOf!(T, field).sizeof)] = (cast(ubyte*)&init)[0..TypeOf!(T, field).sizeof];
        }
        // 8 bytes after this are __monitor, but we don't need to create one 
        (cast(void**)bytes.ptr)[0] = T.classinfo.vtbl.ptr;
        T ret = cast(T)bytes.ptr;
        ret.__ctor(args);
        return ret;
    }
}