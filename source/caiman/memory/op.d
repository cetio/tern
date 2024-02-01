/// Lightning fast and easy hardware-accelerated memory operations
module caiman.memory.op;

import std.traits;
import core.simd;

public:
static:
pure:
@nogc:
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
@trusted void copy(void* src, void* dest, ptrdiff_t length)
{
    switch (length & 15)
    {
        case 0:
            foreach_reverse (j; 0..(length / 16))
                (cast(ulong2*)dest)[j] = (cast(ulong2*)src)[j];
            break;
        case 8:
            foreach_reverse (j; 0..(length / 8))
                (cast(ulong*)dest)[j] = (cast(ulong*)src)[j];
            break;
        case 4:
            foreach_reverse (j; 0..(length / 4))
                (cast(uint*)dest)[j] = (cast(uint*)src)[j];
            break;
        case 2:
            foreach_reverse (j; 0..(length / 2))
                (cast(ushort*)dest)[j] = (cast(ushort*)src)[j];
            break;
        default:
            foreach_reverse (j; 0..length)
                (cast(ubyte*)dest)[j] = (cast(ubyte*)src)[j];
            break;
    }
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
@trusted void memset(void* dest, ptrdiff_t length, ubyte val)
{
    switch (length & 15)
    {
        case 0:
            foreach_reverse (j; 0..(length / 16))
                (cast(ulong2*)dest)[j] = cast(ulong2)val;
            break;
        case 8:
            foreach_reverse (j; 0..(length / 8))
                (cast(ulong*)dest)[j] = cast(ulong)val;
            break;
        case 4:
            foreach_reverse (j; 0..(length / 4))
                (cast(uint*)dest)[j] = cast(uint)val;
            break;
        case 2:
            foreach_reverse (j; 0..(length / 2))
                (cast(ushort*)dest)[j] = cast(ushort)val;
            break;
        default:
            foreach_reverse (j; 0..length)
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