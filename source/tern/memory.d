/// General-purpose memory optimized memory utilities. For memory management, see `tern.typecons.automem`.
module tern.memory;

// TODO: Support AVX, add c-compilation for if SSE/AVX isnt supported, add memset
import tern.experimental.heap_allocator;
import tern.traits;
import core.bitop;
import inteli.tmmintrin;
import inteli.emmintrin;
import inteli.smmintrin;

public:
@nogc:
/**
 * Counts the number of trailing zeroes in `DIR` direction in `mask`.
 *
 * Params:
 *  DIR = Direction to count in, will find index if `DIR == 0` or last index if `DIR == 1`.
 *  mask = Mask to be counted from.
 * 
 * Returns:
 *  Number of trailing zeroes in `DIR` direction in `mask`.
 */
pragma(inline, true)
size_t ctz(uint DIR)(size_t mask) 
{
    if (mask == 0)
        return -1;

    static if (DIR == 0)
        return bsf(mask);
    else
        return bsr(mask);
}

/**
 * Finds the index of `elem` in `src` within `0..len` using SIMD intrinsics.
 *
 * Assumes that `len` is a multiple of 16 and undefined behavior if `T` is not an integral or vector size.
 *
 * Params:
 *  DIR = Direction to count in, will find index if `DIR == 0` or last index if `DIR == 1`.
 *  src = Data source pointer.
 *  len = Length of data to be memchrned.
 *  elem = Data to be searched for.
 */
pragma(inline, true)
size_t memchr(uint DIR, T)(const scope void* src, size_t len, const scope T elem)
{
    static if (T.sizeof == 16)
    {
        __m128d val = _mm_loadu_pd(cast(double*)&elem);
        static if (DIR == 0)
        {
            foreach (i; 0..(len / 16))
            {
                if (_mm_cmpeq_pd(_mm_loadu_pd(cast(double*)(cast(__m128d*)src + i)), val) != 0)
                    return i;
            }
        }
        else
        {
            foreach_reverse (i; 0..(len / 16))
            {
                if (_mm_cmpeq_pd(_mm_loadu_pd(cast(double*)(cast(__m128d*)src + i)), val) != 0)
                    return i;
            }
        }
        return -1;
    }
    else static if (T.sizeof == 8)
    {
        ulong val = *cast(ulong*)&elem;
        static if (DIR == 0)
        {
            foreach (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi64(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi64x(val));
                size_t mask = cast(size_t)_mm_movemask_pd(cast(__m128d)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return index + (i * 2);
            }
        }
        else
        {
            foreach_reverse (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi64(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi64x(val));
                size_t mask = cast(size_t)_mm_movemask_pd(cast(__m128d)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return index + (i * 2);
            }
        }
        return -1;
    }
    else static if (T.sizeof == 4)
    {
        uint val = *cast(uint*)&elem;
        static if (DIR == 0)
        {
            foreach (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi32(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi32(val));
                size_t mask = cast(size_t)_mm_movemask_ps(cast(__m128)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return index + (i * 4);
            }
        }
        else
        {
            foreach_reverse (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi32(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi32(val));
                size_t mask = cast(size_t)_mm_movemask_ps(cast(__m128)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return index + (i * 4);
            }
        }
        return -1;
    }
    else static if (T.sizeof == 2)
    {
        ushort val = *cast(ushort*)&elem;
        static if (DIR == 0)
        {
            foreach (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi16(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi16(val));
                size_t mask = cast(size_t)_mm_movemask_epi8(cast(__m128)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return (index / 2) + (i * 8);
            }
        }
        else
        {
            foreach_reverse (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi16(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi16(val));
                size_t mask = cast(size_t)_mm_movemask_epi8(cast(__m128)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return (index / 2) + (i * 8);
            }
        }
        return -1;
    }
    else
    {
        ubyte val = *cast(ubyte*)&elem;
        static if (DIR == 0)
        {
            foreach (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi8(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi8(val));
                size_t mask = cast(size_t)_mm_movemask_epi8(cast(__m128d)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return index + (i * 16);
            }
        }
        else
        {
            foreach_reverse (i; 0..(len / 16))
            {
                __m128i cmp = _mm_cmpeq_epi8(_mm_loadu_si128(cast(__m128i*)src + i), _mm_set1_epi8(val));
                size_t mask = cast(size_t)_mm_movemask_epi8(cast(__m128d)cmp);
                size_t index = ctz!DIR(mask);

                if (index != -1)
                    return index + (i * 16);
            }
        }
        return -1;
    }
}

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
 * Zeroes the entry pointed to by `ptr`.
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

pure:
/**
 * Creates a reference to `V` instance data.
 *
 * Returns:
 *  `void*` to `V` instance data.
 */
pragma(inline, true)
@trusted scope void* reference(alias V)()
{
    static if (is(typeof(V) == class))
        return cast(void*)V;
    else static if (isDynamicArray!(typeof(V)))
        return cast(void*)V.ptr;
    else
        return cast(void*)&V;
}

static:
/** 
 * Copies all data from `src` to `dst` within range `0..len`.
 *
 * Params:
 *  src = Data source pointer.
 *  dst = Data destination pointer.
 *  len = Length of data to be copied.
 */
pragma(inline, true)
void memcpy(const scope void* src, const scope void* dst, size_t len)
{
    switch (len % 16)
    {
        case 0:
            foreach (i; 0..(len / 16))
                _mm_storeu_pd(cast(double*)dst + i, _mm_loadu_pd(cast(double*)(cast(__m128d*)src + i)));
            break;
        case 8:
            foreach (i; 0..(len / 8))
                (cast(ulong*)dst)[i] = (cast(ulong*)src)[i];
            break;
        case 4:
            foreach (i; 0..(len / 4))
                (cast(uint*)dst)[i] = (cast(uint*)src)[i];
            break;
        case 2:
            foreach (i; 0..(len / 2))
                (cast(ushort*)dst)[i] = (cast(ushort*)src)[i];
            break;
        default:
            foreach (i; 0..len)
                (cast(ubyte*)dst)[i] = (cast(ubyte*)src)[i];
            break;
    }
}

/// ditto
pragma(inline, true)
void memcpy(size_t len)(const scope void* src, const scope void* dst)
{
    static if (len % 16 == 0)
    {
        static foreach (i; 0..(len / 16))
            _mm_storeu_pd(cast(double*)dst + i, _mm_loadu_pd(cast(__m128d*)src + i));
    }
    else static if (len % 8 == 0)
    {            
        static foreach (i; 0..(len / 8))
            (cast(ulong*)dst)[i] = (cast(ulong*)src)[i];
    }
    else static if (len % 4 == 0)
    {            
        static foreach (i; 0..(len / 4))
            (cast(uint*)dst)[i] = (cast(uint*)src)[i];
    }
    else static if (len % 2 == 0)
    {            
        static foreach (i; 0..(len / 2))
            (cast(ushort*)dst)[i] = (cast(ushort*)src)[i];
    }
    else
    {            
        static foreach (i; 0..len)
            (cast(ubyte*)dst)[i] = (cast(ubyte*)src)[i];
    }
}

/** 
 * Zeroes all bytes at `src` within range `0..len`.
 *
 * Params:
 *  src = Data source pointer.
 *  len = Length of data to be copied.
 */
pragma(inline, true)
void memzero(const scope void* src, size_t len)
{
    switch (len % 16)
    {
        case 0:
            foreach (i; 0..(len / 16))
                _mm_storeu_pd(cast(double*)src + i, [0, 0]);
            break;
        case 8:
            foreach (i; 0..(len / 8))
                (cast(ulong*)src)[i] = 0;
            break;
        case 4:
            foreach (i; 0..(len / 4))
                (cast(uint*)src)[i] = 0;
            break;
        case 2:
            foreach (i; 0..(len / 2))
                (cast(ushort*)src)[i] = 0;
            break;
        default:
            foreach (i; 0..len)
                (cast(ubyte*)src)[i] = 0;
            break;
    }
}

/**
 * Swaps all bytes at `src` from `0..len`.
 *
 * Params:
 *  src = Data source pointer.
 *  len = Length of data to be byte-swapped.
 */
pragma(inline, true)
void byteswap(const scope void* src, size_t len)
{
    if (len % 16 == 0)
    {
        foreach (i; 0..(len / 16))
        {
            __m128i mask = _mm_setr_epi8(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);
            _mm_storeu_pd(cast(double*)(cast(__m128i*)src + i), cast(__m128d)_mm_shuffle_epi8(_mm_loadu_si128(cast(__m128i*)src + i), mask));
        }

        size_t end = (len / 32);
        foreach (i; 0..(len / 32))
        {
            __m128d t = _mm_loadu_pd(cast(double*)(cast(__m128*)src + i));
            _mm_storeu_pd(cast(double*)(cast(__m128*)src + i), _mm_loadu_pd(cast(double*)(cast(__m128*)src + (end - i))));
            _mm_storeu_pd(cast(double*)(cast(__m128*)src + (end - i)), t);
        }
        return;
    }

    // TODO: Not this
    import std.algorithm : reverse;
    (cast(ubyte*)src)[0..len].reverse();
}

pragma(inline, true)
void emplace(T)(T* ptr)
{
    if (!hasChildren!T)
    {
        T t;
        memcpy!T.sizeof(cast(void*)ptr, cast(void*)&t);
    }
    else
    {
        static foreach (field; Fields!T)
        {
            typeof(getChild!(T, field)) t;
            memcpy!T.sizeof(cast(void*)ptr + getChild!(T, field).offsetof, cast(void*)&t);
        }
    }
}