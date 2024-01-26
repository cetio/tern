/+ module caiman.memory.allocator.talloc;

import std.experimental.allocator.mmap_allocator;
import std.experimental.allocator;
import core.simd;
import core.sync.mutex;
debug import std.stdio;
import std.algorithm;
debug import std.conv;
import caiman.container.linkedlist;

private enum SLAB_SIZE = 1048576;
private static immutable MmapAllocator os;
private shared static Mutex mutex;

shared static this()
{
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
    LinkedList!Entry available;
    LinkedList!Entry entries;

    pure this(void* baseAddress, ptrdiff_t size)
    {
        this.baseAddress = baseAddress;
        this.size = size;
    }

    Entry* getEntry(ptrdiff_t size)
    {
        foreach (ref entry; available)
        {
            if (entry.size >= size)
                return &entry;
        }
        return null;
    }

    bool empty()
    {
        return available.length == entries.length;
    }

    bool free(void* ptr)
    {
        if (ptr !in entries)
            return false;
        
        available.insertBack(entries[ptr]);
        if (empty)
        {
            available.clear();
            entries.clear();
        }
        return true;
    }

    void* insertEntry(ptrdiff_t size)
    {
        scope (exit) offset += size;
        void* ptr = baseAddress + offset;
        entries[ptr] = Entry(ptr, size);
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

public static class Caimallocator
{
public:
final:
@nogc:
static:
    private static LinkedList!Slab slabs;

    shared static this()
    {
        insertSlab();
    }

    private void insertSlab()
    {
        void[] alloc = os.allocate(SLAB_SIZE);
        slabs.insertBack(Slab(alloc.ptr, SLAB_SIZE));
    }

    void* malloc(ptrdiff_t size)
    {
        if (size > SLAB_SIZE)
        {
            insertSlab();
            return slabs[$-1].insertEntry(size);
        }

        foreach_reverse (ref slab; slabs)
        {
            if (slab.offset + size <= slab.size)
            {
                Entry* entry = slab.getEntry(size);
                if (entry != null)
                    return entry.ptr;
                else
                    return slab.insertEntry(size);
            }
        }

        insertSlab();
        return slabs[$-1].insertEntry(size);
    }
}
/* public static class Caimallocator
{
public:
final:
@nogc:
static:
    private static Block[] blocks;

    shared static this()
    {
        synchronized (mutex)
        {
            void[] alloc = os.allocate(BLOCK_SIZE * 4);
            blocks = os.makeArray!Block(1);
            blocks[0] = Block(alloc.ptr, BLOCK_SIZE * 4);
            debug writeln("Allocated new block, size: ", alloc.length);
        }
    }

    extern (C) export void allocate(ptrdiff_t size)
    {
        synchronized (mutex)
        {
            void[] alloc = os.allocate(size);
            os.expandArray!Block(blocks, 1);
            blocks[$-1] = Block(alloc.ptr, size);
            debug writeln("Allocated new block, size: ", alloc.length);
        }
    }

    extern (C) export void* malloc(ptrdiff_t size)
    {
        synchronized (mutex)
        {
            if (size > BLOCK_SIZE)
            {
                allocate(size);
                return blocks[$-1].allocate(size).ptr;
            }

            foreach (ref block; blocks)
            {
                const ptrdiff_t offset = block.currentAddress - block.baseAddress;
                if (offset >= cast(ptrdiff_t)block.baseAddress + block.size)
                    continue;

                if (block.size - offset >= size)
                {
                    Entry* entry = block.findEntry(size);
                    if (entry != null)
                        return entry.ptr;
                    else
                        return block.allocate(size).ptr;
                }
            }

            allocate(size);
            return blocks[$-1].allocate(size).ptr;
        }
    }

    extern (C) export void* calloc(ptrdiff_t size)
    {
        void* ptr = malloc(size);
        if (size == 0)
            return ptr;

        switch (size & 15)
        {
            case 0:
                foreach_reverse (i; 0..(size / 16))
                    (cast(ulong2*)ptr)[i] = 0;
                break;
            case 8:
                foreach_reverse (i; 0..(size / 8))
                    (cast(ulong*)ptr)[i] = 0;
                break;
            case 4:
                foreach_reverse (i; 0..(size / 4))
                    (cast(uint*)ptr)[i] = 0;
                break;
            case 2:
                foreach_reverse (i; 0..(size / 2))
                    (cast(ushort*)ptr)[i] = 0;
                break;
            default:
                foreach_reverse (i; 0..size)
                    (cast(ubyte*)ptr)[i] = 0;
                break;
        }
        return ptr;
    }

    extern (C) export void* realloc(alias alloc)(void* ptr, ptrdiff_t size)
    {
        synchronized (mutex)
        {
            foreach (ref block; blocks)
            {
                if (ptr >= block.baseAddress && ptr < block.currentAddress)
                {
                    foreach (i, entry; block.entries)
                    {
                        if (entry.size >= size)
                            return ptr;

                        if (entry.ptr == ptr && ((block.entries.length != 0 && block.size < size) 
                            || (i + 1 < block.entries.length && block.entries[i + 1].ptr - entry.ptr < size)))
                        {
                            void* nptr = alloc(size);
                            switch (size & 15)
                            {
                                case 0:
                                    foreach_reverse (j; 0..(size / 16))
                                        (cast(ulong2*)nptr)[j] = (cast(ulong2*)ptr)[j];
                                    break;
                                case 8:
                                    foreach_reverse (j; 0..(size / 8))
                                        (cast(ulong*)nptr)[j] = (cast(ulong*)ptr)[j];
                                    break;
                                case 4:
                                    foreach_reverse (j; 0..(size / 4))
                                        (cast(uint*)nptr)[j] = (cast(uint*)ptr)[j];
                                    break;
                                case 2:
                                    foreach_reverse (j; 0..(size / 2))
                                        (cast(ushort*)nptr)[j] = (cast(ushort*)ptr)[j];
                                    break;
                                default:
                                    foreach_reverse (j; 0..size)
                                        (cast(ubyte*)nptr)[j] = (cast(ubyte*)ptr)[j];
                                    break;
                            }
                            return nptr;
                        }
                    }
                }
            }
            return ptr;
        }
    }

    extern (C) export bool free(T : U*, U)(T ptr)
    {
        synchronized (mutex)
        {
            foreach (ref block; blocks)
            {
                if (ptr >= block.baseAddress && ptr < block.currentAddress && block.free(ptr))
                    return true;
            }
            return false;
        }
    }

    extern (C) export bool deallocate(T : U*, U)(T ptr)
    {
        synchronized (mutex)
        {
            foreach (ref block; blocks)
            {
                if (ptr == block.baseAddress)
                {
                    void[] arr = void;
                    (cast(ptrdiff_t*)&arr)[0] = block.size;
                    (cast(void**)&arr)[1] = ptr;

                    if (!os.deallocate(arr))
                        return false;

                    Block[] _blocks = os.makeArray!Block(blocks.length - 1);
                    ptrdiff_t index = 0;
                    foreach (_block; blocks)
                    {
                        if (_block != block)
                            _blocks[index++] = _block;
                    }
                    blocks = _blocks;

                    debug writeln("Deallocated block, size: ", block.size);
                    return true;
                }
            }
            return false;
        }
    }

    extern (C) export bool empty()
    {
        synchronized (mutex)
        {
            foreach (block; blocks)
            {
                if (!block.empty)
                    return false;
            }
            return true;
        }
    }

    extern (C) export ptrdiff_t totalAlloc()
    {
        synchronized (mutex)
        {
            ptrdiff_t size;
            foreach (block; blocks)
            {
                foreach (entry; block.entries)
                    size += entry.size;
            }
            return size;
        }
    }
}
 */ +/