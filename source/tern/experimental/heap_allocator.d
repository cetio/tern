/// Fast slab-entry based memory allocator with simple defragmentation.
/// Recommended to use `tern.memory` instead if you want thread-safety
module tern.experimental.heap_allocator;

import std.experimental.allocator.mmap_allocator;
import core.sync.mutex;
import tanya.container.list;
import tanya.container.hashtable;
import tern.memory;

private enum SLAB_SIZE = 1_048_576;
private enum ALIGN = size_t.sizeof * 4;
private static immutable MmapAllocator os;
private shared static Mutex mutex;
private static SList!Slab slabs;

shared static this()
{
    slabs.insertFront(Slab(os.allocate(SLAB_SIZE).ptr, SLAB_SIZE));
    mutex = new shared Mutex();
}

private struct Slab
{
public:
final:
@nogc:
    void* baseAddress;
    size_t offset;
    size_t size;
    HashTable!(void*, Entry) entries;
    SList!Entry available;

    pure this(void* baseAddress, size_t size)
    {
        this.baseAddress = baseAddress;
        this.size = size;
    }

    pragma(inline)
    bool empty()
    {
        size_t count;
        foreach (entry; available)
            count++;
        return count == entries.length;
    }

    pragma(inline)
    bool free(void* ptr)
    {
        if (ptr !in entries)
            return false;
        
        available.insertFront(entries[ptr]);
        if (empty)
        {
            available.clear();
            entries.clear();
        }
        return true;
    }

    pragma(inline)
    void* insertEntry(size_t size)
    {
        void* ptr = baseAddress + offset;
        size += ALIGN - (cast(size_t)ptr & (ALIGN - 1));
        entries[ptr] = Entry(ptr, size);
        offset += size;
        return ptr;
    }
}

public struct Entry
{
public:
final:
    void* ptr;
    size_t size;
}

public:
final:
@nogc:
static:
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
pragma(inline)
@trusted void* malloc(bool threadSafe = false)(size_t size)
{
    static if (threadSafe)
    {
        synchronized (mutex)
        {
            foreach (ref slab; slabs)
            {
                if (slab.offset + size <= slab.size)
                {
                    foreach (entry; slab.available)
                    {
                        if (entry.size >= size)
                            return entry.ptr;
                    }
                    return slab.insertEntry(size);
                }
            }

            if (size > SLAB_SIZE)
            {
                slabs.insertFront(Slab(os.allocate(size).ptr, size));
                return slabs.front.insertEntry(size);
            }

            slabs.insertFront(Slab(os.allocate(SLAB_SIZE).ptr, SLAB_SIZE));
            return slabs.front.insertEntry(size);
        }
    }
    else
    {
        foreach (ref slab; slabs)
        {
            if (slab.offset + size <= slab.size)
            {
                foreach (entry; slab.available)
                {
                    if (entry.size >= size)
                        return entry.ptr;
                }
                return slab.insertEntry(size);
            }
        }

        if (size > SLAB_SIZE)
        {
            slabs.insertFront(Slab(os.allocate(size).ptr, size));
            return slabs.front.insertEntry(size);
        }

        slabs.insertFront(Slab(os.allocate(SLAB_SIZE).ptr, SLAB_SIZE));
        return slabs.front.insertEntry(size);
    }
}

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
pragma(inline)
@trusted void* calloc(bool threadSafe = false)(size_t size)
{
    static if (threadSafe)
    {
        synchronized (mutex)
        {
            void* ptr = malloc(size);
            memset(ptr, size, 0);
            return ptr;
        }
    }
    else
    {
        void* ptr = malloc(size);
        memset(ptr, size, 0);
        return ptr;
    }
}

/**
 * Reallocates `ptr` with `size`  
 * Tries to avoid actually doing a new allocation if possible.
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be reallocated.
 *  size = Size of the new entry.
 */
pragma(inline)
@trusted void realloc(bool threadSafe = false)(ref void* ptr, size_t size)
{
    static if (threadSafe)
    {
        synchronized (mutex)
        {
            foreach (ref slab; slabs)
            {
                if (ptr >= slab.baseAddress && ptr < slab.baseAddress + slab.offset)
                {
                    if (ptr !in slab.entries)
                        return;

                    Entry entry = slab.entries[ptr];
                    if (entry.size >= size || (cast(size_t)entry.ptr + size < slab.offset + slab.size && entry.ptr + entry.size !in slab.entries))
                        return;

                    foreach (_entry; slab.available)
                    {
                        if (_entry.ptr == entry.ptr + entry.size)
                            return;
                    }

                    if (entry.ptr == ptr)
                    {
                        void* dest = malloc(size);
                        copy(ptr, dest, entry.size);
                        slab.free(ptr);
                        ptr = dest;
                    }
                }
            }
        }
    }
    else
    {
        foreach (ref slab; slabs)
        {
            if (ptr >= slab.baseAddress && ptr < slab.baseAddress + slab.offset)
            {
                if (ptr !in slab.entries)
                    return;

                Entry entry = slab.entries[ptr];
                if (entry.size >= size || (cast(size_t)entry.ptr + size < slab.offset + slab.size && entry.ptr + entry.size !in slab.entries))
                    return;

                foreach (_entry; slab.available)
                {
                    if (_entry.ptr == entry.ptr + entry.size)
                        return;
                }

                if (entry.ptr == ptr)
                {
                    void* dest = malloc(size);
                    copy(ptr, dest, entry.size);
                    slab.free(ptr);
                    ptr = dest;
                }
            }
        }
    }
}

/**
 * Zeroes the entry pointed to by `ptr`
 *
 * Params:
 *  threadSafe = Should this operation be thread safe? Default false.
 *  ptr = Pointer to entry to be zeroed.
 */
pragma(inline)
@trusted void wake(bool threadSafe = false)(void* ptr)
{
    static if (threadSafe)
    {
        synchronized (mutex)
        {
            foreach (ref slab; slabs)
            {
                if (ptr >= slab.baseAddress && ptr < slab.baseAddress + slab.offset)
                {
                    if (ptr !in slab.entries)
                        return;

                    Entry entry = slab.entries[ptr];
                    memset(ptr, entry.size, 0);
                }
            }
        }
    }
    else
    {
        foreach (ref slab; slabs)
        {
            if (ptr >= slab.baseAddress && ptr < slab.baseAddress + slab.offset)
            {
                if (ptr !in slab.entries)
                    return;

                Entry entry = slab.entries[ptr];
                memset(ptr, entry.size, 0);
            }
        }
    }
}

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
pragma(inline)
@trusted bool free(bool threadSafe = false)(void* ptr)
{
    static if (threadSafe)
    {
        synchronized (mutex)
        {
            foreach (ref slab; slabs)
            {
                if (slab.free(ptr))
                    return true;
            }
            return false;
        }
    }
    else
    {
        foreach (ref slab; slabs)
        {
            if (slab.free(ptr))
                return true;
        }
        return false;
    }
}

pragma(inline)
@trusted bool deallocate(bool threadSafe = false)(void* ptr)
{
    static if (threadSafe)
    {
        synchronized (mutex)
        {
            foreach (ref slab; slabs)
            {
                if (ptr == slab.baseAddress)
                {
                    void[] arr = void;
                    (cast(size_t*)&arr)[0] = slab.size;
                    (cast(void**)&arr)[1] = ptr;

                    if (!os.deallocate(arr))
                        return false;

                    slab.size = 0;
                    return true;
                }
            }
            return false;
        }
    }
    else
    {
        foreach (ref slab; slabs)
        {
            if (ptr == slab.baseAddress)
            {
                void[] arr = void;
                (cast(size_t*)&arr)[0] = slab.size;
                (cast(void**)&arr)[1] = ptr;

                if (!os.deallocate(arr))
                    return false;

                slab.size = 0;
                return true;
            }
        }
        return false;
    }
}