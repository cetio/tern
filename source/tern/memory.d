/// General-purpose and hardware-accelerated memory operations and allocation functions
module tern.memory;

import std.traits;
import core.simd;
import tern.experimental.heap_allocator;
import std.algorithm;

public enum Endianness
{
    Native,
    LittleEndian,
    BigEndian
}

public:
static:
@nogc:
/**
 * Allocates an entry of `size` 
 *
 * Params:
 *  size = Size to be allocated.
 *
 * Returns:
 *  Pointer to the allocated entry.
 */
@trusted void* malloc(size_t size) => tern.experimental.heap_allocator.malloc!true(size);

/**
 * Allocates an entry of `size` and clears the entry.
 *
 * Params:
 *  size = Size of the new entry.
 *
 * Returns:
 *  Pointer to the allocated entry.
 */
@trusted void* calloc(size_t size) => tern.experimental.heap_allocator.calloc!true(size);

/**
 * Reallocates `ptr` with `size`  
 * Tries to avoid actually doing a new allocation if possible.
 *
 * Params:
 *  ptr = Pointer to entry to be reallocated.
 *  size = Size of the new entry.
 */
@trusted void realloc(ref void* ptr, size_t size) => tern.experimental.heap_allocator.realloc!true(ptr, size);

/**
 * Zeroes the entry pointed to by `ptr`
 *
 * Params:
 *  ptr = Pointer to entry to be zeroed.
 */
@trusted void wake(void* ptr) => tern.experimental.heap_allocator.wake!true(ptr);

/**
 * Frees `ptr`, self explanatory.
 *
 * Params:
 *  ptr = Pointer to entry to be freed.
 *
 * Returns:
 *  True if this succeeded, otherwise false.
 */
@trusted bool free(void* ptr) => tern.experimental.heap_allocator.free!true(ptr);

/**
 * Clears and then frees `ptr` before allocating `ptr` as a new entry with `calloc`
 *
 * Params:
 *  ptr = Pointer to entry to be exchanged.
 *  size = New size of `ptr`
 */
@trusted bool exchange(ref void* ptr, size_t size)
{
    wake(ptr);
    bool ret = free(ptr);
    ptr = calloc(size);
    return ret;
}

pure:
/** 
 * Copies all data from `src` to `dest` within range `0..length`
 *
 * Params:
 *  src = Data source pointer.
 *  dest = Data destination pointer.
 *  length = Length of data to be copied.
 * 
 * Remarks:
 *  This is optimized to do as little writes as necessary, and tries to avoid being O(n)
 */
@trusted void copy(scope void* src, scope void* dest, size_t length)
{
    switch (length & 15)
    {
        case 0:
            foreach (j; 0..(length / 16))
                (cast(ulong2*)dest)[j] = (cast(ulong2*)src)[j];
            break;
        case 8:
            foreach (j; 0..(length / 8))
                (cast(ulong*)dest)[j] = (cast(ulong*)src)[j];
            break;
        case 4:
            foreach (j; 0..(length / 4))
                (cast(uint*)dest)[j] = (cast(uint*)src)[j];
            break;
        case 2:
            foreach (j; 0..(length / 2))
                (cast(ushort*)dest)[j] = (cast(ushort*)src)[j];
            break;
        default:
            foreach (j; 0..length)
                (cast(ubyte*)dest)[j] = (cast(ubyte*)src)[j];
            break;
    }
}

unittest
{
    int a = 0;
    int b = 1;
    copy(&b, &a, 4);
    assert(a == b);
}

/** 
 * Sets all bytes at `dest` to `val` within range `0..length`
 *
 * Params:
 *  dest = Data destination pointer.
 *  length = Length of data to be copied.
 *  val = Value to set all bytes to.
 * 
 * Remarks:
 *  This is optimized to do as little writes as necessary, and tries to avoid being O(n)
 */
@trusted void memset(scope void* dest, size_t length, ubyte val)
{
    switch (length & 15)
    {
        case 0:
            foreach (j; 0..(length / 16))
                (cast(ulong2*)dest)[j] = cast(ulong2)val;
            break;
        case 8:
            foreach (j; 0..(length / 8))
                (cast(ulong*)dest)[j] = cast(ulong)val;
            break;
        case 4:
            foreach (j; 0..(length / 4))
                (cast(uint*)dest)[j] = cast(uint)val;
            break;
        case 2:
            foreach (j; 0..(length / 2))
                (cast(ushort*)dest)[j] = cast(ushort)val;
            break;
        default:
            foreach (j; 0..length)
                (cast(ubyte*)dest)[j] = cast(ubyte)val;
            break;
    }
}

/** 
 * Zeros all bytes at `ptr` within range `0..length`
 *
 * Params:
 *  ptr = Data destination pointer.
 *  length = Length of data to be copied.
 * 
 * Remarks:
 *  This is optimized to do as little writes as necessary, and tries to avoid being O(n)
 */
@trusted void zeroSecureMemory(void* ptr, size_t length) => memset(ptr, length, 0);

/**
* Swaps the endianness of the provided value, if applicable.
*
* Params:
*  val = The value to swap endianness.
*  endianness = The desired endianness.
*
* Returns:
*   The value with swapped endianness.
*/
@trusted T makeEndian(T)(T val, Endianness endianness)
{
    version (LittleEndian)
    {
        if (endianness == Endianness.BigEndian)
        {
            static if (is(T == class))
                (*cast(ubyte**)val)[0..__traits(classInstanceSize, T)].reverse();
            else
                (cast(ubyte*)&val)[0..T.sizeof].reverse();
        }
    }
    else version (BigEndian)
    {
        if (endianness == Endianness.LittleEndian)
        {
            static if (is(T == class))
                (*cast(ubyte**)val)[0..__traits(classInstanceSize, T)].reverse();
            else
                (cast(ubyte*)&val)[0..T.sizeof].reverse();
        }
    }
    return val;
}

/**
 * Checks if `val` is actually a valid, non-null class, and has a valid vtable.
 *
 * Params:
 *  val = The value to check if null.
 *
 * Returns:
 *  True if `val` is null or has an invalid vtable.
 */
@trusted bool isNull(T)(auto ref T val)
    if (is(T == class) || isPointer!T)
{
    return val is null || *cast(void**)val is null;
}