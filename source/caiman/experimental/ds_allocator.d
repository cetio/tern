/// Very fast fixed data segment allocators \
/// NOT thread safe.
module caiman.experimental.ds_allocator;

import std.range;
import std.conv;
import caiman.traits;
import caiman.memory;
import caiman.random;

alias ElementType = caiman.traits.ElementType;

private pure string generateCases(ptrdiff_t r)()
{
    string str = "switch (size) {";
    static foreach (i; iota(0, 20_000, ptrdiff_t.sizeof))
    {
        str ~= "case "~i.to!string~":
        static ubyte["~i.to!string~"] data"~r.to!string~";
        *cast(ptrdiff_t*)&data"~r.to!string~" = size;
        T arr;
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(void**)&arr)[1] = cast(void*)&data"~r.to!string~" + ptrdiff_t.sizeof;
        return arr;";
    }
    str ~= "default: assert(0); }";
    return str;
}

public:
static:
@nogc:
/**
 * Creates an array of type `T` on the ds with a specified initial length.
 * 
 * Params:
 *  T = The element type of the array.
 *  length = The initial length of the array.
 *
 * Returns:
 *  A new array of type `T`
 */
T dsNew(T, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__)(ptrdiff_t length)
    if (isDynamicArray!T)
{
    enum elem = cast(ptrdiff_t)(ElementType!T.sizeof * 1.5) + (cast(ptrdiff_t)(ElementType!T.sizeof * 1.5) == 8 ? 0 : (ptrdiff_t.sizeof - (cast(ptrdiff_t)(ElementType!T.sizeof * 1.5) % ptrdiff_t.sizeof)));
    const ptrdiff_t size = elem * length + ptrdiff_t.sizeof;
    mixin(generateCases!(random!(ptrdiff_t, 0, ptrdiff_t.max, uint.max, R0, R1, R2, R3)));
}

/**
 * Resizes a previously allocated array in the data segment to the specified length.
 * 
 * Params:
 *  T = The array type.
 *  arr = The array to be resized.
 *  length = The new length of the array.
 *
 * Remarks:
 *  No validation is done that `arr` was previously allocated with `dsNew`, stay vigilant.
 */
void dsResize(T : U[], U)(ref T arr, ptrdiff_t length)
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
        T tarr = dsNew!T(length);
        copy(cast(void*)arr.ptr, cast(void*)tarr.ptr, size);
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(void**)&arr)[1] = cast(void*)tarr.ptr;
    }
}

/**
 * Resizes a previously allocated array in the data segment to the specified length from beneath.
 * New elements will become [0..length] (or removed.)
 * 
 * Params:
 *  T = The array type.
 *  arr = The array to be resized.
 *  length = The new length of the array.
 *
 * Remarks:
 *  No validation is done that `arr` was previously allocated with `dsNew`, stay vigilant.
 */
void dsResizeBeneath(T : U[], U)(ref T arr, ptrdiff_t length)
{
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
        T tarr = dsNew!T(length);
        copy(cast(void*)arr.ptr + offset, cast(void*)tarr.ptr, size);
        (cast(ptrdiff_t*)&arr)[0] = length;
        (cast(void**)&arr)[1] = cast(void*)tarr.ptr;
    }
}

/**
 * Allocates `T` in the data segment, this will just create `T` normally for value types.
 *
 * Params:
 *   T = The type to be allocated.
 *
 * Returns:
 *   A new instance of `T` allocated in the data segment.
 *
 * Example:
 *   ```d
 *   B a = dsNew!B;
 *   writeln(a); // caiman.main.B
 *   ```
 */
T dsNew(T, uint R0 = __LINE__, string R1 = __TIMESTAMP__, string R2 = __FILE_FULL_PATH__, string R3 = __FUNCTION__)()
    if (!isDynamicArray!T)
{
    static if (!is(T == class))
    {
        static if (hasConstructor!T)
            return T(args);
        else
            return T.init;
    }
    else
    {
        enum rand = random!(ptrdiff_t, 0, ptrdiff_t.max, uint.max, R0, R1, R2, R3).to!string;
        mixin("static ubyte[__traits(classInstanceSize, T)] bytes"~rand~";");
        foreach (field; FieldNames!T)
        {
            auto init = __traits(getMember, T, field).init;
            enum offset = __traits(getMember, T, field).offsetof;
            mixin("bytes"~rand~"[offset..(offset + TypeOf!(T, field).sizeof)] = (cast(ubyte*)&init)[0..TypeOf!(T, field).sizeof];");
        }
        // 8 bytes after this are __monitor, but we don't need to create one 
        mixin("(cast(void**)bytes"~rand~".ptr)[0] = T.classinfo.vtbl.ptr;");
        mixin("T ret = cast(T)bytes"~rand~".ptr;");
        ret.__ctor();
        return ret;
    }
}

// TODO: Arrays
T dsbNew(T, bool ctor = true)()
    if (!is(T : U[], U))
{
    static if (!is(T == class))
    {
        static if (hasCtor!T)
            T ret = T(args);
        else
            T ret;
        return ret;
    }
    else
    {
        enum capacity = 100_194_304 - __traits(classInstanceSize, T);
        static ptrdiff_t offset;
        static ubyte[100_194_304] data;
        //assert(offset < capacity, "DSB allocator ran out of available memory!");

        static foreach (field; FieldNames!T)
        {
            {
                auto init = __traits(getMember, T, field).init;
                ptrdiff_t _offset = __traits(getMember, T, field).offsetof + offset;
                data[_offset..(_offset + TypeOf!(T, field).sizeof)] = (cast(ubyte*)&init)[0..TypeOf!(T, field).sizeof];
            }
        }

        // 8 bytes after this are __monitor, but we don't need to create one 
        (cast(void**)(cast(ubyte*)&data + offset))[0] = T.classinfo.vtbl.ptr;
        T ret = cast(T)(cast(ubyte*)&data + offset);
        static if (ctor)
            ret.__ctor();
        offset += __traits(classInstanceSize, T);
        return ret;
    }
}