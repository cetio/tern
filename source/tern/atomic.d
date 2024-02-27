/// Reimplementation of `core.atomic` with better data support
module tern.atomic;

import core.atomic;
import core.sync.mutex;
import std.traits;
import tern.typecons;

public:
static:
shared Mutex mutex;

shared static this()
{
    mutex = new shared Mutex();
}

/// Inserts a load/store memory fence, ensuring that all loads and stores before this call happen before any loads and stores after.
pragma(inline)
void fence()
{
    atomicFence();
}

/// Atomically loads the value of `rhs`
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

/// Atomically loads an array element in the value of `rhs`
pragma(inline)
auto atomicLoadElem(size_t ELEM, R)(ref shared R rhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return rhs[ELEM];
}

/// Atomically loads a field element in the value of `rhs`
pragma(inline)
auto atomicLoadElem(string ELEM, R)(ref shared R rhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return mixin("rhs."~ELEM);
}

unittest
{
    shared int val = 10;
    assert(val.atomicLoad == 10);
}

/// Atomically stores `lhs` in `rhs`
pragma(inline)
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

/// Atomically stores the array element `lhs` in an array element of `rhs`
pragma(inline)
auto atomicLoadElem(size_t ELEM, R)(ref shared R rhs, L lhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return rhs[ELEM] = lhs;
}

/// Atomically stores the field element `lhs` in a field element of `rhs`
pragma(inline)
auto atomicLoadElem(string ELEM, R)(ref shared R rhs, L lhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return mixin("rhs."~ELEM~" = lhs");
}

unittest
{
    shared int val = 10;
    val.atomicStore(7);
    assert(val.atomicLoad == 7);
}

/// Atomically exchanges `rhs` and `lhs`
pragma(inline)
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

/// Performs an atomic operation `op` on `rhs` and `lhs`
pragma(inline)
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