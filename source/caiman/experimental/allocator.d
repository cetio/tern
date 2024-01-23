module caiman.experimental.allocator;

import std.experimental.allocator.mmap_allocator;
import std.experimental.allocator;
import core.simd;
import core.sync.mutex;
debug import std.stdio;
import std.algorithm;
debug import std.conv;

private enum BLOCK_SIZE = 1048576;
private enum TAKE_SIZE = 256;
private enum ALIGNMENT = ptrdiff_t.sizeof - 1;
private static immutable MmapAllocator os;
private shared static Mutex mutex;

shared static this()
{
    mutex = new shared Mutex();
}

private struct Block
{
public:
final:
@nogc:
    void* baseAddress;
    void* currentAddress;
    ptrdiff_t size;
    uint[] taken;
    Entry[] entries;

    pure this(void* baseAddress, ptrdiff_t size)
    {
        this.baseAddress = baseAddress;
        this.currentAddress = baseAddress;
        this.size = size;
        this.taken = os.makeArray!uint(TAKE_SIZE);
    }

    void claimId(void* ptr)
    {
        synchronized (mutex)
        {
            foreach (i; 0..taken.length)
            {
                if (taken[i] != 0)
                {
                    if (i == taken.length - 1)
                        os.expandArray!uint(taken, TAKE_SIZE);
                    continue;
                }
                taken[i] = cast(uint)(cast(ptrdiff_t)ptr ^ cast(ptrdiff_t)baseAddress) + 1;
                break;
            }
        }
    }

    ptrdiff_t findId(void* ptr)
    {
        synchronized (mutex)
        {
            uint id = cast(uint)(cast(ptrdiff_t)ptr ^ cast(ptrdiff_t)baseAddress) + 1;
            foreach (i; 0..taken.length)
            {
                if (taken[i] == id)
                    return i;
            }
            return -1;
        }
    }

    @nogc Entry* findEntry(ptrdiff_t size)
    {
        synchronized (mutex)
        {
            foreach (ref entry; entries)
            {
                ptrdiff_t index = findId(entry.ptr);
                debug writeln("Checked entry for allocation ", entry.ptr, " is available: ", index == -1 && entry.size >= size);
                if (index == -1 && entry.size >= size)
                    return &entry;
            }
            debug writeln("Found no available entries");
            return null;
        }
    }

    bool empty()
    {
        synchronized (mutex)
        {
            foreach (id; taken)
            {
                if (id != 0)
                    return false;
            }
            return true;
        }
    }

    bool free(void* ptr)
    {
        synchronized (mutex)
        {
            ptrdiff_t index = findId(ptr);
            if (index != -1)
            {
                if (empty)
                {
                    currentAddress = baseAddress;
                    taken = null;
                    entries = null;
                    debug writeln("Freed block");
                }
                else 
                {
                    debug writeln("Freed entry");
                    taken[index] = 0;
                }
                return true;
            }
            return false;
        }
    }

    Entry allocate(ptrdiff_t size)
    {
        synchronized (mutex)
        {
            if (baseAddress == currentAddress)
            {
                entries = os.makeArray!Entry(1);
                entries[0] = Entry(currentAddress, size);
                debug writeln("Allocated new table for entry ", currentAddress, ", size: ", size);
            }
            else
            {
                os.expandArray!Entry(entries, 1);
                entries[$-1] = Entry(currentAddress, size);
                debug writeln("Created new entry in table ", currentAddress, ", size: ", size);
            }

            claimId(entries[$-1].ptr);
            currentAddress += size + (ptrdiff_t.sizeof - (size & ALIGNMENT));
            return entries[$-1];
        }
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

    private void allocate(ptrdiff_t size)
    {
        synchronized (mutex)
        {
            void[] alloc = os.allocate(size);
            os.expandArray!Block(blocks, 1);
            blocks[$-1] = Block(alloc.ptr, size);
            debug writeln("Allocated new block, size: ", alloc.length);
        }
    }

    void* malloc(ptrdiff_t size)
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
                if (offset >= BLOCK_SIZE)
                    continue;

                if (block.size - offset >= size)
                {
                    Entry* entry = block.findEntry(size);
                    if (entry != null)
                    {
                        block.claimId(entry.ptr);
                        return entry.ptr;
                    }
                    else
                        return block.allocate(size).ptr;
                }
            }

            allocate(size);
            return blocks[$-1].allocate(size).ptr;
        }
    }

    void* calloc(ptrdiff_t size)
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

    void* realloc(alias alloc)(void* ptr, ptrdiff_t size)
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

    bool free(T : U*, U)(T ptr)
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

    bool deallocate(T : U*, U)(T ptr)
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

    bool empty()
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

    ptrdiff_t totalAlloc()
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
