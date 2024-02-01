/// Fast slab-entry based memory allocator with simple defragmentation
module caiman.memory.allocator;

import std.experimental.allocator.mmap_allocator;
import core.sync.mutex;
import tanya.container.list;
import tanya.container.hashtable;
import caiman.memory.op;

private enum SLAB_SIZE = 1048576;
private enum ALIGN = ptrdiff_t.sizeof * 4;
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
    ptrdiff_t offset;
    ptrdiff_t size;
    HashTable!(void*, Entry) entries;
    SList!Entry available;

    pure this(void* baseAddress, ptrdiff_t size)
    {
        this.baseAddress = baseAddress;
        this.size = size;
    }

    pragma(inline)
    bool empty()
    {
        ptrdiff_t count;
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
    void* insertEntry(ptrdiff_t size)
    {
        void* ptr = baseAddress + offset;
        size += ALIGN - (cast(ptrdiff_t)ptr & (ALIGN - 1));
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
    ptrdiff_t size;
}

public:
final:
@nogc:
static:
pragma(inline)
@trusted void* malloc(bool threadSafe = false)(ptrdiff_t size)
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

pragma(inline)
@trusted void* calloc(bool threadSafe = false)(ptrdiff_t size)
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

pragma(inline)
@trusted void* realloc(bool threadSafe = false)(void* ptr, ptrdiff_t size)
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
                        return null;

                    Entry entry = slab.entries[ptr];
                    if (entry.size >= size || (cast(ptrdiff_t)entry.ptr + size < slab.offset + slab.size && entry.ptr + entry.size !in slab.entries))
                        return ptr;

                    foreach (_entry; slab.available)
                    {
                        if (_entry.ptr == entry.ptr + entry.size)
                            return ptr;
                    }

                    if (entry.ptr == ptr)
                    {
                        void* dest = malloc(size);
                        copy(ptr, dest, entry.size);
                        slab.free(ptr);
                        return dest;
                    }
                }
            }
            return ptr;
        }
    }
    else
    {
        foreach (ref slab; slabs)
        {
            if (ptr >= slab.baseAddress && ptr < slab.baseAddress + slab.offset)
            {
                if (ptr !in slab.entries)
                    return null;

                Entry entry = slab.entries[ptr];
                if (entry.size >= size || (cast(ptrdiff_t)entry.ptr + size < slab.offset + slab.size && entry.ptr + entry.size !in slab.entries))
                    return ptr;

                foreach (_entry; slab.available)
                {
                    if (_entry.ptr == entry.ptr + entry.size)
                        return ptr;
                }

                if (entry.ptr == ptr)
                {
                    void* dest = malloc(size);
                    copy(ptr, dest, entry.size);
                    slab.free(ptr);
                    return dest;
                }
            }
        }
        return ptr;
    }
}

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
                    (cast(ptrdiff_t*)&arr)[0] = slab.size;
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
                (cast(ptrdiff_t*)&arr)[0] = slab.size;
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