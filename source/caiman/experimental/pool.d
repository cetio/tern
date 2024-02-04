/// Thread safe abstraction of `camain.memory.allocator`
module caiman.experimental.pool;

import caiman.experimental.allocator;

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
@trusted void* malloc(ptrdiff_t size) => caiman.experimental.allocator.malloc!true(size);

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
@trusted void* calloc(ptrdiff_t size) => caiman.experimental.allocator.calloc!true(size);

/**
 * Reallocates `ptr` with `size` \
 * Tries to avoid actually doing a new allocation if possible.
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be reallocated.
 *  size = Size of the new entry.
 */
@trusted void realloc(ref void* ptr, ptrdiff_t size) => caiman.experimental.allocator.realloc!true(ptr, size);

/**
 * Zeroes the entry pointed to by `ptr`
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be zeroed.
 */
@trusted void wake(void* ptr) => caiman.experimental.allocator.wake!true(ptr);

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
@trusted bool free(void* ptr) => caiman.experimental.allocator.free!true(ptr);

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