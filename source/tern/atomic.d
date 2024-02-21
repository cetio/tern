module tern.atomic;

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

pragma(inline)
void fence()
{
    atomicFence();
}

pragma(inline)
auto atomicLoad(R)(ref shared R rhs)
{
    static if (isScalarType!R)
        return core.atomic.atomicLoad!(MemoryOrder.seq)(rhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return rhs;
    }
}

unittest
{
    shared int val = 10;
    assert(val.atomicLoad == 10);
}

void atomicStore(R, L)(ref shared R rhs, L lhs)
{
    static if (isScalarType!R)
        core.atomic.atomicStore!(MemoryOrder.seq)(rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        rhs = lhs;
    }
}

unittest
{
    shared int val = 10;
    val.atomicStore(7);
    assert(val.atomicLoad == 7);
}

void atomicExchange(R, L)(ref shared R rhs, L lhs)
{
    static if (isScalarType!R)
        core.atomic.atomicExchange!(MemoryOrder.seq)(&rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        R t = lhs;
        lhs = rhs; 
        rhs = t;
    }
}

unittest
{
    shared int val = 10;
    shared int val2 = 1;
    val.atomicExchange(val2);
    assert(val.atomicLoad == 1);
}

auto atomicOp(string op, R, L)(ref shared R rhs, L lhs)
{
    static if (isScalarType!R)
        return core.atomic.atomicOp!op(rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return mixin("rhs "~op~" lhs");
    }
}

unittest
{
    shared int val = 10;
    assert(val.atomicOp!"+"(1) == 11);
}

//void spinLock(uint* lock);
//void spinUnlock(uint* lock);