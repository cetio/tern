/// Reimplementation of `core.atomic` with better data support.
module tern.atomic;

import tern.traits;
import core.atomic;
import core.sync.mutex;
import core.sync.condition;

private:
static:
shared Mutex mutex;

public:
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

/// Atomically loads the value of `rhs`.
pragma(inline)
auto atomicLoad(R)(ref shared R rhs)
{
    static if (isScalar!R)
        return core.atomic.atomicLoad!(MemoryOrder.seq)(rhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return rhs;
    }
}

/// Atomically loads an array element in the value of `rhs`.
pragma(inline)
auto atomicLoadElem(size_t ELEM, R)(ref shared R rhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return rhs[ELEM];
}

/// Atomically loads a field element in the value of `rhs`.
pragma(inline)
auto atomicLoadElem(string ELEM, R)(ref shared R rhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return mixin("rhs."~ELEM);
}


/// Atomically stores `lhs` in `rhs`.
pragma(inline)
void atomicStore(R, L)(ref shared R rhs, L lhs)
{
    static if (isScalar!R)
        core.atomic.atomicStore!(MemoryOrder.seq)(rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        rhs = lhs;
    }
}

/// Atomically stores the array element `lhs` in an array element of `rhs`.
pragma(inline)
auto atomicLoadElem(size_t ELEM, R)(ref shared R rhs, L lhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return rhs[ELEM] = lhs;
}

/// Atomically stores the field element `lhs` in a field element of `rhs`.
pragma(inline)
auto atomicLoadElem(string ELEM, R)(ref shared R rhs, L lhs)
{
    mutex.lock();
    scope (exit) mutex.unlock();
    return mixin("rhs."~ELEM~" = lhs");
}

/// Atomically exchanges `rhs` and `lhs`.
pragma(inline)
void atomicExchange(R, L)(ref shared R rhs, L lhs)
{
    static if (isScalar!R)
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

/// Performs an atomic operation `op` on `rhs` and `lhs`.
pragma(inline)
auto atomicOp(string op, R, L)(ref shared R rhs, L lhs)
{
    static if (isScalar!R)
        return core.atomic.atomicOp!op(rhs, lhs);
    else
    {
        mutex.lock();
        scope (exit) mutex.unlock();
        return mixin("rhs "~op~" lhs");
    }
}

/// Spinlock implementation backed by `Condition`.
public class SpinLock
{
private:
final:
shared:
    Mutex mutex;
    Condition condition;

public:
    this()
    {
        mutex = new shared Mutex();
        condition = new shared Condition(mutex);
    }

    void lock() shared
    {
        mutex.lock();
        while (!tryLock())
            condition.wait();
    }

    bool tryLock() shared
    {
        return mutex.tryLock();
    }

    void unlock() shared
    {
        mutex.unlock();
        condition.notifyAll();
    }
}