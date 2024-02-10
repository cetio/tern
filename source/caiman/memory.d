/// Lightning fast and easy hardware-accelerated memory operations
module caiman.memory;

import std.traits;
import core.simd;
import caiman.experimental.heap_allocator;

public:
static:
@nogc:
/**
 * Allocates an entry of `size` 
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  size = Size to be allocated.
 *
 * Returns:
 *  Pointer to the allocated entry.
 */
@trusted void* malloc(ptrdiff_t size) => caiman.experimental.heap_allocator.malloc!true(size);

/**
 * Allocates an entry of `size` and clears the entry.
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  size = Size of the new entry.
 *
 * Returns:
 *  Pointer to the allocated entry.
 */
@trusted void* calloc(ptrdiff_t size) => caiman.experimental.heap_allocator.calloc!true(size);

/**
 * Reallocates `ptr` with `size` \
 * Tries to avoid actually doing a new allocation if possible.
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be reallocated.
 *  size = Size of the new entry.
 */
@trusted void realloc(ref void* ptr, ptrdiff_t size) => caiman.experimental.heap_allocator.realloc!true(ptr, size);

/**
 * Zeroes the entry pointed to by `ptr`
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be zeroed.
 */
@trusted void wake(void* ptr) => caiman.experimental.heap_allocator.wake!true(ptr);

/**
 * Frees `ptr`, self explanatory.
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be freed.
 *
 * Returns:
 *  True if this succeeded, otherwise false.
 */
@trusted bool free(void* ptr) => caiman.experimental.heap_allocator.free!true(ptr);

/**
 * Clears and then frees `ptr` before allocating `ptr` as a new entry with `calloc`
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be exchanged.
 *  size = New size of `ptr`
 */
@trusted bool exchange(ref void* ptr, ptrdiff_t size)
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
@trusted void copy(scope void* src, scope void* dest, ptrdiff_t length)
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
@trusted void memset(scope void* dest, ptrdiff_t length, ubyte val)
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
@trusted void zeroSecureMemory(void* ptr, ptrdiff_t length) => memset(ptr, length, 0);

@trusted bool isStackAllocated(T)(auto ref T val)
{
    ubyte[1] dummy;
    // This will *probably* be accurate.
    return cast(ptrdiff_t)&val < 0x14FA000 && cast(ptrdiff_t)&val > cast(ptrdiff_t)&dummy;
}