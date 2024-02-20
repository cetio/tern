module tern.builtin;

import core.simd;
import core.builtins;
import core.atomic;
import core.sync.mutex;
import std.traits;

public:
static:
shared Mutex mutex;

shared static this()
{
    mutex = new shared Mutex();
}

void prefetch(bool RW, bool LOCALITY)(void* ptr)
{
    version(GDC)
        __builtin_prefetch(ptr, RW, LOCALITY);
    else version (LDC)
        llvm_prefetch(ptr, RW, LOCALITY, 1);
    else
        prefetch!(RW == 1, LOCALITY)(ptr);
}

pragma(inline)
void fence()
{
    atomicFence();
}

pragma(inline)
auto ref R atomicLoad(R)(ref shared R rhs)
{
    static if (isScalarType!R)
    {
        return atomicLoad(MemoryOrder.seq, rhs);
    }
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return rhs;
    }
}

auto ref R atomicStore(R, L)(ref shared R rhs, shared L lhs)
{
    static if (isScalarType!R)
    {
        return atomicStore(MemoryOrder.seq, rhs, lhs);
    }
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return rhs = lhs;
    }
}

auto ref R atomicExchange(R, L)(ref shared R rhs, L lhs)
{
    static if (isScalarType!R)
    {
        return atomicExchange(MemoryOrder.seq, &rhs, lhs);
    }
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        R t = lhs;
        lhs = rhs; 
        return rhs = t;
    }
}

auto ref R atomicOp(string op, R, L)(ref shared R rhs, L lhs)
{
    
}

R atomicFetchAdd(R, L)(auto ref R rhs, L lhs);
R atomicFetchSub(R, L)(auto ref R rhs, L lhs);

//void spinLock(uint* lock);
//void spinUnlock(uint* lock);